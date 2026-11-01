import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../providers/providers.dart';
import 'cover_image.dart';
import 'player_modal.dart';

/// Barra persistente justo encima del menú inferior. Se oculta sin reproducción.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(mediaItemProvider).valueOrNull;
    if (item == null) return const SizedBox.shrink();

    final playing = ref.watch(playbackStateProvider).valueOrNull?.playing ?? false;
    final handler = ref.read(audioHandlerProvider);

    return Material(
      color: AppColors.card,
      child: InkWell(
        onTap: () => showPlayerModal(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              CoverImage(url: item.artUri?.toString(), size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      item.artist ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.subtitle, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(playing ? Icons.pause : Icons.play_arrow, size: 32),
                onPressed: () => playing ? handler.pause() : handler.play(),
              ),
              IconButton(
                icon: const Icon(Icons.skip_next, size: 30),
                onPressed: () => handler.skipToNext(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
