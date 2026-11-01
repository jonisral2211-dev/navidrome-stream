import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/// Se llama con el estado de un audiolibro: cada 5 s mientras suena y al pausar.
/// [completed] es true solo al terminar el último capítulo.
typedef AudiobookProgressCallback = Future<void> Function(
  String audiobookId,
  int chapterIndex,
  int positionMs,
  bool completed,
);

const _progressInterval = Duration(seconds: 5);

const _processingStates = {
  ProcessingState.idle: AudioProcessingState.idle,
  ProcessingState.loading: AudioProcessingState.loading,
  ProcessingState.buffering: AudioProcessingState.buffering,
  ProcessingState.ready: AudioProcessingState.ready,
  ProcessingState.completed: AudioProcessingState.completed,
};

/// Puente entre just_audio y audio_service.
/// Gestiona la cola, el segundo plano, la pantalla de bloqueo y la notificación nativa.
///
/// Cada [MediaItem] lleva en `extras['url']` la fuente ya resuelta:
/// una ruta local (descarga) o una URL http(s) de streaming.
/// Así este handler no depende de repositorios ni de descargas.
class NavidromeAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  NavidromeAudioHandler() {
    _player.playbackEventStream.listen(
      (_) => _broadcastState(),
      onError: (_, __) => playbackState.add(
        playbackState.value.copyWith(processingState: AudioProcessingState.error),
      ),
    );

    // Progreso de audiolibros: timer de 5 s mientras suena; al pausar, guarda al momento.
    _player.playingStream.listen((playing) {
      if (playing) {
        _progressTimer ??= Timer.periodic(_progressInterval, (_) => reportAudiobookProgress());
      } else {
        _progressTimer?.cancel();
        _progressTimer = null;
        reportAudiobookProgress();
      }
    });

    _player.currentIndexStream.listen((index) {
      final items = queue.value;
      if (index != null && index < items.length) mediaItem.add(items[index]);
    });

    // Cuando se conoce la duración real, la reflejamos en la notificación.
    _player.durationStream.listen((duration) {
      final index = _player.currentIndex;
      final items = queue.value;
      if (duration == null || index == null || index >= items.length) return;
      final updated = [...items];
      updated[index] = items[index].copyWith(duration: duration);
      queue.add(updated);
      mediaItem.add(updated[index]);
    });
  }

  final _player = AudioPlayer();

  /// Destino del progreso de audiolibros. Lo fija main() con la base de datos local.
  AudiobookProgressCallback? onAudiobookProgress;

  Timer? _progressTimer;

  /// Carga una cola y la deja lista (sin reproducir).
  /// [initialPosition] reanuda dentro de [startIndex] (usado para continuar audiolibros).
  Future<void> loadQueue(
    List<MediaItem> items, {
    int startIndex = 0,
    Duration initialPosition = Duration.zero,
  }) async {
    queue.add(items);
    mediaItem.add(items[startIndex]);
    await _player.setAudioSource(
      ConcatenatingAudioSource(children: items.map(_toSource).toList()),
      initialIndex: startIndex,
      initialPosition: initialPosition,
    );
  }

  /// Guarda la posición actual si la pista que suena pertenece a un audiolibro.
  Future<void> reportAudiobookProgress() async {
    final callback = onAudiobookProgress;
    final index = _player.currentIndex;
    final items = queue.value;
    if (callback == null || index == null || index >= items.length) return;

    final audiobookId = items[index].extras?['audiobookId'] as String?;
    if (audiobookId == null) return;

    final completed = _player.processingState == ProcessingState.completed &&
        index == items.length - 1;
    await callback(audiobookId, index, _player.position.inMilliseconds, completed);
  }

  AudioSource _toSource(MediaItem item) {
    final url = item.extras!['url'] as String;
    return url.startsWith('http')
        ? AudioSource.uri(Uri.parse(url), tag: item)
        : AudioSource.file(url, tag: item);
  }

  void _broadcastState() {
    final playing = _player.playing;
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: _processingStates[_player.processingState]!,
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: _player.currentIndex,
    ));
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  /// Sin límite de saltos: cada pulsación avanza de verdad.
  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  @override
  Future<void> skipToQueueItem(int index) => _player.seek(Duration.zero, index: index);

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    final enabled = shuffleMode != AudioServiceShuffleMode.none;
    if (enabled) await _player.shuffle();
    await _player.setShuffleModeEnabled(enabled);
    playbackState.add(playbackState.value.copyWith(shuffleMode: shuffleMode));
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    final loop = switch (repeatMode) {
      AudioServiceRepeatMode.none => LoopMode.off,
      AudioServiceRepeatMode.one => LoopMode.one,
      _ => LoopMode.all,
    };
    await _player.setLoopMode(loop);
    playbackState.add(playbackState.value.copyWith(repeatMode: repeatMode));
  }

  @override
  Future<void> stop() async {
    await reportAudiobookProgress();
    _progressTimer?.cancel();
    _progressTimer = null;
    await _player.stop();
    await super.stop();
  }
}
