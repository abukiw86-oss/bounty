import 'package:flutter/material.dart';
import 'package:hvc_net/screens/permission_screen/permission_screen.dart';
import 'package:hvc_net/screens/live_discovery_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HVC.NET',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const PermissionCheckWrapper(),
    );
  }
}

class PermissionCheckWrapper extends StatelessWidget {
  const PermissionCheckWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return PermissionRequestScreen(
      onPermissionsGranted: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LiveDiscoveryPage()),
        );
      },
    );
  }
}
