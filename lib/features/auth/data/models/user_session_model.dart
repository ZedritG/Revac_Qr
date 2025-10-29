import 'package:hive/hive.dart';

import 'package:revec_qr/features/auth/domain/entities/user_role.dart';
import 'package:revec_qr/features/auth/domain/entities/user_session.dart';

part 'user_session_model.g.dart';

@HiveType(typeId: 2)
class UserSessionModel {
  const UserSessionModel({
    required this.id,
    required this.displayName,
    required this.role,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String displayName;

  @HiveField(2)
  final String role;

  factory UserSessionModel.fromEntity(UserSession session) {
    return UserSessionModel(
      id: session.id,
      displayName: session.displayName,
      role: session.role.name,
    );
  }

  UserSession toEntity() => UserSession(
        id: id,
        displayName: displayName,
        role: UserRole.values.firstWhere(
          (item) => item.name == role,
          orElse: () => UserRole.technician,
        ),
      );
}
