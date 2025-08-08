import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../services/secure_config.dart';

/// Interstitial Ad Widget for showing full-screen ads
/// Used for import/export functionality and other key user actions
class InterstitialAdWidget {
  static InterstitialAdWidget? _instance;
  static InterstitialAdWidget get instance => _instance ??= InterstitialAdWidget._();
  
  InterstitialAdWidget._();

  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;
  bool _isAdShowing = false;
  
  // Secure configuration instance
  final SecureConfig _config = SecureConfig.instance;

  // Get ad unit ID securely based on build mode and platform
  String get _adUnitId => _config.adMobInterstitialAdUnitId;

  /// Initialize and load interstitial ad
  Future<void> loadAd() async {
    if (_isAdLoaded || _isAdShowing) return;

    try {
      // Initialize secure configuration if not already done
      await _config.initialize();
      
      // Validate configuration before proceeding
      if (!_config.validateConfiguration()) {
        if (kDebugMode) {
          print('❌ AdMob configuration validation failed for interstitial');
        }
        return;
      }

      if (kDebugMode) {
        print('🔄 Loading interstitial ad with ID: $_adUnitId');
      }

      await InterstitialAd.load(
        adUnitId: _adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            _interstitialAd = ad;
            _isAdLoaded = true;
            
            // Set full screen content callback
            _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
              onAdShowedFullScreenContent: (InterstitialAd ad) {
                if (kDebugMode) {
                  print('📱 Interstitial ad showed full screen content');
                }
                _isAdShowing = true;
              },
              onAdDismissedFullScreenContent: (InterstitialAd ad) {
                if (kDebugMode) {
                  print('✅ Interstitial ad dismissed');
                }
                _isAdShowing = false;
                ad.dispose();
                _interstitialAd = null;
                _isAdLoaded = false;
                
                // Pre-load next ad for better user experience
                _preloadNextAd();
              },
              onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
                if (kDebugMode) {
                  print('❌ Interstitial ad failed to show: ${error.message}');
                }
                _isAdShowing = false;
                ad.dispose();
                _interstitialAd = null;
                _isAdLoaded = false;
              },
            );
            
            if (kDebugMode) {
              print('✅ Interstitial ad loaded successfully');
            }
          },
          onAdFailedToLoad: (LoadAdError error) {
            if (kDebugMode) {
              print('❌ Interstitial ad failed to load: ${error.message}');
            }
            _isAdLoaded = false;
            _interstitialAd = null;
          },
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading interstitial ad: $e');
        if (e.toString().contains('StateError')) {
          print('💡 Check your environment configuration files');
        }
      }
      _isAdLoaded = false;
      _interstitialAd = null;
    }
  }

  /// Show interstitial ad if loaded
  /// Returns true if ad was shown, false otherwise
  Future<bool> showAd() async {
    if (!_isAdLoaded || _interstitialAd == null || _isAdShowing) {
      if (kDebugMode) {
        print('⚠️ Interstitial ad not ready to show');
      }
      return false;
    }

    try {
      await _interstitialAd!.show();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error showing interstitial ad: $e');
      }
      return false;
    }
  }

  /// Show ad with callback for when ad is dismissed
  /// Useful for continuing with the original action after ad
  Future<void> showAdWithCallback({
    required VoidCallback onAdDismissed,
    VoidCallback? onAdFailedToShow,
  }) async {
    if (!_isAdLoaded || _interstitialAd == null || _isAdShowing) {
      if (kDebugMode) {
        print('⚠️ Interstitial ad not ready, executing callback immediately');
      }
      onAdDismissed();
      return;
    }

    // Override the callback to include our custom callback
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) {
        if (kDebugMode) {
          print('📱 Interstitial ad showed full screen content');
        }
        _isAdShowing = true;
      },
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        if (kDebugMode) {
          print('✅ Interstitial ad dismissed, executing callback');
        }
        _isAdShowing = false;
        ad.dispose();
        _interstitialAd = null;
        _isAdLoaded = false;
        
        // Execute the custom callback
        onAdDismissed();
        
        // Pre-load next ad
        _preloadNextAd();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        if (kDebugMode) {
          print('❌ Interstitial ad failed to show: ${error.message}');
        }
        _isAdShowing = false;
        ad.dispose();
        _interstitialAd = null;
        _isAdLoaded = false;
        
        // Execute failure callback or default callback
        if (onAdFailedToShow != null) {
          onAdFailedToShow();
        } else {
          onAdDismissed();
        }
      },
    );

    try {
      await _interstitialAd!.show();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error showing interstitial ad: $e');
      }
      if (onAdFailedToShow != null) {
        onAdFailedToShow();
      } else {
        onAdDismissed();
      }
    }
  }

  /// Pre-load next ad for better user experience
  void _preloadNextAd() {
    // Add a small delay before preloading to avoid rapid requests
    Future.delayed(const Duration(seconds: 2), () {
      loadAd();
    });
  }

  /// Check if ad is ready to be shown
  bool get isAdReady => _isAdLoaded && _interstitialAd != null && !_isAdShowing;

  /// Get current ad loading status
  bool get isLoading => !_isAdLoaded && !_isAdShowing;

  /// Dispose of current ad
  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isAdLoaded = false;
    _isAdShowing = false;
  }
}

/// Helper class for easy integration with UI actions
class InterstitialAdHelper {
  /// Show interstitial ad before executing an action
  /// Perfect for import/export functions
  static Future<void> showAdBeforeAction({
    required String actionName,
    required VoidCallback action,
    VoidCallback? onAdFailure,
  }) async {
    if (kDebugMode) {
      print('🎯 Preparing to show interstitial ad for: $actionName');
    }

    // Ensure ad is loaded
    if (!InterstitialAdWidget.instance.isAdReady) {
      await InterstitialAdWidget.instance.loadAd();
      
      // Wait a moment for ad to load
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // Show ad with callback
    await InterstitialAdWidget.instance.showAdWithCallback(
      onAdDismissed: () {
        if (kDebugMode) {
          print('✅ Ad dismissed, executing action: $actionName');
        }
        action();
      },
      onAdFailedToShow: () {
        if (kDebugMode) {
          print('⚠️ Ad failed to show, executing action anyway: $actionName');
        }
        if (onAdFailure != null) {
          onAdFailure();
        } else {
          action();
        }
      },
    );
  }
}
