import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/screens/help_screen.dart';

/// Cuatro reglas que salieron de la revisión del usuario (2026-10-17):
///
/// 1. **El orden de la app son cuatro pasos.** La cosecha no es un paso que el
///    agricultor dé: nace de la venta (`lib/services/next_step_service.dart`
///    deriva `crop → sowing → expenses → sale` y lo dice en su comentario).
///    Tenerla como paso propio —y encima antes de la venta— contradecía a la
///    app y al intro del propio bloque.
/// 2. **A la finca vacía no se la llama «cultivo».** Con nada registrado, el
///    texto habla de *lo que vas a sembrar*; y si nombra la puerta para crear
///    el cultivo, cita la que existe («Crear nuevo cultivo», en Siembras).
/// 3. **Un tamaño de letra por papel.** La Ayuda mezclaba cinco tamaños en la
///    misma pantalla (12, 12.5, 13, 13.5 y 14); el 14 queda solo para el
///    párrafo de arranque del resumen.
/// 4. **El arranque dice la finalidad, la funcionalidad y el beneficio.** La
///    primera tarjeta es lo primero que se lee: tiene que responder para qué
///    sirve la app, qué hace y de quién son los datos.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Map<String, dynamic> arbDe(String ruta) =>
      jsonDecode(File(ruta).readAsStringSync()) as Map<String, dynamic>;

  test('el orden de la app tiene cuatro pasos y la cosecha no es uno', () {
    for (final ruta in ['lib/l10n/app_es.arb', 'lib/l10n/app_en.arb']) {
      final arb = arbDe(ruta);
      final pasos = arb.keys
          .where((clave) =>
              RegExp(r'^helpFlowStep\d+(Title|Body)$').hasMatch(clave))
          .toList()
        ..sort();

      expect(
          pasos,
          [
            for (var i = 1; i <= 4; i++) ...[
              'helpFlowStep${i}Body',
              'helpFlowStep${i}Title',
            ],
          ],
          reason: '$ruta: el orden de la app son cuatro pasos (cultivo, '
              'siembra, gastos y venta); la cosecha nace de la venta');
    }

    final es = arbDe('lib/l10n/app_es.arb');
    for (final clave in [
      'helpFlowStep1Title',
      'helpFlowStep2Title',
      'helpFlowStep3Title',
      'helpFlowStep4Title',
    ]) {
      expect((es[clave] as String).toLowerCase(), isNot(contains('cosecha')),
          reason: '$clave: la cosecha no es un paso del agricultor, es el '
              'resultado de la venta');
    }
  });

  test('a la finca vacía no se la llama cultivo', () {
    final arb = arbDe('lib/l10n/app_es.arb');
    final titulo = arb['helpCaseBTitle'] as String;
    expect(titulo.toLowerCase(), isNot(contains('cultivo')),
        reason: 'helpCaseBTitle: sin nada registrado el agricultor todavía no '
            'tiene un cultivo; el texto habla de lo que va a sembrar');

    final siembra = arb['helpCaseB2'] as String;
    if (siembra.toLowerCase().contains('crear nuevo cultivo')) {
      expect((arb['sowingNewCropOption'] as String).toLowerCase(),
          contains('crear nuevo cultivo'),
          reason: 'la Ayuda cita «Crear nuevo cultivo»: esa opción tiene que '
              'existir de verdad en la app');
    }
  });

  test('un tamaño de letra por papel en la Ayuda', () {
    final fuente = File('lib/screens/help_screen.dart').readAsStringSync();
    final tamanos = RegExp(r'fontSize:\s*([\d.]+)')
        .allMatches(fuente)
        .map((m) => double.parse(m.group(1)!))
        .toSet()
        .toList()
      ..sort();

    expect(tamanos, everyElement(isIn([11, 12.5, 13, 13.5, 14])),
        reason: 'un tamaño por papel: 11 el número del paso, 12.5 las celdas '
            'de tabla, 13 la prosa y las etiquetas, 13.5 los títulos de '
            'bloque, 14 el párrafo de arranque del resumen');

    final arranques = RegExp(r'fontSize:\s*14\b').allMatches(fuente).length;
    expect(arranques, 1,
        reason: 'el 14 es del párrafo de arranque del resumen, y de nadie más');
  });

  testWidgets('el arranque de la Ayuda dice la finalidad, lo que hace y de '
      'quién son los datos', (tester) async {
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
    final filas = <String, String>{
      'la finalidad (para qué sirve)': l10n.helpWhyTitle,
      'la funcionalidad (qué hace)': l10n.helpDoesTitle,
      'de quién son los datos': l10n.helpDataTitle,
    };

    for (final fila in filas.entries) {
      expect(find.text(fila.value), findsWidgets,
          reason: 'el arranque de la Ayuda no dice ${fila.key}');
    }
  });
}
