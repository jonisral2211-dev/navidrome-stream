import '../../domain/entities/music_entities.dart';

/// Convierte el JSON de Subsonic en entidades de dominio.
abstract final class SubsonicMapper {
  static String _str(Object? value) => value?.toString() ?? '';

  static Artist artist(Map<String, dynamic> j) => Artist(
        id: _str(j['id']),
        name: j['name'] as String? ?? '',
        coverArtId: j['coverArt'] as String?,
        albumCount: j['albumCount'] as int? ?? 0,
      );

  static Album album(Map<String, dynamic> j) => Album(
        id: _str(j['id']),
        name: j['name'] as String? ?? j['title'] as String? ?? '',
        artist: j['artist'] as String? ?? '',
        artistId: j['artistId'] == null ? null : _str(j['artistId']),
        coverArtId: j['coverArt'] as String?,
        year: j['year'] as int?,
        songCount: j['songCount'] as int? ?? 0,
      );

  static Song song(Map<String, dynamic> j) => Song(
        id: _str(j['id']),
        title: j['title'] as String? ?? '',
        artist: j['artist'] as String? ?? '',
        album: j['album'] as String? ?? '',
        albumId: j['albumId'] == null ? null : _str(j['albumId']),
        coverArtId: j['coverArt'] as String?,
        durationSeconds: j['duration'] as int? ?? 0,
        trackNumber: j['track'] as int?,
        suffix: j['suffix'] as String?,
        starred: j['starred'] != null,
      );

  static Playlist playlist(Map<String, dynamic> j) => Playlist(
        id: _str(j['id']),
        name: j['name'] as String? ?? '',
        songCount: j['songCount'] as int? ?? 0,
        coverArtId: j['coverArt'] as String?,
      );
}
