import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService instance = SupabaseService._();

  SupabaseService._();

  SupabaseClient get client => Supabase.instance.client;

  static String get _envUrl =>
      const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static String get _envKey =>
      const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  /// Inicializa el cliente. Lee desde --dart-define en compilación.
  /// Si los valores vienen vacíos, cae en un modo local (sin nube) para
  /// permitir desarrollo offline sin backend.
  Future<void> init() async {
    final url = _envUrl;
    final key = _envKey;
    if (url.isEmpty || key.isEmpty) {
      debugPrint(
        '[SupabaseService] sin claves — modo local/offline. '
        'Pasá --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...',
      );
      return;
    }
    await Supabase.initialize(
      url: url,
      publishableKey: key,
    );
  }

  bool get isConfigured {
    final url = _envUrl;
    final key = _envKey;
    return url.isNotEmpty && key.isNotEmpty;
  }

  bool get isAuthenticated {
    if (!isConfigured) return false;
    try {
      return client.auth.currentSession != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> signIn(String email, String password) async {
    await client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUp(String email, String password) async {
    await client.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }
}