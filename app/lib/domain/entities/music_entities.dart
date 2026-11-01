// Entidades de dominio: sin dependencias de Flutter ni de la API concreta.

class ServerSession {
  const ServerSession({
    required this.serverUrl,
    required this.username,
    required this.password,
  });

  final String serverUrl;
  final String username;
  final String password;
}

class Artist {
  const Artist({
    required this.id,
    required this.name,
    this.coverArtId,
    this.albumCount = 0,
  });

  final String id;
  final String name;
  final String? coverArtId;
  final int albumCount;
}

class Album {
  const Album({
    required this.id,
    required this.name,
    required this.artist,
    this.artistId,
    this.coverArtId,
    this.year,
    this.songCount = 0,
  });

  final String id;
  final String name;
  final String artist;
  final String? artistId;
  final String? coverArtId;
  final int? year;
  final int songCount;
}

class Song {
  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    this.albumId,
    this.coverArtId,
    this.durationSeconds = 0,
    this.trackNumber,
    this.suffix,
    this.starred = false,
  });

  final String id;
  final String title;
  final String artist;
  final String album;
  final String? albumId;
  final String? coverArtId;
  final int durationSeconds;
  final int? trackNumber;

  /// Extensión original del archivo (mp3, flac, ...).
  final String? suffix;
  final bool starred;

  /// Serialización para persistir metadatos de descargas en Hive.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'album': album,
        'albumId': albumId,
        'coverArtId': coverArtId,
        'durationSeconds': durationSeconds,
        'trackNumber': trackNumber,
        'suffix': suffix,
        'starred': starred,
      };

  factory Song.fromJson(Map<String, dynamic> json) => Song(
        id: json['id'] as String,
        title: json['title'] as String,
        artist: json['artist'] as String,
        album: json['album'] as String,
        albumId: json['albumId'] as String?,
        coverArtId: json['coverArtId'] as String?,
        durationSeconds: json['durationSeconds'] as int? ?? 0,
        trackNumber: json['trackNumber'] as int?,
        suffix: json['suffix'] as String?,
        starred: json['starred'] as bool? ?? false,
      );
}

class Playlist {
  const Playlist({
    required this.id,
    required this.name,
    this.songCount = 0,
    this.coverArtId,
  });

  final String id;
  final String name;
  final int songCount;
  final String? coverArtId;
}

class SearchResult {
  const SearchResult({
    this.artists = const [],
    this.albums = const [],
    this.songs = const [],
  });

  final List<Artist> artists;
  final List<Album> albums;
  final List<Song> songs;
}
