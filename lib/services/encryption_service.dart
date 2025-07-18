import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  late final Encrypter _encrypter;
  late final IV _iv;
  static const String _keyPrefName = 'encryption_key';
  static const String _ivPrefName = 'encryption_iv';

  /// Initialize the encryption service
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get or create encryption key
    String? keyString = prefs.getString(_keyPrefName);
    if (keyString == null) {
      keyString = _generateSecureKey();
      await prefs.setString(_keyPrefName, keyString);
    }
    
    // Get or create IV
    String? ivString = prefs.getString(_ivPrefName);
    if (ivString == null) {
      ivString = _generateSecureIV();
      await prefs.setString(_ivPrefName, ivString);
    }
    
    final key = Key.fromBase64(keyString);
    _iv = IV.fromBase64(ivString);
    _encrypter = Encrypter(AES(key));
  }

  /// Generate a secure random key
  String _generateSecureKey() {
    final random = Random.secure();
    final keyBytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64.encode(keyBytes);
  }

  /// Generate a secure random IV
  String _generateSecureIV() {
    final random = Random.secure();
    final ivBytes = List<int>.generate(16, (i) => random.nextInt(256));
    return base64.encode(ivBytes);
  }

  /// Encrypt sensitive data
  String encryptData(String data) {
    try {
      final encrypted = _encrypter.encrypt(data, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      throw Exception('Failed to encrypt data: $e');
    }
  }

  /// Decrypt sensitive data
  String decryptData(String encryptedData) {
    try {
      final encrypted = Encrypted.fromBase64(encryptedData);
      return _encrypter.decrypt(encrypted, iv: _iv);
    } catch (e) {
      throw Exception('Failed to decrypt data: $e');
    }
  }

  /// Encrypt financial transaction data
  String encryptTransaction(Map<String, dynamic> transaction) {
    try {
      final jsonString = json.encode(transaction);
      return encryptData(jsonString);
    } catch (e) {
      throw Exception('Failed to encrypt transaction: $e');
    }
  }

  /// Decrypt financial transaction data
  Map<String, dynamic> decryptTransaction(String encryptedTransaction) {
    try {
      final decryptedString = decryptData(encryptedTransaction);
      return json.decode(decryptedString) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to decrypt transaction: $e');
    }
  }

  /// Encrypt a list of transactions
  List<String> encryptTransactionList(List<Map<String, dynamic>> transactions) {
    return transactions.map((transaction) => encryptTransaction(transaction)).toList();
  }

  /// Decrypt a list of transactions
  List<Map<String, dynamic>> decryptTransactionList(List<String> encryptedTransactions) {
    return encryptedTransactions.map((encrypted) => decryptTransaction(encrypted)).toList();
  }

  /// Hash sensitive data for verification (one-way)
  String hashData(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verify hashed data
  bool verifyHash(String data, String hash) {
    return hashData(data) == hash;
  }

  /// Clear all encryption keys (for app reset)
  Future<void> clearKeys() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPrefName);
    await prefs.remove(_ivPrefName);
  }

  /// Check if encryption is properly initialized
  bool get isInitialized {
    try {
      // Try to encrypt a test string to verify initialization
      encryptData('test');
      return true;
    } catch (e) {
      return false;
    }
  }
}
