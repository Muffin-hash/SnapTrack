import 'package:permission_handler/permission_handler.dart';

/// Result wrapper so UI code can branch on outcome without importing
/// permission_handler directly (keeps the platform package isolated here).
enum AppPermissionStatus { granted, denied, permanentlyDenied, restricted }

/// Wraps all runtime permission requests (camera, gallery/photos, location)
/// behind a single service so widgets never call permission_handler directly.
class PermissionService {
  Future<AppPermissionStatus> requestCamera() async {
    return _request(Permission.camera);
  }

  Future<AppPermissionStatus> requestGallery() async {
    // photos covers iOS; storage is the Android < 13 equivalent fallback.
    final status = await Permission.photos.request();
    if (status.isGranted || status.isLimited) return AppPermissionStatus.granted;
    if (status.isPermanentlyDenied) return AppPermissionStatus.permanentlyDenied;
    return AppPermissionStatus.denied;
  }

  Future<AppPermissionStatus> requestLocation() async {
    return _request(Permission.locationWhenInUse);
  }

  Future<AppPermissionStatus> requestNotifications() async {
    return _request(Permission.notification);
  }

  Future<AppPermissionStatus> _request(Permission permission) async {
    final status = await permission.request();
    if (status.isGranted) return AppPermissionStatus.granted;
    if (status.isPermanentlyDenied) return AppPermissionStatus.permanentlyDenied;
    if (status.isRestricted) return AppPermissionStatus.restricted;
    return AppPermissionStatus.denied;
  }

  /// Sends the user to system settings — used when a permission was
  /// permanently denied and can no longer be requested in-app.
  Future<void> openSettings() => openAppSettings();
}
