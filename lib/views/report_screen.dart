import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:secure_money_management/ad_service/widgets/banner_ad.dart';
import 'package:secure_money_management/helper/constants.dart';
import 'package:secure_money_management/services/currency_service.dart';

import '../models/transaction_model.dart';

class ReportsScreen extends StatefulWidget {
  final List<TransactionModel> transactions;

  const ReportsScreen({super.key, required this.transactions});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  // Filter state
  String _selectedTypeFilter = 'All';
  String _selectedCategoryFilter = 'All';
  String _selectedPaymentModeFilter = 'All';
  DateTimeRange? _selectedDateRange;
  final TextEditingController _searchController = TextEditingController();
  List<TransactionModel> _filteredTransactions = [];

  @override
  void initState() {
    super.initState();
    _filteredTransactions = widget.transactions;
    _searchController.addListener(_performSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyService = CurrencyService.instance;
    final displayTransactions = _filteredTransactions;
    
    final totalIncome = displayTransactions
        .where((txn) => txn.type == 'Income')
        .fold(0.0, (sum, txn) => sum + txn.amount);
    final totalExpenses = displayTransactions
        .where((txn) => txn.type == 'Expense')
        .fold(0.0, (sum, txn) => sum + txn.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter Reports',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
            tooltip: 'Search Transactions',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (Constants.isMobileDevice) const GetBannerAd(),
            const SizedBox(height: 10),
            
            // Active filters display
            if (_hasActiveFilters()) _buildActiveFiltersBar(),
            
            // Summary cards
            _buildSummaryCards(totalIncome, totalExpenses, currencyService),
            const SizedBox(height: 20),
            
            // Pie chart
            _buildPieChart(totalIncome, totalExpenses, currencyService),
            const SizedBox(height: 20),
            
            // Category breakdown
            _buildCategoryBreakdown(displayTransactions, currencyService),
            const SizedBox(height: 20),
            
            // Payment mode breakdown
            if (displayTransactions.any((t) => t.paymentMode != null))
              _buildPaymentModeBreakdown(displayTransactions, currencyService),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(double totalIncome, double totalExpenses, CurrencyService currencyService) {
    final balance = totalIncome - totalExpenses;
    
    return Column(
      children: [
        // Balance card in its own row
        Card(
          elevation: 4,
          color: balance >= 0 ? Colors.green.shade50 : Colors.red.shade50,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  balance >= 0 ? Icons.account_balance_wallet : Icons.warning,
                  color: balance >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                  size: 36,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Balance',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: balance >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currencyService.formatAmount(balance),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: balance >= 0 ? Colors.green.shade800 : Colors.red.shade800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Income and Expenses in a row
        Row(
          children: [
            Expanded(
              child: Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(Icons.trending_up, color: Colors.green.shade700, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        'Total Income',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currencyService.formatAmount(totalIncome),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(Icons.trending_down, color: Colors.red.shade700, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        'Total Expenses',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currencyService.formatAmount(totalExpenses),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPieChart(double totalIncome, double totalExpenses, CurrencyService currencyService) {
    if (totalIncome == 0 && totalExpenses == 0) {
      return Card(
        child: Container(
          height: 300,
          padding: const EdgeInsets.all(20),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pie_chart_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No Data Available',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                Text(
                  'Add some transactions to see the chart',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Income vs Expenses',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  sections: [
                    if (totalIncome > 0)
                      PieChartSectionData(
                        value: totalIncome,
                        color: Colors.green,
                        title: '${((totalIncome / (totalIncome + totalExpenses)) * 100).toStringAsFixed(1)}%',
                        radius: 80,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    if (totalExpenses > 0)
                      PieChartSectionData(
                        value: totalExpenses,
                        color: Colors.red,
                        title: '${((totalExpenses / (totalIncome + totalExpenses)) * 100).toStringAsFixed(1)}%',
                        radius: 80,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                  ],
                  centerSpaceRadius: 50,
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (totalIncome > 0)
                  _buildLegendItem('Income', Colors.green, currencyService.formatAmount(totalIncome)),
                if (totalExpenses > 0)
                  _buildLegendItem('Expenses', Colors.red, currencyService.formatAmount(totalExpenses)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, String amount) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            Text(
              amount,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryBreakdown(List<TransactionModel> transactions, CurrencyService currencyService) {
    final categoryTotals = <String, double>{};
    
    for (final transaction in transactions) {
      final category = transaction.category == 'Other' 
          ? (transaction.customCategory ?? 'Other')
          : transaction.category;
      categoryTotals[category] = (categoryTotals[category] ?? 0) + transaction.amount;
    }

    if (categoryTotals.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Category Breakdown',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...sortedCategories.take(5).map((entry) => _buildCategoryItem(
              entry.key,
              entry.value,
              categoryTotals.values.reduce((a, b) => a + b),
              currencyService,
            )),
            if (sortedCategories.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'And ${sortedCategories.length - 5} more categories...',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(String category, double amount, double total, CurrencyService currencyService) {
    final percentage = (amount / total * 100);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  category,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                currencyService.formatAmount(amount),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade400),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentModeBreakdown(List<TransactionModel> transactions, CurrencyService currencyService) {
    final paymentModeTotals = <String, double>{};
    
    for (final transaction in transactions) {
      if (transaction.paymentMode != null) {
        paymentModeTotals[transaction.paymentMode!] = 
            (paymentModeTotals[transaction.paymentMode!] ?? 0) + transaction.amount;
      }
    }

    if (paymentModeTotals.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedPaymentModes = paymentModeTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Mode Breakdown',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...sortedPaymentModes.map((entry) => _buildCategoryItem(
              entry.key,
              entry.value,
              paymentModeTotals.values.reduce((a, b) => a + b),
              currencyService,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFiltersBar() {
    final activeFilters = <Widget>[];

    if (_selectedTypeFilter != 'All') {
      activeFilters.add(_buildFilterChip('Type: $_selectedTypeFilter', () {
        setState(() => _selectedTypeFilter = 'All');
        _applyFilters();
      }));
    }

    if (_selectedCategoryFilter != 'All') {
      activeFilters.add(_buildFilterChip('Category: $_selectedCategoryFilter', () {
        setState(() => _selectedCategoryFilter = 'All');
        _applyFilters();
      }));
    }

    if (_selectedPaymentModeFilter != 'All') {
      activeFilters.add(_buildFilterChip('Payment: $_selectedPaymentModeFilter', () {
        setState(() => _selectedPaymentModeFilter = 'All');
        _applyFilters();
      }));
    }

    if (_selectedDateRange != null) {
      final dateStr = '${DateFormat('MMM dd').format(_selectedDateRange!.start)} - ${DateFormat('MMM dd').format(_selectedDateRange!.end)}';
      activeFilters.add(_buildFilterChip('Date: $dateStr', () {
        setState(() => _selectedDateRange = null);
        _applyFilters();
      }));
    }

    if (activeFilters.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Active Filters:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                const Spacer(),
                TextButton(
                  onPressed: _clearAllFilters,
                  child: const Text('Clear All', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              children: activeFilters,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onDeleted: onRemove,
      deleteIconColor: Colors.grey,
      backgroundColor: Colors.blue.shade50,
      side: BorderSide(color: Colors.blue.shade200),
    );
  }

  // Filter and search methods
  void _performSearch() {
    final query = _searchController.text.toLowerCase();
    _applyFilters();
  }

  void _applyFilters() {
    final baseList = widget.transactions;
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      _filteredTransactions = baseList.where((transaction) {
        // Search filter
        if (query.isNotEmpty) {
          final category = transaction.category == 'Other' 
              ? (transaction.customCategory ?? '').toLowerCase()
              : transaction.category.toLowerCase();
          final amount = transaction.amount.toString();
          final date = DateFormat('MMM dd yyyy').format(transaction.date).toLowerCase();
          final paymentMode = (transaction.paymentMode ?? '').toLowerCase();
          
          if (!(category.contains(query) ||
                amount.contains(query) ||
                date.contains(query) ||
                paymentMode.contains(query))) {
            return false;
          }
        }
        
        // Type filter
        if (_selectedTypeFilter != 'All' && transaction.type != _selectedTypeFilter) {
          return false;
        }
        
        // Category filter
        if (_selectedCategoryFilter != 'All') {
          final transactionCategory = transaction.category == 'Other' 
              ? transaction.customCategory ?? ''
              : transaction.category;
          if (transactionCategory != _selectedCategoryFilter) {
            return false;
          }
        }
        
        // Payment mode filter
        if (_selectedPaymentModeFilter != 'All') {
          if (transaction.paymentMode != _selectedPaymentModeFilter) {
            return false;
          }
        }
        
        // Date range filter
        if (_selectedDateRange != null) {
          if (transaction.date.isBefore(_selectedDateRange!.start) ||
              transaction.date.isAfter(_selectedDateRange!.end)) {
            return false;
          }
        }
        
        return true;
      }).toList();
    });
  }

  void _clearAllFilters() {
    setState(() {
      _selectedTypeFilter = 'All';
      _selectedCategoryFilter = 'All';
      _selectedPaymentModeFilter = 'All';
      _selectedDateRange = null;
      _searchController.clear();
    });
    _applyFilters();
  }

  bool _hasActiveFilters() {
    return _selectedTypeFilter != 'All' ||
           _selectedCategoryFilter != 'All' ||
           _selectedPaymentModeFilter != 'All' ||
           _selectedDateRange != null ||
           _searchController.text.isNotEmpty;
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Reports'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type filter
              const Text('Transaction Type:', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: _selectedTypeFilter,
                isExpanded: true,
                items: ['All', ...Constants.transactionType].map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedTypeFilter = value!);
                },
              ),
              const SizedBox(height: 16),
              
              // Category filter
              const Text('Category:', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: _selectedCategoryFilter,
                isExpanded: true,
                items: ['All', ...Constants.transactionCategory.where((c) => c != 'Select Category')].map((category) {
                  return DropdownMenuItem(value: category, child: Text(category));
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCategoryFilter = value!);
                },
              ),
              const SizedBox(height: 16),
              
              // Payment mode filter
              const Text('Payment Mode:', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: _selectedPaymentModeFilter,
                isExpanded: true,
                items: ['All', ...Constants.paymentModes].map((mode) {
                  return DropdownMenuItem(value: mode, child: Text(mode));
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedPaymentModeFilter = value!);
                },
              ),
              const SizedBox(height: 16),
              
              // Date range filter
              const Text('Date Range:', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    initialDateRange: _selectedDateRange,
                  );
                  if (picked != null) {
                    setState(() => _selectedDateRange = picked);
                  }
                },
                child: Text(
                  _selectedDateRange == null
                      ? 'Select Date Range'
                      : '${DateFormat('MMM dd').format(_selectedDateRange!.start)} - ${DateFormat('MMM dd').format(_selectedDateRange!.end)}',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _clearAllFilters();
              Navigator.pop(context);
            },
            child: const Text('Clear All'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _applyFilters();
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Transactions'),
        content: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search by category, amount, date, or payment mode...',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              _applyFilters();
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _applyFilters();
              Navigator.pop(context);
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }
}
