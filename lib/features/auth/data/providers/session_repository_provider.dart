import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:revec_qr/features/auth/data/datasources/session_local_data_source.dart';
import 'package:revec_qr/features/auth/data/repositories/session_repository_impl.dart';
import 'package:revec_qr/features/auth/domain/repositories/session_repository.dart';

final sessionLocalDataSourceProvider =
    Provider<SessionLocalDataSource>((ref) {
  return SessionLocalDataSourceImpl();
});

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  final dataSource = ref.watch(sessionLocalDataSourceProvider);
  return SessionRepositoryImpl(dataSource);
});

final sessionRepositoryInitializer = FutureProvider<void>((ref) async {
  final repository = ref.watch(sessionRepositoryProvider);
  await repository.init();
});
