import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/music_entities.dart';
import '../providers/providers.dart';
import 'cover_image.dart';

class SongTile extends ConsumerWidget {
  const SongTile({super.key, required this.song, required this.onTap});

  final Song song;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: CoverImage(url: coverUrl(ref, song.coverArtId), size: 48),
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        song.artist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppColors.subtitle),
      ),
      trailing: DownloadButton(song: song),
    );
  }
}

/// Descargar / quitar descarga, con progreso circular mientras baja.
class DownloadButton extends ConsumerWidget {
  const DownloadButton({super.key, required this.song});

  final Song song;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manager = ref.watch(downloadManagerProvider);

    return ListenableBuilder(
      listenable: manager,
      builder: (context, _) {
        final progress = manager.progressOf(song.id);
        if (progress != null) {
          return SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.spotifyGreen,
              // 0 = tamaño desconocido -> indicador indeterminado
              value: progress > 0 ? progress : null,
            ),
          );
        }

        final done = manager.isDownloaded(song.id);
        return IconButton(
          icon: Icon(
            done ? Icons.check_circle : Icons.download_for_offline_outlined,
            color: done ? AppColors.spotifyGreen : AppColors.subtitle,
          ),
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            try {
              if (done) {
                await manager.remove(song.id);
              } else {
                await manager.download(song);
              }
            } catch (e) {
              messenger.showSnackBar(
                SnackBar(content: Text('Error en la descarga: $e')),
              );
            }
          },
        );
      },
    );
  }
}
