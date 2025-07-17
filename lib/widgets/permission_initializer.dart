import 'package:flutter/material.dart';
import 'package:money_management/services/app_permission_handler.dart';
import 'package:money_management/utils/user_experience_helper.dart';

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
  
  @override
  void initState() {
    super.initState();
    _initializePermissions();
  }
  
  Future<void> _initializePermissions() async {
    try {
      // Check if permission is already granted
      if (await AppPermissionHandler().checkStoragePermission()) {
        setState(() {
          _permissionGranted = true;
          _isInitialized = true;
        });
        return;
      }
      
      // Request storage permission
      final granted = await AppPermissionHandler().requestStoragePermission();
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
        UserExperienceHelper.showWarningSnackbar(
          context,
          'Storage permission denied. Import/export features will be limited.',
        );
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
                    color: Colors.orange.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.folder_shared,
                    size: 64,
                    color: Colors.orange.shade600,
                  ),
                ),
                const SizedBox(height: 24),
                
                const Text(
                  'Storage Permission Required',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                const Text(
                  'To provide the best experience, this app needs storage permission to:',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // Features list
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
                
                // Action buttons
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _initializePermissions,
                      icon: const Icon(Icons.security),
                      label: const Text('Grant Permission'),
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
