import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// La app habla de **tú** en todo el español: «Entra, registra, revisa».
/// El voseo («entrá», «tenés», «vos») quedó atrás y no vuelve: es regional y
/// la app se usa en cualquier país.
void main() {
  /// Formas de voseo y regionalismos que ya se corrigieron una vez.
  const prohibidas = [
    'tenés',
    'podés',
    'querés',
    'sabés',
    'sos',
    'vos',
    'hacé',
    'poné',
    'elegí',
    'escribí',
    'anotá',
    'revisá',
    'tocá',
    'creá',
    'agregá',
    'dejá',
    'dejalo',
    'probá',
    'mirá',
    'entrá',
    'cargá',
    'guardá',
    'borrá',
    'cambiá',
    'completá',
    'empezá',
    'usá',
    'buscá',
    'abrí',
    'cerrá',
    'decime',
    'andá',
    'vení',
    'salí',
    'subí',
    'bajá',
    'pagá',
    'cobrá',
    'contá',
    'separá',
    'asigná',
    'marcá',
    'editá',
    'editala',
    'reintentá',
    'aproximá',
    'plantás',
    'reemplazás',
    'cultivás',
    'agregás',
    'plata',
    'Cenicafé',
  ];

  /// Fronteras que entienden tildes: `\b` no sirve con «revisá».
  final patron = RegExp(
    '(^|[^a-záéíóúüñ])(${prohibidas.join('|')})(\$|[^a-záéíóúüñ])',
    caseSensitive: false,
  );

  test('el español de la app está en tuteo, sin voseo', () {
    final datos = jsonDecode(File('lib/l10n/app_es.arb').readAsStringSync())
        as Map<String, dynamic>;

    final intrusas = <String>[];
    datos.forEach((clave, valor) {
      if (clave.startsWith('@') || valor is! String) return;
      if (patron.hasMatch(valor)) intrusas.add('$clave: $valor');
    });

    expect(intrusas, isEmpty,
        reason: 'estos textos volvieron al voseo o a un regionalismo:\n'
            '${intrusas.join('\n')}');
  });
}
