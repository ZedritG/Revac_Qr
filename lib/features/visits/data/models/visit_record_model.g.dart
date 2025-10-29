// GENERATED CODE - MANUAL STUB UNTIL build_runner IS EXECUTED.

part of 'visit_record_model.dart';

class VisitRecordModelAdapter extends TypeAdapter<VisitRecordModel> {
  @override
  final int typeId = 1;

  @override
  VisitRecordModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VisitRecordModel(
      id: fields[0] as String,
      scannedCode: fields[1] as String,
      teamName: fields[2] as String,
      visitedAt: fields[3] as DateTime,
      latitude: fields[4] as double,
      longitude: fields[5] as double,
      technicianId: fields[6] as String,
      note: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, VisitRecordModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.scannedCode)
      ..writeByte(2)
      ..write(obj.teamName)
      ..writeByte(3)
      ..write(obj.visitedAt)
      ..writeByte(4)
      ..write(obj.latitude)
      ..writeByte(5)
      ..write(obj.longitude)
      ..writeByte(6)
      ..write(obj.technicianId)
      ..writeByte(7)
      ..write(obj.note);
  }
}
