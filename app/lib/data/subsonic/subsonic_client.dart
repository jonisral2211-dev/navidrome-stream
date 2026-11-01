import 'package:dio/dio.dart';

import 'subsonic_auth.dart';

class SubsonicException implements Exception {
  const SubsonicException(this.code, this.message);

  final int code;
  final String message;

  @override
  String toString() => 'SubsonicException($code): $message';
}

/// Cliente HTTP de bajo nivel. Devuelve JSON crudo; el mapeo a entidades
/// vive en [SubsonicMapper] / [SubsonicRepository].
class SubsonicClient {
  SubsonicClient({
    required String serverUrl,
    required SubsonicAuth auth,
    Dio? dio,
  })  : _baseUrl = serverUrl.replaceAll(RegExp(r'/+$'), ''),
        _auth = auth,
        _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 30),
            ));

  final String _baseUrl;
  final SubsonicAuth _auth;
  final Dio _dio;

  Uri buildUri(String endpoint, [Map<String, String> extra = const {}]) =>
      Uri.parse('$_baseUrl/rest/$endpoint.view')
          .replace(queryParameters: {..._auth.authParams(), ...extra});

  Future<Map<String, dynamic>> _get(
    String endpoint, [
    Map<String, String> extra = const {},
  ]) async {
    final response =
        await _dio.getUri<Map<String, dynamic>>(buildUri(endpoint, extra));
    final root = response.data?['subsonic-response'] as Map<String, dynamic>?;
    if (root == null) {
      throw const SubsonicException(0, 'Respuesta inválida del servidor');
    }
    if (root['status'] != 'ok') {
      final error = root['error'] as Map<String, dynamic>? ?? const {};
      throw SubsonicException(
        error['code'] as int? ?? 0,
        error['message'] as String? ?? 'Error desconocido',
      );
    }
    return root;
  }

  static List<Map<String, dynamic>> _list(Object? value) =>
      (value as List?)?.cast<Map<String, dynamic>>() ?? const [];

  Future<void> ping() async {
    await _get('ping');
  }

  Future<List<Map<String, dynamic>>> fetchArtists() async {
    final root = await _get('getArtists');
    final indexes = _list((root['artists'] as Map?)?['index']);
    return [for (final index in indexes) ..._list(index['artist'])];
  }

  Future<List<Map<String, dynamic>>> fetchAlbums({
    String type = 'newest',
    int size = 100,
  }) async {
    final root = await _get('getAlbumList2', {'type': type, 'size': '$size'});
    return _list((root['albumList2'] as Map?)?['album']);
  }

  Future<List<Map<String, dynamic>>> fetchAlbumSongs(String albumId) async {
    final root = await _get('getAlbum', {'id': albumId});
    return _list((root['album'] as Map?)?['song']);
  }

  Future<List<Map<String, dynamic>>> fetchPlaylists() async {
    final root = await _get('getPlaylists');
    return _list((root['playlists'] as Map?)?['playlist']);
  }

  Future<List<Map<String, dynamic>>> fetchPlaylistSongs(String playlistId) async {
    final root = await _get('getPlaylist', {'id': playlistId});
    return _list((root['playlist'] as Map?)?['entry']);
  }

  Future<Map<String, List<Map<String, dynamic>>>> search(String query) async {
    final root = await _get('search3', {
      'query': query,
      'artistCount': '10',
      'albumCount': '20',
      'songCount': '50',
    });
    final result = (root['searchResult3'] as Map?) ?? const {};
    return {
      'artist': _list(result['artist']),
      'album': _list(result['album']),
      'song': _list(result['song']),
    };
  }

  Future<void> setStarred(String id, bool starred) async {
    await _get(starred ? 'star' : 'unstar', {'id': id});
  }

  /// Las URLs se construyen localmente (sin petición), así que son síncronas.
  String streamUrl(String songId, {bool original = false}) => buildUri(
        'stream',
        {'id': songId, if (original) 'format': 'raw'},
      ).toString();

  String coverArtUrl(String coverArtId, {int size = 600}) =>
      buildUri('getCoverArt', {'id': coverArtId, 'size': '$size'}).toString();
}
