import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/music_entities.dart';
import '../../domain/repositories/music_repository.dart';
import '../local/local_database_service.dart';
import '../local/models/local_track.dart';

/// Descarga canciones a `<documentos>/offline/` y registra su metadata en
/// [LocalDatabaseService]. Es un ChangeNotifier para que la UI reaccione.
class DownloadManager extends ChangeNotifier {
  DownloadManager({
    required this.db,
    required this.repository,
    required this.documentsPath,
    Dio? dio,
  }) : _dio = dio ?? Dio();

  final LocalDatabaseService db;
  final MusicRepository repository;

  /// Carpeta de documentos de la app (`getApplicationDocumentsDirectory`).
  /// Se inyecta para que la resolución de rutas sea síncrona y testeable.
  final String documentsPath;
  final Dio _dio;

  /// songId -> progreso 0..1 (0 mientras no se conoce el tamaño).
  final Map<String, double> _progress = {};

  List<Song> get downloads => db.allTracks().map((t) => t.toSong()).toList();

  bool isDownloaded(String songId) => db.hasTrack(songId);

  double? progressOf(String songId) => _progress[songId];

  /// Ruta absoluta del archivo local, o null si no está descargado o el
  /// archivo ya no existe. Si devuelve null, la reproducción usa streaming.
  String? localPathFor(String songId) {
    final track = db.getTrack(songId);
    if (track == null) return null;
    final path = _absolute(track.relativePath);
    return File(path).existsSync() ? path : null;
  }

  Future<void> download(Song song) async {
    if (isDownloaded(song.id) || _progress.containsKey(song.id)) return;

    final relative = 'offline/${song.id}.${_extension(song.suffix)}';
    final path = _absolute(relative);
    await Directory(_absolute('offline')).create(recursive: true);

    _progress[song.id] = 0;
    notifyListeners();
    try {
      await _dio.download(
        repository.getSongStreamUrl(song.id, original: true),
        path,
        onReceiveProgress: (received, total) {
          if (total <= 0) return;
          _progress[song.id] = received / total;
          notifyListeners();
        },
      );
      await db.saveTrack(LocalTrack(
        id: song.id,
        title: song.title,
        artist: song.artist,
        album: song.album,
        durationSeconds: song.durationSeconds,
        relativePath: relative,
        downloadedAt: DateTime.now().toUtc(),
        albumId: song.albumId,
        coverArtId: song.coverArtId,
        trackNumber: song.trackNumber,
        suffix: song.suffix,
        starred: song.starred,
      ));
    } catch (_) {
      final partial = File(path);
      if (await partial.exists()) await partial.delete();
      rethrow;
    } finally {
      _progress.remove(song.id);
      notifyListeners();
    }
  }

  /// Descarga en secuencia. Devuelve cuántas canciones fallaron.
  Future<int> downloadAll(List<Song> songs) async {
    var failed = 0;
    for (final song in songs) {
      try {
        await download(song);
      } catch (_) {
        failed++;
      }
    }
    return failed;
  }

  Future<void> remove(String songId) async {
    final track = db.getTrack(songId);
    if (track != null) {
      final file = File(_absolute(track.relativePath));
      if (await file.exists()) await file.delete();
    }
    await db.deleteTrack(songId);
    notifyListeners();
  }

  String _absolute(String relative) => '$documentsPath/$relative';

  static String _extension(String? suffix) {
    final clean = (suffix ?? '').replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    return clean.isEmpty ? 'mp3' : clean;
  }
}
