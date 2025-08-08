import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:secure_money_management/helper/constants.dart';
import 'package:secure_money_management/services/secure_transaction_service.dart';
import 'package:secure_money_management/services/currency_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ad_service/widgets/banner_ad.dart';
import '../models/transaction_model.dart';
import '../utils/user_experience_helper.dart';
import 'add_edit_transaction_form.dart';

class TransactionScreen extends StatefulWidget {
  final VoidCallback
      onTransactionsUpdated; // Callback to notify the home screen

  const TransactionScreen({super.key, required this.onTransactionsUpdated});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  List<TransactionModel> _transactions = [];
  List<TransactionModel> _filteredTransactions = [];
  final SecureTransactionService _secureStorage = SecureTransactionService();
  
  // Search and filter controllers
  final TextEditingController _searchController = TextEditingController();
  String _selectedTypeFilter = 'All';
  String _selectedCategoryFilter = 'All';
  DateTimeRange? _selectedDateRange;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _initializeAndLoadTransactions();
    _searchController.addListener(_performSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Initialize secure storage and load transactions
  Future<void> _initializeAndLoadTransactions() async {
    try {
      // Initialize the secure transaction service
      await _secureStorage.initialize();
      
      // Attempt to migrate from plain text storage
      final migrated = await _secureStorage.migrateFromPlainTextStorage();
      if (migrated) {
        debugPrint('Successfully migrated transactions to encrypted storage');
      }
      
      // Load transactions after initialization/migration
      await _loadTransactions();
      
    } catch (e) {
      debugPrint('Error initializing secure storage: $e');
      // Fallback to loading without migration
      await _loadTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyService = CurrencyService.instance;
    final displayTransactions = _filteredTransactions.isEmpty && _searchController.text.isEmpty
        ? _transactions
        : _filteredTransactions;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search transactions...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
              )
            : const Text('Transactions'),
        centerTitle: !_isSearching,
        actions: [
          if (!_isSearching) ...[
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => setState(() => _isSearching = true),
            ),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                });
              },
            ),
          ],
        },
      ),
      body: Column(
        children: [
          if (Constants.isMobileDevice) const GetBannerAd(),
          if (_hasActiveFilters()) _buildActiveFiltersBar(),
          const SizedBox(height: 5),
          Expanded(
            child: displayTransactions.isEmpty
                ? _buildEmptyState()
                : _buildTransactionsList(displayTransactions, currencyService),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _addTransaction(context),
      ),
    );
  }

  // Load transactions from local storage
  Future<void> _loadTransactions() async {
    try {
      final loadedTransactions = await _secureStorage.loadTransactions();
      setState(() {
        _transactions = loadedTransactions;
      });
    } catch (e) {
      debugPrint('Error loading transactions: $e');
      // Try legacy migration as fallback
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
          _transactions = legacyTransactions;
        });
        
        debugPrint('Successfully migrated ${legacyTransactions.length} transactions from legacy storage');
      }
    } catch (e) {
      debugPrint('Error during legacy migration: $e');
      // Show error toaster if loading fails
      UserExperienceHelper.showErrorSnackbar(
        context,
        'Failed to load transactions. Please restart the app.',
      );
    }
  }

  // Save transactions to local storage
  Future<void> _saveTransactionsToLocalStorage() async {
    try {
      // Use secure storage to save transactions
      await _secureStorage.saveTransactions(_transactions);
    } catch (e) {
      // Show error toaster if saving fails
      UserExperienceHelper.showErrorSnackbar(
        context,
        'Failed to save transactions. Please try again.',
      );
      rethrow; // Re-throw to let calling method handle the error
    }
  }

  // Add or edit a transaction
  Future<void> _saveTransaction(TransactionModel newTransaction) async {
    bool isEdit = newTransaction.id != null;
    
    // Show loading indicator
    UserExperienceHelper.showLoadingSnackbar(
      context,
      isEdit ? 'Updating transaction...' : 'Adding transaction...',
    );
    
    try {
      setState(() {
        if (newTransaction.id == null) {
          // New transaction
          newTransaction.id = DateTime.now().toString(); // Use timestamp as ID
          _transactions.add(newTransaction);
        } else {
          // Update existing transaction
          int index =
              _transactions.indexWhere((txn) => txn.id == newTransaction.id);
          if (index != -1) {
            _transactions[index] = newTransaction;
          }
        }
      });

      await _saveTransactionsToLocalStorage(); // Save updated transactions to local storage

      // Notify the home screen that transactions have been updated
      widget.onTransactionsUpdated();

      // Hide loading indicator
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Show success toaster
      if (isEdit) {
        UserExperienceHelper.showSuccessSnackbar(
          context,
          'Transaction updated successfully!',
        );
      } else {
        UserExperienceHelper.showSuccessSnackbar(
          context,
          'Transaction added successfully!',
        );
      }
    } catch (e) {
      // Hide loading indicator
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      // Show error toaster if saving fails
      UserExperienceHelper.showErrorSnackbar(
        context,
        isEdit ? 'Failed to update transaction. Please try again.' : 'Failed to add transaction. Please try again.',
      );
    }
  }

  // Delete a transaction with confirmation
  Future<void> _deleteTransaction(String id) async {
    final transaction = _transactions.firstWhere((txn) => txn.id == id);
    final transactionName = transaction.category != 'Other' 
        ? transaction.category 
        : transaction.customCategory!;
    final formattedAmount = indianRupeeFormat.format(transaction.amount);

    final confirmed = await UserExperienceHelper.showConfirmationDialog(
      context,
      title: 'Delete Transaction',
      message: 'Are you sure you want to delete this transaction?\n\n'
               'Category: $transactionName\n'
               'Type: ${transaction.type}\n'
               'Amount: $formattedAmount\n\n'
               'This action cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      confirmColor: Colors.red,
      icon: Icons.delete_forever,
    );

    if (confirmed) {
      // Show loading indicator
      UserExperienceHelper.showLoadingSnackbar(
        context,
        'Deleting transaction...',
      );
      
      try {
        setState(() {
          _transactions.removeWhere((txn) => txn.id == id);
        });
        
        await _saveTransactionsToLocalStorage();
        
        // Notify the home screen that transactions have been updated
        widget.onTransactionsUpdated();
        
        // Hide loading indicator
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        
        // Show success toaster
        UserExperienceHelper.showSuccessSnackbar(
          context,
          'Transaction "$transactionName" deleted successfully!',
        );
      } catch (e) {
        // Hide loading indicator
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        
        // Show error toaster if deletion fails
        UserExperienceHelper.showErrorSnackbar(
          context,
          'Failed to delete transaction. Please try again.',
        );
      }
    }
  }

  // Navigate to add transaction screen
  Future<void> _addTransaction(BuildContext context) async {
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddEditTransactionScreen(
            onSave: _saveTransaction,
          ),
        ),
      );
    } catch (e) {
      // Show error toaster if navigation fails
      UserExperienceHelper.showErrorSnackbar(
        context,
        'Failed to open add transaction screen. Please try again.',
      );
    }
  }

  // Navigate to edit transaction screen
  Future<void> _editTransaction(BuildContext context, TransactionModel txn) async {
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddEditTransactionScreen(
            onSave: _saveTransaction,
            transaction: txn,
          ),
        ),
      );
    } catch (e) {
      // Show error toaster if navigation fails
      UserExperienceHelper.showErrorSnackbar(
        context,
        'Failed to open edit screen. Please try again.',
      );
    }
  }

  Widget _buildEmptyState() {
    if (_searchController.text.isNotEmpty || _hasActiveFilters()) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No transactions found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No transactions added yet',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Tap the + button to add your first transaction',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(List<TransactionModel> transactions, CurrencyService currencyService) {
    // Sort transactions by date (latest first)
    final sortedTransactions = List<TransactionModel>.from(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    return ListView.builder(
      itemCount: sortedTransactions.length,
      itemBuilder: (context, index) {
        final txn = sortedTransactions[index];
        return _buildTransactionCard(txn, currencyService);
      },
    );
  }

  Widget _buildTransactionCard(TransactionModel txn, CurrencyService currencyService) {
    String displayCategory = txn.category;
    if (txn.category == 'Other' && txn.customCategory != null) {
      displayCategory = txn.customCategory!;
    }

    IconData iconData = txn.type == 'Expense'
        ? Icons.arrow_downward
        : Icons.arrow_upward;
    Color iconColor = txn.type == 'Expense'
        ? Colors.red
        : Colors.green;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Icon(iconData, color: iconColor, size: 24),
        ),
        title: Text(
          displayCategory,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM dd, yyyy').format(txn.date),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                if (txn.paymentMode != null) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.payment, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    txn.paymentMode!,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                txn.type,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: iconColor,
                ),
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              currencyService.formatAmount(txn.amount),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  color: Colors.blue,
                  onPressed: () => _editTransaction(context, txn),
                  tooltip: 'Edit Transaction',
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  color: Colors.red,
                  onPressed: () => _deleteTransaction(txn.id!),
                  tooltip: 'Delete Transaction',
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
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

    if (_selectedDateRange != null) {
      final dateStr = '${DateFormat('MMM dd').format(_selectedDateRange!.start)} - ${DateFormat('MMM dd').format(_selectedDateRange!.end)}';
      activeFilters.add(_buildFilterChip('Date: $dateStr', () {
        setState(() => _selectedDateRange = null);
        _applyFilters();
      }));
    }

    if (activeFilters.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

  bool _hasActiveFilters() {
    return _selectedTypeFilter != 'All' ||
           _selectedCategoryFilter != 'All' ||
           _selectedDateRange != null;
  }

  void _performSearch() {
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      if (query.isEmpty) {
        _filteredTransactions = [];
      } else {
        _filteredTransactions = _transactions.where((transaction) {
          final category = transaction.category == 'Other' 
              ? (transaction.customCategory ?? '').toLowerCase()
              : transaction.category.toLowerCase();
          final amount = transaction.amount.toString();
          final date = DateFormat('MMM dd yyyy').format(transaction.date).toLowerCase();
          final paymentMode = (transaction.paymentMode ?? '').toLowerCase();
          
          return category.contains(query) ||
                 amount.contains(query) ||
                 date.contains(query) ||
                 paymentMode.contains(query);
        }).toList();
      }
    });
    
    _applyFilters();
  }

  void _applyFilters() {
    final baseList = _searchController.text.isEmpty ? _transactions : _filteredTransactions;
    
    setState(() {
      _filteredTransactions = baseList.where((transaction) {
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
      _selectedDateRange = null;
    });
    _performSearch(); // Reapply search without filters
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Transactions'),
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
}
