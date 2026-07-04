// lib/services/device_info_service.dart
import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';

class DeviceInfoService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        return await _getAndroidInfo();
      } else if (Platform.isIOS) {
        return await _getIOSInfo();
      } else if (Platform.isWindows) {
        return await _getWindowsInfo();
      } else if (Platform.isMacOS) {
        return await _getMacOSInfo();
      } else if (Platform.isLinux) {
        return await _getLinuxInfo();
      }
    } catch (e) {
      print("Error getting device info: $e");
    }

    return {
      'model': 'Unknown Device',
      'os': Platform.operatingSystem,
      'osVersion': Platform.operatingSystemVersion,
    };
  }

  static Future<Map<String, dynamic>> _getAndroidInfo() async {
    final info = await _deviceInfo.androidInfo;
    return {
      'model': '${info.manufacturer} ${info.model}',
      'brand': info.brand,
      'device': info.device,
      'os': 'Android',
      'osVersion': info.version.release,
      'sdkVersion': info.version.sdkInt,
      'username': '${info.manufacturer} ${info.model}', // Default username
    };
  }

  static Future<Map<String, dynamic>> _getIOSInfo() async {
    final info = await _deviceInfo.iosInfo;
    return {
      'model': info.model,
      'name': info.name,
      'os': 'iOS',
      'osVersion': info.systemVersion,
      'username': info.model,
    };
  }

  static Future<Map<String, dynamic>> _getWindowsInfo() async {
    final info = await _deviceInfo.windowsInfo;
    return {
      'model': info.computerName,
      'os': 'Windows',
      'osVersion': info.releaseId,
      'username': info.computerName,
    };
  }

  static Future<Map<String, dynamic>> _getMacOSInfo() async {
    final info = await _deviceInfo.macOsInfo;
    return {
      'model': info.model,
      'os': 'macOS',
      'osVersion': info.osRelease,
      'username': info.computerName,
    };
  }

  static Future<Map<String, dynamic>> _getLinuxInfo() async {
    final info = await _deviceInfo.linuxInfo;
    return {
      'model': info.name ?? 'Linux Machine',
      'os': 'Linux',
      'osVersion': info.versionId ?? 'Unknown',
      'username': info.name ?? 'Linux User',
    };
  }

  // Generate a readable display name
  static Future<String> getDisplayName() async {
    final info = await getDeviceInfo();
    final model = info['model'] ?? 'Unknown';
    final os = info['os'] ?? '';
    final osVersion = info['osVersion'] ?? '';

    return '$model ($os $osVersion)';
  }

  // Generate a unique device ID
  static Future<String> getDeviceId() async {
    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        return 'android_${info.id}';
      } else if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        return 'ios_${info.identifierForVendor ?? info.name}';
      }
    } catch (e) {
      print("Error getting device ID: $e");
    }

    return 'device_${DateTime.now().millisecondsSinceEpoch}';
  }
}
