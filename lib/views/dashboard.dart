import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:secure_money_management/helper/constants.dart';
import 'package:secure_money_management/utils/util_services.dart';
import 'package:secure_money_management/widgets/theme_settings_widget.dart';
import 'package:secure_money_management/services/file_operations_service.dart';
import 'package:secure_money_management/services/currency_service.dart';
import 'package:secure_money_management/views/country_selection_screen.dart';
import 'package:secure_money_management/views/add_edit_transaction_form.dart';

import '../ad_service/widgets/banner_ad.dart';
import '../models/transaction_model.dart';

class DashboardScreen extends StatefulWidget {
  final List<TransactionModel> transactions; // Add a transactions parameter
  final double totalBalance;
  final Future<void> Function() onTransactionsUpdated;

  const DashboardScreen({
    super.key,
    required this.transactions,
    required this.totalBalance,
    required this.onTransactionsUpdated,
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
    // Use currency service for formatting
    final currencyService = CurrencyService.instance;

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
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToAddTransaction(context),
            tooltip: 'Add Transaction',
          ),
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
                        currencyService.formatAmount(widget.totalBalance),
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
                                ? currencyService.formatAmount(totalIncome)
                                : currencyService.formatAmount(0),
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
                              currencyService.formatAmount(totalExpenses),
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

              // Recent Transactions Section with Month Separation
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recent Transactions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // Navigate to transactions screen
                              Navigator.of(context).pushNamed('/transactions');
                            },
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      widget.transactions.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32.0),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.receipt_long_outlined,
                                      size: 48,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'No transactions yet',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Tap the + button to add your first transaction',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : _buildMonthSeparatedTransactions(),
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
                
                // Country/Currency Settings Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.language, color: Theme.of(context).primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'Country & Currency',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text('Current: ${CurrencyService.instance.displayName}'),
                        const SizedBox(height: 8),
                        const Text(
                          'Change currency symbol and formatting based on your country',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () async {
                            Navigator.pop(context);
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CountrySelectionScreen(),
                              ),
                            );
                            if (result == true) {
                              // Refresh the dashboard to show new currency
                              widget.onTransactionsUpdated();
                            }
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Change Country'),
                        ),
                      ],
                    ),
                  ),
                ),
                
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

  Widget _buildMonthSeparatedTransactions() {
    final currencyService = CurrencyService.instance;
    
    // Sort transactions by date (latest first)
    final sortedTransactions = List<TransactionModel>.from(widget.transactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    // Group transactions by month
    final Map<String, List<TransactionModel>> groupedTransactions = {};
    
    for (final transaction in sortedTransactions) {
      final monthKey = DateFormat('MMMM yyyy').format(transaction.date);
      if (groupedTransactions[monthKey] == null) {
        groupedTransactions[monthKey] = [];
      }
      groupedTransactions[monthKey]!.add(transaction);
    }

    // Show only recent transactions (last 10 transactions)
    final recentTransactions = sortedTransactions.take(10).toList();
    final Map<String, List<TransactionModel>> recentGrouped = {};
    
    for (final transaction in recentTransactions) {
      final monthKey = DateFormat('MMMM yyyy').format(transaction.date);
      if (recentGrouped[monthKey] == null) {
        recentGrouped[monthKey] = [];
      }
      recentGrouped[monthKey]!.add(transaction);
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recentGrouped.keys.length,
      itemBuilder: (context, index) {
        final monthKey = recentGrouped.keys.toList()[index];
        final monthTransactions = recentGrouped[monthKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                monthKey,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            // Transactions for this month
            ...monthTransactions.map((transaction) => _buildTransactionTile(transaction, currencyService)),
            if (index < recentGrouped.keys.length - 1) const Divider(),
          ],
        );
      },
    );
  }

  Widget _buildTransactionTile(TransactionModel transaction, CurrencyService currencyService) {
    IconData iconData = transaction.type == 'Expense'
        ? Icons.arrow_downward
        : Icons.arrow_upward;
    Color iconColor = transaction.type == 'Expense'
        ? Colors.red
        : Colors.green;

    String displayCategory = transaction.category;
    if (transaction.category == 'Other' && transaction.customCategory != null) {
      displayCategory = transaction.customCategory!;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2.0),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(iconData, color: iconColor, size: 20),
        ),
        title: Text(
          displayCategory,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Row(
          children: [
            Text(
              DateFormat('MMM dd').format(transaction.date),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            if (transaction.paymentMode != null) ...[
              const Text(' • ', style: TextStyle(color: Colors.grey)),
              Text(
                transaction.paymentMode!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
        trailing: Text(
          currencyService.formatAmount(transaction.amount),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: iconColor,
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToAddTransaction(BuildContext context) async {
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddEditTransactionScreen(
            onSave: (TransactionModel transaction) async {
              // Save the transaction and refresh the dashboard
              await widget.onTransactionsUpdated();
            },
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to open add transaction screen. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
