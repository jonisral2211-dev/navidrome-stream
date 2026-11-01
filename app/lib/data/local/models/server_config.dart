/// Configuración del servidor y preferencias del usuario. Hay un único registro.
///
/// AVISO: [sessionToken] se guarda en Hive, que no está cifrado. Las
/// credenciales reales siguen en el Keychain/Keystore (CredentialsStore); no
/// dupliques contraseñas aquí.
class ServerConfig {
  const ServerConfig({
    required this.serverUrl,
    this.sessionToken,
    this.preferences = const {},
  });

  final String serverUrl;
  final String? sessionToken;

  /// Preferencias libres (p. ej. `{'theme': 'dark', 'streamFormat': 'mp3'}`).
  final Map<String, dynamic> preferences;

  ServerConfig copyWith({
    String? serverUrl,
    String? sessionToken,
    Map<String, dynamic>? preferences,
  }) =>
      ServerConfig(
        serverUrl: serverUrl ?? this.serverUrl,
        sessionToken: sessionToken ?? this.sessionToken,
        preferences: preferences ?? this.preferences,
      );

  Map<String, dynamic> toMap() => {
        'serverUrl': serverUrl,
        'sessionToken': sessionToken,
        'preferences': preferences,
      };

  factory ServerConfig.fromMap(Map<String, dynamic> map) => ServerConfig(
        serverUrl: map['serverUrl'] as String,
        sessionToken: map['sessionToken'] as String?,
        preferences: Map<String, dynamic>.from(
          (map['preferences'] as Map?) ?? const {},
        ),
      );
}
