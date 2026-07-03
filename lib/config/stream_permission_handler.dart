import 'package:permission_handler/permission_handler.dart';

class StreamPermissionManager {
  static PermissionStatus? cameraStatus;
  static PermissionStatus? microphoneStatus;
  static PermissionStatus? locationStatus;

  // Check if all permissions are granted
  static bool areAllPermissionsGranted() {
    bool coreGranted =
        cameraStatus?.isGranted == true &&
        microphoneStatus?.isGranted == true &&
        locationStatus?.isGranted == true;

    return coreGranted;
  }

  static Future<bool> requestAllPermissions({
    bool requestNotification = false,
  }) async {
    List<Permission> permissions = [
      Permission.camera,
      Permission.microphone,
      Permission.location,
    ];

    Map<Permission, PermissionStatus> statuses = await permissions.request();

    cameraStatus = statuses[Permission.camera];
    microphoneStatus = statuses[Permission.microphone];
    locationStatus = statuses[Permission.location];

    return areAllPermissionsGranted();
  }

  static List<Permission> getDeniedPermissions() {
    List<Permission> denied = [];

    if (cameraStatus != null && !cameraStatus!.isGranted) {
      denied.add(Permission.camera);
    }
    if (microphoneStatus != null && !microphoneStatus!.isGranted) {
      denied.add(Permission.microphone);
    }
    if (locationStatus != null && !locationStatus!.isGranted) {
      denied.add(Permission.location);
    }
    return denied;
  }

  static List<Permission> getPermanentlyDeniedPermissions() {
    List<Permission> permanentlyDenied = [];

    if (cameraStatus != null && cameraStatus!.isPermanentlyDenied) {
      permanentlyDenied.add(Permission.camera);
    }
    if (microphoneStatus != null && microphoneStatus!.isPermanentlyDenied) {
      permanentlyDenied.add(Permission.microphone);
    }
    if (locationStatus != null && locationStatus!.isPermanentlyDenied) {
      permanentlyDenied.add(Permission.location);
    }

    return permanentlyDenied;
  }

  static void resetStatuses() {
    cameraStatus = null;
    microphoneStatus = null;
    locationStatus = null;
  }
}
