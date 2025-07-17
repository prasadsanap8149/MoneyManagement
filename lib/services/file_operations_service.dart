import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:money_management/services/permission_manager.dart';
import 'package:money_management/utils/user_experience_helper.dart';

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

      // Show success message - handled by the calling function
      // UserExperienceHelper.showSuccessSnackbar(
      //   context,
      //   '$filename exported successfully',
      // );

      return true;
    } catch (e) {
      debugPrint('Error exporting file: $e');
      if (context.mounted) {
        UserExperienceHelper.showErrorSnackbar(
          context,
          'Failed to export file: ${e.toString()}',
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

      // Show success message - handled by the calling function
      // UserExperienceHelper.showSuccessSnackbar(
      //   context,
      //   '$filename exported successfully',
      // );

      return true;
    } catch (e) {
      debugPrint('Error exporting binary file: $e');
      if (context.mounted) {
        UserExperienceHelper.showErrorSnackbar(
          context,
          'Failed to export file: ${e.toString()}',
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

      // Show success message - handled by the calling function
      // UserExperienceHelper.showSuccessSnackbar(
      //   context,
      //   'File imported successfully',
      // );

      return content;
    } catch (e) {
      debugPrint('Error importing file: $e');
      if (context.mounted) {
        UserExperienceHelper.showErrorSnackbar(
          context,
          'Failed to import file: ${e.toString()}',
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
    await UserExperienceHelper.showFeatureUnavailableDialog(
      context,
      feature: feature,
      reason: 'Storage permission is required to use $feature. Please grant permission to access this feature.',
    );
  }
}
