import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/screens/help_screen.dart';
import 'package:mi_cafetal/services/local_store.dart';

/// Reglas de la Ayuda que se revisaron con el usuario:
///
/// 1. **Un caso se lee de un tirón.** Cuatro pasos como máximo: si hay más, la
///    persona deja de leer y la Ayuda vuelve a ser un manual.
/// 2. **Un tamaño de letra por papel.** Seis tamaños como máximo, cada uno con
///    su función; el título del caso abierto es el único de 15.
/// 3. **La portada primero pregunta, después enseña.** Al abrir, están los
///    cuatro casos y ningún camino abierto.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Map<String, dynamic> arbDe(String ruta) =>
      jsonDecode(File(ruta).readAsStringSync()) as Map<String, dynamic>;

  test('cada caso tiene cuatro pasos como máximo', () {
    const casos = [
      'helpSelling',
      'helpStarting',
      'helpRenew',
      'helpWorkers',
    ];

    for (final ruta in ['lib/l10n/app_es.arb', 'lib/l10n/app_en.arb']) {
      final arb = arbDe(ruta);
      for (final caso in casos) {
        var pasos = 0;
        while (arb.containsKey('${caso}Step${pasos + 1}')) {
          pasos++;
        }
        expect(pasos, greaterThanOrEqualTo(3),
            reason: '$ruta · $caso: un caso sin pasos no enseña nada');
        expect(pasos, lessThanOrEqualTo(4),
            reason: '$ruta · $caso: más de cuatro pasos y nadie lo lee');
        expect(arb['${caso}ExampleTitle'], isA<String>(),
            reason: '$ruta · $caso: el caso necesita su ejemplo');
      }
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

    expect(tamanos, everyElement(isIn([12, 12.5, 13, 13.5, 14, 15])),
        reason: 'un tamaño por papel: 12 el número del paso, 12.5 las notas y '
            'las celdas de tabla, 13 la prosa, 13.5 los títulos de bloque, '
            '14 el título de la tarjeta, 15 el título del caso abierto');

    final quince = RegExp(r'fontSize:\s*15\b').allMatches(fuente).length;
    expect(quince, 1,
        reason: 'el 15 es del título del caso abierto, y de nadie más');
  });

  testWidgets('la portada pregunta primero y no abre ningún camino',
      (tester) async {
    tester.view.physicalSize = const Size(900, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final provider = TransactionProvider(LocalStore(prefs));

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: provider,
      child: const MaterialApp(
        locale: Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: HelpScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    final l10n = stringsFor('es');
    expect(find.text(l10n.helpStartTitle), findsOneWidget);
    expect(find.text(l10n.helpStartQuestion), findsOneWidget);
    expect(find.text(l10n.helpSellingStep1), findsNothing);
  });
}
