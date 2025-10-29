import 'package:permission_handler/permission_handler.dart';

import 'package:revec_qr/core/services/permission_service.dart';

class PermissionServiceImpl implements PermissionService {
  const PermissionServiceImpl();

  @override
  Future<bool> hasPermission(AppPermission permission) async {
    final status = await _toPermission(permission).status;
    return status.isGranted || status.isLimited;
  }

  @override
  Future<bool> request(AppPermission permission) async {
    final permissionHandler = _toPermission(permission);
    final status = await permissionHandler.request();
    return status.isGranted || status.isLimited;
  }

  Permission _toPermission(AppPermission permission) {
    switch (permission) {
      case AppPermission.camera:
        return Permission.camera;
      case AppPermission.location:
        return Permission.location;
    }
  }
}
