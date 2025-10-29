import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:revec_qr/core/constants/users_catalog.dart';
import 'package:revec_qr/features/auth/data/providers/session_repository_provider.dart';
import 'package:revec_qr/features/auth/domain/entities/user_session.dart';
import 'package:revec_qr/shared/providers/service_providers.dart';

class SessionController extends AsyncNotifier<UserSession?> {
  @override
  Future<UserSession?> build() async {
    await ref.read(sessionRepositoryInitializer.future);
    final repository = ref.read(sessionRepositoryProvider);
    try {
      return repository.currentSession();
    } catch (error, stackTrace) {
      ref
          .read(loggerProvider)
          .e(
            'Error al restaurar la sesion',
            error: error,
            stackTrace: stackTrace,
          );
      rethrow;
    }
  }

  Future<void> login({required String email, required String password}) async {
    final account = UsersCatalog.authenticate(email, password);
    if (account == null) {
      ref
          .read(loggerProvider)
          .w('Intento de login con credenciales invalidas para $email');
      throw const InvalidCredentialsException();
    }

    final session = account.toSession();
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(sessionRepositoryProvider);
      await repository.persistSession(session);
      return session;
    });
    state.whenOrNull(
      error: (error, stackTrace) => ref
          .read(loggerProvider)
          .e('Error al iniciar sesion', error: error, stackTrace: stackTrace),
    );
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(sessionRepositoryProvider);
      await repository.clearSession();
      return null;
    });
    state.whenOrNull(
      error: (error, stackTrace) => ref
          .read(loggerProvider)
          .e('Error al cerrar sesion', error: error, stackTrace: stackTrace),
    );
  }
}

final sessionControllerProvider =
    AsyncNotifierProvider<SessionController, UserSession?>(
      SessionController.new,
    );

final currentSessionProvider = Provider<UserSession?>((ref) {
  final sessionState = ref.watch(sessionControllerProvider);
  return sessionState.value;
});

class InvalidCredentialsException implements Exception {
  const InvalidCredentialsException();
}
