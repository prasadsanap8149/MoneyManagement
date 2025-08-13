import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:secure_money_management/helper/constants.dart';
import 'package:secure_money_management/services/connectivity_service.dart';
import 'package:secure_money_management/services/currency_service.dart';
import 'package:secure_money_management/services/file_operations_service.dart';
import 'package:secure_money_management/services/import_export_service.dart';
import 'package:secure_money_management/utils/util_services.dart';
import 'package:secure_money_management/views/add_edit_transaction_form.dart';
import 'package:secure_money_management/views/country_selection_screen.dart';
import 'package:secure_money_management/views/transactions_screen.dart';
import 'package:secure_money_management/widgets/theme_settings_widget.dart';
import 'package:secure_money_management/widgets/feature_hint.dart';
import 'package:secure_money_management/widgets/help_demo_widget.dart';
import 'package:secure_money_management/widgets/faq_widget.dart';
import 'package:secure_money_management/services/onboarding_service.dart';
import 'package:secure_money_management/screens/splash_screen.dart';

import '../ad_service/widgets/banner_ad.dart';
import '../models/transaction_model.dart';

class DashboardScreen extends StatefulWidget {
  final List<TransactionModel> transactions; // Add a transactions parameter
  final double totalBalance;
  final Future<void> Function() onTransactionsUpdated;
  final Future<void> Function(TransactionModel) onSaveTransaction;

