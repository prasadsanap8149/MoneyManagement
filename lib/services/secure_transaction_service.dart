import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_model.dart';
import 'encryption_service.dart';

class SecureTransactionService {
  static final SecureTransactionService _instance = SecureTransactionService._internal();
  factory SecureTransactionService() => _instance;
  SecureTransactionService._internal();

  final EncryptionService _encryptionService = EncryptionService();
  static const String _transactionsKey = 'secure_transactions';
  static const String _transactionHashKey = 'transaction_hash';

  /// Initialize the secure transaction service
  Future<void> initialize() async {
    await _encryptionService.initialize();
  }

  /// Save transactions with encryption
  Future<void> saveTransactions(List<TransactionModel> transactions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convert transactions to JSON
      final transactionMaps = transactions.map((t) => t.toJson()).toList();
      
      // Encrypt each transaction
      final encryptedTransactions = _encryptionService.encryptTransactionList(transactionMaps);
      
      // Save encrypted transactions
      await prefs.setStringList(_transactionsKey, encryptedTransactions);
      
      // Create and save hash for integrity verification
      final dataHash = _encryptionService.hashData(json.encode(transactionMaps));
      await prefs.setString(_transactionHashKey, dataHash);
      
    } catch (e) {
      throw Exception('Failed to save transactions securely: $e');
    }
  }

  /// Load transactions with decryption
  Future<List<TransactionModel>> loadTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get encrypted transactions
      final encryptedTransactions = prefs.getStringList(_transactionsKey);
      if (encryptedTransactions == null || encryptedTransactions.isEmpty) {
        return [];
      }
      
      // Decrypt transactions
      final decryptedMaps = _encryptionService.decryptTransactionList(encryptedTransactions);
      
      // Verify data integrity
      final storedHash = prefs.getString(_transactionHashKey);
      if (storedHash != null) {
        final currentHash = _encryptionService.hashData(json.encode(decryptedMaps));
        if (currentHash != storedHash) {
          throw Exception('Data integrity check failed. Transactions may have been tampered with.');
        }
      }
      
      // Convert to TransactionModel objects
      return decryptedMaps.map((map) => TransactionModel.fromJson(map)).toList();
      
    } catch (e) {
      throw Exception('Failed to load transactions securely: $e');
    }
  }

  /// Add a single transaction
  Future<void> addTransaction(TransactionModel transaction) async {
    try {
      final transactions = await loadTransactions();
      
      // Assign ID if not present
      transaction.id ??= DateTime.now().millisecondsSinceEpoch.toString();
      
      transactions.add(transaction);
      await saveTransactions(transactions);
      
    } catch (e) {
      throw Exception('Failed to add transaction: $e');
    }
  }

  /// Update a transaction
  Future<void> updateTransaction(TransactionModel updatedTransaction) async {
    try {
      final transactions = await loadTransactions();
      
      final index = transactions.indexWhere((t) => t.id == updatedTransaction.id);
      if (index != -1) {
        transactions[index] = updatedTransaction;
        await saveTransactions(transactions);
      } else {
        throw Exception('Transaction not found');
      }
      
    } catch (e) {
      throw Exception('Failed to update transaction: $e');
    }
  }

  /// Delete a transaction
  Future<void> deleteTransaction(String transactionId) async {
    try {
      final transactions = await loadTransactions();
      
      transactions.removeWhere((t) => t.id == transactionId);
      await saveTransactions(transactions);
      
    } catch (e) {
      throw Exception('Failed to delete transaction: $e');
    }
  }

  /// Get transactions by date range
  Future<List<TransactionModel>> getTransactionsByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      final allTransactions = await loadTransactions();
      
      return allTransactions.where((transaction) {
        final transactionDate = transaction.date;
        return transactionDate.isAfter(startDate) && transactionDate.isBefore(endDate);
      }).toList();
      
    } catch (e) {
      throw Exception('Failed to get transactions by date range: $e');
    }
  }

  /// Get transactions by type (Income/Expense)
  Future<List<TransactionModel>> getTransactionsByType(String type) async {
    try {
      final allTransactions = await loadTransactions();
      
      return allTransactions.where((transaction) => transaction.type == type).toList();
      
    } catch (e) {
      throw Exception('Failed to get transactions by type: $e');
    }
  }

  /// Get total balance
  Future<double> getTotalBalance() async {
    try {
      final transactions = await loadTransactions();
      
      double balance = 0.0;
      for (final transaction in transactions) {
        if (transaction.type == 'Income') {
          balance += transaction.amount;
        } else if (transaction.type == 'Expense') {
          balance -= transaction.amount;
        }
      }
      
      return balance;
      
    } catch (e) {
      throw Exception('Failed to calculate total balance: $e');
    }
  }

  /// Clear all transactions (for reset)
  Future<void> clearAllTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_transactionsKey);
      await prefs.remove(_transactionHashKey);
      
    } catch (e) {
      throw Exception('Failed to clear transactions: $e');
    }
  }

  /// Backup transactions to unencrypted format (for export)
  Future<String> backupTransactions() async {
    try {
      final transactions = await loadTransactions();
      final transactionMaps = transactions.map((t) => t.toJson()).toList();
      
      return json.encode(transactionMaps);
      
    } catch (e) {
      throw Exception('Failed to backup transactions: $e');
    }
  }

  /// Restore transactions from backup (import)
  Future<void> restoreTransactions(String backupData) async {
    try {
      final List<dynamic> transactionMaps = json.decode(backupData);
      final transactions = transactionMaps.map((map) => TransactionModel.fromJson(map)).toList();
      
      await saveTransactions(transactions);
      
    } catch (e) {
      throw Exception('Failed to restore transactions: $e');
    }
  }

  /// Import and append transactions from JSON backup (doesn't replace existing data)
  Future<int> importAndAppendTransactions(String jsonData) async {
    try {
      final List<dynamic> transactionMaps = json.decode(jsonData);
      final importedTransactions = transactionMaps.map((map) => TransactionModel.fromJson(map)).toList();
      
      // Load existing transactions
      final existingTransactions = await loadTransactions();
      
      // Create a set of existing transaction IDs for duplicate detection
      final existingIds = existingTransactions.map((t) => t.id).toSet();
      
      // Filter out duplicates from imported transactions
      final newTransactions = importedTransactions.where((t) => !existingIds.contains(t.id)).toList();
      
      // Combine existing and new transactions
      final allTransactions = [...existingTransactions, ...newTransactions];
      
      // Save combined transactions
      await saveTransactions(allTransactions);
      
      return newTransactions.length; // Return number of new transactions added
      
    } catch (e) {
      throw Exception('Failed to import transactions: $e');
    }
  }

  /// Verify data integrity
  Future<bool> verifyDataIntegrity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedHash = prefs.getString(_transactionHashKey);
      
      if (storedHash == null) {
        return false; // No hash stored, can't verify
      }
      
      // Load and check current data hash
      final transactions = await loadTransactions();
      final transactionMaps = transactions.map((t) => t.toJson()).toList();
      final currentHash = _encryptionService.hashData(json.encode(transactionMaps));
      
      return currentHash == storedHash;
      
    } catch (e) {
      return false;
    }
  }

  /// Migrate existing plain text transactions to encrypted storage
  Future<bool> migrateFromPlainTextStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if plain text transactions exist
      final plainTextTransactions = prefs.getString('transactions');
      if (plainTextTransactions == null) {
        return false; // No migration needed
      }
      
      // Check if encrypted transactions already exist
      final encryptedTransactions = prefs.getStringList(_transactionsKey);
      if (encryptedTransactions != null && encryptedTransactions.isNotEmpty) {
        // Encrypted storage already exists, don't migrate
        return false;
      }
      
      // Parse plain text transactions
      final List<dynamic> decodedTransactions = json.decode(plainTextTransactions);
      final transactions = decodedTransactions
          .map((json) => TransactionModel.fromJson(json))
          .toList();
      
      // Save to encrypted storage
      await saveTransactions(transactions);
      
      // Remove plain text storage
      await prefs.remove('transactions');
      
      return true; // Migration completed successfully
      
    } catch (e) {
      throw Exception('Failed to migrate transactions: $e');
    }
  }
}
