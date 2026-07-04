import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hvc_net/bloc/live_stream.dart';
import '/infrastructure/stream_repository.dart';
import 'package:hvc_net/screens/main_screen.dart';
import 'package:hvc_net/config/stream_permission_handler.dart';

class PermissionCheckPage extends StatefulWidget {
  const PermissionCheckPage({super.key});

  @override
  State<PermissionCheckPage> createState() => _PermissionCheckPageState();
}

class _PermissionCheckPageState extends State<PermissionCheckPage> {
  bool _isLoading = false;
  bool _allPermissionsGranted = false;
  Map<Permission, PermissionStatus>? _permissionStatuses;

  final Map<Permission, Map<String, dynamic>> _permissionConfig = {
    Permission.camera: {
      'icon': Icons.camera_alt,
      'title': 'Camera',
      'description': 'Required for video streaming',
      'color': Colors.blue,
      'required': true,
    },
    Permission.microphone: {
      'icon': Icons.mic,
      'title': 'Microphone',
      'description': 'Required for audio streaming',
      'color': Colors.green,
      'required': true,
    },
    Permission.location: {
      'icon': Icons.location_on,
      'title': 'Location',
      'description': 'Required for location features',
      'color': Colors.orange,
      'required': true,
    },
  };
  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() => _isLoading = true);

    try {
      bool allGranted = await StreamPermissionManager.requestAllPermissions(
        requestNotification: true,
      );

      setState(() {
        _isLoading = false;
        _allPermissionsGranted = allGranted;
        if (allGranted) {
          _startStreaming();
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error checking permissions: $e')));
    }
  }

  Future<void> _requestMissingPermissions() async {
    setState(() => _isLoading = true);

    try {
      final deniedPermissions = StreamPermissionManager.getDeniedPermissions();

      if (deniedPermissions.isEmpty) {
        setState(() => _isLoading = false);
        if (StreamPermissionManager.areAllPermissionsGranted()) {
          _startStreaming();
        }
        return;
      }

      // Request only denied permissions
      final statuses = await deniedPermissions.request();

      setState(() {
        _permissionStatuses ??= {};
        _permissionStatuses!.addAll(statuses);
        _isLoading = false;
        _allPermissionsGranted =
            StreamPermissionManager.areAllPermissionsGranted();
      });

      if (_allPermissionsGranted) {
        _startStreaming();
      } else {
        _showPermissionDialog();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error requesting permissions: $e')),
      );
    }
  }

  void _showPermissionDialog() {
    final permanentlyDenied =
        StreamPermissionManager.getPermanentlyDeniedPermissions();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Permissions Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (permanentlyDenied.isNotEmpty) ...[
              const Text(
                'Some permissions are permanently denied. Please enable them in settings:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...permanentlyDenied.map(
                (permission) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        _permissionConfig[permission]?['icon'],
                        color: _permissionConfig[permission]?['color'],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _permissionConfig[permission]?['title'] ??
                              permission.toString(),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  openAppSettings();
                },
                icon: const Icon(Icons.settings),
                label: const Text('Open Settings'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ] else ...[
              const Text(
                'Please grant the following permissions to continue:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...StreamPermissionManager.getDeniedPermissions().map(
                (permission) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        _permissionConfig[permission]?['icon'],
                        color: _permissionConfig[permission]?['color'],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _permissionConfig[permission]?['title'] ??
                              permission.toString(),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (permanentlyDenied.isEmpty) ...[
            TextButton(
              onPressed: _requestMissingPermissions,
              child: const Text('Try Again'),
            ),
          ],
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _startStreaming() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => RepositoryProvider(
          create: (context) => StreamRepository(),
          child: BlocProvider(
            create: (context) =>
                StreamLiveBloc(context.read<StreamRepository>())
                  ..add(InitStreamSetupEvent()),
            child: const TikTokLivePage(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.pinkAccent),
                  SizedBox(height: 20),
                  Text(
                    'Checking permissions...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            )
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    const Text(
                      'Welcome to HVC.NET',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please grant permissions to start streaming',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                    ..._permissionConfig.entries.map((entry) {
                      final permission = entry.key;
                      final config = entry.value;
                      final isGranted =
                          _permissionStatuses?[permission]?.isGranted ?? false;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isGranted
                                ? Colors.green
                                : Colors.grey.shade800,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: isGranted
                              ? Colors.green.withValues(alpha: 0.1)
                              : null,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: (config['color'] as Color).withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                config['icon'],
                                color: config['color'],
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        config['title'],
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      if (config['required'] == true)
                                        const Text(
                                          '*',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontSize: 16,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    config['description'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isGranted)
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 24,
                              )
                            else
                              const Icon(
                                Icons.pending,
                                color: Colors.grey,
                                size: 24,
                              ),
                          ],
                        ),
                      );
                    }),
                    const Spacer(),
                    if (_allPermissionsGranted)
                      ElevatedButton(
                        onPressed: _startStreaming,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 54),
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Continue to Stream',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      )
                    else
                      ElevatedButton(
                        onPressed: _requestMissingPermissions,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 54),
                          backgroundColor: Colors.pinkAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Grant Permissions',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}
