import 'package:revec_qr/features/visits/data/datasources/visit_local_data_source.dart';
import 'package:revec_qr/features/visits/data/models/visit_record_model.dart';
import 'package:revec_qr/features/visits/domain/entities/visit_record.dart';
import 'package:revec_qr/features/visits/domain/repositories/visit_repository.dart';

class VisitRepositoryImpl implements VisitRepository {
  VisitRepositoryImpl(this._localDataSource);

  final VisitLocalDataSource _localDataSource;

  @override
  Future<void> init() async {
    await _localDataSource.init();
  }

  @override
  Future<VisitRecord> saveVisit(VisitRecord record) async {
    final model = VisitRecordModel.fromEntity(record);
    await _localDataSource.save(model);
    return record;
  }

  @override
  Stream<List<VisitRecord>> watchVisits() {
    return _localDataSource
        .watchAll()
        .map((models) => models.map((m) => m.toEntity()).toList());
  }

  @override
  Future<List<VisitRecord>> fetchVisits() async {
    final models = await _localDataSource.getAll();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> clear() async {
    await _localDataSource.clear();
  }
}
