import 'package:hive/hive.dart';

import '../../domain/entities/visit_record.dart';

part 'visit_record_model.g.dart';

@HiveType(typeId: 1)
class VisitRecordModel {
  const VisitRecordModel({
    required this.id,
    required this.scannedCode,
    required this.teamName,
    required this.visitedAt,
    required this.latitude,
    required this.longitude,
    required this.technicianId,
    this.note,
  });

  factory VisitRecordModel.fromEntity(VisitRecord record) {
    return VisitRecordModel(
      id: record.id,
      scannedCode: record.scannedCode,
      teamName: record.teamName,
      visitedAt: record.visitedAt,
      latitude: record.latitude,
      longitude: record.longitude,
      technicianId: record.technicianId,
      note: record.note,
    );
  }

  VisitRecord toEntity() => VisitRecord(
    id: id,
    scannedCode: scannedCode,
    teamName: teamName,
    visitedAt: visitedAt,
    latitude: latitude,
    longitude: longitude,
    technicianId: technicianId,
    note: note,
  );

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String scannedCode;

  @HiveField(2)
  final String teamName;

  @HiveField(3)
  final DateTime visitedAt;

  @HiveField(4)
  final double latitude;

  @HiveField(5)
  final double longitude;

  @HiveField(6)
  final String technicianId;

  @HiveField(7)
  final String? note;
}
