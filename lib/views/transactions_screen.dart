import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:secure_money_management/helper/constants.dart';
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
  _TransactionScreenState createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  List<TransactionModel> _transactions = [];

  // Format numbers as Indian Rupees (₹)
  final indianRupeeFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  @override
  void initState() {
    super.initState();
    _loadTransactions(); // Load transactions from local storage when screen loads
    // setState(() {
    //   _transactions=Constants.transaction;
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transactions'),
        centerTitle: true,),
      body: _transactions.isEmpty
          ?  Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if(Constants.isMobileDevice)
                  const GetBannerAd(),
                const SizedBox(height: 5),
                const Center(child: Text('No transactions added yet.')),
              ],
            )
          : Column(
              children: [
                if(Constants.isMobileDevice)
                  const GetBannerAd(),
                const SizedBox(height: 5,),
                Expanded(
                  child: ListView.builder(
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      final txn = _transactions[index];
                      return Card(
                        color: Colors.white, // Background color for the card
                        elevation: 2, // Add subtle shadow for depth
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              8), // Slightly rounded corners
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 5, horizontal: 10),
                          // Minimal padding for a tight layout
                          leading: CircleAvatar(
                            backgroundColor: txn.type == 'Income'
                                ? Colors.green
                                : Colors.red, // Icon based on transaction type
                            child: Icon(
                              txn.type == 'Income'
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            txn.category != 'Other'
                                ? txn.category
                                : txn.customCategory!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize:
                                  16, // Slightly smaller font to fit more text
                              color: Colors.black87,
                            ),
                          ),
                          subtitle: Text(
                            '${txn.type} - ${indianRupeeFormat.format(txn.amount)}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14, // Keep subtitle text smaller
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.blueAccent),
                                onPressed: () => _editTransaction(context, txn),
                                tooltip: 'Edit Transaction',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.redAccent),
                                onPressed: () => _deleteTransaction(txn.id!),
                                tooltip: 'Delete Transaction',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
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
      final prefs = await SharedPreferences.getInstance();
      final String? savedTransactions = prefs.getString('transactions');
      if (savedTransactions != null) {
        List<dynamic> decodedTransactions = jsonDecode(savedTransactions);
        setState(() {
          _transactions = decodedTransactions
              .map((json) => TransactionModel.fromJson(json))
              .toList();
        });
      }
    } catch (e) {
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
      final prefs = await SharedPreferences.getInstance();
      String transactionsJson =
          jsonEncode(_transactions.map((txn) => txn.toJson()).toList());
      await prefs.setString('transactions', transactionsJson);
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
}
