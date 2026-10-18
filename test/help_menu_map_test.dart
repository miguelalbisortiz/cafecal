import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/screens/help_screen.dart';

/// La Ayuda tiene que nombrar cada puerta que el menú abre: si el menú gana una
/// entrada y el mapa «¿Dónde entro cada dato?» se queda corto, el agricultor no
/// la encuentra — que es justo lo que pasó cuando la app creció y la Ayuda no.
///
/// Es una guarda de **contrato**, no de verdad semántica: vigila que el destino
/// esté **nombrado**, no que esté bien explicado. Eso último es revisión humana.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  test('el menú y la Ayuda hablan de las mismas puertas', () {
    final valores = valoresDelMenu();
    expect(valores, isNotEmpty,
        reason: 'el barrido tiene que estar viendo el menú de verdad');

    expect(
        valores,
        {...destinos.keys, ...permiso},
        reason: 'una entrada nueva del menú (o una que se fue) obliga a tocar la '
            'Ayuda: si es un destino de datos se le pone su fila en el mapa de '
            '«¿Dónde entro cada dato?»; si no lo es, se declara en `permiso` con '
            'su razón');
  });

  testWidgets('la Ayuda nombra cada destino de datos del menú', (tester) async {
    tester.view.physicalSize = const Size(900, 12000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(
      locale: Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: HelpScreen(),
    ));
    await tester.pump();

    final l10n = stringsFor('es');
    final etiquetas = <String, String>{
      'menuReport': l10n.menuReport,
      'menuCrops': l10n.menuCrops,
      'menuSowings': l10n.menuSowings,
      'menuWorkers': l10n.menuWorkers,
      'menuSettings': l10n.menuSettings,
    };

    for (final entrada in destinos.entries) {
      expect(find.text(etiquetas[entrada.value]!), findsWidgets,
          reason: '${entrada.key}: ese destino del menú no aparece nombrado en '
              'la Ayuda');
    }
  });
}
