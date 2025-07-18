import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:secure_money_management/helper/constants.dart';
import 'package:secure_money_management/utils/util_services.dart';
import 'package:secure_money_management/services/app_permission_handler.dart';
import 'package:secure_money_management/utils/user_experience_helper.dart';
import 'package:secure_money_management/utils/app_settings_helper.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showPermissionSettingsDialog(context),
            tooltip: 'Permission Settings',
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

  /// Show permission settings dialog
  Future<void> _showPermissionSettingsDialog(BuildContext context) async {
    // Check current permission status
    final hasPermission = await AppPermissionHandler().checkStoragePermission();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              Icon(
                hasPermission ? Icons.check_circle : Icons.settings,
                color: hasPermission ? Colors.green : Colors.blue,
              ),
              const SizedBox(width: 8),
              const Expanded(child: Text('Storage Permission')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: hasPermission
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      hasPermission ? Icons.check : Icons.warning,
                      color: hasPermission ? Colors.green : Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        hasPermission
                            ? 'Storage permission is granted. You can use all import/export features.'
                            : 'Storage permission is not granted. Import/export features are disabled.',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Storage permission allows you to:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text('• Export transactions as JSON, CSV, PDF, Excel'),
              const Text('• Import transaction data from files'),
              const Text('• Share transaction reports'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            if (!hasPermission) ...[
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();

                  // Request permission
                  final granted =
                      await AppPermissionHandler().requestStoragePermission();

                  if (granted) {
                    UserExperienceHelper.showSuccessSnackbar(
                      context,
                      'Storage permission granted! You can now use import/export features.',
                    );
                  } else {
                    // Show app settings dialog
                    await AppSettingsHelper.showOpenSettingsDialog(
                      context,
                      title: 'Enable Storage Permission',
                      message:
                          'To use import/export features, please enable storage permission in app settings.',
                      feature: 'import/export',
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Enable Permission'),
              ),
            ],
          ],
        );
      },
    );
  }
}
