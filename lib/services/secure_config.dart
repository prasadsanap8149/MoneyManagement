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

    // Load environment configuration
    await EnvironmentLoader.instance.loadConfiguration();

    if (kDebugMode) {
      _initializeDebugConfig();
    } else {
      _initializeReleaseConfig();
    }

    _isInitialized = true;
  }

  /// Debug/Test configuration - uses Google test ad units
  void _initializeDebugConfig() {
    final envLoader = EnvironmentLoader.instance;
    
    // Google Test AdMob App IDs (safe for debug)
    _adMobAppId = Platform.isAndroid 
        ? envLoader.getConfigValueOrDefault('ADMOB_APP_ID_ANDROID', 'ca-app-pub-3940256099942544~3347511713')
        : envLoader.getConfigValueOrDefault('ADMOB_APP_ID_IOS', 'ca-app-pub-3940256099942544~1458002511');

    // Google Test Ad Unit IDs (safe for debug)
    _adMobBannerAdUnitId = Platform.isAndroid
        ? envLoader.getConfigValueOrDefault('ADMOB_BANNER_ID_ANDROID', 'ca-app-pub-3940256099942544/9214589741')
        : envLoader.getConfigValueOrDefault('ADMOB_BANNER_ID_IOS', 'ca-app-pub-3940256099942544/2435281174');

    _adMobInterstitialAdUnitId = Platform.isAndroid
        ? envLoader.getConfigValueOrDefault('ADMOB_INTERSTITIAL_ID_ANDROID', 'ca-app-pub-3940256099942544/1033173712')
        : envLoader.getConfigValueOrDefault('ADMOB_INTERSTITIAL_ID_IOS', 'ca-app-pub-3940256099942544/4411468910');

    _adMobRewardedAdUnitId = Platform.isAndroid
        ? envLoader.getConfigValueOrDefault('ADMOB_REWARDED_ID_ANDROID', 'ca-app-pub-3940256099942544/5224354917')
        : envLoader.getConfigValueOrDefault('ADMOB_REWARDED_ID_IOS', 'ca-app-pub-3940256099942544/1712485313');

    if (kDebugMode) {
      print('🔧 Debug Mode: Using Google Test AdMob IDs');
    }
  }

  /// Production configuration - reads from secure environment
  void _initializeReleaseConfig() {
    final envLoader = EnvironmentLoader.instance;
    
    // Production AdMob IDs - loaded from environment variables or secure config
    _adMobAppId = Platform.isAndroid
        ? envLoader.getConfigValueOrDefault('ADMOB_APP_ID_ANDROID', 'ca-app-pub-8068332503400690~1411312338')
        : envLoader.getConfigValueOrDefault('ADMOB_APP_ID_IOS', 'ca-app-pub-8068332503400690~1411312338');
    
    _adMobBannerAdUnitId = Platform.isAndroid
        ? envLoader.getConfigValueOrDefault('ADMOB_BANNER_ID_ANDROID', 'ca-app-pub-8068332503400690/XXXXXXXXXX')
        : envLoader.getConfigValueOrDefault('ADMOB_BANNER_ID_IOS', 'ca-app-pub-8068332503400690/XXXXXXXXXX');
    
    _adMobInterstitialAdUnitId = Platform.isAndroid
        ? envLoader.getConfigValueOrDefault('ADMOB_INTERSTITIAL_ID_ANDROID', 'ca-app-pub-8068332503400690/XXXXXXXXXX')
        : envLoader.getConfigValueOrDefault('ADMOB_INTERSTITIAL_ID_IOS', 'ca-app-pub-8068332503400690/XXXXXXXXXX');
    
    _adMobRewardedAdUnitId = Platform.isAndroid
        ? envLoader.getConfigValueOrDefault('ADMOB_REWARDED_ID_ANDROID', 'ca-app-pub-8068332503400690/XXXXXXXXXX')
        : envLoader.getConfigValueOrDefault('ADMOB_REWARDED_ID_IOS', 'ca-app-pub-8068332503400690/XXXXXXXXXX');

    if (kDebugMode) {
      print('🚀 Release Mode: Using Production AdMob IDs');
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
