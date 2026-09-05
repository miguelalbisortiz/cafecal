import 'package:flutter/foundation.dart';

import '../services/local_store.dart';
import '../services/supabase_service.dart';

enum SignUpResult { success, emailConfirmationRequired, failure }

class AuthProvider extends ChangeNotifier {
  final LocalStore _store;
  bool _isLoading = false;
  String? _error;
  bool _guestMode = false;

  AuthProvider(this._store) {
    _guestMode = _store.loadGuestMode();
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isGuest => _guestMode;

  bool get isLoggedIn => _guestMode || SupabaseService.instance.isAuthenticated;

  Future<void> init() async {
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    try {
      await SupabaseService.instance.signIn(email.trim(), password);
      await _exitGuestMode();
      _error = null;
      return true;
    } catch (e) {
      _error = _friendlyAuthError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<SignUpResult> signUp(String email, String password) async {
    _setLoading(true);
    try {
      final sessionCreated =
          await SupabaseService.instance.signUp(email.trim(), password);
      _error = null;
      return sessionCreated
          ? SignUpResult.success
          : SignUpResult.emailConfirmationRequired;
    } catch (e) {
      _error = _friendlyAuthError(e);
      return SignUpResult.failure;
    } finally {
      _setLoading(false);
    }
  }

  /// Modo visita: entra a la app sin cuenta. Los datos quedan solo en el
  /// dispositivo y no se sincronizan.
  Future<void> signInAsGuest() async {
    _guestMode = true;
    await _store.saveGuestMode(true);
    notifyListeners();
  }

  Future<void> signOut() async {
    await _exitGuestMode();
    await SupabaseService.instance.signOut();
    await _store.clearAll();
    notifyListeners();
  }

  Future<void> _exitGuestMode() async {
    _guestMode = false;
    await _store.saveGuestMode(false);
  }

  String _friendlyAuthError(Object e) {
    final msg = e.toString();
    if (msg.contains('Invalid login credentials')) {
      return 'Correo o contraseña incorrectos.';
    }
    if (msg.contains('Email not confirmed')) {
      return 'Tu correo aún no está confirmado. Revisa tu bandeja de entrada.';
    }
    if (msg.contains('already registered')) {
      return 'Ese correo ya está registrado. Inicia sesión.';
    }
    if (msg.contains('Password should be at least')) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }
    if (msg.contains('Unable to validate email')) {
      return 'Formato de correo inválido.';
    }
    if (msg.contains('network') || msg.contains('SocketException')) {
      return 'Sin conexión. Verifica tu internet e intenta de nuevo.';
    }
    return 'No se pudo completar la acción. Intenta de nuevo.';
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}