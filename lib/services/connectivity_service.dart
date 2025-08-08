import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Service to check internet connectivity
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  List<ConnectivityResult> _connectionStatus = [ConnectivityResult.none];

  /// Initialize connectivity service
  void initialize() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> result) {
      _connectionStatus = result;
      if (kDebugMode) {
        print('🌐 Connectivity changed: $result');
      }
    });
  }

  /// Check if device has internet connection
  Future<bool> hasInternetConnection() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      
      // Check if any connection is available (not none)
      bool hasConnection = connectivityResult.any((result) => 
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet ||
        result == ConnectivityResult.vpn
      );
      
      if (kDebugMode) {
        print('🌐 Internet connection check: $hasConnection (Results: $connectivityResult)');
      }
      
      return hasConnection;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking connectivity: $e');
      }
      return false;
    }
  }

  /// Get current connection status
  List<ConnectivityResult> get connectionStatus => _connectionStatus;

  /// Check if currently connected
  bool get isConnected => _connectionStatus.any((result) => 
    result == ConnectivityResult.mobile ||
    result == ConnectivityResult.wifi ||
    result == ConnectivityResult.ethernet ||
    result == ConnectivityResult.vpn
  );

  /// Get connection type string for display
  String get connectionTypeString {
    if (_connectionStatus.contains(ConnectivityResult.wifi)) {
      return 'WiFi';
    } else if (_connectionStatus.contains(ConnectivityResult.mobile)) {
      return 'Mobile';
    } else if (_connectionStatus.contains(ConnectivityResult.ethernet)) {
      return 'Ethernet';
    } else if (_connectionStatus.contains(ConnectivityResult.vpn)) {
      return 'VPN';
    } else {
      return 'No Connection';
    }
  }

  /// Dispose of connectivity service
  void dispose() {
    _connectivitySubscription?.cancel();
  }
}
