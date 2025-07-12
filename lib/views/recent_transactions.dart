import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:money_management/helper/util_services.dart';
import 'package:money_management/models/transaction_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
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
    _loadTransactions();
  }

  Future<void> _exportTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final transactionsJson = prefs.getString('transactions');

    if (transactionsJson == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("No transactions to export."),
      ));
      return;
    }

    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/transactions_export.json';
    final file = File(filePath);

    await file.writeAsString(transactionsJson);

    await Share.shareXFiles([XFile(file.path)], text: 'Transaction export');
  }

  Future<void> _importTransactions() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final jsonStr = await file.readAsString();

      try {
        final decodedList = jsonDecode(jsonStr) as List;
        final List<TransactionModel> importedTransactions =
            decodedList.map((item) => TransactionModel.fromJson(item)).toList();

        // Save back to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('transactions', jsonEncode(importedTransactions));

        // Reload in app
        await _loadTransactions();

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Transactions imported successfully."),
        ));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Import failed: ${e.toString()}"),
        ));
      }
    }
  }

  Future<void> _exportToCSV() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/transactions_export.csv');

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
    await file.writeAsString(csv);

    await Share.shareXFiles([XFile(file.path)], text: 'Transaction CSV Export');
  }

  Future<void> _exportToPDF() async {
    final pdf = pw.Document();
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/transactions_export.pdf');

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

    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(file.path)], text: 'Transaction PDF Export');
  }

  Future<void> _exportToExcel() async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Transactions'];

    // Header row
    // sheetObject.appendRow([
    //   CellValue.value('ID'),
    //   CellValue.value('Amount'),
    //   CellValue.value('Type'),
    //   CellValue.value('Date'),
    //   CellValue.value('Category'),
    //   CellValue.value('Custom Category'),
    // ]);
    //
    // // Data rows
    // for (var txn in transactions) {
    //   sheetObject.appendRow([
    //     CellValue.value(txn.id ?? ''),
    //     CellValue.value(txn.amount.toString()),
    //     CellValue.value(txn.type),
    //     CellValue.value(txn.date.toIso8601String()),
    //     CellValue.value(txn.category),
    //     CellValue.value(txn.customCategory ?? ''),
    //   ]);
    // }

    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/transactions_export.xlsx';

    File(filePath)
      ..createSync(recursive: true)
      ..writeAsBytesSync(excel.save()!);

    await Share.shareXFiles([XFile(filePath)],
        text: 'Transaction Excel Export');
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
                icon: Icon(Icons.download),
                itemBuilder: (context) => [
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
