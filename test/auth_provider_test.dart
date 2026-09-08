import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cafetal/providers/auth_provider.dart';
import 'package:mi_cafetal/services/local_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthProvider — validación de credenciales (H3)', () {
    late AuthProvider auth;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      auth = AuthProvider(LocalStore(prefs));
    });

    test('rechaza email inválido antes de llamar a Supabase', () async {
      final ok = await auth.signIn('no-es-email', '123456');
      expect(ok, isFalse);
      expect(auth.error, 'Formato de correo inválido.');
    });

    test('rechaza contraseña corta (< 6)', () async {
      final ok = await auth.signIn('correo@ejemplo.co', '123');
      expect(ok, isFalse);
      expect(auth.error, 'La contraseña debe tener al menos 6 caracteres.');
    });

    test('signUp valida igual y devuelve failure', () async {
      final ok = await auth.signUp('mal', '123456');
      expect(ok, SignUpResult.failure);
      expect(auth.error, 'Formato de correo inválido.');
    });
  });
}