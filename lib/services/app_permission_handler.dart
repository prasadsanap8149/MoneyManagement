import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class AppPermissionHandler {
  static final AppPermissionHandler _instance = AppPermissionHandler._internal();
  factory AppPermissionHandler() => _instance;
  AppPermissionHandler._internal();

  bool _permissionsInitialized = false;
  bool _storagePermissionGranted = false;

  bool get permissionsInitialized => _permissionsInitialized;
  bool get storagePermissionGranted => _storagePermissionGranted;

  /// Initialize all required permissions when app starts
  Future<void> initializePermissions() async {
    if (_permissionsInitialized) return;

    try {
      // Request storage permissions
      _storagePermissionGranted = await _requestStoragePermissions();
      
      _permissionsInitialized = true;
    } catch (e) {
      debugPrint('Error initializing permissions: $e');
      _permissionsInitialized = true; // Set to true to prevent infinite loading
    }
  }

  /// Request storage permissions based on Android version
  Future<bool> _requestStoragePermissions() async {
    if (!Platform.isAndroid) {
      return true; // iOS doesn't need explicit storage permission for app documents
    }

    try {
      // Check Android version to determine which permissions to request
      if (await _isAndroid13OrHigher()) {
        return await _requestAndroid13StoragePermissions();
      } else {
        return await _requestLegacyStoragePermissions();
      }
    } catch (e) {
      debugPrint('Error requesting storage permissions: $e');
      return false;
    }
  }

  /// Check if device is running Android 13 or higher
  Future<bool> _isAndroid13OrHigher() async {
    try {
      // Use a simple approach to check Android version
      // In production, you might want to use device_info_plus for more accurate detection
      final status = await Permission.photos.status;
      // If photos permission exists and is not denied, we're likely on Android 13+
      return status != PermissionStatus.denied;
    } catch (e) {
      // If there's an error, assume older Android version
      return false;
    }
  }

  /// Request storage permissions for Android 13+
  Future<bool> _requestAndroid13StoragePermissions() async {
    final permissions = [
      Permission.photos,
      Permission.videos,
      Permission.audio,
    ];

    bool hasAnyPermission = false;
    
    for (var permission in permissions) {
      try {
        final status = await permission.status;
        if (status.isGranted) {
          hasAnyPermission = true;
          continue;
        }
        
        if (status.isDenied) {
          final result = await permission.request();
          if (result.isGranted) {
            hasAnyPermission = true;
          }
        }
      } catch (e) {
        debugPrint('Error requesting permission $permission: $e');
      }
    }

    return hasAnyPermission;
  }

  /// Request storage permissions for Android 12 and below
  Future<bool> _requestLegacyStoragePermissions() async {
    try {
      // Try MANAGE_EXTERNAL_STORAGE first (for Android 11+)
      var manageStorageStatus = await Permission.manageExternalStorage.status;
      if (manageStorageStatus.isDenied) {
        manageStorageStatus = await Permission.manageExternalStorage.request();
      }

      if (manageStorageStatus.isGranted) {
        return true;
      }

      // Fall back to regular storage permission
      var storageStatus = await Permission.storage.status;
      if (storageStatus.isDenied) {
        storageStatus = await Permission.storage.request();
      }

      return storageStatus.isGranted;
    } catch (e) {
      debugPrint('Error requesting legacy storage permissions: $e');
      return false;
    }
  }

  /// Check if storage permission is currently granted
  Future<bool> checkStoragePermission() async {
    if (!Platform.isAndroid) return true;

    try {
      if (await _isAndroid13OrHigher()) {
        // Check if any media permission is granted
        final permissions = [Permission.photos, Permission.videos, Permission.audio];
        for (var permission in permissions) {
          if (await permission.status.isGranted) {
            return true;
          }
        }
        return false;
      } else {
        // Check legacy permissions
        final manageStorage = await Permission.manageExternalStorage.status;
        if (manageStorage.isGranted) return true;
        
        final storage = await Permission.storage.status;
        return storage.isGranted;
      }
    } catch (e) {
      debugPrint('Error checking storage permission: $e');
      return false;
    }
  }

  /// Request storage permission if not already granted
  Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid) return true;
    
    final isGranted = await checkStoragePermission();
    if (isGranted) return true;
    
    return await _requestStoragePermissions();
  }

  /// Show permission dialog to user
  Future<bool> showPermissionDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permission Required'),
          content: const Text(
            'This app needs storage permission to import/export transaction data. '
            'Please grant the permission to use all features.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Grant Permission'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  /// Show settings dialog when permission is permanently denied
  Future<void> showSettingsDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permission Denied'),
          content: const Text(
            'Storage permission is required for importing and exporting files. '
            'Please enable it in app settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
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

  /// Get storage permission status
  Future<PermissionStatus> getStoragePermissionStatus() async {
    if (!Platform.isAndroid) return PermissionStatus.granted;

    try {
      if (await _isAndroid13OrHigher()) {
        // Check media permissions for Android 13+
        final permissions = [Permission.photos, Permission.videos, Permission.audio];
        for (var permission in permissions) {
          final status = await permission.status;
          if (status.isGranted) return PermissionStatus.granted;
          if (status.isPermanentlyDenied) return PermissionStatus.permanentlyDenied;
        }
        return PermissionStatus.denied;
      } else {
        // Check legacy permissions
        final manageStorage = await Permission.manageExternalStorage.status;
        if (manageStorage.isGranted) return PermissionStatus.granted;
        if (manageStorage.isPermanentlyDenied) return PermissionStatus.permanentlyDenied;
        
        final storage = await Permission.storage.status;
        return storage;
      }
    } catch (e) {
      debugPrint('Error getting storage permission status: $e');
      return PermissionStatus.denied;
    }
  }
}
