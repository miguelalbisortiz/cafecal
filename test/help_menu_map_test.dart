import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// La Ayuda tiene que nombrar cada puerta que el menú abre: si el menú gana una
/// entrada y la Ayuda se queda corta, el agricultor no la encuentra — que es
/// justo lo que pasó cuando la app creció y la Ayuda no.
///
/// Es una guarda de **contrato**, no de verdad semántica: vigila que el destino
/// esté **nombrado**, no que esté bien explicado. Eso último es revisión humana.
void main() {
  /// Las entradas del menú que son **destinos de datos**: cada una tiene que
  /// aparecer en la Ayuda con el nombre real de la pantalla.
  const destinos = <String, String>{
    'report': 'menuReport',
    'crops': 'menuCrops',
    'sowings': 'menuSowings',
    'workers': 'menuWorkers',
    'settings': 'menuSettings',
  };

  /// Entradas que no son destinos de datos: la Ayuda misma (es esta pantalla) y
  /// cerrar sesión. Se declaran aquí a propósito, para que una entrada nueva del
  /// menú tenga que pasar por esta decisión en vez de colarse en silencio.
  const permiso = <String>['help', 'logout'];

  /// Los valores del `PopupMenuButton` de la pantalla de inicio. Las líneas
  /// comentadas no cuentan: «Cosechas» vive ahí como camino de restauración.
  Set<String> valoresDelMenu() {
    final lineas = File('lib/screens/home_screen.dart').readAsLinesSync();
    final valores = <String>{};
    for (final linea in lineas) {
      if (linea.trimLeft().startsWith('//')) continue;
      final hallado = RegExp(r"value:\s*'([a-z]+)'").firstMatch(linea);
      if (hallado != null) valores.add(hallado.group(1)!);
    }
    return valores;
  }

  /// Todo el copy de la Ayuda en un solo texto: los pasos nombran la pantalla
  /// dentro de la frase («Anota el pago: Registrar › Gasto › Mano de obra»).
  String copyDeLaAyuda(String ruta) {
    final arb =
        jsonDecode(File(ruta).readAsStringSync()) as Map<String, dynamic>;
    return arb.entries
        .where((e) => e.key.startsWith('help') && !e.key.startsWith('@'))
        .where((e) => e.value is String)
        .map((e) => e.value as String)
        .join('\n');
  }

  test('el menú y la Ayuda hablan de las mismas puertas', () {
    final valores = valoresDelMenu();
    expect(valores, isNotEmpty,
        reason: 'el barrido tiene que estar viendo el menú de verdad');

    expect(
        valores,
        {...destinos.keys, ...permiso},
        reason: 'una entrada nueva del menú (o una que se fue) obliga a tocar la '
            'Ayuda: si es un destino de datos se le nombra en los pasos; si no '
            'lo es, se declara en `permiso` con su razón');
  });

  test('la Ayuda nombra cada destino de datos del menú', () {
    const etiquetasEs = <String, String>{
      'menuReport': 'Reporte',
      'menuCrops': 'Cultivos',
      'menuSowings': 'Siembras',
      'menuWorkers': 'Trabajadores',
      'menuSettings': 'Configuración',
    };
    const etiquetasEn = <String, String>{
      'menuReport': 'Report',
      'menuCrops': 'Crops',
      'menuSowings': 'Plantings',
      'menuWorkers': 'Workers',
      'menuSettings': 'Settings',
    };

    for (final ruta in ['lib/l10n/app_es.arb', 'lib/l10n/app_en.arb']) {
      final copy = copyDeLaAyuda(ruta);
      final etiquetas = ruta.endsWith('_en.arb') ? etiquetasEn : etiquetasEs;
      for (final entrada in destinos.entries) {
        final esperada = etiquetas[entrada.value]!;
        expect(copy.contains(esperada), isTrue,
            reason: '$ruta: «$esperada» no aparece nombrado en la Ayuda, y es '
                'una puerta del menú (${entrada.key})');
      }
    }
  });
}
