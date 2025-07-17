import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:money_management/services/permission_manager.dart';

class FileOperationsService {
  static final FileOperationsService _instance = FileOperationsService._internal();
  factory FileOperationsService() => _instance;
  FileOperationsService._internal();

  /// Export file with permission handling
  Future<bool> exportFile(
    BuildContext context, {
    required String content,
    required String filename,
    required String mimeType,
    String? feature,
  }) async {
    try {
      // Check and request permission
      final permissionResult = await PermissionManager().requestStoragePermission(context);
      final hasPermission = await PermissionManager().handlePermissionResult(
        context, 
        permissionResult, 
        feature: feature ?? 'export files'
      );
      
      if (!hasPermission) {
        return false;
      }

      // Create file
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$filename');
      await file.writeAsString(content);

      // Share file
      await Share.shareXFiles(
        [XFile(file.path)], 
        text: 'Exported from Money Management App',
        subject: filename,
      );

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$filename exported successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

      return true;
    } catch (e) {
      debugPrint('Error exporting file: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export file: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  /// Export binary file with permission handling
  Future<bool> exportBinaryFile(
    BuildContext context, {
    required List<int> bytes,
    required String filename,
    required String mimeType,
    String? feature,
  }) async {
    try {
      // Check and request permission
      final permissionResult = await PermissionManager().requestStoragePermission(context);
      final hasPermission = await PermissionManager().handlePermissionResult(
        context, 
        permissionResult, 
        feature: feature ?? 'export files'
      );
      
      if (!hasPermission) {
        return false;
      }

      // Create file
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$filename');
      await file.writeAsBytes(bytes);

      // Share file
      await Share.shareXFiles(
        [XFile(file.path)], 
        text: 'Exported from Money Management App',
        subject: filename,
      );

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$filename exported successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

      return true;
    } catch (e) {
      debugPrint('Error exporting binary file: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export file: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  /// Import file with permission handling
  Future<String?> importFile(
    BuildContext context, {
    List<String>? allowedExtensions,
    String? feature,
  }) async {
    try {
      // Check and request permission
      final permissionResult = await PermissionManager().requestStoragePermission(context);
      final hasPermission = await PermissionManager().handlePermissionResult(
        context, 
        permissionResult, 
        feature: feature ?? 'import files'
      );
      
      if (!hasPermission) {
        return null;
      }

      // Pick file
      final result = await FilePicker.platform.pickFiles(
        type: allowedExtensions != null ? FileType.custom : FileType.any,
        allowedExtensions: allowedExtensions,
      );

      if (result == null || result.files.single.path == null) {
        return null;
      }

      // Read file
      final file = File(result.files.single.path!);
      final content = await file.readAsString();

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File imported successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

      return content;
    } catch (e) {
      debugPrint('Error importing file: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to import file: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  /// Check if file operations are available
  Future<bool> isFileOperationsAvailable() async {
    return await PermissionManager().isStoragePermissionGranted();
  }

  /// Show feature unavailable dialog
  Future<void> showFeatureUnavailableDialog(
    BuildContext context, {
    required String feature,
  }) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$feature Unavailable'),
          content: Text(
            'Storage permission is required to use $feature. '
            'Please grant permission to access this feature.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final result = await PermissionManager().requestStoragePermission(context);
                await PermissionManager().handlePermissionResult(
                  context, 
                  result, 
                  feature: feature
                );
              },
              child: const Text('Grant Permission'),
            ),
          ],
        );
      },
    );
  }
}
