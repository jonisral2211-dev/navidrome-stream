import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'core/audio/navidrome_audio_handler.dart';
import 'data/local/local_database_service.dart';
import 'data/local/models/audiobook_progress.dart';
import 'presentation/providers/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Sesión de audio "music": ducking y pausa al recibir llamadas.
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());

  final db = LocalDatabaseService();
  await db.init();
  final documents = await getApplicationDocumentsDirectory();

  final audioHandler = await AudioService.init(
    builder: NavidromeAudioHandler.new,
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.navidrome_stream.audio',
      androidNotificationChannelName: 'Reproducción',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

  // Progreso de audiolibros -> base de datos local (cada 5 s y al pausar).
  audioHandler.onAudiobookProgress = (audiobookId, chapterIndex, positionMs, completed) =>
      db.saveProgress(AudiobookProgress(
        audiobookId: audiobookId,
        chapterIndex: chapterIndex,
        positionMs: positionMs,
        completed: completed,
        lastPlayedAt: DateTime.now().toUtc(),
      ));

  runApp(
    ProviderScope(
      overrides: [
        audioHandlerProvider.overrideWithValue(audioHandler),
        localDatabaseProvider.overrideWithValue(db),
        documentsPathProvider.overrideWithValue(documents.path),
      ],
      child: const NavidromeApp(),
    ),
  );
}
