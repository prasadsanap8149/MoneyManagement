import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/transaction_model.dart';

class SharedPreferenceService{


  // Load transactions from local storage
  Future<List<dynamic>?> loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedTransactions = prefs.getString('transactions');
    if (savedTransactions != null) {
      List<dynamic> decodedTransactions = jsonDecode(savedTransactions);
      return decodedTransactions
            .map((json) => TransactionModel.fromJson(json))
            .toList();
       // Recalculate balance after loading

    }
    return null;
  }
}