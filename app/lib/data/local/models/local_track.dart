import '../../../domain/entities/music_entities.dart';

/// Pista descargada en el dispositivo.
///
/// [relativePath] es relativa a la carpeta de documentos de la app
/// (p. ej. `offline/123.mp3`). iOS cambia la ruta absoluta del contenedor en
/// cada actualización, así que nunca se persiste una ruta absoluta.
class LocalTrack {
  const LocalTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.durationSeconds,
    required this.relativePath,
    required this.downloadedAt,
    this.albumId,
    this.coverArtId,
    this.trackNumber,
    this.suffix,
    this.starred = false,
  });

  final String id;
  final String title;
  final String artist;
  final String album;
  final int durationSeconds;
  final String relativePath;
  final DateTime downloadedAt;
  final String? albumId;
  final String? coverArtId;
  final int? trackNumber;
  final String? suffix;
  final bool starred;

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'artist': artist,
        'album': album,
        'durationSeconds': durationSeconds,
        'relativePath': relativePath,
        'downloadedAt': downloadedAt.toUtc().millisecondsSinceEpoch,
        'albumId': albumId,
        'coverArtId': coverArtId,
        'trackNumber': trackNumber,
        'suffix': suffix,
        'starred': starred,
      };

  /// Lee registros nuevos y también el formato antiguo de `DownloadStore`,
  /// que guardaba una `path` absoluta. De ese formato solo se conserva el
  /// nombre del archivo dentro de `offline/`.
  factory LocalTrack.fromMap(Map<String, dynamic> map) {
    final relative = map['relativePath'] as String? ?? _legacyRelativePath(map['path'] as String?);
    return LocalTrack(
      id: map['id'] as String,
      title: map['title'] as String,
      artist: map['artist'] as String,
      album: map['album'] as String,
      durationSeconds: map['durationSeconds'] as int? ?? 0,
      relativePath: relative,
      downloadedAt: map['downloadedAt'] is int
          ? DateTime.fromMillisecondsSinceEpoch(map['downloadedAt'] as int, isUtc: true)
          : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      albumId: map['albumId'] as String?,
      coverArtId: map['coverArtId'] as String?,
      trackNumber: map['trackNumber'] as int?,
      suffix: map['suffix'] as String?,
      starred: map['starred'] as bool? ?? false,
    );
  }

  /// Vista de dominio para reutilizar las listas existentes de la UI.
  Song toSong() => Song(
        id: id,
        title: title,
        artist: artist,
        album: album,
        albumId: albumId,
        coverArtId: coverArtId,
        durationSeconds: durationSeconds,
        trackNumber: trackNumber,
        suffix: suffix,
        starred: starred,
      );

  static String _legacyRelativePath(String? absolute) {
    if (absolute == null) throw ArgumentError('Falta relativePath y path');
    final name = absolute.split(RegExp(r'[\\/]')).last;
    return 'offline/$name';
  }
}
