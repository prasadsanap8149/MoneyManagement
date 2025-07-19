import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

import '../models/transaction_model.dart';

class UtilService{
    double calculateBalance(List<TransactionModel> transactions, String transactionType){
     return transactions
         .where((txn) => txn.type == transactionType)
       .fold(0.0, (sum, txn) => sum + (txn.amount > 0 ? txn.amount : 0));
   }
    final indianRupeeFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    /// Deprecated - Storage permissions are no longer needed for Android 11+
    /// File operations now use SAF (Storage Access Framework) automatically
    @deprecated
    Future<void> requestStoragePermission() async {
      debugPrint("Storage permission request is deprecated. Using SAF instead.");
      // Note: This method is kept for compatibility but does nothing
      // File operations now use SAF which doesn't require permissions on Android 11+
    }
}
final UtilService utilService=UtilService();
