import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_model.dart';


class TransactionStorage {
  static const String transactionsKey = 'transactions_key';

  // Save transactions to local storage
  Future<void> saveTransactions(List<TransactionModel> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> jsonTransactions = transactions.map((txn) => jsonEncode(txn.toJson())).toList();
    await prefs.setStringList(transactionsKey, jsonTransactions);
  }

  // Load transactions from local storage
  Future<List<TransactionModel>> loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? jsonTransactions = prefs.getStringList(transactionsKey);
    if (jsonTransactions == null) return [];

    return jsonTransactions.map((jsonTxn) => TransactionModel.fromJson(jsonDecode(jsonTxn))).toList();
  }
}
