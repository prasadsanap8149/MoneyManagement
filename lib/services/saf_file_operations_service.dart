import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:secure_money_management/utils/user_experience_helper.dart';

/// File operations service that uses SAF (Storage Access Framework) for Android 11+
/// and legacy methods for older Android versions.
/// This eliminates the need for storage permissions on modern Android versions.
class SafFileOperationsService {
  static final SafFileOperationsService _instance = SafFileOperationsService._internal();
  factory SafFileOperationsService() => _instance;
  SafFileOperationsService._internal();

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

  /// Export file using SAF for Android 11+ or legacy methods for older versions
  Future<bool> exportFile(
    BuildContext context, {
    required String content,
    required String filename,
    required String mimeType,
    String? feature,
  }) async {
    try {
      final isAndroid11Plus = await _isAndroid11OrHigher();
      
      if (isAndroid11Plus) {
        return await _exportFileUsingSAF(context, content, filename, mimeType);
      } else {
        return await _exportFileLegacy(context, content, filename, mimeType);
      }
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

  /// Export binary file using SAF for Android 11+ or legacy methods for older versions
  Future<bool> exportBinaryFile(
    BuildContext context, {
    required Uint8List bytes,
    required String filename,
    required String mimeType,
    String? feature,
  }) async {
    try {
      final isAndroid11Plus = await _isAndroid11OrHigher();
      
      if (isAndroid11Plus) {
        return await _exportBinaryFileUsingSAF(context, bytes, filename, mimeType);
      } else {
        return await _exportBinaryFileLegacy(context, bytes, filename, mimeType);
      }
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

  /// Import file using SAF for Android 11+ or legacy methods for older versions
  Future<String?> importFile(
    BuildContext context, {
    List<String>? allowedExtensions,
    String? feature,
  }) async {
    try {
      // FilePicker already uses SAF on Android 11+ automatically
      final result = await FilePicker.platform.pickFiles(
        type: allowedExtensions != null ? FileType.custom : FileType.any,
        allowedExtensions: allowedExtensions,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final file = result.files.first;
      
      // On Android 11+, file.path might be null, so we use file.bytes instead
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

  /// Import binary file using file picker
  Future<Uint8List?> importBinaryFile(
    BuildContext context, {
    List<String>? allowedExtensions,
    String? feature,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: allowedExtensions != null ? FileType.custom : FileType.any,
        allowedExtensions: allowedExtensions,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final file = result.files.first;
      
      // On Android 11+, prefer file.bytes over file.path
      if (file.bytes != null) {
        return file.bytes;
      } else if (file.path != null) {
        final fileData = File(file.path!);
        return await fileData.readAsBytes();
      } else {
        throw Exception('Unable to read file data');
      }
    } catch (e) {
      debugPrint('Error importing binary file: $e');
      if (context.mounted) {
        UserExperienceHelper.showErrorSnackbar(
          context,
          'Failed to import file: ${e.toString()}',
        );
      }
      return null;
    }
  }

  /// Export file using SAF (Android 11+)
  Future<bool> _exportFileUsingSAF(
    BuildContext context,
    String content,
    String filename,
    String mimeType,
  ) async {
    // For Android 11+, we create the file in app directory and share it
    // This avoids requesting storage permissions
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$filename');
    await file.writeAsString(content);

    // Share the file using system share dialog
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Exported from SecureMoney',
      subject: filename,
    );

    return true;
  }

  /// Export binary file using SAF (Android 11+)
  Future<bool> _exportBinaryFileUsingSAF(
    BuildContext context,
    Uint8List bytes,
    String filename,
    String mimeType,
  ) async {
    // For Android 11+, we create the file in app directory and share it
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$filename');
    await file.writeAsBytes(bytes);

    // Share the file using system share dialog
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Exported from SecureMoney',
      subject: filename,
    );

    return true;
  }

  /// Export file using legacy method (Android 10 and below)
  Future<bool> _exportFileLegacy(
    BuildContext context,
    String content,
    String filename,
    String mimeType,
  ) async {
    // For legacy Android, we'd need storage permission
    // But for now, we'll use the same share approach for consistency
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$filename');
    await file.writeAsString(content);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Exported from SecureMoney',
      subject: filename,
    );

    return true;
  }

  /// Export binary file using legacy method (Android 10 and below)
  Future<bool> _exportBinaryFileLegacy(
    BuildContext context,
    Uint8List bytes,
    String filename,
    String mimeType,
  ) async {
    // For legacy Android, we'd need storage permission
    // But for now, we'll use the same share approach for consistency
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$filename');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Exported from SecureMoney',
      subject: filename,
    );

    return true;
  }

  /// Check if file operations are available (always true with SAF)
  Future<bool> isFileOperationsAvailable() async {
    return true; // SAF is always available, no permissions needed
  }

  /// Show information about file operations
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
            const Text('This app can:'),
            const SizedBox(height: 8),
            const Text('• Export data as CSV, PDF, Excel, or JSON files'),
            const Text('• Import transaction data from files'),
            const Text('• Share reports with other apps'),
            const SizedBox(height: 16),
            Text(
              isAndroid11Plus 
                ? 'Using modern Storage Access Framework (no permissions required)'
                : 'Using traditional file access',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
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
