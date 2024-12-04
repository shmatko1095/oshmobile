import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:oshmobile/core/web/chopper_example/models/session.dart';

final class SessionStorage {
  static final sessionKey = "SESSION_KEY";

  SessionStorage({required FlutterSecureStorage storage}) : _storage = storage;

  final FlutterSecureStorage _storage;

  Session? _session;

  Session? get session => _session;

  Future<void> setSession(Session? session) async {
    if (session != null) {
      final jsonString = jsonEncode(session.toJson());
      await _storage.write(key: sessionKey, value: jsonString);
    } else {
      await _storage.delete(key: sessionKey);
    }
    _session = session;
  }

  Future<void> initialize() async {
    final sessionJson = await _storage.read(key: sessionKey);
    if (sessionJson != null) {
      _session = Session.fromJson(jsonDecode(sessionJson));
    }
  }
}
