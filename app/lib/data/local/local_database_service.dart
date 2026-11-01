import 'package:hive_flutter/hive_flutter.dart';

import 'models/audiobook_progress.dart';
import 'models/local_track.dart';
import 'models/server_config.dart';

/// Repositorio local sobre Hive. Es la única capa que toca las cajas.
///
/// Cajas:
/// - `downloads`: [LocalTrack] (la misma caja que usaba DownloadStore, para no
///   perder descargas existentes).
/// - `audiobook_progress`: [AudiobookProgress], clave = audiobookId.
/// - `server_config`: [ServerConfig], clave única `current`.
class LocalDatabaseService {
  static const _tracksBox = 'downloads';
  static const _progressBox = 'audiobook_progress';
  static const _configBox = 'server_config';
  static const _configKey = 'current';

  late final Box<Map> _tracks;
  late final Box<Map> _progress;
  late final Box<Map> _config;

  /// Abre las cajas. [path] solo se usa en tests; en la app se usa el
  /// directorio de documentos de la plataforma.
  Future<void> init({String? path}) async {
    if (path != null) {
      Hive.init(path);
    } else {
      await Hive.initFlutter();
    }
    _tracks = await Hive.openBox<Map>(_tracksBox);
    _progress = await Hive.openBox<Map>(_progressBox);
    _config = await Hive.openBox<Map>(_configBox);
  }

  Future<void> close() => Hive.close();

  // --- Pistas descargadas ---------------------------------------------------

  bool hasTrack(String id) => _tracks.containsKey(id);

  LocalTrack? getTrack(String id) {
    final raw = _tracks.get(id);
    return raw == null ? null : LocalTrack.fromMap(Map<String, dynamic>.from(raw));
  }

  List<LocalTrack> allTracks() => _tracks.values
      .map((m) => LocalTrack.fromMap(Map<String, dynamic>.from(m)))
      .toList();

  Future<void> saveTrack(LocalTrack track) => _tracks.put(track.id, track.toMap());

  Future<void> deleteTrack(String id) => _tracks.delete(id);

  // --- Progreso de audiolibros ----------------------------------------------

  AudiobookProgress? getProgress(String audiobookId) {
    final raw = _progress.get(audiobookId);
    return raw == null ? null : AudiobookProgress.fromMap(Map<String, dynamic>.from(raw));
  }

  List<AudiobookProgress> allProgress() => _progress.values
      .map((m) => AudiobookProgress.fromMap(Map<String, dynamic>.from(m)))
      .toList();

  Future<void> saveProgress(AudiobookProgress progress) =>
      _progress.put(progress.audiobookId, progress.toMap());

  Future<void> deleteProgress(String audiobookId) => _progress.delete(audiobookId);

  // --- Configuración del servidor -------------------------------------------

  ServerConfig? getServerConfig() {
    final raw = _config.get(_configKey);
    return raw == null ? null : ServerConfig.fromMap(Map<String, dynamic>.from(raw));
  }

  Future<void> saveServerConfig(ServerConfig config) =>
      _config.put(_configKey, config.toMap());

  Future<void> clearServerConfig() => _config.delete(_configKey);
}
