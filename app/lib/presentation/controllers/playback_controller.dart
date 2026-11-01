import 'dart:math' as math;

import 'package:audio_service/audio_service.dart';

import '../../core/audio/navidrome_audio_handler.dart';
import '../../data/download/download_manager.dart';
import '../../data/local/local_database_service.dart';
import '../../domain/entities/music_entities.dart';
import '../../domain/repositories/music_repository.dart';

/// Traduce entidades de dominio a [MediaItem] y decide la fuente de cada pista:
/// descarga local si existe, streaming en otro caso.
class PlaybackController {
  PlaybackController({
    required this.handler,
    required this.repository,
    required this.downloads,
    required this.db,
  });

  final NavidromeAudioHandler handler;
  final MusicRepository repository;
  final DownloadManager downloads;
  final LocalDatabaseService db;

  Future<void> playSongs(List<Song> songs, {int startIndex = 0}) async {
    if (songs.isEmpty) return;
    await handler.loadQueue(
      songs.map((s) => _toMediaItem(s)).toList(),
      startIndex: startIndex,
    );
    await handler.play();
  }

  /// Reproduce un audiolibro (capítulos = pistas) y reanuda donde se quedó.
  /// Si el audiolibro ya estaba terminado, empieza desde el principio.
  Future<void> playAudiobook(String audiobookId, List<Song> chapters) async {
    if (chapters.isEmpty) return;

    final saved = db.getProgress(audiobookId);
    var index = 0;
    var position = Duration.zero;
    if (saved != null && !saved.completed) {
      index = math.min(saved.chapterIndex, chapters.length - 1);
      position = Duration(milliseconds: saved.positionMs);
    }

    await handler.loadQueue(
      chapters.map((s) => _toMediaItem(s, audiobookId: audiobookId)).toList(),
      startIndex: index,
      initialPosition: position,
    );
    await handler.play();
  }

  MediaItem _toMediaItem(Song song, {String? audiobookId}) {
    final local = downloads.localPathFor(song.id);
    final cover = song.coverArtId == null
        ? null
        : repository.getCoverArtUrl(song.coverArtId!);

    return MediaItem(
      id: song.id,
      title: song.title,
      artist: song.artist,
      album: song.album,
      duration: Duration(seconds: song.durationSeconds),
      artUri: cover == null ? null : Uri.tryParse(cover),
      extras: {
        // Descarga local si existe (sin red); streaming en otro caso.
        'url': local ?? repository.getSongStreamUrl(song.id),
        'starred': song.starred,
        if (audiobookId != null) 'audiobookId': audiobookId,
      },
    );
  }
}
