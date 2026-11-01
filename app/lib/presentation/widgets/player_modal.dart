import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../providers/providers.dart';
import 'cover_image.dart';

/// Abre el reproductor a pantalla completa; se cierra arrastrando hacia abajo.
Future<void> showPlayerModal(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) => SizedBox(
      height: MediaQuery.sizeOf(sheetContext).height,
      child: const PlayerModal(),
    ),
  );
}

class PlayerModal extends ConsumerStatefulWidget {
  const PlayerModal({super.key});

  @override
  ConsumerState<PlayerModal> createState() => _PlayerModalState();
}

class _PlayerModalState extends ConsumerState<PlayerModal> {
  /// Valor mientras el usuario arrastra el slider (ms). Null = seguir la posición real.
  double? _dragValue;
  bool _starred = false;
  String? _starredFor;

  @override
  Widget build(BuildContext context) {
    final item = ref.watch(mediaItemProvider).valueOrNull;
    final state = ref.watch(playbackStateProvider).valueOrNull;
    if (item == null) return const SizedBox.shrink();

    final handler = ref.read(audioHandlerProvider);

    // Re-sincroniza el estado de favorito cuando cambia la pista.
    if (_starredFor != item.id) {
      _starredFor = item.id;
      _starred = item.extras?['starred'] == true;
    }

    final duration = item.duration ?? Duration.zero;
    final maxMs = duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1.0;
    final playing = state?.playing ?? false;
    final shuffleOn = state?.shuffleMode == AudioServiceShuffleMode.all;
    final repeat = state?.repeatMode ?? AudioServiceRepeatMode.none;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down, size: 32),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const Expanded(
                  child: Text(
                    'REPRODUCIENDO',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.subtitle, fontSize: 12, letterSpacing: 1.2),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 1,
              child: CoverImage(url: item.artUri?.toString(), radius: 12),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.artist ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.subtitle, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _starred ? Icons.favorite : Icons.favorite_border,
                    color: _starred ? AppColors.spotifyGreen : Colors.white,
                  ),
                  onPressed: () => _toggleStar(item.id),
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<Duration>(
              stream: AudioService.position,
              builder: (context, snap) {
                final position = snap.data ?? Duration.zero;
                final raw = _dragValue ?? position.inMilliseconds.toDouble();
                final current = raw > maxMs ? maxMs : raw;
                return Column(
                  children: [
                    Slider(
                      value: current,
                      max: maxMs,
                      onChanged: (v) => setState(() => _dragValue = v),
                      onChangeEnd: (v) {
                        handler.seek(Duration(milliseconds: v.round()));
                        setState(() => _dragValue = null);
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formatDuration(Duration(milliseconds: current.round())),
                          style: const TextStyle(color: AppColors.subtitle, fontSize: 12),
                        ),
                        Text(
                          formatDuration(duration),
                          style: const TextStyle(color: AppColors.subtitle, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.shuffle,
                    color: shuffleOn ? AppColors.spotifyGreen : AppColors.subtitle,
                  ),
                  onPressed: () => handler.setShuffleMode(
                    shuffleOn ? AudioServiceShuffleMode.none : AudioServiceShuffleMode.all,
                  ),
                ),
                IconButton(
                  iconSize: 40,
                  icon: const Icon(Icons.skip_previous),
                  onPressed: () => handler.skipToPrevious(),
                ),
                Container(
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: IconButton(
                    iconSize: 40,
                    color: Colors.black,
                    icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                    onPressed: () => playing ? handler.pause() : handler.play(),
                  ),
                ),
                IconButton(
                  iconSize: 40,
                  icon: const Icon(Icons.skip_next),
                  onPressed: () => handler.skipToNext(),
                ),
                IconButton(
                  icon: Icon(
                    repeat == AudioServiceRepeatMode.one ? Icons.repeat_one : Icons.repeat,
                    color: repeat == AudioServiceRepeatMode.none
                        ? AppColors.subtitle
                        : AppColors.spotifyGreen,
                  ),
                  onPressed: () => handler.setRepeatMode(_nextRepeat(repeat)),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// Optimista: cambia el icono al instante y revierte si el servidor falla.
  Future<void> _toggleStar(String songId) async {
    final next = !_starred;
    setState(() => _starred = next);
    try {
      await ref.read(musicRepositoryProvider).setStarred(songId, next);
    } catch (_) {
      if (mounted) setState(() => _starred = !next);
    }
  }

  static AudioServiceRepeatMode _nextRepeat(AudioServiceRepeatMode mode) => switch (mode) {
        AudioServiceRepeatMode.none => AudioServiceRepeatMode.all,
        AudioServiceRepeatMode.all => AudioServiceRepeatMode.one,
        _ => AudioServiceRepeatMode.none,
      };
}
