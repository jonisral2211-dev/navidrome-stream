import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../providers/providers.dart';
import '../widgets/common_widgets.dart';
import '../widgets/song_tile.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  /// Espera a que el usuario pare de escribir antes de consultar al servidor.
  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(searchQueryProvider.notifier).state = value.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              onChanged: _onChanged,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                hintText: 'Artistas, canciones o álbumes',
                hintStyle: const TextStyle(color: Colors.black54),
                prefixIcon: const Icon(Icons.search, color: Colors.black),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: query.isEmpty
                ? const Center(
                    child: Text(
                      'Busca tu música',
                      style: TextStyle(color: AppColors.subtitle),
                    ),
                  )
                : _Results(query: query),
          ),
        ],
      ),
    );
  }
}

class _Results extends ConsumerWidget {
  const _Results({required this.query});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(searchResultsProvider(query));

    return results.when(
      loading: () => const LoadingBox(),
      error: (e, _) => ErrorMessage('$e'),
      data: (r) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          if (r.songs.isNotEmpty) const SectionTitle('Canciones'),
          for (var i = 0; i < r.songs.length; i++)
            SongTile(
              song: r.songs[i],
              onTap: () => ref.read(playbackControllerProvider).playSongs(r.songs, startIndex: i),
            ),
          if (r.albums.isNotEmpty) const SectionTitle('Álbumes'),
          for (final a in r.albums)
            CollectionTile(
              kind: 'album',
              id: a.id,
              title: a.name,
              subtitle: a.artist,
              coverArtId: a.coverArtId,
            ),
          if (r.artists.isNotEmpty) const SectionTitle('Artistas'),
          for (final a in r.artists)
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
          if (r.songs.isEmpty && r.albums.isEmpty && r.artists.isEmpty)
            const ErrorMessage('Sin resultados'),
        ],
      ),
    );
  }
}
