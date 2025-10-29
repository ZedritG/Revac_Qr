import 'package:revec_qr/features/auth/domain/entities/user_role.dart';
import 'package:revec_qr/features/auth/domain/entities/user_session.dart';

class UserAccount {
  const UserAccount({
    required this.id,
    required this.email,
    required this.password,
    required this.displayName,
    required this.role,
  });

  final String id;
  final String email;
  final String password;
  final String displayName;
  final UserRole role;

  UserSession toSession() =>
      UserSession(id: id, displayName: displayName, role: role);
}

class UsersCatalog {
  const UsersCatalog._();

  static final technicianNorth = UserAccount(
    id: 'tech-001',
    email: 'tecnico@revec.com',
    password: 'qrtech123',
    displayName: 'Carlos Ruiz (Técnico Norte)',
    role: UserRole.technician,
  );

  static final technicianSouth = UserAccount(
    id: 'tech-002',
    email: 'tecnico.sur@revec.com',
    password: 'qrtech456',
    displayName: 'Jimena Torres (Técnica Sur)',
    role: UserRole.technician,
  );

  static final supervisor = UserAccount(
    id: 'sup-001',
    email: 'supervisor@revec.com',
    password: 'qradmin123',
    displayName: 'Laura Mendez (Supervisora)',
    role: UserRole.supervisor,
  );

  static List<UserAccount> get all => [
    technicianNorth,
    technicianSouth,
    supervisor,
  ];

  static UserAccount get technician => technicianNorth;
  static UserAccount get technicianAlt => technicianSouth;

  static UserAccount? authenticate(String email, String password) {
    for (final account in all) {
      if (account.email.toLowerCase() == email.toLowerCase() &&
          account.password == password) {
        return account;
      }
    }
    return null;
  }
}
