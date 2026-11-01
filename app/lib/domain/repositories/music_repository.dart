import '../entities/music_entities.dart';

/// Contrato que consume la capa de presentación. Permite cambiar la fuente
/// (Subsonic, otra API, mocks en tests) sin tocar la UI.
abstract interface class MusicRepository {
  Future<void> ping();
  Future<List<Artist>> getArtists();
  Future<List<Album>> getAlbums({String type = 'newest'});
  Future<List<Song>> getAlbumSongs(String albumId);
  Future<List<Playlist>> getPlaylists();
  Future<List<Song>> getPlaylistSongs(String playlistId);
  Future<SearchResult> search(String query);

  /// URL de streaming firmada. `original: true` pide el archivo sin transcodificar.
  String getSongStreamUrl(String songId, {bool original = false});
  String getCoverArtUrl(String coverArtId, {int size = 600});
  Future<void> setStarred(String songId, bool starred);
}
