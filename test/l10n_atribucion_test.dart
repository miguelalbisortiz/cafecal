import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Etapa B · guarda de copy de la atribución de kilos por lote.
void main() {
  final es = jsonDecode(File('lib/l10n/app_es.arb').readAsStringSync())
      as Map<String, dynamic>;
  final en = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
      as Map<String, dynamic>;

  const claves = [
    'jornalHarvestedKgLotLabel',
    'jornalHarvestedKgLotNone',
    'jornalHarvestedKgLotRenewed',
    'jornalHarvestedKgLotMissing',
    'cohortKgLabel',
    'cohortKgPerPlantLabel',
  ];

  test('las claves de la etapa B están en los dos ARB', () {
    for (final clave in claves) {
      expect(es[clave], isA<String>(), reason: 'falta «$clave» en español');
      expect(en[clave], isA<String>(), reason: 'falta «$clave» en inglés');
      expect((es[clave] as String).trim(), isNotEmpty, reason: clave);
      expect((en[clave] as String).trim(), isNotEmpty, reason: clave);
    }
  });

  test('los placeholders coinciden en nombre y cantidad entre ES y EN', () {
    for (final clave in claves) {
      final pes = (es['@$clave']?['placeholders'] as Map?)?.keys.toList() ?? [];
      final pen = (en['@$clave']?['placeholders'] as Map?)?.keys.toList() ?? [];
      expect(pes.toSet(), pen.toSet(),
          reason:
              '«$clave» no declara los mismos argumentos en los dos idiomas');
      expect(pes.length, pen.length, reason: '«$clave» cambia de argumentos');
    }
  });

  test('las cifras viajan como String ya formateadas', () {
    for (final clave in ['cohortKgLabel', 'cohortKgPerPlantLabel']) {
      final tipo = es['@$clave']['placeholders'] as Map<String, dynamic>;
      for (final p in tipo.values) {
        expect((p as Map)['type'], 'String',
            reason: '«$clave» tiene que recibir el número ya formateado');
      }
    }
  });

  test('el copy visible no usa «cohorte» ni «cohort»', () {
    for (final clave in claves) {
      expect((es[clave] as String).toLowerCase().contains('cohorte'), isFalse,
          reason: '«$clave» usa «cohorte»; se dice «lote»');
      expect((en[clave] as String).toLowerCase().contains('cohort'), isFalse,
          reason: '«$clave» usa «cohort»; se dice «lot»');
    }
  });

  test('el aviso no promete que los kilos se reparten', () {
    final aviso = (es['jornalHarvestedKgLotMissing'] as String).toLowerCase();
    expect(aviso.contains('cada lote'), isFalse);
    expect(aviso.contains('se reparte'), isFalse);
    expect(aviso.contains('puedes guardar'), isTrue,
        reason: 'avisar sin bloquear');
  });
}
