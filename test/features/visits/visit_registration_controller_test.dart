import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:revec_qr/core/services/geolocation_service.dart';
import 'package:revec_qr/features/auth/domain/entities/user_role.dart';
import 'package:revec_qr/features/auth/domain/entities/user_session.dart';
import 'package:revec_qr/features/auth/presentation/controllers/session_controller.dart';
import 'package:revec_qr/features/visits/data/providers/visit_repository_provider.dart';
import 'package:revec_qr/features/visits/domain/entities/visit_record.dart';
import 'package:revec_qr/features/visits/domain/repositories/visit_repository.dart';
import 'package:revec_qr/features/visits/presentation/controllers/visit_registration_controller.dart';
import 'package:revec_qr/shared/providers/service_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _FakeVisitRepository implements VisitRepository {
  final List<VisitRecord> stored = [];
  bool initCalled = false;

  @override
  Future<void> init() async {
    initCalled = true;
  }

  @override
  Future<VisitRecord> saveVisit(VisitRecord record) async {
    stored.add(record);
    return record;
  }

  @override
  Stream<List<VisitRecord>> watchVisits() async* {
    yield stored;
  }

  @override
  Future<List<VisitRecord>> fetchVisits() async => stored;

  @override
  Future<void> clear() async {
    stored.clear();
  }
}

class _FakeGeolocationService implements GeolocationService {
  @override
  Future<void> ensurePermissions() async {}

  @override
  Future<Position> getCurrentPosition() async => Position(
        latitude: 10.0,
        longitude: 20.0,
        timestamp: DateTime.now(),
        accuracy: 1,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        headingAccuracy: 0,
        altitudeAccuracy: 0,
      );
}

void main() {
  group('VisitRegistrationController', () {
    late _FakeVisitRepository repository;
    late ProviderContainer container;

    setUp(() {
      repository = _FakeVisitRepository();
      container = ProviderContainer(
        overrides: [
          visitRepositoryProvider.overrideWithValue(repository),
          visitRepositoryInitializer.overrideWith((ref) async {
            await repository.init();
          }),
          geolocationServiceProvider
              .overrideWithValue(_FakeGeolocationService()),
          currentSessionProvider.overrideWithValue(
            const UserSession(
              id: 'tech-001',
              displayName: 'Carlos Ruiz',
              role: UserRole.technician,
            ),
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('registers visit with note and location', () async {
      final controller =
          container.read(visitRegistrationProvider.notifier);

      final record = await controller.registerVisit(
        scannedCode: 'TM-001',
        note: 'Equipo revisado y calibrado.',
      );

      expect(repository.initCalled, isTrue);
      expect(repository.stored, hasLength(1));
      expect(record.note, 'Equipo revisado y calibrado.');
      expect(record.latitude, 10.0);
      expect(record.longitude, 20.0);
      expect(record.technicianId, 'tech-001');
    });
  });
}
