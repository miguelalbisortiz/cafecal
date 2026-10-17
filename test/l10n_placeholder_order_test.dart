import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// El orden de los 'placeholders' de un mensaje —el del ARB, que es el orden en
/// el que se lee la frase— tiene que ser el orden de los argumentos de su firma
/// generada.
///
/// Cuando no coinciden, la llamada escrita «como se lee» cae en la casilla de al
/// lado y el mensaje miente sin que nada se queje. Así salieron tres: el aviso
/// previo a borrar un cultivo («Se eliminarán las siembras (Café) y las cosechas
/// (2) de «1»»), la caja en rojo (decía que lo gastado era el arrastre) y el
/// déficit sin cultivo (decía que 3 registros eran 3 pesos).
///
/// Los 'placeholders' que el ARB no declara los ordena el generador por su
/// cuenta (alfabéticamente), así que el orden de la firma no es cosa de suerte:
/// se fija declarándolos, y este test lo vigila para que ningún mensaje nuevo
/// nazca torcido.
void main() {
  test('el orden de los placeholders es el de la firma que los recibe', () {
    final arb = jsonDecode(File('lib/l10n/app_es.arb').readAsStringSync())
        as Map<String, dynamic>;
    final generado =
        File('lib/l10n/generated/app_localizations.dart').readAsStringSync();

    // Firmas del generado: nombre del mensaje → nombres de sus argumentos.
    final firmas = <String, List<String>>{};
    for (final m in RegExp(r'String\s+(\w+)\s*\(([^)]*)\)\s*;',
            multiLine: true, dotAll: true)
        .allMatches(generado)) {
      firmas[m.group(1)!] = m
          .group(2)!
          .split(',')
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty)
          .map((p) => p.split(RegExp(r'\s+')).last)
          .toList();
    }

    final descuadres = <String>[];
    var revisados = 0;
    arb.forEach((clave, valor) {
      if (clave.startsWith('@') || valor is! String) return;
      final enTexto = <String>[];
      for (final m in RegExp(r'\{(\w+)[,}]').allMatches(valor)) {
        final nombre = m.group(1)!;
        if (!enTexto.contains(nombre)) enTexto.add(nombre);
      }
      // Con un solo dato no hay orden que equivocar.
      if (enTexto.length < 2) return;
      revisados++;
      final firma = firmas[clave] ?? const <String>[];
      if (firma.join(' ') != enTexto.join(' ')) {
        descuadres.add('$clave\n'
            '    texto: ${enTexto.join(', ')}\n'
            '    firma: ${firma.join(', ')}');
      }
    });

    expect(revisados, greaterThan(20),
        reason: 'el barrido tiene que estar mirando mensajes de verdad: si '
            'revisa pocos, el ARB o el generado cambiaron de sitio');
    expect(descuadres, isEmpty,
        reason: 'estos mensajes no se leen en el orden de sus argumentos: una '
            'llamada escrita como se lee caería en la casilla de al lado.\n'
            '${descuadres.join('\n')}');
  });
}
