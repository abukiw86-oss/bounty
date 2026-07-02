import 'package:permission_handler/permission_handler.dart';

class StreamPermissionManager {
  static Future<bool> requestStreamingPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.camera,
      Permission.microphone,
    ].request();

    if (statuses[Permission.camera]!.isGranted &&
        statuses[Permission.microphone]!.isGranted &&
        statuses[Permission.location]!.isGranted) {
      return true;
    } else {
      return false;
    }
  }
}
