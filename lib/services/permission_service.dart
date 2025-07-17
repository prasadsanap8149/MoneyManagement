import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Checks and requests a single permission
  static Future<bool> checkAndRequestPermission(Permission permission) async {
    var status = await Permission.manageExternalStorage.request();

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied || status.isLimited || status.isRestricted) {
      status = await permission.request();
      return status.isGranted;
    }

    if (status.isPermanentlyDenied) {
      await openAppSettings(); // Guide user to settings
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
    final message =
        '${permission.toString().split(".").last} permission: ${status.toString().split(".").last}';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
