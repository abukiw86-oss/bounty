import 'package:flutter/material.dart';
import '/screens/live_discovery_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
    return LiveDiscoveryPage();
  }
}
