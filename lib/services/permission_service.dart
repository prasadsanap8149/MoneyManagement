import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class PermissionService {
  /// Checks and requests a single permission
  static Future<bool> checkAndRequestPermission(Permission permission) async {
    var status = await permission.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied || status.isLimited || status.isRestricted) {
      status = await permission.request();
      return status.isGranted;
    }

    if (status.isPermanentlyDenied) {
      await openAppSettings(); // Guide user to settings
      return false;
    }

    return false;
  }

  /// Requests storage permission based on Android version
  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      // For Android 13+ (API 33+), use granular permissions
      if (await _isAndroid13OrHigher()) {
        return await _requestAndroid13StoragePermission();
      } else {
        // For Android 12 and below
        return await _requestLegacyStoragePermission();
      }
    }
    return true; // iOS doesn't need explicit storage permission for app documents
  }

  /// Check if device is running Android 13 or higher
  static Future<bool> _isAndroid13OrHigher() async {
    try {
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.version.sdkInt >= 33; // Android 13 is API level 33
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Request storage permission for Android 13+
  static Future<bool> _requestAndroid13StoragePermission() async {
    // For Android 13+, we'll primarily use Storage Access Framework (SAF)
    // for document access, which doesn't require specific media permissions
    // This method will mainly handle the storage permission for backward compatibility
    try {
      // Check if we can access external storage for documents
      final storageStatus = await Permission.storage.status;
      if (storageStatus.isDenied) {
        final result = await Permission.storage.request();
        return result.isGranted;
      }
      return storageStatus.isGranted;
    } catch (e) {
      debugPrint('Error requesting Android 13+ storage permission: $e');
      return false;
    }
  }

  /// Request storage permission for Android 12 and below
  static Future<bool> _requestLegacyStoragePermission() async {
    // Try MANAGE_EXTERNAL_STORAGE first (for Android 11+)
    var manageStorageStatus = await Permission.manageExternalStorage.status;
    if (manageStorageStatus.isDenied) {
      manageStorageStatus = await Permission.manageExternalStorage.request();
    }

    if (manageStorageStatus.isGranted) {
      return true;
    }

    // Fall back to regular storage permissions
    final storagePermissions = [
      Permission.storage,
    ];

    for (var permission in storagePermissions) {
      final status = await permission.request();
      if (status.isGranted) {
        return true;
      }
    }

    return false;
  }

  /// Checks and requests multiple permissions at once
  static Future<Map<Permission, PermissionStatus>> checkAndRequestMultiple(
      List<Permission> permissions) async {
    Map<Permission, PermissionStatus> statuses = {};

    for (var permission in permissions) {
      final result = await permission.request();
      statuses[permission] = result;
    }

    return statuses;
  }

  /// Helper for displaying permission status in a snackbar
  static void showPermissionStatusSnackbar(
      BuildContext context, Permission permission, PermissionStatus status) {
    final permissionName = permission.toString().split('.').last;
    final statusName = status.toString().split('.').last;
    final message = '$permissionName permission: $statusName';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: status.isGranted ? Colors.green : Colors.red,
      ),
    );
  }

  /// Check if storage permission is granted
  static Future<bool> isStoragePermissionGranted() async {
    if (Platform.isAndroid) {
      if (await _isAndroid13OrHigher()) {
        // For Android 13+, check basic storage permission
        // Document access will be handled via Storage Access Framework (SAF)
        final storage = await Permission.storage.status;
        return storage.isGranted;
      } else {
        // Check legacy permissions
        final manageStorage = await Permission.manageExternalStorage.status;
        if (manageStorage.isGranted) {
          return true;
        }
        
        final storage = await Permission.storage.status;
        return storage.isGranted;
      }
    }
    return true; // iOS doesn't need explicit storage permission for app documents
  }
}
