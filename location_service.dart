import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// Result of a location read, kept simple so the UI layer doesn't need to
/// know about geolocator's Position type.
class DeviceLocation {
  final double latitude;
  final double longitude;
  final String? label;

  const DeviceLocation({
    required this.latitude,
    required this.longitude,
    this.label,
  });
}

/// Thrown when location services are off at the OS level (different from
/// a denied permission, which permission_service already handles).
class LocationServiceDisabledException implements Exception {
  const LocationServiceDisabledException();
}

/// Wraps geolocator/geocoding so widgets never call those packages
/// directly. Assumes the caller has already obtained permission via
/// PermissionService — this service only reads position data.
class LocationService {
  Future<DeviceLocation> getCurrentLocation({bool withLabel = true}) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceDisabledException();
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    String? label;
    if (withLabel) {
      label = await _reverseGeocode(position.latitude, position.longitude);
    }

    return DeviceLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      label: label,
    );
  }

  /// Best-effort reverse geocode. Returns null instead of throwing if it
  /// fails (e.g. offline) — a missing label shouldn't block attaching
  /// raw coordinates to a record.
  Future<String?> _reverseGeocode(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return null;
      final p = placemarks.first;
      final parts = [p.locality, p.administrativeArea, p.country]
          .where((e) => e != null && e.isNotEmpty)
          .toList();
      return parts.isEmpty ? null : parts.join(', ');
    } catch (_) {
      return null;
    }
  }
}
