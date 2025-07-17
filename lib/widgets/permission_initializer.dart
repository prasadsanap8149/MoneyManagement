import 'package:flutter/material.dart';
import 'package:money_management/services/app_permission_handler.dart';

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
    } catch (e) {
      setState(() {
        _permissionGranted = false;
        _isInitialized = true;
      });
    }
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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.warning,
                size: 64,
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
              const Text(
                'Storage Permission Required',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This app needs storage permission to export and import transaction data.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _initializePermissions,
                child: const Text('Grant Permission'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  setState(() {
                    _permissionGranted = true;
                  });
                },
                child: const Text('Continue without permission'),
              ),
            ],
          ),
        ),
      );
    }
    
    return widget.child;
  }
}
