import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/subsonic/subsonic_auth.dart';
import '../../data/subsonic/subsonic_client.dart';
import '../../data/subsonic/subsonic_repository.dart';
import '../../domain/entities/music_entities.dart';
import '../providers/providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _url = TextEditingController(text: 'http://100.x.y.z:4533');
  final _user = TextEditingController();
  final _pass = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _url.dispose();
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);

    final session = ServerSession(
      serverUrl: _url.text.trim(),
      username: _user.text.trim(),
      password: _pass.text,
    );
    try {
      final repo = SubsonicRepository(
        SubsonicClient(
          serverUrl: session.serverUrl,
          auth: SubsonicAuth(username: session.username, password: session.password),
        ),
      );
      await repo.ping();
      await ref.read(credentialsStoreProvider).save(session);
      // Cambiar la sesión hace que la raíz muestre MainShell y desmonte esta pantalla.
      ref.read(serverSessionProvider.notifier).state = session;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo conectar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 32),
              const Text(
                'Navidrome Stream',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Usa la IP de Tailscale de tu servidor, p. ej. http://100.x.y.z:4533',
                style: TextStyle(color: AppColors.subtitle),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _url,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(labelText: 'URL del servidor'),
                validator: (v) => (v == null || !v.startsWith('http'))
                    ? 'Incluye http:// o https://'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _user,
                decoration: const InputDecoration(labelText: 'Usuario'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Obligatorio' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pass,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Contraseña'),
                validator: (v) => (v == null || v.isEmpty) ? 'Obligatorio' : null,
              ),
              const SizedBox(height: 32),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.spotifyGreen,
                  foregroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(52),
                ),
                onPressed: _busy ? null : _connect,
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Text('Conectar', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
