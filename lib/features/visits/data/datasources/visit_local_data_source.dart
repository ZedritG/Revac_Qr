import 'package:hive_flutter/hive_flutter.dart';

import '../models/visit_record_model.dart';

abstract class VisitLocalDataSource {
  Future<void> init();

  Future<VisitRecordModel> save(VisitRecordModel record);

  Stream<List<VisitRecordModel>> watchAll();

  Future<List<VisitRecordModel>> getAll();

  Future<void> clear();
}

class VisitLocalDataSourceImpl implements VisitLocalDataSource {
  VisitLocalDataSourceImpl(this._boxName);

  final String _boxName;
  Box<VisitRecordModel>? _box;

  @override
  Future<void> init() async {
    final adapter = VisitRecordModelAdapter();
    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter(adapter);
    }

    _box ??= await Hive.openBox<VisitRecordModel>(_boxName);
  }

  Box<VisitRecordModel> get _ensureBox {
    final box = _box;
    if (box == null) {
      throw StateError('VisitLocalDataSource not initialized');
    }
    return box;
  }

  @override
  Future<VisitRecordModel> save(VisitRecordModel record) async {
    await _ensureBox.put(record.id, record);
    return record;
  }

  @override
  Stream<List<VisitRecordModel>> watchAll() async* {
    final box = _ensureBox;
    yield box.values.toList();
    await for (final _ in box.watch()) {
      yield box.values.toList();
    }
  }

  @override
  Future<List<VisitRecordModel>> getAll() async {
    return _ensureBox.values.toList();
  }

  @override
  Future<void> clear() async {
    await _ensureBox.clear();
  }
}
