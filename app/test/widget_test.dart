import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:navidrome_stream/core/utils/format.dart';
import 'package:navidrome_stream/data/subsonic/subsonic_auth.dart';

void main() {
  group('formatDuration', () {
    test('formatea m:ss', () {
      expect(formatDuration(const Duration(seconds: 5)), '0:05');
      expect(formatDuration(const Duration(minutes: 3, seconds: 42)), '3:42');
    });

    test('formatea h:mm:ss', () {
      expect(formatDuration(const Duration(hours: 1, minutes: 2, seconds: 3)), '1:02:03');
    });
  });

  group('SubsonicAuth', () {
    test('token = md5(password + salt) y parámetros obligatorios', () {
      final auth = SubsonicAuth(username: 'jonis', password: 'secreto');
      final params = auth.authParams();

      final expected = md5.convert(utf8.encode('secreto${params['s']}')).toString();
      expect(params['t'], expected);
      expect(params['u'], 'jonis');
      expect(params['v'], '1.16.1');
      expect(params['f'], 'json');
      expect(params.containsKey('p'), isFalse, reason: 'nunca enviar la contraseña en claro');
    });

    test('genera un salt distinto en cada llamada', () {
      final auth = SubsonicAuth(username: 'u', password: 'p');
      expect(auth.authParams()['s'], isNot(auth.authParams()['s']));
    });
  });
}
