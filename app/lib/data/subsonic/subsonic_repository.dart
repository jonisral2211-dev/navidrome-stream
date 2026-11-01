import '../../domain/entities/music_entities.dart';
import '../../domain/repositories/music_repository.dart';
import 'subsonic_client.dart';
import 'subsonic_mapper.dart';

class SubsonicRepository implements MusicRepository {
  SubsonicRepository(this._client);

  final SubsonicClient _client;

  @override
  Future<void> ping() => _client.ping();

  @override
  Future<List<Artist>> getArtists() async =>
      (await _client.fetchArtists()).map(SubsonicMapper.artist).toList();

  @override
  Future<List<Album>> getAlbums({String type = 'newest'}) async =>
      (await _client.fetchAlbums(type: type)).map(SubsonicMapper.album).toList();

  @override
  Future<List<Song>> getAlbumSongs(String albumId) async =>
      (await _client.fetchAlbumSongs(albumId)).map(SubsonicMapper.song).toList();

  @override
  Future<List<Playlist>> getPlaylists() async =>
      (await _client.fetchPlaylists()).map(SubsonicMapper.playlist).toList();

  @override
  Future<List<Song>> getPlaylistSongs(String playlistId) async =>
      (await _client.fetchPlaylistSongs(playlistId))
          .map(SubsonicMapper.song)
          .toList();

  @override
  Future<SearchResult> search(String query) async {
    final raw = await _client.search(query);
    return SearchResult(
      artists: raw['artist']!.map(SubsonicMapper.artist).toList(),
      albums: raw['album']!.map(SubsonicMapper.album).toList(),
      songs: raw['song']!.map(SubsonicMapper.song).toList(),
    );
  }

  @override
  String getSongStreamUrl(String songId, {bool original = false}) =>
      _client.streamUrl(songId, original: original);

  @override
  String getCoverArtUrl(String coverArtId, {int size = 600}) =>
      _client.coverArtUrl(coverArtId, size: size);

  @override
  Future<void> setStarred(String songId, bool starred) =>
      _client.setStarred(songId, starred);
}
