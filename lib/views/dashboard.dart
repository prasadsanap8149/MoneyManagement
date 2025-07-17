import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:money_management/helper/constants.dart';
import 'package:money_management/utils/util_services.dart';

import '../ad_service/widgets/banner_ad.dart';
import '../models/transaction_model.dart';
import 'add_edit_transaction_form.dart'; // Add this for currency formatting

class DashboardScreen extends StatefulWidget {
  final List<TransactionModel> transactions; // Add a transactions parameter
  final double totalBalance;

  const DashboardScreen({
    super.key,
    required this.transactions,
    required this.totalBalance,
    required Future<void> Function() onTransactionsUpdated,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Format numbers as Indian Rupees (₹)
    final indianRupeeFormat =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    // Validate and calculate total income and expenses
    final totalIncome = utilService.calculateBalance(
        widget.transactions, Constants.transactionType[0]);
    final totalExpenses = utilService.calculateBalance(
        widget.transactions, Constants.transactionType[1]);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (Constants.isMobileDevice) const GetBannerAd(),
              const SizedBox(height: 5),
              // Total Balance Card
              Card(
                elevation: 4,
                color: Colors.green[100],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Balance',
                          style: TextStyle(fontSize: 18)),
                      const SizedBox(height: 8),
                      Text(
                        indianRupeeFormat.format(widget.totalBalance),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 5),

              // Income and Expense Summary
              Row(
                children: [
                  Expanded(
                    child: Card(
                      color: Colors.green[200],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Income'),
                            const SizedBox(height: 8),
                            Text(
                              indianRupeeFormat.format(totalIncome),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[900],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Card(
                      color: Colors.red[200],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Expenses'),
                            const SizedBox(height: 8),
                            Text(
                              indianRupeeFormat.format(totalExpenses),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.red[900],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 5),

              // Recent Transactions Section
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Recent Transactions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      widget.transactions.isEmpty
                          ? const Center(child: Text('No transactions found.'))
                          : ListView.builder(
                              itemCount: widget.transactions.length,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemBuilder: (context, index) {
                                final sortedTransactions = List.from(
                                    widget.transactions)
                                  ..sort((a, b) => b.date.compareTo(a.date));
                                final txn = sortedTransactions[index];

                                IconData iconData = txn.type == 'Expense'
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward;
                                Color iconColor = txn.type == 'Expense'
                                    ? Colors.red
                                    : Colors.green;

                                return ListTile(
                                  leading: Icon(iconData, color: iconColor),
                                  title: Text(
                                    txn.category != 'Other'
                                        ? txn.category
                                        : txn.customCategory,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  subtitle: Text(
                                    indianRupeeFormat.format(txn.amount),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  trailing: Text(
                                    txn.date.toLocal().toString().split(' ')[0],
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 12),
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Navigate to add transaction screen
  void _addTransaction(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditTransactionScreen(
          onSave: () {},
        ),
      ),
    );
  }
}
