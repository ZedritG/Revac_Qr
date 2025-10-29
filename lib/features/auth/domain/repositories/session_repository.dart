import 'package:revec_qr/features/auth/domain/entities/user_session.dart';

abstract class SessionRepository {
  Future<void> init();

  Future<UserSession?> currentSession();

  Future<void> persistSession(UserSession session);

  Future<void> clearSession();
}
