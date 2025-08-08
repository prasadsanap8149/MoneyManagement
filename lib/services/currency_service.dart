import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyService {
  static CurrencyService? _instance;
  static CurrencyService get instance {
    _instance ??= CurrencyService._internal();
    return _instance!;
  }
  
  CurrencyService._internal();

  String _currencySymbol = '₹';
  String _currencyCode = 'INR';
  String _currencyLocale = 'en_IN';
  String _selectedCountry = 'India';

  String get currencySymbol => _currencySymbol;
  String get currencyCode => _currencyCode;
  String get currencyLocale => _currencyLocale;
  String get selectedCountry => _selectedCountry;

  Future<void> initialize() async {
    await _loadCurrencySettings();
  }

  Future<void> _loadCurrencySettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _selectedCountry = prefs.getString('selected_country') ?? 'India';
      _currencySymbol = prefs.getString('currency_symbol') ?? '₹';
      _currencyCode = prefs.getString('currency_code') ?? 'INR';
      _currencyLocale = prefs.getString('currency_locale') ?? 'en_IN';
    } catch (e) {
      // Use default values if loading fails
      _selectedCountry = 'India';
      _currencySymbol = '₹';
      _currencyCode = 'INR';
      _currencyLocale = 'en_IN';
    }
  }

  Future<void> updateCurrency({
    required String country,
    required String symbol,
    required String code,
    required String locale,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_country', country);
      await prefs.setString('currency_symbol', symbol);
      await prefs.setString('currency_code', code);
      await prefs.setString('currency_locale', locale);
      
      _selectedCountry = country;
      _currencySymbol = symbol;
      _currencyCode = code;
      _currencyLocale = locale;
    } catch (e) {
      throw Exception('Failed to update currency settings: $e');
    }
  }

  // Refresh currency settings from SharedPreferences
  Future<void> refreshSettings() async {
    await _loadCurrencySettings();
  }

  NumberFormat get currencyFormat {
    try {
      return NumberFormat.currency(locale: _currencyLocale, symbol: _currencySymbol);
    } catch (e) {
      // Fallback to default format if locale is not supported
      return NumberFormat.currency(locale: 'en_IN', symbol: _currencySymbol);
    }
  }

  String formatAmount(double amount) {
    return currencyFormat.format(amount);
  }

  String formatAmountCompact(double amount) {
    try {
      final compact = NumberFormat.compactCurrency(
        locale: _currencyLocale,
        symbol: _currencySymbol,
      );
      return compact.format(amount);
    } catch (e) {
      // Fallback to regular format
      return formatAmount(amount);
    }
  }

  // Get display name for the current country/currency
  String get displayName => '$_selectedCountry ($_currencyCode)';
}
