import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:navidrome_stream/data/local/local_database_service.dart';
import 'package:navidrome_stream/data/local/models/audiobook_progress.dart';
import 'package:navidrome_stream/data/local/models/local_track.dart';
import 'package:navidrome_stream/data/local/models/server_config.dart';

void main() {
  late Directory tempDir;
  late LocalDatabaseService db;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('navidrome_db_test_');
    db = LocalDatabaseService();
    await db.init(path: tempDir.path);
  });

  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  final downloadedAt = DateTime.utc(2026, 10, 31, 12, 30);

  LocalTrack track(String id, {String relative = 'offline/x.mp3'}) => LocalTrack(
        id: id,
        title: 'Título $id',
        artist: 'Artista',
        album: 'Álbum',
        durationSeconds: 215,
        relativePath: relative,
        downloadedAt: downloadedAt,
        suffix: 'mp3',
        trackNumber: 3,
        starred: true,
      );

  group('LocalTrack', () {
    test('round-trip conserva todos los campos', () {
      final original = track('1');
      final restored = LocalTrack.fromMap(original.toMap());

      expect(restored.id, '1');
      expect(restored.relativePath, 'offline/x.mp3');
      expect(restored.downloadedAt, downloadedAt);
      expect(restored.trackNumber, 3);
      expect(restored.starred, isTrue);
    });

    test('migra el formato antiguo (path absoluta) a ruta relativa', () {
      final legacy = {
        'id': '42',
        'title': 'Vieja',
        'artist': 'A',
        'album': 'B',
        'durationSeconds': 10,
        'suffix': 'flac',
        'path': r'C:\Users\jonis\AppData\Roaming\app\offline\42.flac',
      };
      final migrated = LocalTrack.fromMap(legacy);
      expect(migrated.relativePath, 'offline/42.flac');
    });

    test('migra una ruta antigua de iOS con barras /', () {
      final legacy = {
        'id': '7',
        'title': 'iOS',
        'artist': 'A',
        'album': 'B',
        'path':
            '/var/mobile/Containers/Data/Application/ABC/Documents/offline/7.mp3',
      };
      expect(LocalTrack.fromMap(legacy).relativePath, 'offline/7.mp3');
    });

    test('toSong expone los campos de dominio', () {
      final song = track('9').toSong();
      expect(song.id, '9');
      expect(song.durationSeconds, 215);
      expect(song.starred, isTrue);
    });
  });

  group('AudiobookProgress', () {
    test('round-trip', () {
      final p = AudiobookProgress(
        audiobookId: 'book-1',
        chapterIndex: 4,
        positionMs: 123456,
        completed: false,
        lastPlayedAt: downloadedAt,
      );
      final restored = AudiobookProgress.fromMap(p.toMap());
      expect(restored.chapterIndex, 4);
      expect(restored.positionMs, 123456);
      expect(restored.lastPlayedAt, downloadedAt);
    });
  });

  group('ServerConfig', () {
    test('round-trip con preferencias anidadas', () {
      const c = ServerConfig(
        serverUrl: 'http://localhost:4533',
        sessionToken: 'tok',
        preferences: {'theme': 'dark', 'bitrate': 192},
      );
      final restored = ServerConfig.fromMap(c.toMap());
      expect(restored.serverUrl, 'http://localhost:4533');
      expect(restored.preferences['bitrate'], 192);
    });
  });

  group('LocalDatabaseService', () {
    test('CRUD de pistas', () async {
      await db.saveTrack(track('1'));
      await db.saveTrack(track('2'));

      expect(db.hasTrack('1'), isTrue);
      expect(db.getTrack('2')?.title, 'Título 2');
      expect(db.allTracks(), hasLength(2));

      await db.saveTrack(track('1', relative: 'offline/nuevo.m4a'));
      expect(db.getTrack('1')?.relativePath, 'offline/nuevo.m4a');
      expect(db.allTracks(), hasLength(2));

      await db.deleteTrack('1');
      expect(db.hasTrack('1'), isFalse);
      expect(db.getTrack('1'), isNull);
    });

    test('guarda y actualiza el progreso de un audiolibro', () async {
      expect(db.getProgress('book-1'), isNull);

      await db.saveProgress(AudiobookProgress(
        audiobookId: 'book-1',
        chapterIndex: 2,
        positionMs: 5000,
        completed: false,
        lastPlayedAt: downloadedAt,
      ));
      await db.saveProgress(AudiobookProgress(
        audiobookId: 'book-1',
        chapterIndex: 2,
        positionMs: 10000,
        completed: false,
        lastPlayedAt: downloadedAt,
      ));

      expect(db.getProgress('book-1')?.positionMs, 10000);
      expect(db.allProgress(), hasLength(1));

      await db.deleteProgress('book-1');
      expect(db.getProgress('book-1'), isNull);
    });

    test('persiste la configuración del servidor y permite borrarla', () async {
      await db.saveServerConfig(const ServerConfig(serverUrl: 'http://a:4533'));
      expect(db.getServerConfig()?.serverUrl, 'http://a:4533');

      await db.clearServerConfig();
      expect(db.getServerConfig(), isNull);
    });

    test('los datos sobreviven a cerrar y reabrir las cajas', () async {
      await db.saveTrack(track('persist'));
      await db.saveProgress(AudiobookProgress(
        audiobookId: 'b',
        chapterIndex: 1,
        positionMs: 999,
        completed: true,
        lastPlayedAt: downloadedAt,
      ));
      await db.close();

      final reopened = LocalDatabaseService();
      await reopened.init(path: tempDir.path);
      addTearDown(reopened.close);

      expect(reopened.getTrack('persist')?.title, 'Título persist');
      expect(reopened.getProgress('b')?.completed, isTrue);
    });

    test('lee una caja "downloads" escrita con el formato antiguo', () async {
      await db.close();
      Hive.init(tempDir.path);
      final legacyBox = await Hive.openBox<Map>('downloads');
      await legacyBox.put('old', {
        'id': 'old',
        'title': 'Antigua',
        'artist': 'A',
        'album': 'B',
        'durationSeconds': 60,
        'suffix': 'mp3',
        'starred': false,
        'path': '/data/Documents/offline/old.mp3',
      });
      await legacyBox.close();

      final reopened = LocalDatabaseService();
      await reopened.init(path: tempDir.path);
      addTearDown(reopened.close);

      final migrated = reopened.getTrack('old');
      expect(migrated?.title, 'Antigua');
      expect(migrated?.relativePath, 'offline/old.mp3');
    });
  });
}
