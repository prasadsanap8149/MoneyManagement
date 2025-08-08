import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Environment configuration loader
/// Handles loading configuration from environment files and build-time variables
class EnvironmentLoader {
  static EnvironmentLoader? _instance;
  static EnvironmentLoader get instance => _instance ??= EnvironmentLoader._();
  
  EnvironmentLoader._();

  Map<String, String> _config = {};
  bool _isLoaded = false;

  /// Load environment configuration based on build mode
  Future<void> loadConfiguration() async {
    if (_isLoaded) return;

    try {
      // Load configuration based on build mode
      if (kDebugMode) {
        await _loadDebugConfig();
      } else {
        await _loadProductionConfig();
      }
      
      _isLoaded = true;
      
      if (kDebugMode) {
        print('✅ Environment configuration loaded successfully');
        print('📋 Build Mode: ${kDebugMode ? "Debug" : "Release"}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to load environment configuration: $e');
      }
      // Fallback to default configuration
      _loadDefaultConfig();
    }
  }

  /// Load debug configuration from assets or environment
  Future<void> _loadDebugConfig() async {
    try {
      // Try to load from assets first (for development)
      final String envContent = await rootBundle.loadString('assets/config/.env.debug');
      _parseEnvContent(envContent);
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Could not load debug config from assets, using defaults');
      }
      _loadDefaultDebugConfig();
    }
  }

  /// Load production configuration from environment variables
  Future<void> _loadProductionConfig() async {
    // In production, prioritize environment variables
    _config = Map<String, String>.from(Platform.environment);
    
    // If no environment variables are set, use default production config
    if (!_config.containsKey('ADMOB_APP_ID_ANDROID')) {
      _loadDefaultProductionConfig();
    }
  }

  /// Parse environment file content
  void _parseEnvContent(String content) {
    final lines = content.split('\n');
    for (String line in lines) {
      line = line.trim();
      
      // Skip empty lines and comments
      if (line.isEmpty || line.startsWith('#')) continue;
      
      // Parse key=value pairs
      final parts = line.split('=');
      if (parts.length == 2) {
        final key = parts[0].trim();
        final value = parts[1].trim();
        _config[key] = value;
      }
    }
  }

  /// Default debug configuration - removed to enforce environment file usage
  void _loadDefaultDebugConfig() {
    throw StateError(
      'Debug environment configuration not found! '
      'Please ensure you have a proper debug configuration file:\n'
      '- assets/config/.env.debug (bundled with app)\n'
      '- or .env.debug in project root\n'
      'No default fallback configuration is provided.'
    );
  }

  /// Default production configuration - removed to enforce environment variable usage
  void _loadDefaultProductionConfig() {
    throw StateError(
      'Production environment configuration not found! '
      'Please ensure you have set proper environment variables or .env.production file:\n'
      '- Environment variables (recommended for CI/CD)\n'
      '- or .env.production file with actual AdMob IDs\n'
      'No default fallback configuration is provided for security reasons.'
    );
  }

  /// Fallback to basic default configuration
  void _loadDefaultConfig() {
    if (kDebugMode) {
      _loadDefaultDebugConfig();
    } else {
      _loadDefaultProductionConfig();
    }
  }

  /// Get configuration value
  String? getConfigValue(String key) {
    if (!_isLoaded) {
      if (kDebugMode) {
        print('⚠️ Warning: Configuration not loaded yet for key: $key');
      }
      return null;
    }
    return _config[key];
  }

  /// Get configuration value with default
  String getConfigValueOrDefault(String key, String defaultValue) {
    return getConfigValue(key) ?? defaultValue;
  }

  /// Check if configuration is loaded
  bool get isLoaded => _isLoaded;

  /// Get all configuration (for debugging)
  Map<String, String> getAllConfig() {
    return Map<String, String>.from(_config);
  }

  /// Clear configuration (for testing)
  void clearConfiguration() {
    _config.clear();
    _isLoaded = false;
  }
}
