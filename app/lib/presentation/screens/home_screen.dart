import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../widgets/common_widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newest = ref.watch(albumsProvider('newest'));
    final playlists = ref.watch(playlistsProvider);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(albumsProvider('newest'));
          ref.invalidate(playlistsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            const Text(
              'Inicio',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const SectionTitle('Tus playlists'),
            playlists.when(
              loading: () => const LoadingBox(),
              error: (e, _) => ErrorMessage('$e'),
              data: (list) => Column(
                children: [
                  for (final p in list.take(6))
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
            const SizedBox(height: 16),
            const SectionTitle('Añadido recientemente'),
            newest.when(
              loading: () => const LoadingBox(),
              error: (e, _) => ErrorMessage('$e'),
              data: (albums) => GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.72,
                children: [for (final a in albums) AlbumCard(album: a)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
