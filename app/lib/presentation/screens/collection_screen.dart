import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../providers/providers.dart';
import '../widgets/common_widgets.dart';
import '../widgets/cover_image.dart';
import '../widgets/song_tile.dart';

/// Detalle de álbum o playlist: carátula, reproducir y lista de canciones.
class CollectionScreen extends ConsumerWidget {
  const CollectionScreen({
    super.key,
    required this.kind,
    required this.id,
    required this.title,
    this.coverArtId,
  });

  /// 'album' | 'playlist'
  final String kind;
  final String id;
  final String title;
  final String? coverArtId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songs = ref.watch(collectionSongsProvider((kind: kind, id: id)));

    return Scaffold(
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: songs.when(
        loading: () => const LoadingBox(),
        error: (e, _) => ErrorMessage('$e'),
        data: (list) => ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: 220,
                  height: 220,
                  child: CoverImage(url: coverUrl(ref, coverArtId), radius: 8),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.spotifyGreen,
                      foregroundColor: Colors.black,
                      iconSize: 32,
                    ),
                    icon: const Icon(Icons.play_arrow),
                    onPressed: list.isEmpty
                        ? null
                        : () => ref.read(playbackControllerProvider).playSongs(list),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.download_outlined),
                    tooltip: 'Descargar todo',
                    onPressed: list.isEmpty
                        ? null
                        : () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final failed = await ref
                                .read(downloadManagerProvider)
                                .downloadAll(list);
                            messenger.showSnackBar(SnackBar(
                              content: Text(failed == 0
                                  ? 'Descarga completa'
                                  : '$failed canciones fallaron'),
                            ));
                          },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < list.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SongTile(
                  song: list[i],
                  onTap: () => ref
                      .read(playbackControllerProvider)
                      .playSongs(list, startIndex: i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
