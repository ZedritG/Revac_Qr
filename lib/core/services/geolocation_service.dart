import 'package:geolocator/geolocator.dart';

abstract class GeolocationService {
  Future<void> ensurePermissions();

  Future<Position> getCurrentPosition();
}
