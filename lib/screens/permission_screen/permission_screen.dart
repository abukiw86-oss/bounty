import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hvc_net/config/stream_permission_handler.dart';

class PermissionRequestScreen extends StatefulWidget {
  final VoidCallback onPermissionsGranted;

  const PermissionRequestScreen({Key? key, required this.onPermissionsGranted})
    : super(key: key);

  @override
  State<PermissionRequestScreen> createState() =>
      _PermissionRequestScreenState();
}

class _PermissionRequestScreenState extends State<PermissionRequestScreen> {
  bool _isLoading = false;
  Map<Permission, PermissionStatus>? _permissionStatuses;

  final Map<Permission, Map<String, dynamic>> _permissionConfig = {
    Permission.camera: {
      'icon': Icons.camera_alt,
      'title': 'Camera',
      'description': 'Required for video streaming',
      'color': Colors.blue,
    },
    Permission.microphone: {
      'icon': Icons.mic,
      'title': 'Microphone',
      'description': 'Required for audio streaming',
      'color': Colors.green,
    },
    Permission.location: {
      'icon': Icons.location_on,
      'title': 'Location',
      'description': 'Required for location-based features',
      'color': Colors.orange,
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
      final statuses = await StreamPermissionManager.requestAllPermissions();

      setState(() {
        _permissionStatuses = statuses;
        _isLoading = false;
      });
      if (StreamPermissionManager.areAllPermissionsGranted()) {
        widget.onPermissionsGranted();
      }
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
          widget.onPermissionsGranted();
        }
        return;
      }

      final newStatuses =
          await StreamPermissionManager.requestSpecificPermissions(
            deniedPermissions,
          );

      setState(() {
        if (_permissionStatuses != null) {
          _permissionStatuses!.addAll(newStatuses);
        }
        _isLoading = false;
      });

      // Check if all granted now
      if (StreamPermissionManager.areAllPermissionsGranted()) {
        widget.onPermissionsGranted();
      } else {
        _showPermissionStatusDialog();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error requesting permissions: $e')),
      );
    }
  }

  void _showPermissionStatusDialog() {
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
              ...permanentlyDenied
                  .map(
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
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
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
              ...StreamPermissionManager.getDeniedPermissions()
                  .map(
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
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ],
          ],
        ),
        actions: [
          if (permanentlyDenied.isEmpty) ...[
            TextButton(
              onPressed: () => _requestMissingPermissions(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permissions Required'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Streaming Permissions',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please grant the following permissions to start streaming',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                    ..._permissionConfig.entries.map((entry) {
                      final permission = entry.key;
                      final config = entry.value;
                      final isGranted =
                          _permissionStatuses?[permission]?.isGranted ?? false;
                      final isDenied =
                          _permissionStatuses?[permission]?.isDenied ?? false;
                      final isPermanentlyDenied =
                          _permissionStatuses?[permission]
                              ?.isPermanentlyDenied ??
                          false;

                      return PermissionTile(
                        icon: config['icon'],
                        title: config['title'],
                        description: config['description'],
                        color: config['color'],
                        status: _permissionStatuses?[permission],
                        onRetry: () => _requestMissingPermissions(),
                      );
                    }).toList(),
                    const Spacer(),
                    if (StreamPermissionManager.areAllPermissionsGranted())
                      ElevatedButton(
                        onPressed: widget.onPermissionsGranted,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 54),
                          backgroundColor: Colors.green,
                        ),
                        child: const Text(
                          'Continue to Stream',
                          style: TextStyle(fontSize: 18),
                        ),
                      )
                    else
                      ElevatedButton(
                        onPressed: _requestMissingPermissions,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 54),
                        ),
                        child: const Text(
                          'Grant Permissions',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

// Custom Permission Tile Widget
class PermissionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final PermissionStatus? status;
  final VoidCallback onRetry;

  const PermissionTile({
    Key? key,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    this.status,
    required this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isGranted = status?.isGranted ?? false;
    final isDenied = status?.isDenied ?? false;
    final isPermanentlyDenied = status?.isPermanentlyDenied ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: isGranted ? Colors.green : Colors.grey.shade300,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
        color: isGranted ? Colors.green.withOpacity(0.05) : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          if (isGranted)
            const Icon(Icons.check_circle, color: Colors.green, size: 28)
          else if (isPermanentlyDenied)
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.red),
              onPressed: () => openAppSettings(),
              tooltip: 'Open settings',
            )
          else if (isDenied)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.orange),
              onPressed: onRetry,
              tooltip: 'Request permission',
            )
          else
            const Icon(Icons.pending, color: Colors.grey, size: 28),
        ],
      ),
    );
  }
}
