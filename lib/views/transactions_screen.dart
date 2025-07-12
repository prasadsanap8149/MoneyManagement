import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:money_management/helper/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ad_service/widgets/banner_ad.dart';
import '../models/transaction_model.dart';
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
  }

  // Save transactions to local storage
  Future<void> _saveTransactionsToLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    String transactionsJson =
        jsonEncode(_transactions.map((txn) => txn.toJson()).toList());
    await prefs.setString('transactions', transactionsJson);
  }

  // Add or edit a transaction
  void _saveTransaction(TransactionModel newTransaction) {
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
      _saveTransactionsToLocalStorage(); // Save updated transactions to local storage

      // Notify the home screen that transactions have been updated
      widget.onTransactionsUpdated();
    });
  }

  // Delete a transaction with confirmation
  void _deleteTransaction(String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content:
              const Text('Are you sure you want to delete this transaction?'),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.greenAccent, // Background color
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20), // Optional padding
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // Optional rounded corners
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.redAccent, // Background color
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20), // Optional padding
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // Optional rounded corners
                ),
              ),
              onPressed: () {
                setState(() {
                  _transactions.removeWhere((txn) => txn.id == id);
                  _saveTransactionsToLocalStorage(); // Save updated transactions to local storage

                  // Notify the home screen that transactions have been updated
                  widget.onTransactionsUpdated();
                });
                Navigator.of(context).pop();
              },
              child: const Text('Delete'),
            ),


          ],
        );
      },
    );
  }

  // Navigate to add transaction screen
  void _addTransaction(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditTransactionScreen(
          onSave: _saveTransaction,
        ),
      ),
    );
  }

  // Navigate to edit transaction screen
  void _editTransaction(BuildContext context, TransactionModel txn) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditTransactionScreen(
          onSave: _saveTransaction,
          transaction: txn,
        ),
      ),
    );
  }
}
