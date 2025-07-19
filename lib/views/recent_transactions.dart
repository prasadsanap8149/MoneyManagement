import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:secure_money_management/utils/util_services.dart';
import 'package:secure_money_management/models/transaction_model.dart';
import 'package:secure_money_management/services/file_operations_service.dart';
import 'package:secure_money_management/utils/user_experience_helper.dart';
import 'package:secure_money_management/ad_service/widgets/interstitial_ad.dart';
import 'package:secure_money_management/services/secure_transaction_service.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';

class RecentTransactions extends StatefulWidget {
  const RecentTransactions({
    super.key,
  });
  @override
  State<RecentTransactions>  createState() => _RecentTransactionsState();
}

class _RecentTransactionsState extends State<RecentTransactions> {
  late List<TransactionModel> transactions = [];
  final SecureTransactionService _secureStorage = SecureTransactionService();

  @override
  void initState() {
    super.initState();
    _initializeSecureStorage();
    
    // Pre-load interstitial ad for import/export functionality
    _initializeInterstitialAds();
  }

  /// Initialize secure storage and perform migration if needed
  Future<void> _initializeSecureStorage() async {
    try {
      // Initialize the secure transaction service
      await _secureStorage.initialize();
      
      // Attempt to migrate from plain text storage
      final migrated = await _secureStorage.migrateFromPlainTextStorage();
      if (migrated) {
        debugPrint('Successfully migrated transactions to encrypted storage');
      }
      
      // Load transactions after initialization/migration
      await _checkInternetAndLoad();
      
    } catch (e) {
      debugPrint('Error initializing secure storage: $e');
      // Fallback to loading without migration
      await _checkInternetAndLoad();
    }
  }

  /// Initialize and pre-load interstitial ads for better user experience
  void _initializeInterstitialAds() {
    // Pre-load interstitial ad in background
    Future.delayed(const Duration(seconds: 1), () {
      InterstitialAdWidget.instance.loadAd();
    });
  }

  @override
  void dispose() {
    // Dispose of interstitial ads to free memory
    InterstitialAdWidget.instance.dispose();
    super.dispose();
  }

