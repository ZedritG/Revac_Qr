import 'package:geolocator/geolocator.dart';

import 'package:revec_qr/core/services/geolocation_service.dart';
import 'package:revec_qr/core/services/permission_service.dart';

class GeolocationServiceImpl implements GeolocationService {
  GeolocationServiceImpl(this._permissionService);

  final PermissionService _permissionService;

  @override
  Future<void> ensurePermissions() async {
    final hasPermission =
        await _permissionService.hasPermission(AppPermission.location);
    if (!hasPermission) {
      final granted =
          await _permissionService.request(AppPermission.location);
      if (!granted) {
        throw const LocationPermissionDeniedException();
      }
    }

    var geolocatorPermission = await Geolocator.checkPermission();
    if (geolocatorPermission == LocationPermission.deniedForever) {
      throw const LocationPermissionPermanentlyDeniedException();
    }

    if (geolocatorPermission == LocationPermission.denied) {
      geolocatorPermission = await Geolocator.requestPermission();
      if (geolocatorPermission == LocationPermission.denied) {
        throw const LocationPermissionDeniedException();
      }
      if (geolocatorPermission == LocationPermission.deniedForever) {
        throw const LocationPermissionPermanentlyDeniedException();
      }
    }
  }

  @override
  Future<Position> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceDisabledException();
    }

    await ensurePermissions();
    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );
  }
}

class LocationPermissionDeniedException implements Exception {
  const LocationPermissionDeniedException();
}

class LocationPermissionPermanentlyDeniedException implements Exception {
  const LocationPermissionPermanentlyDeniedException();
}

class LocationServiceDisabledException implements Exception {
  const LocationServiceDisabledException();
}
