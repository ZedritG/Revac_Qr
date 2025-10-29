enum AppPermission {
  camera,
  location,
}

abstract class PermissionService {
  Future<bool> request(AppPermission permission);

  Future<bool> hasPermission(AppPermission permission);
}
