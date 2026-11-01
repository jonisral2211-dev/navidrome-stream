import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'presentation/providers/providers.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/main_shell.dart';

class NavidromeApp extends ConsumerWidget {
  const NavidromeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boot = ref.watch(bootstrapProvider);
    final session = ref.watch(serverSessionProvider);

    final Widget home = switch ((boot.isLoading, session)) {
      (true, _) => const Scaffold(body: Center(child: CircularProgressIndicator())),
      (_, null) => const LoginScreen(),
      _ => const MainShell(),
    };

    return MaterialApp(
      title: 'Navidrome Stream',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: home,
    );
  }
}
