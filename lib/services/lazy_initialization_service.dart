import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../helper/constants.dart';

/// Lazy initialization service for non-critical app features
/// This helps improve app startup time by deferring heavy operations
class LazyInitializationService {
  static LazyInitializationService? _instance;
  static LazyInitializationService get instance => _instance ??= LazyInitializationService._();
  
  LazyInitializationService._();

  bool _isInitialized = false;
  bool _adsInitialized = false;

  /// Initialize non-critical services after app has loaded
  Future<void> initializeLazily() async {
    if (_isInitialized) return;
    
    try {
      // Initialize Google Mobile Ads in background
      await _initializeAds();
      
      // Add other non-critical initializations here
      // e.g., analytics, crash reporting, etc.
      
      _isInitialized = true;
      
      if (kDebugMode) {
        print('✅ Lazy initialization completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Lazy initialization failed: $e');
      }
      // Don't throw - these are non-critical features
    }
  }

  /// Initialize Google Mobile Ads
  Future<void> _initializeAds() async {
    if (_adsInitialized || !Constants.isMobileDevice) return;
    
    try {
      if (kDebugMode) {
        print('🔧 Initializing Google Mobile Ads...');
      }
      
      await MobileAds.instance.initialize();
      _adsInitialized = true;
      
      if (kDebugMode) {
        print('✅ Google Mobile Ads initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to initialize Google Mobile Ads: $e');
      }
      // Don't rethrow - ads are not critical for app functionality
    }
  }

  /// Clear any cached data to free up memory
  void clearCaches() {
    if (kDebugMode) {
      print('🧹 Clearing caches to free up memory');
    }
    
    // Here we could clear any cached data
    // For now, just log the action
    // In the future, this could clear image caches, temporary data, etc.
  }

  /// Check if ads are initialized
  bool get adsInitialized => _adsInitialized;

  /// Get initialization status
  bool get isInitialized => _isInitialized;

  /// Reset initialization state (for testing)
  void reset() {
    _isInitialized = false;
    _adsInitialized = false;
  }
}