  Future<void> _checkInternetAndLoad() async {
    bool hasInternet = await _checkInternetConnection();
    debugPrint('RESULT @:: $hasInternet');

    if (!hasInternet) {
      if (mounted) {
        UserExperienceHelper.showWarningSnackbar(
          context,
          'No internet connection. Please connect to the internet and try again.',
        );
      }
      return;
    }

    await _loadTransactions();
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<void> _exportTransactions() async {
    // Show interstitial ad before export
    await InterstitialAdHelper.showAdBeforeAction(
      actionName: 'Export Transactions JSON',
      action: () => _performExportTransactions(),
    );
  }

  Future<void> _performExportTransactions() async {
    if (!await _checkInternetConnection()) {
      UserExperienceHelper.showWarningSnackbar(
        context,
        'Internet connection required to export transactions.',
      );
      return;
    }

    // Show loading indicator
    final loadingSnackbar = UserExperienceHelper.showLoadingSnackbar(
      context,
      'Preparing export...',
    );

    try {
      // Use secure storage to get transactions for export
      final transactionsJson = await _secureStorage.backupTransactions();

      if (transactionsJson.isEmpty || transactionsJson == '[]') {
        loadingSnackbar.close();
        UserExperienceHelper.showWarningSnackbar(
          context,
          'No transactions found to export.',
        );
        return;
      }

      // Close loading snackbar
      loadingSnackbar.close();

      // Use FileOperationsService for export with permission handling
      final success = await FileOperationsService().exportFile(
        context,
        content: transactionsJson,
        filename: 'transactions_export.json',
        mimeType: 'application/json',
        feature: 'export transactions',
      );

      if (success) {
        UserExperienceHelper.showSuccessSnackbar(
          context,
          'Transactions exported successfully!',
        );
      }
    } catch (e) {
      loadingSnackbar.close();
      UserExperienceHelper.showErrorSnackbar(
        context,
        'Export failed: ${e.toString()}',
      );
    }
  }

  Future<void> _importTransactions() async {
    // Show interstitial ad before import
    await InterstitialAdHelper.showAdBeforeAction(
      actionName: 'Import Transactions',
      action: () => _performImportTransactions(),
    );
  }

  Future<void> _performImportTransactions() async {
    if (!await _checkInternetConnection()) {
      UserExperienceHelper.showWarningSnackbar(
        context,
        'Internet connection required to import transactions.',
      );
      return;
    }
    
    // Show confirmation dialog explaining the import behavior
    final confirmed = await UserExperienceHelper.showConfirmationDialog(
      context,
      title: 'Import Transactions',
      message: 'This will import transactions from a JSON file and add them to your existing data.\n\n'
               '• Only JSON files exported from SecureMoney are supported\n'
               '• Duplicate transactions will be automatically skipped\n'
               '• Your existing transactions will NOT be replaced\n\n'
               'Do you want to continue?',
      confirmText: 'Import',
      cancelText: 'Cancel',
      confirmColor: Colors.blue,
      icon: Icons.upload_file,
    );

    if (!confirmed) return;

    // Show loading indicator
    final loadingSnackbar = UserExperienceHelper.showLoadingSnackbar(
      context,
      'Importing transactions...',
    );

    try {
      // Use FileOperationsService for JSON import with file restriction
      final jsonStr = await FileOperationsService().importTransactionJsonFile(context);
      
      if (jsonStr != null) {
        try {
          // Use secure storage to import and append transactions (not replace)
          final newTransactionCount = await _secureStorage.importAndAppendTransactions(jsonStr);

          // Reload in app
          await _loadTransactions();

          loadingSnackbar.close();
          
          if (newTransactionCount > 0) {
            UserExperienceHelper.showSuccessSnackbar(
              context,
              'Successfully imported $newTransactionCount new transactions! (Duplicates were skipped)',
            );
          } else {
            UserExperienceHelper.showInfoSnackbar(
              context,
              'No new transactions to import. All transactions from the file already exist.',
            );
          }
        } catch (e) {
          loadingSnackbar.close();
          UserExperienceHelper.showErrorSnackbar(
            context,
            'Import failed: Invalid transaction file format. Please ensure the file is a valid SecureMoney JSON export.',
          );
        }
      } else {
        loadingSnackbar.close();
        UserExperienceHelper.showInfoSnackbar(
          context,
          'Import cancelled or no file selected.',
        );
      }
    } catch (e) {
      loadingSnackbar.close();
      UserExperienceHelper.showErrorSnackbar(
        context,
        'Import failed: ${e.toString()}',
      );
    }
  }

  Future<void> _exportToCSV() async {
    // Show interstitial ad before CSV export
    await InterstitialAdHelper.showAdBeforeAction(
      actionName: 'Export Transactions CSV',
      action: () => _performExportToCSV(),
    );
  }

  Future<void> _performExportToCSV() async {
    if (!await _checkInternetConnection()) {
      UserExperienceHelper.showWarningSnackbar(
        context,
        'Internet connection required to export transactions.',
      );
      return;
    }

    if (transactions.isEmpty) {
      UserExperienceHelper.showWarningSnackbar(
        context,
        'No transactions found to export.',
      );
      return;
    }

    // Show loading indicator
    final loadingSnackbar = UserExperienceHelper.showLoadingSnackbar(
      context,
      'Generating CSV file...',
    );

    try {
      List<List<String>> csvData = [
        // Headers
        ['ID', 'Amount', 'Type', 'Date', 'Category', 'Custom Category'],
        // Rows
        ...transactions.map((txn) => [
              txn.id ?? '',
              txn.amount.toString(),
              txn.type,
              txn.date.toIso8601String(),
              txn.category,
              txn.customCategory ?? '',
            ]),
      ];

      String csv = const ListToCsvConverter().convert(csvData);
      
      // Close loading snackbar
      loadingSnackbar.close();
      
      // Use FileOperationsService for export with permission handling
      final success = await FileOperationsService().exportFile(
        context,
        content: csv,
        filename: 'transactions_export.csv',
        mimeType: 'text/csv',
        feature: 'export transactions as CSV',
      );

      if (success) {
        UserExperienceHelper.showSuccessSnackbar(
          context,
          'CSV file exported successfully!',
        );
      }
    } catch (e) {
      loadingSnackbar.close();
      UserExperienceHelper.showErrorSnackbar(
        context,
        'CSV export failed: ${e.toString()}',
      );
    }
  }

  Future<void> _exportToPDF() async {
    // Show interstitial ad before PDF export
    await InterstitialAdHelper.showAdBeforeAction(
      actionName: 'Export Transactions PDF',
      action: () => _performExportToPDF(),
    );
  }

  Future<void> _performExportToPDF() async {
    if (!await _checkInternetConnection()) {
      UserExperienceHelper.showWarningSnackbar(
        context,
        'Internet connection required to export transactions.',
      );
      return;
    }

    if (transactions.isEmpty) {
      UserExperienceHelper.showWarningSnackbar(
        context,
        'No transactions found to export.',
      );
      return;
    }

    // Show loading indicator
    final loadingSnackbar = UserExperienceHelper.showLoadingSnackbar(
      context,
      'Generating PDF file...',
    );

    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Table.fromTextArray(
              headers: [
                'ID',
                'Amount',
                'Type',
                'Date',
                'Category',
                'Custom Category'
              ],
              data: transactions
                  .map((txn) => [
                        txn.id ?? '',
                        txn.amount.toString(),
                        txn.type,
                        txn.date.toIso8601String(),
                        txn.category,
                        txn.customCategory ?? ''
                      ])
                  .toList(),
            );
          },
        ),
      );

      final bytes = await pdf.save();
      
      // Close loading snackbar
      loadingSnackbar.close();
      
      // Use FileOperationsService for export with permission handling
      final success = await FileOperationsService().exportBinaryFile(
        context,
        bytes: bytes,
        filename: 'transactions_export.pdf',
        mimeType: 'application/pdf',
        feature: 'export transactions as PDF',
      );

      if (success) {
        UserExperienceHelper.showSuccessSnackbar(
          context,
          'PDF file exported successfully!',
        );
      }
    } catch (e) {
      loadingSnackbar.close();
      UserExperienceHelper.showErrorSnackbar(
        context,
        'PDF export failed: ${e.toString()}',
      );
    }
  }

  Future<void> _exportToExcel() async {
    // Show interstitial ad before Excel export
    await InterstitialAdHelper.showAdBeforeAction(
      actionName: 'Export Transactions Excel',
      action: () => _performExportToExcel(),
    );
  }

  Future<void> _performExportToExcel() async {
    if (!await _checkInternetConnection()) {
      UserExperienceHelper.showWarningSnackbar(
        context,
        'Internet connection required to export transactions.',
      );
      return;
    }

    if (transactions.isEmpty) {
      UserExperienceHelper.showWarningSnackbar(
        context,
        'No transactions found to export.',
      );
      return;
    }

    // Show loading indicator
    final loadingSnackbar = UserExperienceHelper.showLoadingSnackbar(
      context,
      'Generating Excel file...',
    );

    try {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Transactions'];

      // Header row
      sheetObject.appendRow([
        TextCellValue('ID'),
        TextCellValue('Amount'),
        TextCellValue('Type'),
        TextCellValue('Date'),
        TextCellValue('Category'),
        TextCellValue('Custom Category'),
      ]);

      // Data rows
      for (var txn in transactions) {
        sheetObject.appendRow([
          TextCellValue(txn.id ?? ''),
          TextCellValue(txn.amount.toString()),
          TextCellValue(txn.type),
          TextCellValue(txn.date.toIso8601String()),
          TextCellValue(txn.category),
          TextCellValue(txn.customCategory ?? ''),
        ]);
      }

      final bytes = excel.save();
      
      // Close loading snackbar
      loadingSnackbar.close();
      
      // Use FileOperationsService for export with permission handling
      final success = await FileOperationsService().exportBinaryFile(
        context,
        bytes: bytes!,
        filename: 'transactions_export.xlsx',
        mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        feature: 'export transactions as Excel',
      );

      if (success) {
        UserExperienceHelper.showSuccessSnackbar(
          context,
          'Excel file exported successfully!',
        );
      }
    } catch (e) {
      loadingSnackbar.close();
      UserExperienceHelper.showErrorSnackbar(
        context,
        'Excel export failed: ${e.toString()}',
      );
    }
  }

  // Load transactions from secure storage
  Future<void> _loadTransactions() async {
    try {
      final loadedTransactions = await _secureStorage.loadTransactions();
      setState(() {
        transactions = loadedTransactions;
      });
    } catch (e) {
      debugPrint('Error loading transactions: $e');
      // If secure loading fails, try to load from legacy storage and migrate
      await _tryLegacyMigration();
    }
  }

  /// Try to load from legacy storage and migrate to secure storage
  Future<void> _tryLegacyMigration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? savedTransactions = prefs.getString('transactions');
      if (savedTransactions != null) {
        List<dynamic> decodedTransactions = jsonDecode(savedTransactions);
        final legacyTransactions = decodedTransactions
            .map((json) => TransactionModel.fromJson(json))
            .toList();
        
        // Migrate to secure storage
        await _secureStorage.saveTransactions(legacyTransactions);
        await prefs.remove('transactions'); // Remove legacy storage
        
        setState(() {
          transactions = legacyTransactions;
        });
        
        debugPrint('Successfully migrated ${legacyTransactions.length} transactions from legacy storage');
      }
    } catch (e) {
      debugPrint('Error during legacy migration: $e');
      setState(() {
        transactions = [];
      });
    }
  }

  String _selectedMonth = 'All'; // Default to show all transactions
  final DateFormat monthFormat = DateFormat('MMMM yyyy');

  @override
  Widget build(BuildContext context) {
    // Group transactions by month
    Map<String, List<TransactionModel>> transactionsByMonth =
        _groupTransactionsByMonth();

    // Calculate income, expenses, and monthly totals
    Map<String, Map<String, double>> monthlyTotals =
        _calculateMonthlyTotals(transactionsByMonth);

    // Get the list of transactions to display (filtered by selected month)
    List<TransactionModel> filteredTransactions = _selectedMonth == 'All'
        ? transactions
        : transactionsByMonth[_selectedMonth] ?? [];

    // Sort filtered transactions by date (descending)
    filteredTransactions.sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Recent Transactions',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          // Import button in app bar
          IconButton(
            onPressed: _importTransactions,
            icon: const Icon(Icons.upload),
            tooltip: 'Import Transactions',
          ),
          // Quick export button in app bar
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'json') _exportTransactions();
              if (value == 'csv') _exportToCSV();
              if (value == 'pdf') _exportToPDF();
              if (value == 'excel') _exportToExcel();
            },
            icon: const Icon(Icons.download),
            tooltip: 'Export Options',
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'json',
                child: Row(
                  children: [
                    Icon(Icons.code, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Export as JSON'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'csv',
                child: Row(
                  children: [
                    Icon(Icons.table_chart, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Export as CSV'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Export as PDF'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'excel',
                child: Row(
                  children: [
                    Icon(Icons.grid_on, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Export as Excel'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
                  onPressed: _exportTransactions,
                  icon: const Icon(Icons.download),
                  label: const Text('Export JSON'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    disabledBackgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding:
                        const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _importTransactions,
                  icon: const Icon(Icons.upload),
                  label: const Text('Import JSON'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    disabledBackgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding:
                        const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // Dropdown to select the month
            DropdownButtonFormField<String>(
              value: _selectedMonth,
              decoration: InputDecoration(
                labelText: 'Select Month',
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.grey, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.teal, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
              items: ['All', ...transactionsByMonth.keys].map((String month) {
                return DropdownMenuItem<String>(
                  value: month,
                  child: Text(month),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedMonth = value!;
                });
              },
            ),

            // Display totals (income, expense, and difference) for selected month
            _selectedMonth != 'All'
                ? Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 5.0, horizontal: 5),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildStatCard(
                            title: 'Income',
                            amount: monthlyTotals[_selectedMonth]?['income'] ?? 0,
                            color: Colors.green.shade200,
                            textColor: Colors.green.shade900,
                          ),
                          const SizedBox(width: 10), // Space between cards
                          _buildStatCard(
                            title: 'Expenses',
                            amount:
                                monthlyTotals[_selectedMonth]?['expenses'] ?? 0,
                            color: Colors.red.shade300,
                            textColor: Colors.red.shade900,
                          ),
                          const SizedBox(width: 10),
                          _buildStatCard(
                            title: 'Difference',
                            amount: (monthlyTotals[_selectedMonth]?['income'] ??
                                    0) -
                                (monthlyTotals[_selectedMonth]?['expenses'] ?? 0),
                            color: Colors.blue.shade300,
                            textColor: Colors.blue.shade900,
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox(),

            Expanded(
              child: filteredTransactions.isEmpty
                  ? const Center(child: Text('No transactions found.'))
                  : ListView.builder(
                      itemCount: filteredTransactions.length,
                      itemBuilder: (context, index) {
                        final txn = filteredTransactions[index];

                        // Determine the icon and color based on transaction type
                        IconData iconData = txn.type == 'Expense'
                            ? Icons.arrow_downward
                            : Icons.arrow_upward;
                        Color iconColor =
                            txn.type == 'Expense' ? Colors.red : Colors.green;
                            txn.type == 'Expense' ? Colors.red : Colors.green;

                        return ListTile(
                          leading: Icon(iconData, color: iconColor),
                          title: Text(
                              txn.category != 'Other'
                                  ? txn.category
                                  : txn.customCategory!,
                              style: const TextStyle(fontSize: 12)),
                          subtitle: Text(
                              utilService.indianRupeeFormat.format(txn.amount),
                              style: const TextStyle(fontSize: 14)),
                          trailing: Text(
                            txn.date.toLocal().toString().split(' ')[0],
                            style:
                                const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      {required String title,
      required double amount,
      required Color color,
      required Color textColor}) {
    return Container(
      width: 150, // Set width for consistency
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3), // Shadow position
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            utilService.indianRupeeFormat.format(amount),
            style: TextStyle(
              fontSize: 14,
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Group transactions by month
  Map<String, List<TransactionModel>> _groupTransactionsByMonth() {
    Map<String, List<TransactionModel>> groupedTransactions = {};

    for (var txn in transactions) {
      String month = monthFormat.format(txn.date);
      if (groupedTransactions.containsKey(month)) {
        groupedTransactions[month]!.add(txn);
      } else {
        groupedTransactions[month] = [txn];
      }
    }

    return groupedTransactions;
  }

  // Calculate income, expenses, and the total for each month
  Map<String, Map<String, double>> _calculateMonthlyTotals(
      Map<String, List<TransactionModel>> transactionsByMonth) {
    Map<String, Map<String, double>> totals = {};

    transactionsByMonth.forEach((month, transactions) {
      double income = 0.0;
      double expenses = 0.0;

      for (var txn in transactions) {
        if (txn.type == 'Income') {
          income += txn.amount;
        } else if (txn.type == 'Expense') {
          expenses += txn.amount;
        }
      }

      totals[month] = {
        'income': income,
        'expenses': expenses,
      };
    });

    return totals;
  }
}
