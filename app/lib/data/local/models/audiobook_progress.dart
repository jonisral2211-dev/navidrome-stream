/// Posición de escucha de un audiolibro. Una fila por audiolibro.
class AudiobookProgress {
  const AudiobookProgress({
    required this.audiobookId,
    required this.chapterIndex,
    required this.positionMs,
    required this.completed,
    required this.lastPlayedAt,
  });

  final String audiobookId;

  /// Índice del capítulo (pista) actual dentro del audiolibro.
  final int chapterIndex;

  /// Posición dentro del capítulo, en milisegundos.
  final int positionMs;
  final bool completed;
  final DateTime lastPlayedAt;

  AudiobookProgress copyWith({
    int? chapterIndex,
    int? positionMs,
    bool? completed,
    DateTime? lastPlayedAt,
  }) =>
      AudiobookProgress(
        audiobookId: audiobookId,
        chapterIndex: chapterIndex ?? this.chapterIndex,
        positionMs: positionMs ?? this.positionMs,
        completed: completed ?? this.completed,
        lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      );

  Map<String, dynamic> toMap() => {
        'audiobookId': audiobookId,
        'chapterIndex': chapterIndex,
        'positionMs': positionMs,
        'completed': completed,
        'lastPlayedAt': lastPlayedAt.toUtc().millisecondsSinceEpoch,
      };

  factory AudiobookProgress.fromMap(Map<String, dynamic> map) => AudiobookProgress(
        audiobookId: map['audiobookId'] as String,
        chapterIndex: map['chapterIndex'] as int? ?? 0,
        positionMs: map['positionMs'] as int? ?? 0,
        completed: map['completed'] as bool? ?? false,
        lastPlayedAt: DateTime.fromMillisecondsSinceEpoch(
          map['lastPlayedAt'] as int? ?? 0,
          isUtc: true,
        ),
      );
}
