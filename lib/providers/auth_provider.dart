import 'package:flutter/foundation.dart';

import '../services/local_store.dart';
import '../services/supabase_service.dart';

class AuthProvider extends ChangeNotifier {
  final LocalStore _store;
  bool _isLoading = false;
  String? _error;

  AuthProvider(this._store);

  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get isLoggedIn => SupabaseService.instance.isAuthenticated;

  Future<void> init() async {
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    try {
      await SupabaseService.instance.signIn(email.trim(), password);
      _error = null;
      return true;
    } catch (e) {
      _error = _friendlyAuthError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signUp(String email, String password) async {
    _setLoading(true);
    try {
      await SupabaseService.instance.signUp(email.trim(), password);
      _error = null;
      return true;
    } catch (e) {
      _error = _friendlyAuthError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    await SupabaseService.instance.signOut();
    await _store.clearAll();
    notifyListeners();
  }

  String _friendlyAuthError(Object e) {
    final msg = e.toString();
    if (msg.contains('Invalid login credentials')) {
      return 'Correo o contraseña incorrectos.';
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