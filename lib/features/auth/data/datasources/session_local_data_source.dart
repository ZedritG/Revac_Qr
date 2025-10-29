import 'package:hive_flutter/hive_flutter.dart';

import 'package:revec_qr/core/storage/hive_boxes.dart';
import 'package:revec_qr/features/auth/data/models/user_session_model.dart';

abstract class SessionLocalDataSource {
  Future<void> init();

  Future<UserSessionModel?> getSession();

  Future<void> saveSession(UserSessionModel session);

  Future<void> clearSession();
}

class SessionLocalDataSourceImpl implements SessionLocalDataSource {
  SessionLocalDataSourceImpl();

  Box<UserSessionModel>? _box;

  @override
  Future<void> init() async {
    final adapter = UserSessionModelAdapter();
    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter(adapter);
    }
    _box ??= await Hive.openBox<UserSessionModel>(HiveBoxes.session);
  }

  Box<UserSessionModel> get _ensureBox {
    final box = _box;
    if (box == null) {
      throw StateError('SessionLocalDataSource not initialized');
    }
    return box;
  }

  @override
  Future<UserSessionModel?> getSession() async {
    final box = _ensureBox;
    if (box.values.isEmpty) {
      return null;
    }
    return box.values.first;
  }

  @override
  Future<void> saveSession(UserSessionModel session) async {
    final box = _ensureBox;
    await box.clear();
    await box.put(session.id, session);
  }

  @override
  Future<void> clearSession() async {
    await _ensureBox.clear();
  }
}
