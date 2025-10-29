import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:revec_qr/features/auth/domain/entities/user_role.dart';
import 'package:revec_qr/features/auth/presentation/controllers/session_controller.dart';
import 'package:revec_qr/features/visits/data/providers/visit_repository_provider.dart';
import 'package:revec_qr/features/visits/domain/entities/visit_record.dart';
import 'package:revec_qr/shared/providers/service_providers.dart';

class VisitHistoryController
    extends AutoDisposeAsyncNotifier<List<VisitRecord>> {
  StreamSubscription<List<VisitRecord>>? _subscription;

  @override
  Future<List<VisitRecord>> build() async {
    final session = ref.watch(currentSessionProvider);
    await ref.read(visitRepositoryInitializer.future);
    final repository = ref.read(visitRepositoryProvider);
    _subscription?.cancel();
    _subscription = repository.watchVisits().listen(
      (data) => state = AsyncValue.data(
        _filterVisits(data, session?.role, session?.id),
      ),
      onError: (Object error, StackTrace stackTrace) {
        ref
            .read(loggerProvider)
            .e(
              'Error en stream de historial de visitas',
              error: error,
              stackTrace: stackTrace,
            );
      },
    );
    ref.onDispose(() => _subscription?.cancel());
    try {
      final visits = await repository.fetchVisits();
      return _filterVisits(visits, session?.role, session?.id);
    } catch (error, stackTrace) {
      ref
          .read(loggerProvider)
          .e(
            'Error al cargar historial de visitas',
            error: error,
            stackTrace: stackTrace,
          );
      rethrow;
    }
  }

  Future<void> refresh() async {
    final session = ref.read(currentSessionProvider);
    final repository = ref.read(visitRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final visits = await repository.fetchVisits();
      return _filterVisits(visits, session?.role, session?.id);
    });
    state.whenOrNull(
      error: (error, stackTrace) => ref
          .read(loggerProvider)
          .e(
            'Error al refrescar historial de visitas',
            error: error,
            stackTrace: stackTrace,
          ),
    );
  }

  List<VisitRecord> _filterVisits(
    List<VisitRecord> visits,
    UserRole? role,
    String? technicianId,
  ) {
    if (role == null) {
      return <VisitRecord>[];
    }
    if (role == UserRole.technician && technicianId != null) {
      return visits
          .where((visit) => visit.technicianId == technicianId)
          .toList();
    }
    return visits;
  }
}

final visitHistoryProvider =
    AutoDisposeAsyncNotifierProvider<VisitHistoryController, List<VisitRecord>>(
      VisitHistoryController.new,
    );
