import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:secure_money_management/helper/constants.dart';
import 'package:secure_money_management/utils/util_services.dart';
import 'package:secure_money_management/widgets/theme_settings_widget.dart';
import 'package:secure_money_management/services/file_operations_service.dart';

import '../ad_service/widgets/banner_ad.dart';
import '../models/transaction_model.dart';

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

    // Debug prints (can be removed in production)
    debugPrint('Dashboard - Transactions: ${widget.transactions.length}, Income: $totalIncome, Expenses: $totalExpenses');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showAppSettingsDialog(context),
            tooltip: 'App Settings',
          ),
        ],
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
                              totalIncome > 0 
                                ? indianRupeeFormat.format(totalIncome)
                                : '₹0.00',
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

  /// Show comprehensive app settings dialog
  Future<void> _showAppSettingsDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Row(
            children: [
              Icon(Icons.settings, color: Colors.blue),
              SizedBox(width: 8),
              Text('App Settings'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Theme Settings Section
                const ThemeSettingsWidget(),
                const SizedBox(height: 16),
                
                // File Operations Info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.file_copy, color: Theme.of(context).primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'File Operations',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text('✓ Export data as CSV, PDF, Excel, JSON'),
                        const Text('✓ Import transaction data from files'),
                        const Text('✓ Share reports with other apps'),
                        const SizedBox(height: 8),
                        const Text(
                          'Uses Storage Access Framework (no permissions required on Android 11+)',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () async {
                            Navigator.pop(context);
                            await FileOperationsService().showFileOperationsInfo(context);
                          },
                          icon: const Icon(Icons.info_outline),
                          label: const Text('More Info'),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // App Information
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info, color: Theme.of(context).primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'About SecureMoney',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text('✓ End-to-end encryption for all data'),
                        const Text('✓ Local storage (no cloud dependency)'),
                        const Text('✓ Privacy-focused design'),
                        const Text('✓ Modern Android compatibility'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
