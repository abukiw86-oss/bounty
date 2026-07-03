// lib/main.dart
import 'package:flutter/material.dart';
import 'package:hvc_net/screens/permission_screen/permission_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HVC.NET',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const PermissionCheckPage(),
    );
  }
}
