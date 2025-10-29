import 'package:revec_qr/features/auth/domain/entities/user_role.dart';

class UserSession {
  const UserSession({
    required this.id,
    required this.displayName,
    required this.role,
  });

  final String id;
  final String displayName;
  final UserRole role;
}
