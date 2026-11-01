import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../../core/config/app_config.dart';

/// Autenticación Subsonic por token: t = md5(password + salt), s = salt.
/// La contraseña nunca viaja en claro ni se guarda en la URL.
class SubsonicAuth {
  SubsonicAuth({required this.username, required this.password, Random? random})
      : _random = random ?? Random.secure();

  final String username;
  final String password;
  final Random _random;

  static const _alphabet =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

  /// Genera parámetros frescos (salt nuevo en cada llamada).
  Map<String, String> authParams() {
    final salt = _newSalt();
    final token = md5.convert(utf8.encode('$password$salt')).toString();
    return {
      'u': username,
      't': token,
      's': salt,
      'v': AppConfig.subsonicApiVersion,
      'c': AppConfig.clientName,
      'f': 'json',
    };
  }

  String _newSalt([int length = 12]) => List.generate(
        length,
        (_) => _alphabet[_random.nextInt(_alphabet.length)],
      ).join();
}
