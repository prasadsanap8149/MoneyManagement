import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../service/consent_manager.dart';
import '../../services/secure_config.dart';

/// An example app that loads a banner ad.
class GetBannerAd extends StatefulWidget {
  const GetBannerAd({super.key});

  @override
  GetBannerAdState createState() => GetBannerAdState();
}

class GetBannerAdState extends State<GetBannerAd> {
  var _isMobileAdsInitializeCalled = false;
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  Orientation? _currentOrientation;

  // Secure configuration instance
  final SecureConfig _config = SecureConfig.instance;

  // Get ad unit ID securely based on build mode and platform
  String get _adUnitId => _config.adMobBannerAdUnitId;

  @override
  void initState() {
    super.initState();
    
    // Initialize secure configuration and ads
    _initializeConfiguration();
  }

  /// Initialize secure configuration and start ad loading process
  Future<void> _initializeConfiguration() async {
    try {
      // Initialize secure configuration
      await _config.initialize();
      
      // Validate configuration before proceeding
      if (!_config.validateConfiguration()) {
        if (kDebugMode) {
          print('❌ AdMob configuration validation failed');
        }
        return;
      }
      
      if (kDebugMode) {
        print('🔧 AdMob Configuration: ${_config.isUsingTestAds ? "Test Ads" : "Production Ads"}');
        print('📱 Ad Unit ID: ${_config.adMobBannerAdUnitId}');
      }
      
      // Proceed with consent and ad initialization
      _startAdInitialization();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to initialize secure configuration: $e');
      }
    }
  }

  /// Start the ad initialization process with consent management
  void _startAdInitialization() {
    consentManager.gatherConsent((consentGatheringError) {
      if (consentGatheringError != null) {
        // Consent not obtained in current session.
        debugPrint(
            "${consentGatheringError.errorCode}: ${consentGatheringError.message}");
      }
      // Attempt to initialize the Mobile Ads SDK.
      _initializeMobileAdsSDK();
    });

    // This sample attempts to load ads using consent obtained in the previous session.
    _initializeMobileAdsSDK();
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        if (_currentOrientation != orientation) {
          _isLoaded = false;
          _loadAd();
          _currentOrientation = orientation;
        }
        return Stack(
          children: [
            if (_bannerAd != null && _isLoaded)
              Align(
                alignment: Alignment.topCenter,
                child: SafeArea(
                  child: SizedBox(
                    width: _bannerAd!.size.width.toDouble(),
                    height: _bannerAd!.size.height.toDouble(),
                    child: AdWidget(ad: _bannerAd!),
                  ),
                ),
              )
          ],
        );
      },
    );
  }

  /// Loads and shows a banner ad.
  ///
  /// Dimensions of the ad are determined by the width of the screen.
  void _loadAd() async {
    // Only load an ad if the Mobile Ads SDK has gathered consent aligned with
    // the app's configured messages.
    var canRequestAds = await consentManager.canRequestAds();
    if (!canRequestAds) {
      return;
    }

    if (!mounted) {
      return;
    }

    // Get an AnchoredAdaptiveBannerAdSize before loading the ad.
    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
        MediaQuery.sizeOf(context).width.truncate());

    if (size == null) {
      // Unable to get width of anchored banner.
      return;
    }

    BannerAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      size: size,
      listener: BannerAdListener(
        // Called when an ad is successfully received.
        onAdLoaded: (ad) {
          setState(() {
            _bannerAd = ad as BannerAd;
            _isLoaded = true;
          });
        },
        // Called when an ad request failed.
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
        },
        // Called when an ad opens an overlay that covers the screen.
        onAdOpened: (Ad ad) {},
        // Called when an ad removes an overlay that covers the screen.
        onAdClosed: (Ad ad) {},
        // Called when an impression occurs on the ad.
        onAdImpression: (Ad ad) {},
      ),
    ).load();
  }

  /// Initialize the Mobile Ads SDK if the SDK has gathered consent aligned with
  /// the app's configured messages.
  void _initializeMobileAdsSDK() async {
    if (_isMobileAdsInitializeCalled) {
      return;
    }

    if (await consentManager.canRequestAds()) {
      _isMobileAdsInitializeCalled = true;

      // Initialize the Mobile Ads SDK.
      MobileAds.instance.initialize();

      // Load an ad.
      _loadAd();
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }
}
