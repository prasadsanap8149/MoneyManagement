import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:secure_money_management/utils/user_experience_helper.dart';

/// Updated file operations service that uses SAF (Storage Access Framework) 
/// for Android 11+ without requiring storage permissions
class FileOperationsService {
  static final FileOperationsService _instance = FileOperationsService._internal();
  factory FileOperationsService() => _instance;
  FileOperationsService._internal();

  /// Check if we're running on Android 11+ (API 30+)
  Future<bool> _isAndroid11OrHigher() async {
    if (!Platform.isAndroid) return false;
    
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.version.sdkInt >= 30; // Android 11 is API 30
    } catch (e) {
      debugPrint('Error checking Android version: $e');
      return false;
    }
  }

  /// Export file using SAF-compatible approach (no permissions needed for Android 11+)
  Future<bool> exportFile(
    BuildContext context, {
    required String content,
    required String filename,
    required String mimeType,
    String? feature,
  }) async {
    try {
      // Create file in app's private directory
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$filename');
      await file.writeAsString(content);

      // Share file using system share dialog - this works without permissions
      await Share.shareXFiles(
        [XFile(file.path)], 
        text: 'Exported from SecureMoney',
        subject: filename,
      );

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

  /// Export binary file using SAF-compatible approach
  Future<bool> exportBinaryFile(
    BuildContext context, {
    required List<int> bytes,
    required String filename,
    required String mimeType,
    String? feature,
  }) async {
    try {
      // Create file in app's private directory
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$filename');
      await file.writeAsBytes(bytes);

      // Share file using system share dialog
      await Share.shareXFiles(
        [XFile(file.path)], 
        text: 'Exported from SecureMoney',
        subject: filename,
      );

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

  /// Import file using SAF (Storage Access Framework) - no permissions needed
  Future<String?> importFile(
    BuildContext context, {
    List<String>? allowedExtensions,
    String? feature,
  }) async {
    try {
      // FilePicker automatically uses SAF on Android 11+ without permissions
      final result = await FilePicker.platform.pickFiles(
        type: allowedExtensions != null ? FileType.custom : FileType.any,
        allowedExtensions: allowedExtensions,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final file = result.files.first;
      
      // On Android 11+, prefer file.bytes if path is null (SAF behavior)
      if (file.bytes != null) {
        return String.fromCharCodes(file.bytes!);
      } else if (file.path != null) {
        final fileData = File(file.path!);
        return await fileData.readAsString();
      } else {
        throw Exception('Unable to read file data');
      }
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

  /// Check if file operations are available (always true with SAF)
  Future<bool> isFileOperationsAvailable() async {
    // SAF is always available on Android and doesn't require permissions
    return true;
  }

  /// Show information about file access capabilities
  Future<void> showFileOperationsInfo(BuildContext context) async {
    final isAndroid11Plus = await _isAndroid11OrHigher();
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('File Operations'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This app can help you:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const Text('• Export transaction data as CSV, PDF, Excel, or JSON files'),
            const Text('• Import transaction data from supported file formats'),
            const Text('• Share financial reports with other apps'),
            const SizedBox(height: 16),
            Text(
              isAndroid11Plus 
                ? 'Using modern Storage Access Framework (no storage permissions required)'
                : 'File operations are fully supported on this device',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your data remains private and secure on your device.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  /// Show feature unavailable dialog (deprecated - kept for compatibility)
  @deprecated
  Future<void> showFeatureUnavailableDialog(
    BuildContext context, {
    required String feature,
  }) async {
    // Since SAF doesn't require permissions, this should rarely be called
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Feature Information'),
        content: Text(
          '$feature is available on this device. If you\'re experiencing issues, '
          'please try again or restart the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
