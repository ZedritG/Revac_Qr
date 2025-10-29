import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:revec_qr/core/constants/team_catalog.dart';
import 'package:revec_qr/core/services/geolocation_service_impl.dart';
import 'package:revec_qr/features/auth/domain/entities/user_role.dart';
import 'package:revec_qr/features/auth/presentation/controllers/session_controller.dart';
import 'package:revec_qr/features/visits/domain/entities/visit_record.dart';
import 'package:revec_qr/features/visits/data/providers/visit_repository_provider.dart';
import 'package:revec_qr/shared/providers/service_providers.dart';
import 'package:revec_qr/shared/utils/id_generator.dart';

class VisitRegistrationController
    extends AutoDisposeAsyncNotifier<VisitRecord?> {
  static const String fallbackLocationNote =
      'Ubicacion no disponible (permiso o servicio desactivado).';

  @override
  Future<VisitRecord?> build() async => null;

  Future<VisitRecord> registerVisit({
    required String scannedCode,
    String? note,
  }) async {
    final session = ref.read(currentSessionProvider);
    if (session == null || session.role != UserRole.technician) {
      throw StateError('Se requiere un tecnico autenticado para registrar.');
    }

    await ref.read(visitRepositoryInitializer.future);
    final repository = ref.read(visitRepositoryProvider);
    final geolocationService = ref.read(geolocationServiceProvider);

    state = const AsyncValue.loading();

    try {
      double latitude = 0;
      double longitude = 0;
      bool usedFallbackLocation = false;

      try {
        final position = await geolocationService.getCurrentPosition();
        latitude = position.latitude;
        longitude = position.longitude;
      } on LocationPermissionDeniedException {
        ref
            .read(loggerProvider)
            .w('Permiso de ubicacion denegado temporalmente.');
        usedFallbackLocation = true;
      } on LocationPermissionPermanentlyDeniedException {
        ref
            .read(loggerProvider)
            .w(
              'Permiso de ubicacion denegado permanentemente. '
              'Se almacenara la visita sin coordenadas.',
            );
        usedFallbackLocation = true;
      } on LocationServiceDisabledException {
        ref.read(loggerProvider).w('Servicio de ubicacion deshabilitado.');
        usedFallbackLocation = true;
      }

      final team = TeamCatalog.infoFor(scannedCode);
      final effectiveNote = usedFallbackLocation
          ? (note == null || note.isEmpty
                ? fallbackLocationNote
                : '$note\n$fallbackLocationNote')
          : note;

      final record = VisitRecord(
        id: IdGenerator.newId(),
        scannedCode: scannedCode,
        teamName: team.name,
        visitedAt: DateTime.now(),
        latitude: latitude,
        longitude: longitude,
        technicianId: session.id,
        note: effectiveNote,
      );

      await repository.saveVisit(record);
      state = AsyncValue.data(record);
      return record;
    } catch (error, stackTrace) {
      ref
          .read(loggerProvider)
          .e(
            'Error al registrar la visita',
            error: error,
            stackTrace: stackTrace,
          );
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}

final visitRegistrationProvider =
    AutoDisposeAsyncNotifierProvider<VisitRegistrationController, VisitRecord?>(
      VisitRegistrationController.new,
    );
