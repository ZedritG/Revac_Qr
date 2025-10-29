import 'package:revec_qr/features/auth/data/datasources/session_local_data_source.dart';
import 'package:revec_qr/features/auth/data/models/user_session_model.dart';
import 'package:revec_qr/features/auth/domain/entities/user_session.dart';
import 'package:revec_qr/features/auth/domain/repositories/session_repository.dart';

class SessionRepositoryImpl implements SessionRepository {
  SessionRepositoryImpl(this._localDataSource);

  final SessionLocalDataSource _localDataSource;

  @override
  Future<void> init() => _localDataSource.init();

  @override
  Future<UserSession?> currentSession() async {
    final model = await _localDataSource.getSession();
    return model?.toEntity();
  }

  @override
  Future<void> persistSession(UserSession session) async {
    await _localDataSource.saveSession(
      UserSessionModel.fromEntity(session),
    );
  }

  @override
  Future<void> clearSession() => _localDataSource.clearSession();
}
