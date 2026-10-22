import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/models/sowing.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/screens/crops_screen.dart';
import 'package:mi_cafetal/screens/report_screen.dart';
import 'package:mi_cafetal/screens/sowing_screen.dart';
import 'package:mi_cafetal/services/local_store.dart';

/// Tabla de verificación manual §12 · puntos 3 a 10.
///
/// Los puntos 6 (no reemplazar de más) y 7 (área incompleta) ya tienen sus
/// tests en `sowing_screen_cohorts_test.dart` y `crops_screen_cohorts_test.dart`
/// y no se repiten aquí; el 9 (una sola cohorte igual que siempre) se cubre en
/// el último caso de reporte.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<TransactionProvider> nuevo() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    return TransactionProvider(LocalStore(prefs));
  }

  /// 1.000 matas de 2020 en 5 ha.
  Future<TransactionProvider> conLote({double? area = 5}) async {
    final p = await nuevo();
    final crop = await p.addCrop('Café', areaHa: area);
    await p.addSowing(
        cropId: crop.id,
        date: DateTime(2020, 3, 12),
        plants: 1000,
        areaHa: area);
    return p;
  }

  void agrandar(WidgetTester tester, double alto) {
    tester.view.physicalSize = Size(900, alto);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Future<AppLocalizations> abrirForm(
      WidgetTester tester, TransactionProvider provider) async {
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: provider,
      child: const MaterialApp(
        locale: Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SowingScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    final l10n =
        AppLocalizations.of(tester.element(find.byType(SowingScreen)))!;
    await tester.tap(find.text(l10n.sowingAdd));
    await tester.pumpAndSettle();
    return l10n;
  }

  Future<AppLocalizations> irATarjetas(
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
    return AppLocalizations.of(tester.element(find.byType(CropsScreen)))!;
  }

  testWidgets('punto 3 · renovación parcial: 700/4 + 300/1 = 1.000/5',
      (tester) async {
    agrandar(tester, 3600);
    final p = await conLote();
    final vieja = p.sowings.single.id;

    final l10n = await abrirForm(tester, p);
    await tester.enterText(find.byType(TextFormField).first, '300');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(1), '1');
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.sowingRenewOption));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(2), '300');
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.add).last);
    await tester.pumpAndSettle();

    final cohorts = cropCohorts(p.crops.single.id, p.sowings);
    expect(cohorts.first.livePlants, 700);
    expect(cohorts.first.areaHa, 4);
    expect(cohorts.last.livePlants, 300);
    expect(cohorts.last.areaHa, 1);
    expect(p.sowings.last.cohortSowingId, vieja);
    expect(p.crops.single.livePlants, 1000);
    expect(p.crops.single.areaHa, 5);

    await irATarjetas(tester, p);
    expect(find.text(l10n.cohortsCount(2)), findsOneWidget,
        reason: 'dos edades de verdad');
  });

  testWidgets('punto 4 · renovación total: la vieja al historial y 300/1',
      (tester) async {
    agrandar(tester, 3600);
    final p = await conLote();

    final l10n = await abrirForm(tester, p);
    await tester.enterText(find.byType(TextFormField).first, '300');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(1), '1');
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.sowingRenewOption));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.sowingReplaceAll(1000)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.add).last);
    await tester.pumpAndSettle();

    expect(p.crops.single.livePlants, 300);
    expect(p.crops.single.areaHa, 1);
    expect(openCohorts(p.crops.single.id, p.sowings), hasLength(1),
        reason: 'queda una sola edad viva');

    await irATarjetas(tester, p);
    expect(find.text(l10n.cohortsCount(2)), findsNothing);
    expect(find.text(l10n.cohortsHistoryTitle), findsOneWidget);
    await tester.tap(find.text(l10n.cohortsHistoryTitle));
    await tester.pumpAndSettle();
    final hoy = DateTime.now();
    final mes = '${hoy.month.toString().padLeft(2, '0')}/${hoy.year}';
    expect(find.textContaining(l10n.cohortRenewedOn(mes)), findsOneWidget,
        reason: 'la vieja se cierra con la fecha de la siembra que la reemplazó');
  });

  testWidgets('punto 5 · resiembra en el lote viejo: 100 menos, fecha anclada',
      (tester) async {
    final p = await conLote();
    final vieja = p.sowings.single.id;
    await p.addSowing(
        cropId: p.crops.single.id,
        date: DateTime(2024, 5, 1),
        plants: 300,
        areaHa: 1,
        replacesPlants: 0);
    expect(p.crops.single.livePlants, 1300);

    await p.addSowing(
        cropId: p.crops.single.id,
        kind: SowingKind.resiembra,
        date: DateTime(2026, 6, 1),
        plants: 0,
        lostPlants: 100,
        cohortSowingId: vieja);

    final cohorts = cropCohorts(p.crops.single.id, p.sowings);
    expect(cohorts.first.livePlants, 900, reason: 'la vieja baja de 1.000 a 900');
    expect(p.crops.single.livePlants, 1200, reason: '900 + 300');
    expect(
        lossEarliestDate(p.sowings, p.crops.single.id, cohortSowingId: vieja),
        DateTime(2020, 3, 12),
        reason: 'la pérdida no puede fecharse antes de la siembra de SU lote');
  });

  testWidgets('punto 8 · el reporte dice «promedio de 2 edades» y no abre filas',
      (tester) async {
    agrandar(tester, 8000);
    final p = await nuevo();
    final crop = await p.addCrop('Café', areaHa: 2);
    final vieja = await p.addSowing(
        cropId: crop.id,
        date: DateTime(2020, 3, 12),
        plants: 1000,
        areaHa: 2);
    await p.addSowing(
        cropId: crop.id,
        date: DateTime(2024, 5, 1),
        plants: 300,
        replacesPlants: 300,
        cohortSowingId: vieja.id);
    await p.addHarvest(cropId: crop.id, date: DateTime.now(), amount: 50);
    expect(p.crops.single.livePlants, 1000, reason: '700 + 300');

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: p,
      child: const MaterialApp(
        locale: Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ReportScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(tester.element(find.byType(ReportScreen)))!;

    expect(find.text(l10n.perHaAgesAverage(2)), findsOneWidget,
        reason: 'aclara que el kg/planta mezcla dos lotes');
    expect(find.text('0.05 kg/planta'), findsOneWidget,
        reason: '50 kg / 1.000 plantas: la fórmula no cambia');
    expect(find.text(l10n.cohortsCount(2)), findsNothing,
        reason: 'el reporte no abre filas por lote');
  });

  testWidgets('punto 9 · una sola cohorte: el reporte se ve como siempre',
      (tester) async {
    agrandar(tester, 8000);
    final p = await conLote(area: 2);
    await p.addHarvest(cropId: p.crops.single.id, date: DateTime.now(), amount: 50);

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: p,
      child: const MaterialApp(
        locale: Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ReportScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(tester.element(find.byType(ReportScreen)))!;

    expect(find.text(l10n.perHaAgesAverage(2)), findsNothing);
    expect(find.text('0.05 kg/planta'), findsOneWidget);
  });

  test('punto 10 · sin señal: la siembra con reemplazo se guarda entera', () async {
    final p = await conLote();
    final vieja = p.sowings.single.id;
    await p.addSowing(
        cropId: p.crops.single.id,
        date: DateTime(2024, 5, 1),
        plants: 300,
        areaHa: 1,
        replacesPlants: 300,
        replacesAreaHa: 1,
        cohortSowingId: vieja);

    expect(p.sowings.last.pendingSync, isTrue,
        reason: 'nació sin red: queda por subir');

    // Reabrir la app equivale a leer el disco con un provider nuevo.
    final prefs = await SharedPreferences.getInstance();
    final reabierta = TransactionProvider(LocalStore(prefs));
    final s = reabierta.sowings.last;
    expect(s.plants, 300);
    expect(s.areaHa, 1);
    expect(s.replacesPlants, 300);
    expect(s.replacesAreaHa, 1);
    expect(s.cohortSowingId, vieja,
        reason: 'el puntero sobrevive al cierre, no se renormaliza');
    expect(reabierta.crops.single.livePlants, 1000);
  });
}
