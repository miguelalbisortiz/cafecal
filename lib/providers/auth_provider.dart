import 'package:flutter/foundation.dart';

import '../services/local_store.dart';
import '../services/supabase_service.dart';

enum SignUpResult { success, emailConfirmationRequired, failure }

class AuthProvider extends ChangeNotifier {
  final LocalStore _store;
  final Future<void> Function()? onUserChanged;
  bool _isLoading = false;
  String? _error;

  AuthProvider(this._store, {this.onUserChanged});

  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get isLoggedIn => SupabaseService.instance.isAuthenticated;

  Future<void> _bindCurrentUser() async {
    await _store.bindUser(SupabaseService.instance.currentUserId);
    await onUserChanged?.call();
  }

  Future<void> init() async {
    await _bindCurrentUser();
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    try {
      await SupabaseService.instance.signIn(email.trim(), password);
      await _bindCurrentUser();
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
      await _bindCurrentUser();
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

  /// Envía el correo de recuperación de contraseña. Devuelve `true` si
  /// Supabase aceptó el envío (el correo puede tardar unos minutos).
  Future<bool> sendPasswordRecovery(String email) async {
    try {
      await SupabaseService.instance.sendPasswordRecovery(email.trim());
      _error = null;
      return true;
    } catch (e) {
      _error = _friendlyAuthError(e);
      return false;
    }
  }

  Future<void> signOut() async {
    await SupabaseService.instance.signOut();
    await _store.clearAll();
    // Cierra el namespace del usuario saliente: si entra otra cuenta, la
    // sesión local arranca limpia y solo ve sus propios datos (H1).
    await _store.bindUser(null);
    notifyListeners();
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