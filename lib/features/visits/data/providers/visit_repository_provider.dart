import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:revec_qr/core/storage/hive_boxes.dart';
import 'package:revec_qr/features/visits/data/datasources/visit_local_data_source.dart';
import 'package:revec_qr/features/visits/data/repositories/visit_repository_impl.dart';
import 'package:revec_qr/features/visits/domain/repositories/visit_repository.dart';

final visitLocalDataSourceProvider = Provider<VisitLocalDataSource>((ref) {
  return VisitLocalDataSourceImpl(HiveBoxes.visits);
});

final visitRepositoryProvider = Provider<VisitRepository>((ref) {
  final dataSource = ref.watch(visitLocalDataSourceProvider);
  return VisitRepositoryImpl(dataSource);
});

final visitRepositoryInitializer = FutureProvider<void>((ref) async {
  final repository = ref.watch(visitRepositoryProvider);
  await repository.init();
});
