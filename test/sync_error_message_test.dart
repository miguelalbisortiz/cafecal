import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cafetal/providers/sync_provider.dart';

void main() {
  test('un check violado se explica, no se muestra crudo', () {
    final e = Exception(
        'PostgrestException(message: new row for relation "sowings" violates '
        'check constraint "sowings_plants_check", code: 23514)');
    final texto = describeSyncError(e);
    expect(texto, isNot(contains('PostgrestException')));
    expect(texto, contains('cifra'));
  });

  test('los errores ya conocidos siguen diciendo lo mismo', () {
    expect(describeSyncError(Exception('code: PGRST204')), contains('columna'));
    expect(describeSyncError(Exception('code: 23503')),
        contains('registro relacionado'));
    expect(describeSyncError(Exception('JWT expired')), contains('sesión'));
  });
}
