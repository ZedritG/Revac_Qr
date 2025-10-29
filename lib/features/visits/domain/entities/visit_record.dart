import 'package:revec_qr/features/auth/domain/entities/user_role.dart';

class VisitRecord {
  const VisitRecord({
    required this.id,
    required this.scannedCode,
    required this.teamName,
    required this.visitedAt,
    required this.latitude,
    required this.longitude,
    required this.technicianId,
    this.note,
  });

  final String id;
  final String scannedCode;
  final String teamName;
  final DateTime visitedAt;
  final double latitude;
  final double longitude;
  final String technicianId;
  final String? note;

  bool isVisibleFor(UserRole role, {required String currentTechnicianId}) {
    if (role == UserRole.supervisor) {
      return true;
    }

    return technicianId == currentTechnicianId;
  }
}
