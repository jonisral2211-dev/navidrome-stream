import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/navidrome_audio_handler.dart';
import '../../data/download/download_manager.dart';
import '../../data/local/credentials_store.dart';
import '../../data/local/local_database_service.dart';
import '../../data/subsonic/subsonic_auth.dart';
import '../../data/subsonic/subsonic_client.dart';
import '../../data/subsonic/subsonic_repository.dart';
import '../../domain/entities/music_entities.dart';
import '../../domain/repositories/music_repository.dart';
import '../controllers/playback_controller.dart';

/// Álbum o playlist: el registro de Dart 3 sirve como clave de family.
typedef CollectionRef = ({String kind, String id});

// --- Infraestructura inicializada en main() y sobrescrita en ProviderScope ---
final audioHandlerProvider = Provider<NavidromeAudioHandler>(
  (ref) => throw UnimplementedError('Sobrescribir en main()'),
);
final localDatabaseProvider = Provider<LocalDatabaseService>(
  (ref) => throw UnimplementedError('Sobrescribir en main()'),
);
final documentsPathProvider = Provider<String>(
  (ref) => throw UnimplementedError('Sobrescribir en main()'),
);

// --- Sesión ---
final credentialsStoreProvider = Provider<CredentialsStore>((ref) => CredentialsStore());
final serverSessionProvider = StateProvider<ServerSession?>((ref) => null);

/// Restaura la sesión guardada al arrancar.
final bootstrapProvider = FutureProvider<void>((ref) async {
  final saved = await ref.read(credentialsStoreProvider).load();
  if (saved != null) ref.read(serverSessionProvider.notifier).state = saved;
});

final musicRepositoryProvider = Provider<MusicRepository>((ref) {
  final session = ref.watch(serverSessionProvider);
  if (session == null) throw StateError('No hay sesión activa');
  return SubsonicRepository(
    SubsonicClient(
      serverUrl: session.serverUrl,
      auth: SubsonicAuth(username: session.username, password: session.password),
    ),
  );
});

// --- Descargas y reproducción ---
final downloadManagerProvider = ChangeNotifierProvider<DownloadManager>((ref) {
  return DownloadManager(
    db: ref.watch(localDatabaseProvider),
    documentsPath: ref.watch(documentsPathProvider),
    repository: ref.watch(musicRepositoryProvider),
  );
});

final playbackControllerProvider = Provider<PlaybackController>((ref) {
  return PlaybackController(
    handler: ref.watch(audioHandlerProvider),
    repository: ref.watch(musicRepositoryProvider),
    downloads: ref.watch(downloadManagerProvider),
    db: ref.watch(localDatabaseProvider),
  );
});

final playbackStateProvider = StreamProvider<PlaybackState>(
  (ref) => ref.watch(audioHandlerProvider).playbackState,
);

final mediaItemProvider = StreamProvider<MediaItem?>(
  (ref) => ref.watch(audioHandlerProvider).mediaItem,
);

// --- Datos de la biblioteca ---
final artistsProvider = FutureProvider<List<Artist>>(
  (ref) => ref.watch(musicRepositoryProvider).getArtists(),
);

final albumsProvider = FutureProvider.family<List<Album>, String>(
  (ref, type) => ref.watch(musicRepositoryProvider).getAlbums(type: type),
);

final playlistsProvider = FutureProvider<List<Playlist>>(
  (ref) => ref.watch(musicRepositoryProvider).getPlaylists(),
);

final collectionSongsProvider = FutureProvider.family<List<Song>, CollectionRef>((ref, c) {
  final repo = ref.watch(musicRepositoryProvider);
  return c.kind == 'album' ? repo.getAlbumSongs(c.id) : repo.getPlaylistSongs(c.id);
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider.family<SearchResult, String>(
  (ref, query) => ref.watch(musicRepositoryProvider).search(query),
);

/// URL de carátula o null. Se lee en build(); no provoca rebuilds por sí sola.
String? coverUrl(WidgetRef ref, String? coverArtId) => coverArtId == null
    ? null
    : ref.read(musicRepositoryProvider).getCoverArtUrl(coverArtId);
