import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/entities/music_entities.dart';

/// Guarda la sesión en el Keychain (iOS) / Keystore (Android), no en prefs planas.
class CredentialsStore {
  CredentialsStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _kUrl = 'server_url';
  static const _kUser = 'username';
  static const _kPass = 'password';

  final FlutterSecureStorage _storage;

  Future<void> save(ServerSession session) async {
    await _storage.write(key: _kUrl, value: session.serverUrl);
    await _storage.write(key: _kUser, value: session.username);
    await _storage.write(key: _kPass, value: session.password);
  }

  Future<ServerSession?> load() async {
    final url = await _storage.read(key: _kUrl);
    final user = await _storage.read(key: _kUser);
    final pass = await _storage.read(key: _kPass);
    if (url == null || user == null || pass == null) return null;
    return ServerSession(serverUrl: url, username: user, password: pass);
  }

  Future<void> clear() => _storage.deleteAll();
}
