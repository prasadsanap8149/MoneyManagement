import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:money_management/helper/util_services.dart';
import 'package:money_management/models/transaction_model.dart';
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
                  padding: const EdgeInsets.symmetric(vertical: 5.0,horizontal: 5),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStatCard(
                          title: 'Income',
                          amount: monthlyTotals[_selectedMonth]?['income'] ?? 0,
                          color: Colors.green.shade200,
                          textColor:Colors.green.shade900,
                        ),
                        const SizedBox(width: 10), // Space between cards
                        _buildStatCard(
                          title: 'Expenses',
                          amount:
                              monthlyTotals[_selectedMonth]?['expenses'] ?? 0,
                          color: Colors.red.shade300,
                          textColor:Colors.red.shade900,
                        ),
                        const SizedBox(width: 10),
                        _buildStatCard(
                          title: 'Difference',
                          amount: (monthlyTotals[_selectedMonth]?['income'] ??
                                  0) -
                              (monthlyTotals[_selectedMonth]?['expenses'] ?? 0),
                          color: Colors.blue.shade300,
                          textColor:Colors.blue.shade900,
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
      {required String title, required double amount, required Color color, required Color textColor}) {
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
          Text( utilService.indianRupeeFormat.format(amount),
            style:  TextStyle(
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
