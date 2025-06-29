// import 'dart:convert';
//
// import 'package:shared_preferences/shared_preferences.dart';
//
// import '../models/transaction_model.dart';
//
// class TransactionService {
//
//   // Add or edit a transaction
//   void _saveTransaction(TransactionModel newTransaction) {
//     setState(() {
//       if (newTransaction.id == null) {
//         // New transaction
//         newTransaction.id = DateTime.now().toString(); // Use timestamp as ID
//         _transactions.add(newTransaction);
//       } else {
//         // Update existing transaction
//         int index = _transactions.indexWhere((txn) => txn.id == newTransaction.id);
//         if (index != -1) {
//           _transactions[index] = newTransaction;
//         }
//       }
//       _saveTransactionsToLocalStorage(); // Save updated transactions to local storage
//
//       // Notify the home screen that transactions have been updated
//       widget.onTransactionsUpdated();
//     });
//   }
//
//   // Save transactions to local storage
//   Future<void> _saveTransactionsToLocalStorage() async {
//     final prefs = await SharedPreferences.getInstance();
//     String transactionsJson = jsonEncode(_transactions.map((txn) => txn.toJson()).toList());
//     await prefs.setString('transactions', transactionsJson);
//   }
//
//
// }