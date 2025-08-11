import 'dart:async';
import 'package:flutter/material.dart';
import 'package:secure_money_management/services/lazy_initialization_service.dart';
import 'package:secure_money_management/services/system_ui_service.dart';
import '../main.dart' show HomeScreen;

/// Splash Screen with proper initialization and branding
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  String _loadingText = 'Initializing SecureMoney...';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
    ));

    _animationController.forward();
  }

  Future<void> _initializeApp() async {
    try {
      // Simplified initialization - just perform basic setup
      await _performInitialization();
      
      if (mounted) {
        _navigateToHome();
      }
    } catch (e) {
      debugPrint('App initialization error: $e');
      // For now, just proceed to home screen even if initialization fails
      // This prevents the app from getting stuck on splash screen
      if (mounted) {
        _navigateToHome();
      }
    }
  }

  Future<void> _performInitialization() async {
    // Configure system UI for splash screen
    try {
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;
      SystemUIService.instance.configureSystemUI(isDarkMode: isDarkMode);
    } catch (e) {
      debugPrint('System UI configuration error: $e');
      // Continue even if system UI config fails
    }
    
    // Step 1: Basic app initialization
    _updateLoadingText('⚙️ Loading configuration...');
    await Future.delayed(const Duration(milliseconds: 500));

    // Step 2: Setting up features
    _updateLoadingText('📱 Setting up features...');
    await Future.delayed(const Duration(milliseconds: 500));

    // Step 3: Final preparation
    _updateLoadingText('🚀 Almost ready...');
    await Future.delayed(const Duration(milliseconds: 500));

    // Wait for animation to complete
    await _animationController.forward();
  }

  void _updateLoadingText(String text) {
    if (mounted) {
      setState(() {
        _loadingText = text;
      });
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
    
    // Initialize services in the background after navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeServicesInBackground();
    });
  }
  
  Future<void> _initializeServicesInBackground() async {
    try {
      // Initialize services lazily after the home screen is shown
      // This is optional and shouldn't block the app if it fails
      await LazyInitializationService.instance.initializeLazily();
      debugPrint('✅ Background services initialized successfully');
    } catch (e) {
      debugPrint('⚠️ Background initialization error (non-critical): $e');
      // Don't block the UI for background initialization failures
      // The app can function without these services
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4CAF50), // Your app's green color
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4CAF50), // Primary green
              Color(0xFF2E7D32), // Darker green
            ],
          ),
        ),
        // Use full screen for edge-to-edge, but add padding for safe areas
        child: Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top,
            bottom: MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo/Icon
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet,
                          size: 60,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 30),
              
              // App Name
              FadeTransition(
                opacity: _fadeAnimation,
                child: const Text(
                  'SecureMoney',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // App Tagline
              FadeTransition(
                opacity: _fadeAnimation,
                child: const Text(
                  'Personal Finance Manager',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
              
              const SizedBox(height: 60),
              
              // Loading Indicator (always show, no error state)
              const SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 20),
              
              // Loading Text
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  _loadingText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Security Badge
              FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.security,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Bank-Grade Security',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
