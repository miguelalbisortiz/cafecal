import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/models/sowing.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/screens/crops_screen.dart';
import 'package:mi_cafetal/screens/sowing_screen.dart';
import 'package:mi_cafetal/services/local_store.dart';

/// Tabla de verificación manual §12 · puntos 1 y 2, con las pantallas reales.
///
/// El escenario es el de una finca que venía de antes de la etapa A: un cultivo
/// con dos siembras y **las tres claves nuevas ausentes** en el disco, que es
/// lo que deja un cliente viejo. No se arma con `addSowing`, porque esa puerta
/// ya escribe los campos nuevos: se reescribe el JSON guardado.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const clavesNuevas = [
    'replaces_plants',
    'replaces_area_ha',
    'cohort_sowing_id',
  ];

  /// 1.000 matas de 2020 en 5 ha, más 300 de 2024 en 1 ha, al modo viejo.
  ///
  /// Así lo veía la app vieja: 300 matas en 1 ha, porque la última siembra
  /// reemplazaba al cultivo entero.
  Future<SharedPreferences> sembrarViejo() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final p = TransactionProvider(LocalStore(prefs));
    final crop = await p.addCrop('Café', areaHa: 5);
    await p.addSowing(
        cropId: crop.id,
        date: DateTime(2020, 3, 12),
        plants: 1000,
        areaHa: 5);
    await p.addSowing(
        cropId: crop.id,
        date: DateTime(2024, 5, 1),
        plants: 300,
        areaHa: 1);

    final raw = jsonDecode(prefs.getString('sowings_v1')!) as List<dynamic>;
    for (final row in raw) {
      final mapa = (row as Map).cast<String, dynamic>();
      for (final clave in clavesNuevas) {
        mapa.remove(clave);
      }
    }
    await prefs.setString('sowings_v1', jsonEncode(raw));
    return prefs;
  }

  void agrandar(WidgetTester tester, double alto) {
    tester.view.physicalSize = Size(900, alto);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Future<void> pumpCropsCon(
      WidgetTester tester, TransactionProvider provider) async {
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: provider,
      child: const MaterialApp(
        locale: Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CropsScreen(),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('punto 1 · reabrir no mueve una sola cifra', (tester) async {
    agrandar(tester, 2400);
    final prefs = await sembrarViejo();

    final primera = TransactionProvider(LocalStore(prefs));
    await pumpCropsCon(tester, primera);
    final l10n =
        AppLocalizations.of(tester.element(find.byType(CropsScreen)))!;

    expect(primera.crops.single.livePlants, 300,
        reason: 'los 300 de la última siembra, como los veía la app vieja');
    expect(primera.crops.single.areaHa, 1);
    expect(openCohorts(primera.crops.single.id, primera.sowings), hasLength(1),
        reason: 'el lote viejo ya estaba reemplazado, no se le inventa vida');
    expect(find.textContaining('300'), findsWidgets);
    expect(find.text(l10n.cohortsCount(2)), findsNothing,
        reason: 'una sola edad: la tarjeta se ve como siempre');

    final guardado = prefs.getString('sowings_v1');
    final segunda = TransactionProvider(LocalStore(prefs));
    await pumpCropsCon(tester, segunda);

    expect(prefs.getString('sowings_v1'), guardado,
        reason: 'ya normalizado: reabrir no reescribe ni una fila');
    expect(segunda.crops.single.livePlants, 300);
    expect(segunda.crops.single.areaHa, 1);
    expect(find.textContaining('300'), findsWidgets);
  });

  testWidgets('punto 2 · la corrección manda y no se renormaliza',
      (tester) async {
    agrandar(tester, 3600);
    final prefs = await sembrarViejo();
    final p = TransactionProvider(LocalStore(prefs));

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: p,
      child: const MaterialApp(
        locale: Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SowingScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(tester.element(find.byType(SowingScreen)))!;

    // La lista va de más nueva a más vieja: la de 2024 es la primera.
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.sowingExpandOption));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.add).last);
    await tester.pumpAndSettle();

    expect(p.sowings.last.replacesPlants, 0,
        reason: '«Amplío» se guarda como 0 explícito');
    expect(p.sowings.last.cohortSowingId, isNull);
    expect(p.crops.single.livePlants, 1300,
        reason: 'el lote viejo recupera sus 1.000 y las 300 se suman');
    expect(p.crops.single.areaHa, 6);

    final otra = TransactionProvider(LocalStore(prefs));
    await pumpCropsCon(tester, otra);
    expect(otra.crops.single.livePlants, 1300,
        reason: 'reabrir no vuelve a restar: la fila ya no está en null');
    expect(otra.sowings.last.replacesPlants, 0);
    expect(find.text(l10n.cohortsCount(2)), findsOneWidget,
        reason: 'con la corrección quedan dos edades de verdad');
  });
}
