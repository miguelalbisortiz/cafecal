import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guarda de la tanda 4 (T3).
///
/// `unitToKg` convierte `racimo` y `cajon` a 1 kg porque no tiene factor. Eso
/// era justo la mentira que se corrigió: cualquier cantidad que vaya a un total
/// tiene que pasar por `kgFromUnit`, que devuelve `null` cuando falta el peso.
///
/// Este test no mira si el número salió bien (eso lo hacen los tests de cada
/// métrica): mira que nadie vuelva a abrir la puerta vieja.
void main() {
  test('nadie fuera de units.dart convierte cantidades con unitToKg', () {
    final offenders = <String>[];

    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => !f.path.replaceAll('\\', '/').endsWith('models/units.dart'));

    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        // Un comentario que lo menciona no convierte nada.
        if (line.trimLeft().startsWith('//')) continue;
        if (line.contains('unitToKg(')) {
          offenders.add('${file.path}:${i + 1}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'usá kgFromUnit: unitToKg trata racimo y cajón como 1 kg',
    );
  });
}
