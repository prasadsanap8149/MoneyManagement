import 'dart:io';
import 'package:flutter/foundation.dart';
import 'environment_loader.dart';

/// Secure configuration service for managing sensitive data like AdMob IDs
/// Handles different configurations for debug, release, and testing environments
class SecureConfig {
  static SecureConfig? _instance;
  static SecureConfig get instance => _instance ??= SecureConfig._();
  
  SecureConfig._();

  // AdMob Configuration
  late final String _adMobAppId;
  late final String _adMobBannerAdUnitId;
  late final String _adMobInterstitialAdUnitId;
  late final String _adMobRewardedAdUnitId;

  bool _isInitialized = false;

  /// Initialize configuration based on build mode and platform
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load environment configuration with timeout
      await EnvironmentLoader.instance.loadConfiguration()
          .timeout(const Duration(seconds: 2));

      if (kDebugMode) {
        _initializeDebugConfig();
      } else {
        _initializeReleaseConfig();
      }

      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Secure config initialization failed: $e');
      }
      // Re-throw the error instead of using fallback config
      rethrow;
    }
  }

  /// Fallback configuration if initialization fails
  void _initializeFallbackConfig() {
    // No fallback - configuration must come from environment files only
    throw StateError(
      'AdMob configuration failed to initialize! '
      'Please ensure your environment configuration files are properly set up:\n'
      '- For debug builds: assets/config/.env.debug or .env.debug\n'
      '- For production builds: .env.production with proper environment variables\n'
      'No fallback testing IDs are provided for security reasons.'
    );
  }

  /// Debug/Test configuration - reads only from environment files
  void _initializeDebugConfig() {
    final envLoader = EnvironmentLoader.instance;
    
    // AdMob IDs must come from environment files only
    final androidAppId = envLoader.getConfigValue('ADMOB_APP_ID_ANDROID');
    final iosAppId = envLoader.getConfigValue('ADMOB_APP_ID_IOS');
    
    if (androidAppId == null || iosAppId == null) {
      throw StateError('AdMob App IDs not found in debug environment configuration');
    }
    
    _adMobAppId = Platform.isAndroid ? androidAppId : iosAppId;

    // Banner Ad Unit IDs
    final androidBannerId = envLoader.getConfigValue('ADMOB_BANNER_ID_ANDROID');
    final iosBannerId = envLoader.getConfigValue('ADMOB_BANNER_ID_IOS');
    
    if (androidBannerId == null || iosBannerId == null) {
      throw StateError('AdMob Banner IDs not found in debug environment configuration');
    }
    
    _adMobBannerAdUnitId = Platform.isAndroid ? androidBannerId : iosBannerId;

    // Interstitial Ad Unit IDs
    final androidInterstitialId = envLoader.getConfigValue('ADMOB_INTERSTITIAL_ID_ANDROID');
    final iosInterstitialId = envLoader.getConfigValue('ADMOB_INTERSTITIAL_ID_IOS');
    
    if (androidInterstitialId == null || iosInterstitialId == null) {
      throw StateError('AdMob Interstitial IDs not found in debug environment configuration');
    }
    
    _adMobInterstitialAdUnitId = Platform.isAndroid ? androidInterstitialId : iosInterstitialId;

    // Rewarded Ad Unit IDs  
    final androidRewardedId = envLoader.getConfigValue('ADMOB_REWARDED_ID_ANDROID');
    final iosRewardedId = envLoader.getConfigValue('ADMOB_REWARDED_ID_IOS');
    
    if (androidRewardedId == null || iosRewardedId == null) {
      throw StateError('AdMob Rewarded IDs not found in debug environment configuration');
    }
    
    _adMobRewardedAdUnitId = Platform.isAndroid ? androidRewardedId : iosRewardedId;

    if (kDebugMode) {
      print('🔧 Debug Mode: AdMob IDs loaded from environment configuration only');
      print('📱 Platform: ${Platform.operatingSystem}');
    }
  }

  /// Production configuration - reads only from secure environment
  void _initializeReleaseConfig() {
    final envLoader = EnvironmentLoader.instance;
    
    // Production AdMob IDs must come from environment variables only
    final androidAppId = envLoader.getConfigValue('ADMOB_APP_ID_ANDROID');
    final iosAppId = envLoader.getConfigValue('ADMOB_APP_ID_IOS');
    
    if (androidAppId == null || iosAppId == null) {
      throw StateError('AdMob App IDs not found in production environment configuration');
    }
    
    _adMobAppId = Platform.isAndroid ? androidAppId : iosAppId;
    
    // Banner Ad Unit IDs
    final androidBannerId = envLoader.getConfigValue('ADMOB_BANNER_ID_ANDROID');
    final iosBannerId = envLoader.getConfigValue('ADMOB_BANNER_ID_IOS');
    
    if (androidBannerId == null || iosBannerId == null) {
      throw StateError('AdMob Banner IDs not found in production environment configuration');
    }
    
    _adMobBannerAdUnitId = Platform.isAndroid ? androidBannerId : iosBannerId;
    
    // Interstitial Ad Unit IDs
    final androidInterstitialId = envLoader.getConfigValue('ADMOB_INTERSTITIAL_ID_ANDROID');
    final iosInterstitialId = envLoader.getConfigValue('ADMOB_INTERSTITIAL_ID_IOS');
    
    if (androidInterstitialId == null || iosInterstitialId == null) {
      throw StateError('AdMob Interstitial IDs not found in production environment configuration');
    }
    
    _adMobInterstitialAdUnitId = Platform.isAndroid ? androidInterstitialId : iosInterstitialId;
    
    // Rewarded Ad Unit IDs
    final androidRewardedId = envLoader.getConfigValue('ADMOB_REWARDED_ID_ANDROID');
    final iosRewardedId = envLoader.getConfigValue('ADMOB_REWARDED_ID_IOS');
    
    if (androidRewardedId == null || iosRewardedId == null) {
      throw StateError('AdMob Rewarded IDs not found in production environment configuration');
    }
    
    _adMobRewardedAdUnitId = Platform.isAndroid ? androidRewardedId : iosRewardedId;

    if (kDebugMode) {
      print('🚀 Production Mode: AdMob IDs loaded from environment configuration only');
      print('📱 Platform: ${Platform.operatingSystem}');
    }
  }

  // Public getters for ad IDs
  String get adMobAppId {
    if (!_isInitialized) {
      throw StateError('SecureConfig not initialized. Call initialize() first.');
    }
    return _adMobAppId;
  }

  String get adMobBannerAdUnitId {
    if (!_isInitialized) {
      throw StateError('SecureConfig not initialized. Call initialize() first.');
    }
    return _adMobBannerAdUnitId;
  }

  String get adMobInterstitialAdUnitId {
    if (!_isInitialized) {
      throw StateError('SecureConfig not initialized. Call initialize() first.');
    }
    return _adMobInterstitialAdUnitId;
  }

  String get adMobRewardedAdUnitId {
    if (!_isInitialized) {
      throw StateError('SecureConfig not initialized. Call initialize() first.');
    }
    return _adMobRewardedAdUnitId;
  }

  /// Check if we're using test ads
  bool get isUsingTestAds => kDebugMode;

  /// Get current configuration info for debugging
  Map<String, dynamic> getConfigInfo() {
    return {
      'isDebugMode': kDebugMode,
      'isUsingTestAds': isUsingTestAds,
      'platform': Platform.operatingSystem,
      'appId': adMobAppId,
      'bannerAdUnitId': adMobBannerAdUnitId,
      // Don't log other IDs in production for security
      if (kDebugMode) ...{
        'interstitialAdUnitId': adMobInterstitialAdUnitId,
        'rewardedAdUnitId': adMobRewardedAdUnitId,
      }
    };
  }

  /// Validate configuration
  bool validateConfiguration() {
    try {
      // Check if all required IDs are present and valid
      if (adMobAppId.isEmpty || !adMobAppId.startsWith('ca-app-pub-')) {
        if (kDebugMode) print('❌ Invalid AdMob App ID: $adMobAppId');
        return false;
      }

      if (adMobBannerAdUnitId.isEmpty || !adMobBannerAdUnitId.startsWith('ca-app-pub-')) {
        if (kDebugMode) print('❌ Invalid Banner Ad Unit ID: $adMobBannerAdUnitId');
        return false;
      }

      if (kDebugMode) {
        print('✅ AdMob configuration validation passed');
        print('📋 Config: ${getConfigInfo()}');
      }

      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Configuration validation error: $e');
      return false;
    }
  }
}