  const DashboardScreen({
    super.key,
    required this.transactions,
    required this.totalBalance,
    required this.onTransactionsUpdated,
    required this.onSaveTransaction,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ImportExportService _importExportService = ImportExportService();
  final ConnectivityService _connectivityService = ConnectivityService();
  bool _isTransactionListExpanded = false;

  @override
  void initState() {
    super.initState();
    // Initialize services
    _importExportService.initialize();
    _connectivityService.initialize();
  }

  @override
  void dispose() {
    _importExportService.dispose();
    _connectivityService.dispose();
    super.dispose();
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
    debugPrint(
        'Dashboard - Transactions: ${widget.transactions.length}, Income: $totalIncome, Expenses: $totalExpenses');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
        actions: [
          FeatureHint(
            message: "Tap here to add your first transaction! 💰\n\nYou can track both income and expenses.",
            stepId: "add_transaction_button",
            child: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _navigateToAddTransaction(context),
              tooltip: 'Add Transaction',
            ),
          ),
          FeatureHint(
            message: "Access app settings, themes, and tutorials here! ⚙️",
            stepId: "settings_button",
            child: IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => _showAppSettingsDialog(context),
              tooltip: 'App Settings',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Fixed top section (non-scrolling)
          Padding(
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
                const SizedBox(height: 1),
                // Import/Export Quick Actions
                _buildImportExportSection(),

              ],
            ),
          ),

          // Scrollable Recent Transactions Section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                elevation: 4,
                child: Column(
                  children: [
                    // Header (fixed)
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Recent Transactions',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (!_isTransactionListExpanded &&
                                  widget.transactions.length > 5)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 3, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${widget.transactions.length}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _isTransactionListExpanded =
                                    !_isTransactionListExpanded;
                              });
                            },
                            icon: AnimatedRotation(
                              turns: _isTransactionListExpanded ? 0.5 : 0,
                              duration: const Duration(milliseconds: 300),
                              child: const Icon(
                                Icons.expand_more,
                                size: 18,
                              ),
                            ),
                            label: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Text(
                                _isTransactionListExpanded
                                    ? 'Show Less'
                                    : 'View All',
                                key: ValueKey(_isTransactionListExpanded),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Scrollable content with animation
                    Expanded(
                      child: // Scrollable content with animation
                          AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: widget.transactions.isEmpty
                            ? const Padding(
                                key: ValueKey('empty'),
                                padding: EdgeInsets.all(0.0),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.receipt_long_outlined,
                                        size: 48,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 1),
                                      Text(
                                        'No transactions yet',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      SizedBox(height: 1),
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
                            : Expanded(
                                key: ValueKey(_isTransactionListExpanded),
                                child: _buildScrollableTransactions(),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 1),
        ],
      ),
    );
  }

  /// Build import/export section with quick actions
  Widget _buildImportExportSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.import_export,
                    color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Import & Export',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                // Connection status indicator
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _connectivityService.isConnected
                            ? Colors.green
                            : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _connectivityService.connectionTypeString,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Securely backup and restore your transactions',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _importExportService.importFromJson(
                      context,
                      () {
                        // Refresh dashboard after import
                        widget.onTransactionsUpdated();
                      },
                    ),
                    icon: const Icon(Icons.file_download, size: 18),
                    label: const Text('Import'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _importExportService.showExportDialog(
                      context,
                      widget.transactions,
                    ),
                    icon: const Icon(Icons.file_upload, size: 18),
                    label: const Text('Export'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.security, size: 12, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  'Internet required • Ad supported',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Show comprehensive app settings dialog with enhanced features
  Future<void> _showAppSettingsDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.95,
              maxHeight: MediaQuery.of(context).size.height * 0.85,
              minWidth: 300,
              minHeight: 400,
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.surface,
                    Theme.of(context).colorScheme.surface.withOpacity(0.95),
                  ],
                ),
              ),
              child: DefaultTabController(
                length: 5,
                child: Column(
                  children: [
                    // Header with close button
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20)),
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.settings,
                                color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'App Settings',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Customize your SecureMoney experience',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.grey.shade600,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.grey.shade100,
                              foregroundColor: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Tab Bar
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: TabBar(
                        labelColor: Theme.of(context).primaryColor,
                        unselectedLabelColor: Colors.grey.shade600,
                        indicatorColor: Theme.of(context).primaryColor,
                        labelStyle: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 10),
                        unselectedLabelStyle: const TextStyle(
                            fontWeight: FontWeight.normal, fontSize: 10),
                        isScrollable: false,
                        tabs: const [
                          Tab(
                              icon: Icon(Icons.palette, size: 18),
                              text: 'Theme'),
                          Tab(
                              icon: Icon(Icons.language, size: 18),
                              text: 'Region'),
                          Tab(
                              icon: Icon(Icons.storage, size: 18),
                              text: 'Data'),
                          Tab(icon: Icon(Icons.help, size: 18), text: 'Help'),
                          Tab(icon: Icon(Icons.info, size: 18), text: 'About'),
                        ],
                      ),
                    ),

                    // Tab Views
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildThemeSettingsTab(context),
                          _buildRegionSettingsTab(context),
                          _buildDataManagementTab(context),
                          _buildHelpTab(context),
                          _buildAboutTab(context),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Build Theme Settings Tab
  Widget _buildThemeSettingsTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette,
                  color: Theme.of(context).primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Appearance',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Customize the look and feel of your app',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 16),

          // Theme Settings Widget
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const ThemeSettingsWidget(),
          ),

          const SizedBox(height: 16),

          // Additional theme options
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.color_lens,
                        color: Theme.of(context).primaryColor, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Color Scheme',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'SecureMoney uses a green color scheme for financial positivity and trust.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildColorSwatch(Colors.green, 'Current'),
                    const SizedBox(width: 12),
                    _buildColorSwatch(Colors.blue, 'Coming Soon'),
                    const SizedBox(width: 12),
                    _buildColorSwatch(Colors.purple, 'Coming Soon'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build Color Swatch Widget
  Widget _buildColorSwatch(Color color, String label) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300, width: 2),
          ),
          child: color == Colors.green
              ? const Icon(Icons.check, color: Colors.white, size: 20)
              : null,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
            fontWeight:
                color == Colors.green ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  /// Build Region Settings Tab
  Widget _buildRegionSettingsTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.language,
                  color: Theme.of(context).primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Region & Currency',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Set your location and currency preferences',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 16),

          // Current Settings Display
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.1),
                  Theme.of(context).primaryColor.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on,
                        color: Theme.of(context).primaryColor, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Current Settings',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSettingRow(
                    'Country/Region', CurrencyService.instance.displayName),
                const SizedBox(height: 8),
                _buildSettingRow(
                    'Currency Symbol', CurrencyService.instance.currencySymbol),
                const SizedBox(height: 8),
                _buildSettingRow('Format Example',
                    CurrencyService.instance.formatAmount(1234.56)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CountrySelectionScreen(),
                        ),
                      );
                      if (result == true) {
                        await CurrencyService.instance.refreshSettings();
                        setState(() {});
                        widget.onTransactionsUpdated();
                      }
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text(
                      'Change Country/Currency',
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Additional Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.blue.shade700, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Currency Information',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• Currency affects how amounts are displayed\n'
                  '• Existing transactions keep their values\n'
                  '• Change anytime without data loss\n'
                  '• Supports 190+ countries and currencies',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build Data Management Tab
  Widget _buildDataManagementTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storage,
                  color: Theme.of(context).primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Data Management',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Manage your transaction data and security',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 16),

          // Data Statistics
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.shade50,
                  Colors.green.shade100,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.analytics,
                        color: Colors.green.shade700, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Data Overview',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _buildStatCard(
                            'Total Transactions',
                            '${widget.transactions.length}',
                            Icons.receipt_long)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildStatCard(
                            'Storage Used', '< 1 MB', Icons.storage)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                        child: _buildStatCard(
                            'Encrypted', '100%', Icons.security)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildStatCard(
                            'Local Only', 'Yes', Icons.device_hub)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Quick Actions
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.build,
                        color: Theme.of(context).primaryColor, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Quick Actions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildActionTile(
                  icon: Icons.file_upload,
                  title: 'Export All Data',
                  subtitle: 'Create backup of all transactions',
                  onTap: () {
                    Navigator.pop(context);
                    _importExportService.showExportDialog(
                        context, widget.transactions);
                  },
                ),
                _buildActionTile(
                  icon: Icons.file_download,
                  title: 'Import Data',
                  subtitle: 'Restore from backup file',
                  onTap: () {
                    Navigator.pop(context);
                    _importExportService.importFromJson(
                        context, widget.onTransactionsUpdated);
                  },
                ),
                _buildActionTile(
                  icon: Icons.info_outline,
                  title: 'File Operations Info',
                  subtitle: 'Learn about import/export features',
                  onTap: () async {
                    Navigator.pop(context);
                    await FileOperationsService()
                        .showFileOperationsInfo(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build Help Tab
  Widget _buildHelpTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help, color: Theme.of(context).primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Help & Support',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Get help and learn how to use SecureMoney',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 20),

          // Tutorial Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade50,
                  Colors.blue.shade100,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.school, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Interactive Tutorial',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Step-by-step guide to get you started with SecureMoney',
                  style: TextStyle(color: Colors.blue.shade700),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context); // Close settings
                      await OnboardingService.resetTutorial();
                      if (mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SplashScreen(),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Tutorial'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // How it Works Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.play_circle, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'How SecureMoney Works',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Watch a quick demo of the main features',
                  style: TextStyle(color: Colors.green.shade700),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context); // Close settings
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HelpDemoWidget(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.video_library),
                    label: const Text('Watch Demo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // FAQ Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.quiz, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Frequently Asked Questions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade800,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Find answers to common questions',
                  style: TextStyle(color: Colors.orange.shade700),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context); // Close settings
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FAQWidget(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.help_outline),
                    label: const Text('View FAQ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Quick Tips
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.purple.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb, color: Colors.purple, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Quick Tips',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.purple.shade800,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...[
                  'Long-press transactions to delete them quickly',
                  'Use custom categories for better organization',
                  'Export your data regularly as backup',
                  'Use search and filters to find specific transactions',
                  'Check reports for spending insights',
                ].map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(top: 6, right: 12),
                        decoration: BoxDecoration(
                          color: Colors.purple,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          tip,
                          style: TextStyle(
                            color: Colors.purple.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build About Tab
  Widget _buildAboutTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: Theme.of(context).primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'About SecureMoney',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Privacy-focused personal finance manager',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 16),

          // App Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.1),
                  Theme.of(context).primaryColor.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.account_balance_wallet,
                      color: Colors.white, size: 32),
                ),
                const SizedBox(height: 12),
                Text(
                  'SecureMoney',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 1.0.1+3',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Features
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber.shade600, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Key Features',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildFeatureTile(Icons.security, 'End-to-end encryption'),
                _buildFeatureTile(Icons.offline_pin, 'Local storage only'),
                _buildFeatureTile(Icons.privacy_tip, 'Privacy-focused design'),
                _buildFeatureTile(
                    Icons.phone_android, 'Modern Android compatibility'),
                _buildFeatureTile(
                    Icons.import_export, 'Import/Export capabilities'),
                _buildFeatureTile(Icons.dark_mode, 'Dark theme support'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Copyright
          Center(
            child: Text(
              '© 2025 SecureMoney. All rights reserved.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Helper Methods for Building UI Components

  Widget _buildSettingRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.green.shade600, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: Theme.of(context).primaryColor, size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey.shade600,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  Widget _buildFeatureTile(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollableTransactions({Key? key}) {
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

    // Determine which transactions to show based on expand/collapse state
    final transactionsToShow = _isTransactionListExpanded
        ? sortedTransactions // Show all transactions when expanded
        : sortedTransactions
            .take(5)
            .toList(); // Show only first 5 when collapsed

    final Map<String, List<TransactionModel>> displayGrouped = {};

    for (final transaction in transactionsToShow) {
      final monthKey = DateFormat('MMMM yyyy').format(transaction.date);
      if (displayGrouped[monthKey] == null) {
        displayGrouped[monthKey] = [];
      }
      displayGrouped[monthKey]!.add(transaction);
    }

    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          // Transaction list
          Expanded(
            child: ListView.builder(
              itemCount: displayGrouped.keys.length,
              itemBuilder: (context, index) {
                final monthKey = displayGrouped.keys.toList()[index];
                final monthTransactions = displayGrouped[monthKey]!;

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
                    ...monthTransactions.map((transaction) =>
                        _buildTransactionTile(transaction, currencyService)),
                    if (index < displayGrouped.keys.length - 1) const Divider(),
                    // Add some bottom padding for the last item
                    if (index == displayGrouped.keys.length - 1)
                      const SizedBox(height: 16),
                  ],
                );
              },
            ),
          ),
          // Show indicator if there are more transactions
          if (!_isTransactionListExpanded && sortedTransactions.length > 5)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                '+${sortedTransactions.length - 5} more transactions',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          // Navigation to full transactions screen
          if (_isTransactionListExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TransactionScreen(
                        onTransactionsUpdated: widget.onTransactionsUpdated,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.list_alt, size: 16),
                label: const Text('Open Transactions Screen'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade600,
                ),
              ),
            ),
        ],
      ),
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
            ...monthTransactions.map((transaction) =>
                _buildTransactionTile(transaction, currencyService)),
            if (index < recentGrouped.keys.length - 1) const Divider(),
          ],
        );
      },
    );
  }

  Widget _buildTransactionTile(
      TransactionModel transaction, CurrencyService currencyService) {
    IconData iconData = transaction.type == 'Expense'
        ? Icons.arrow_downward
        : Icons.arrow_upward;
    Color iconColor = transaction.type == 'Expense' ? Colors.red : Colors.green;

    String displayCategory = transaction.category;
    if (transaction.category == 'Other' && transaction.customCategory != null) {
      displayCategory = transaction.customCategory!;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2.0),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
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
              try {
                // Save the transaction using the provided callback
                await widget.onSaveTransaction(transaction);

                // Show success message
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Transaction added successfully!'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                // Show error message
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Failed to save transaction. Please try again.'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Failed to open add transaction screen. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
