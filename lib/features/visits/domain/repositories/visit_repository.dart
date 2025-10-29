import '../entities/visit_record.dart';

abstract class VisitRepository {
  Future<void> init();

  Future<VisitRecord> saveVisit(VisitRecord record);

  Stream<List<VisitRecord>> watchVisits();

  Future<List<VisitRecord>> fetchVisits();

  Future<void> clear();
}
