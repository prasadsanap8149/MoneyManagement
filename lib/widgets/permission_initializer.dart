import 'package:flutter/material.dart';
import 'package:secure_money_management/services/app_permission_handler.dart';
import 'package:secure_money_management/utils/user_experience_helper.dart';
import 'package:secure_money_management/utils/app_settings_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionInitializer extends StatefulWidget {
  final Widget child;
  
  const PermissionInitializer({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<PermissionInitializer> createState() => _PermissionInitializerState();
}

class _PermissionInitializerState extends State<PermissionInitializer> {
  bool _isInitialized = false;
  bool _permissionGranted = false;
  bool _permissionPermanentlyDenied = false;
  int _denialCount = 0;
  
  @override
  void initState() {
    super.initState();
    _initializePermissions();
  }
  
  Future<void> _initializePermissions() async {
    try {
      // Load previous denial count
      final prefs = await SharedPreferences.getInstance();
      _denialCount = prefs.getInt('permission_denial_count') ?? 0;
      
      // Check if permission is already granted
      if (await AppPermissionHandler().checkStoragePermission()) {
        setState(() {
          _permissionGranted = true;
          _isInitialized = true;
        });
        return;
      }
      
      // If denied multiple times, show rationale first
      if (_denialCount > 0) {
        final shouldRequestAgain = await AppSettingsHelper.showPermissionRationaleDialog(
          context,
          feature: 'import/export',
          denialCount: _denialCount,
        );
        
        if (!shouldRequestAgain) {
          setState(() {
            _permissionGranted = false;
            _isInitialized = true;
          });
          return;
        }
      }
      
      // Request storage permission
      final granted = await AppPermissionHandler().requestStoragePermission();
      
      if (!granted) {
        // Increment denial count
        _denialCount++;
        await prefs.setInt('permission_denial_count', _denialCount);
        
        // Check if permission is permanently denied
        final permissionStatus = await AppPermissionHandler().getStoragePermissionStatus();
        _permissionPermanentlyDenied = permissionStatus == PermissionStatus.permanentlyDenied;
      } else {
        // Reset denial count on success
        await prefs.remove('permission_denial_count');
        _denialCount = 0;
      }
      
      setState(() {
        _permissionGranted = granted;
        _isInitialized = true;
      });

      // Show feedback based on permission result
      if (granted) {
        UserExperienceHelper.showSuccessSnackbar(
          context,
          'Storage permission granted successfully!',
        );
      } else {
        if (_permissionPermanentlyDenied) {
          UserExperienceHelper.showWarningSnackbar(
            context,
            'Permission denied permanently. You can enable it in app settings.',
          );
        } else {
          UserExperienceHelper.showWarningSnackbar(
            context,
            'Storage permission denied. Import/export features will be limited.',
          );
        }
      }
    } catch (e) {
      setState(() {
        _permissionGranted = false;
        _isInitialized = true;
      });
      
      UserExperienceHelper.showErrorSnackbar(
        context,
        'Failed to initialize permissions: ${e.toString()}',
      );
    }
  }
  
  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 24,
          color: Colors.blue.shade600,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Initializing permissions...'),
            ],
          ),
        ),
      );
    }
    
    if (!_permissionGranted) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon and main title
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _permissionPermanentlyDenied 
                        ? Colors.red.shade50 
                        : Colors.orange.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _permissionPermanentlyDenied 
                        ? Icons.block 
                        : Icons.folder_shared,
                    size: 64,
                    color: _permissionPermanentlyDenied 
                        ? Colors.red.shade600 
                        : Colors.orange.shade600,
                  ),
                ),
                const SizedBox(height: 24),
                
                Text(
                  _permissionPermanentlyDenied
                      ? 'Permission Permanently Denied'
                      : _denialCount > 1
                          ? 'Storage Permission Still Needed'
                          : 'Storage Permission Required',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                Text(
                  _permissionPermanentlyDenied
                      ? 'You can still enable this permission manually in your device settings.'
                      : _denialCount > 1
                          ? 'This permission is essential for import/export functionality.'
                          : 'To provide the best experience, this app needs storage permission to:',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // Features list (only show if not permanently denied)
                if (!_permissionPermanentlyDenied) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Column(
                      children: [
                        _buildFeatureItem(
                          icon: Icons.file_download,
                          title: 'Export Transactions',
                          description: 'Save your data as JSON, CSV, PDF, or Excel files',
                        ),
                        const SizedBox(height: 12),
                        _buildFeatureItem(
                          icon: Icons.file_upload,
                          title: 'Import Transactions',
                          description: 'Restore your data from backup files',
                        ),
                        const SizedBox(height: 12),
                        _buildFeatureItem(
                          icon: Icons.share,
                          title: 'Share Data',
                          description: 'Share your transaction reports with others',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
                
                // Show denial warning if multiple denials
                if (_denialCount > 1 && !_permissionPermanentlyDenied) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange.shade600, size: 24),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Permission Denied Multiple Times',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You\'ve denied this permission ${_denialCount} time${_denialCount > 1 ? 's' : ''}. '
                          'If you choose "Don\'t ask again", you can still enable it in app settings.',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Action buttons
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_permissionPermanentlyDenied) ...[
                      ElevatedButton.icon(
                        onPressed: () async {
                          await AppSettingsHelper.showOpenSettingsDialog(
                            context,
                            title: 'Enable Storage Permission',
                            message: 'To use import/export features, please enable storage permission in app settings.',
                            feature: 'import/export',
                          );
                        },
                        icon: const Icon(Icons.settings),
                        label: const Text('Open App Settings'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _permissionGranted = true;
                          });
                          UserExperienceHelper.showInfoSnackbar(
                            context,
                            'You can enable permissions later in app settings to use import/export features.',
                          );
                        },
                        icon: const Icon(Icons.skip_next),
                        label: const Text('Continue without permission'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ] else ...[
                      ElevatedButton.icon(
                        onPressed: _initializePermissions,
                        icon: const Icon(Icons.security),
                        label: Text(_denialCount > 0 ? 'Try Again' : 'Grant Permission'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _permissionGranted = true;
                          });
                          UserExperienceHelper.showInfoSnackbar(
                            context,
                            'You can grant permission later in app settings to enable import/export features.',
                          );
                        },
                        icon: const Icon(Icons.skip_next),
                        label: const Text('Continue without permission'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                
                // Privacy note
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.privacy_tip, 
                        size: 16, 
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your data remains private and is only used for the features mentioned above.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return widget.child;
  }
}
