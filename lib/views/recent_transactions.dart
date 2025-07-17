import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:money_management/utils/util_services.dart';
import 'package:money_management/models/transaction_model.dart';
import 'package:money_management/services/file_operations_service.dart';
import 'package:money_management/utils/user_experience_helper.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';

class RecentTransactions extends StatefulWidget {
  const RecentTransactions({
    super.key,
  });

  @override
  _RecentTransactionsState createState() => _RecentTransactionsState();
}

class _RecentTransactionsState extends State<RecentTransactions> {
  late List<TransactionModel> transactions = [];

  @override
  void initState() {
    super.initState();
    //_checkInternetAndLoad();
  }

  @override
  void dispose() {
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
      final prefs = await SharedPreferences.getInstance();
      final transactionsJson = prefs.getString('transactions');

      if (transactionsJson == null) {
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
    if (!await _checkInternetConnection()) {
      UserExperienceHelper.showWarningSnackbar(
        context,
        'Internet connection required to import transactions.',
      );
      return;
    }
    
    // Show confirmation dialog
    final confirmed = await UserExperienceHelper.showConfirmationDialog(
      context,
      title: 'Import Transactions',
      message: 'This will replace your current transactions with imported data. Are you sure?',
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
      // Use FileOperationsService for import with permission handling
      final jsonStr = await FileOperationsService().importFile(
        context,
        feature: 'import transactions',
      );
      
      if (jsonStr != null) {
        try {
          final decodedList = jsonDecode(jsonStr) as List;
          final List<TransactionModel> importedTransactions =
              decodedList.map((item) => TransactionModel.fromJson(item)).toList();

          // Save back to SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('transactions', jsonEncode(importedTransactions));

          // Reload in app
          await _loadTransactions();

          loadingSnackbar.close();
          UserExperienceHelper.showSuccessSnackbar(
            context,
            'Transactions imported successfully! ${importedTransactions.length} transactions loaded.',
          );
        } catch (e) {
          loadingSnackbar.close();
          UserExperienceHelper.showErrorSnackbar(
            context,
            'Import failed: Invalid file format. Please ensure the file is a valid JSON export.',
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

  // Load transactions from local storage
  Future<void> _loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedTransactions = prefs.getString('transactions');
    if (savedTransactions != null) {
      List<dynamic> decodedTransactions = jsonDecode(savedTransactions);
      setState(() {
        transactions = decodedTransactions
            .map((json) => TransactionModel.fromJson(json))
            .toList();
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

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'json') _exportTransactions();
                  if (value == 'csv') _exportToCSV();
                  if (value == 'pdf') _exportToPDF();
                  if (value == 'excel') _exportToExcel();
                },
                icon: const Icon(Icons.download),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'json', child: Text('Export as JSON')),
                  PopupMenuItem(value: 'csv', child: Text('Export as CSV')),
                  PopupMenuItem(value: 'pdf', child: Text('Export as PDF')),
                  PopupMenuItem(value: 'excel', child: Text('Export as Excel')),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _exportTransactions,
                icon: const Icon(Icons.download),
                label: const Text('Export'),
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
                label: const Text('Import'),
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
