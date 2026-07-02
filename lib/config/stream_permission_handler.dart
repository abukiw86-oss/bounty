import 'package:permission_handler/permission_handler.dart';

class StreamPermissionManager {
  static PermissionStatus? cameraStatus;
  static PermissionStatus? microphoneStatus;
  static PermissionStatus? locationStatus;

  static Future<Map<Permission, PermissionStatus>>
  requestAllPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
      Permission.location,
    ].request();

    cameraStatus = statuses[Permission.camera];
    microphoneStatus = statuses[Permission.microphone];
    locationStatus = statuses[Permission.location];

    return statuses;
  }

  static bool areAllPermissionsGranted() {
    return cameraStatus?.isGranted == true &&
        microphoneStatus?.isGranted == true &&
        locationStatus?.isGranted == true;
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

  static Future<Map<Permission, PermissionStatus>> requestSpecificPermissions(
    List<Permission> permissions,
  ) async {
    if (permissions.isEmpty) return {};

    Map<Permission, PermissionStatus> statuses = await permissions.request();

    statuses.forEach((permission, status) {
      if (permission == Permission.camera) cameraStatus = status;
      if (permission == Permission.microphone) microphoneStatus = status;
      if (permission == Permission.location) locationStatus = status;
    });

    return statuses;
  }

  static void resetStatuses() {
    cameraStatus = null;
    microphoneStatus = null;
    locationStatus = null;
  }
}
