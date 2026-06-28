import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestCamera() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  static Future<bool> requestMicrophone() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  static Future<bool> requestLocation() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  static Future<bool> requestStorage() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  static Future<bool> checkCamera() async => await Permission.camera.isGranted;
  static Future<bool> checkMicrophone() async => await Permission.microphone.isGranted;
  static Future<bool> checkLocation() async => await Permission.location.isGranted;

  static Future<void> openSettings() async => await openAppSettings();
}
