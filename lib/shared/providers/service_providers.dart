import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import 'package:revec_qr/core/services/geolocation_service.dart';
import 'package:revec_qr/core/services/geolocation_service_impl.dart';
import 'package:revec_qr/core/services/permission_service.dart';
import 'package:revec_qr/core/services/permission_service_impl.dart';

final permissionServiceProvider = Provider<PermissionService>(
  (ref) => const PermissionServiceImpl(),
);

final geolocationServiceProvider = Provider<GeolocationService>((ref) {
  final permissionService = ref.watch(permissionServiceProvider);
  return GeolocationServiceImpl(permissionService);
});

final loggerProvider = Provider<Logger>((ref) {
  return Logger(
    printer: PrettyPrinter(
      noBoxingByDefault: true,
      methodCount: 0,
      errorMethodCount: 5,
    ),
  );
});
