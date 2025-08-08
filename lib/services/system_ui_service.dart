import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Service to handle system UI configuration for edge-to-edge display
/// Replaces deprecated Window.setStatusBarColor and related APIs
class SystemUIService {
  static SystemUIService? _instance;
  static SystemUIService get instance => _instance ??= SystemUIService._();
  
  SystemUIService._();

  /// Configure system UI for edge-to-edge display without deprecated APIs
  void configureSystemUI({
    required bool isDarkMode,
    Color? statusBarColor,
    Color? navigationBarColor,
  }) {
    if (Platform.isAndroid) {
      // Use the modern SystemChrome API instead of deprecated Window methods
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
          // Status bar configuration
          statusBarColor: Colors.transparent, // Always transparent for edge-to-edge
          statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
          
          // Navigation bar configuration  
          systemNavigationBarColor: Colors.transparent, // Always transparent for edge-to-edge
          systemNavigationBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
          systemNavigationBarDividerColor: Colors.transparent, // Remove divider
          
          // Enforce edge-to-edge display
          systemNavigationBarContrastEnforced: false,
        ),
      );
      
      // Enable edge-to-edge mode
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
      );
    }
  }

  /// Configure system UI based on theme mode
  void configureForTheme(ThemeMode themeMode, BuildContext context) {
    final isDarkMode = themeMode == ThemeMode.dark || 
        (themeMode == ThemeMode.system && 
         MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    
    configureSystemUI(isDarkMode: isDarkMode);
  }

  /// Configure system UI for light theme
  void configureForLightTheme() {
    configureSystemUI(isDarkMode: false);
  }

  /// Configure system UI for dark theme
  void configureForDarkTheme() {
    configureSystemUI(isDarkMode: true);
  }

  /// Configure system UI for splash screen or specific screens
  void configureForScreen({
    required bool isDarkMode,
    bool hideStatusBar = false,
    bool hideNavigationBar = false,
  }) {
    if (Platform.isAndroid) {
      if (hideStatusBar || hideNavigationBar) {
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.immersive,
        );
      } else {
        configureSystemUI(isDarkMode: isDarkMode);
      }
    }
  }

  /// Reset system UI to edge-to-edge mode
  void resetToEdgeToEdge() {
    if (Platform.isAndroid) {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
      );
    }
  }

  /// Lock app to portrait orientation to prevent overflow issues
  Future<void> lockToPortrait() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  /// Allow all orientations (if needed for specific screens)
  Future<void> allowAllOrientations() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  /// Force portrait up only (strictest option)
  Future<void> forcePortraitUp() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }
}
