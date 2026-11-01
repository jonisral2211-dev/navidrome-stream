import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../providers/providers.dart';
import '../widgets/common_widgets.dart';
import '../widgets/song_tile.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloads = ref.watch(downloadManagerProvider);
    final playlists = ref.watch(playlistsProvider);
    final albums = ref.watch(albumsProvider('alphabeticalByName'));
    final artists = ref.watch(artistsProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const Text(
            'Tu Biblioteca',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Descargas: visibles y reproducibles sin conexión.
          const SectionTitle('Descargas'),
          ListenableBuilder(
            listenable: downloads,
            builder: (context, _) {
              final songs = downloads.downloads;
              if (songs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Aún no hay descargas',
                    style: TextStyle(color: AppColors.subtitle),
                  ),
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < songs.length; i++)
                    SongTile(
                      song: songs[i],
                      onTap: () => ref
                          .read(playbackControllerProvider)
                          .playSongs(songs, startIndex: i),
                    ),
                ],
              );
            },
          ),

          const SectionTitle('Playlists'),
          playlists.when(
            loading: () => const LoadingBox(),
            error: (e, _) => ErrorMessage('$e'),
            data: (list) => Column(
              children: [
                for (final p in list)
                  CollectionTile(
                    kind: 'playlist',
                    id: p.id,
                    title: p.name,
                    subtitle: '${p.songCount} canciones',
                    coverArtId: p.coverArtId,
                  ),
              ],
            ),
          ),

          const SectionTitle('Álbumes'),
          albums.when(
            loading: () => const LoadingBox(),
            error: (e, _) => ErrorMessage('$e'),
            data: (list) => Column(
              children: [
                for (final a in list)
                  CollectionTile(
                    kind: 'album',
                    id: a.id,
                    title: a.name,
                    subtitle: a.artist,
                    coverArtId: a.coverArtId,
                  ),
              ],
            ),
          ),

          const SectionTitle('Artistas'),
          artists.when(
            loading: () => const LoadingBox(),
            error: (e, _) => ErrorMessage('$e'),
            data: (list) => Column(
              children: [
                for (final a in list)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.card,
                      child: Icon(Icons.person, color: AppColors.subtitle),
                    ),
                    title: Text(a.name),
                    subtitle: Text(
                      '${a.albumCount} álbumes',
                      style: const TextStyle(color: AppColors.subtitle),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
