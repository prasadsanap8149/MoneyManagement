import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

import '../models/transaction_model.dart';

class UtilService{
    double calculateBalance(List<TransactionModel> transactions, String transactionType){
     return transactions
         .where((txn) => txn.type == transactionType)
       .fold(0.0, (sum, txn) => sum + (txn.amount > 0 ? txn.amount : 0));
   }
    final indianRupeeFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    Future<void> requestStoragePermission() async {
      final status = await Permission.storage.status;

      if (!status.isGranted) {
        final result = await Permission.storage.request();
        if (result.isGranted) {
          debugPrint("Storage permission granted");
        } else if (result.isPermanentlyDenied) {
          // Direct user to app settings
          openAppSettings();
        } else {
          debugPrint("Storage permission denied");
        }
      }
    }
}
final UtilService utilService=UtilService();