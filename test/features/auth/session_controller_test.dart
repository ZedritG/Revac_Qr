import 'package:flutter_test/flutter_test.dart';
import 'package:revec_qr/features/auth/data/providers/session_repository_provider.dart';
import 'package:revec_qr/features/auth/domain/entities/user_session.dart';
import 'package:revec_qr/features/auth/domain/repositories/session_repository.dart';
import 'package:revec_qr/features/auth/presentation/controllers/session_controller.dart';
import 'package:revec_qr/features/auth/domain/entities/user_role.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _FakeSessionRepository implements SessionRepository {
  UserSession? stored;
  bool initCalled = false;

  @override
  Future<void> init() async {
    initCalled = true;
  }

  @override
  Future<UserSession?> currentSession() async => stored;

  @override
  Future<void> persistSession(UserSession session) async {
    stored = session;
  }

  @override
  Future<void> clearSession() async {
    stored = null;
  }
}

void main() {
  group('SessionController', () {
    late _FakeSessionRepository repository;
    late ProviderContainer container;

    setUp(() {
      repository = _FakeSessionRepository();
      container = ProviderContainer(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(repository),
          sessionRepositoryInitializer.overrideWith((ref) async {
            await repository.init();
          }),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('login persists technician session', () async {
      await container.read(sessionControllerProvider.future);

      await container
          .read(sessionControllerProvider.notifier)
          .login(
            email: 'tecnico@revec.com',
            password: 'qrtech123',
          );

      final state = container.read(sessionControllerProvider);
      expect(state.hasValue, isTrue);
      expect(state.value, isNotNull);
      expect(state.value!.role, UserRole.technician);
      expect(repository.stored, isNotNull);
      expect(repository.stored!.id, 'tech-001');
      expect(repository.initCalled, isTrue);
    });

    test('login with invalid credentials throws', () async {
      await container.read(sessionControllerProvider.future);

      expect(
        () => container
            .read(sessionControllerProvider.notifier)
            .login(email: 'foo@bar.com', password: 'wrong'),
        throwsA(isA<InvalidCredentialsException>()),
      );
    });
  });
}
