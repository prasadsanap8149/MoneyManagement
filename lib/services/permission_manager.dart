import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class PermissionManager {
  static final PermissionManager _instance = PermissionManager._internal();
  factory PermissionManager() => _instance;
  PermissionManager._internal();

  static const String _permissionDeniedKey = 'permission_denied_count';
  static const String _permissionLastAskedKey = 'permission_last_asked';
  static const int _maxDenialCount = 2;
  static const int _cooldownHours = 24;

  /// Check if we should request permission again
  Future<bool> shouldRequestPermission() async {
    final prefs = await SharedPreferences.getInstance();
    final deniedCount = prefs.getInt(_permissionDeniedKey) ?? 0;
    final lastAskedTime = prefs.getInt(_permissionLastAskedKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // If denied too many times, check cooldown period
    if (deniedCount >= _maxDenialCount) {
      final hoursSinceLastAsked = (now - lastAskedTime) / (1000 * 60 * 60);
      return hoursSinceLastAsked >= _cooldownHours;
    }
    
    return true;
  }

  /// Record permission denial
  Future<void> recordPermissionDenial() async {
    final prefs = await SharedPreferences.getInstance();
    final deniedCount = prefs.getInt(_permissionDeniedKey) ?? 0;
    await prefs.setInt(_permissionDeniedKey, deniedCount + 1);
    await prefs.setInt(_permissionLastAskedKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Reset permission denial count
  Future<void> resetPermissionDenials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_permissionDeniedKey);
    await prefs.remove(_permissionLastAskedKey);
  }

  /// Check if storage permission is granted
  Future<bool> isStoragePermissionGranted() async {
    if (!Platform.isAndroid) return true;

    try {
      if (await _isAndroid13OrHigher()) {
        // Check media permissions for Android 13+
        final permissions = [Permission.photos, Permission.videos, Permission.audio];
        for (var permission in permissions) {
          if (await permission.isGranted) return true;
        }
        return false;
      } else {
        // Check legacy permissions
        final manageStorage = await Permission.manageExternalStorage.isGranted;
        if (manageStorage) return true;
        
        final storage = await Permission.storage.isGranted;
        return storage;
      }
    } catch (e) {
      debugPrint('Error checking storage permission: $e');
      return false;
    }
  }

  /// Request storage permission with proper UX
  Future<PermissionResult> requestStoragePermission(BuildContext context) async {
    if (!Platform.isAndroid) return PermissionResult.granted;

    // Check if already granted
    if (await isStoragePermissionGranted()) {
      return PermissionResult.granted;
    }

    // Check if we should request permission
    if (!await shouldRequestPermission()) {
      return PermissionResult.cooldown;
    }

    // Show explanation dialog first
    final shouldRequest = await _showPermissionExplanationDialog(context);
    if (!shouldRequest) {
      await recordPermissionDenial();
      return PermissionResult.denied;
    }

    // Request actual permission
    final granted = await _requestActualPermission();
    
    if (granted) {
      await resetPermissionDenials();
      return PermissionResult.granted;
    } else {
      await recordPermissionDenial();
      
      // Check if permanently denied
      if (await _isPermissionPermanentlyDenied()) {
        return PermissionResult.permanentlyDenied;
      }
      
      return PermissionResult.denied;
    }
  }

  /// Request permission with proper error handling
  Future<bool> _requestActualPermission() async {
    try {
      if (await _isAndroid13OrHigher()) {
        return await _requestAndroid13Permissions();
      } else {
        return await _requestLegacyPermissions();
      }
    } catch (e) {
      debugPrint('Error requesting permission: $e');
      return false;
    }
  }

  /// Check if running Android 13 or higher
  Future<bool> _isAndroid13OrHigher() async {
    try {
      // Simple check: if photos permission is available, we're on Android 13+
      final status = await Permission.photos.status;
      return status != PermissionStatus.denied || 
             await Permission.photos.isPermanentlyDenied;
    } catch (e) {
      return false;
    }
  }

  /// Request Android 13+ permissions
  Future<bool> _requestAndroid13Permissions() async {
    final permissions = [Permission.photos, Permission.videos, Permission.audio];
    
    for (var permission in permissions) {
      try {
        final status = await permission.request();
        if (status.isGranted) return true;
      } catch (e) {
        debugPrint('Error requesting $permission: $e');
      }
    }
    return false;
  }

  /// Request legacy Android permissions
  Future<bool> _requestLegacyPermissions() async {
    try {
      // Try MANAGE_EXTERNAL_STORAGE first
      var status = await Permission.manageExternalStorage.request();
      if (status.isGranted) return true;

      // Fall back to storage permission
      status = await Permission.storage.request();
      return status.isGranted;
    } catch (e) {
      debugPrint('Error requesting legacy permissions: $e');
      return false;
    }
  }

  /// Check if permission is permanently denied
  Future<bool> _isPermissionPermanentlyDenied() async {
    try {
      if (await _isAndroid13OrHigher()) {
        final permissions = [Permission.photos, Permission.videos, Permission.audio];
        for (var permission in permissions) {
          if (await permission.isPermanentlyDenied) return true;
        }
        return false;
      } else {
        final manageStorage = await Permission.manageExternalStorage.isPermanentlyDenied;
        final storage = await Permission.storage.isPermanentlyDenied;
        return manageStorage || storage;
      }
    } catch (e) {
      return false;
    }
  }

  /// Show permission explanation dialog
  Future<bool> _showPermissionExplanationDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Storage Permission Needed'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This app needs storage access to:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text('• Export transaction data as CSV, PDF, or Excel files'),
              Text('• Import transaction data from files'),
              Text('• Share transaction reports'),
              SizedBox(height: 16),
              Text(
                'Your data remains private and secure on your device.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Not Now'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Grant Permission'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  /// Show settings dialog for permanently denied permissions
  Future<void> showSettingsDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permission Required'),
          content: const Text(
            'Storage permission is required to export and import files. '
            'Please enable it in app settings to use these features.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  /// Show cooldown dialog
  Future<void> showCooldownDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permission Temporarily Disabled'),
          content: const Text(
            'Permission request is temporarily disabled. '
            'You can manually enable storage permission in app settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  /// Handle permission result with appropriate UI feedback
  Future<bool> handlePermissionResult(
    BuildContext context, 
    PermissionResult result,
    {String? feature}
  ) async {
    final featureText = feature ?? 'this feature';
    
    switch (result) {
      case PermissionResult.granted:
        return true;
        
      case PermissionResult.denied:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Storage permission is required to use $featureText'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () async {
                final newResult = await requestStoragePermission(context);
                await handlePermissionResult(context, newResult, feature: feature);
              },
            ),
          ),
        );
        return false;
        
      case PermissionResult.permanentlyDenied:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Storage permission is required to use $featureText'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => showSettingsDialog(context),
            ),
          ),
        );
        return false;
        
      case PermissionResult.cooldown:
        await showCooldownDialog(context);
        return false;
    }
  }
}

enum PermissionResult {
  granted,
  denied,
  permanentlyDenied,
  cooldown,
}
