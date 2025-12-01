import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:oshmobile/core/common/entities/session.dart';

final class SessionStorage {
  static final sessionKey = "SESSION_KEY";

  SessionStorage({required FlutterSecureStorage storage}) : _storage = storage;

  final FlutterSecureStorage _storage;
  bool _initialized = false;

  Session? _session;

  Session? getSession() {
    if (!_initialized) {
      throw Exception("SessionStorage is not initialized yet");
    }
    return _session;
  }

  Future<void> setSession(Session session) async {
    final jsonString = jsonEncode(session.toJson());
    await _storage.write(key: sessionKey, value: jsonString);
    _session = session;
  }

  Future<void> clearSession() async {
    await _storage.delete(key: sessionKey);
    _session = null;
  }

  Future<void> initialize() async {
    try {
      final sessionJson = await _storage.read(key: sessionKey);
      if (sessionJson != null) {
        _session = Session.fromJson(jsonDecode(sessionJson));
      }
    } catch (e) {
      clearSession();
    } finally {
      _initialized = true;
    }
  }
}
