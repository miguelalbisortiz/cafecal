import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/models/tasks.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/screens/crops_screen.dart';
import 'package:mi_cafetal/services/local_store.dart';
import 'package:mi_cafetal/utils/format.dart';

/// Etapa B · kg y kg/planta por lote en la tarjeta del cultivo.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<TransactionProvider> makeProvider() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    return TransactionProvider(LocalStore(prefs));
  }

  Future<void> pumpCrops(
      WidgetTester tester, TransactionProvider provider) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

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

  /// Café con dos edades: 700 de 2020 y 300 de 2026.
  Future<TransactionProvider> dosLotes() async {
    final p = await makeProvider();
    final crop = await p.addCrop('Café', areaHa: 5, livePlants: 1000);
    await p.addSowing(
        cropId: crop.id, date: DateTime(2020, 3, 12), plants: 700, areaHa: 4);
    await p.addSowing(
        cropId: crop.id, date: DateTime(2026, 3, 12), plants: 300, areaHa: 1);
    return p;
  }

  Future<void> jornal(TransactionProvider p, String lote, double kg) async {
    await p.addTransaction(
      type: TransactionType.expense,
      category: 'mano_obra',
      amount: 50000,
      cropId: p.crops.single.id,
      task: kTaskCosechar,
      harvestedKg: kg,
      cohortSowingId: lote,
    );
  }

  Future<AppLocalizations> l10nDe(WidgetTester tester) async {
    return AppLocalizations.of(tester.element(find.byType(CropsScreen)))!;
  }

  testWidgets('el lote con 250 kg y 700 matas dice 250 kg y 0,36 kg/planta',
      (tester) async {
    final p = await dosLotes();
    final viejo = p.sowings.first.id;
    await jornal(p, viejo, 250);
    await pumpCrops(tester, p);
    final l10n = await l10nDe(tester);

    await tester.tap(find.text(l10n.cohortsCount(2)));
    await tester.pumpAndSettle();

    expect(find.textContaining(l10n.cohortKgLabel(formatKg(250, 'es'))),
        findsOneWidget);
    expect(
        find.textContaining(
            l10n.cohortKgPerPlantLabel(formatKgPerPlant(250 / 700, 'es'))),
        findsOneWidget);
  });

  testWidgets('el lote sin kilos no muestra kg ni 0', (tester) async {
    final p = await dosLotes();
    await jornal(p, p.sowings.first.id, 250);
    await pumpCrops(tester, p);
    final l10n = await l10nDe(tester);

    await tester.tap(find.text(l10n.cohortsCount(2)));
    await tester.pumpAndSettle();

    expect(
        find.textContaining(l10n.cohortKgPerPlantLabel('0,00')), findsNothing);
    expect(find.textContaining(l10n.cohortKgLabel('250')), findsOneWidget,
        reason: 'solo la fila con kilos pesados');
  });

  testWidgets('una sola edad: la tarjeta es la de siempre', (tester) async {
    final p = await makeProvider();
    final crop = await p.addCrop('Café', areaHa: 5);
    final lote = await p.addSowing(
        cropId: crop.id, date: DateTime(2020, 3, 12), plants: 700, areaHa: 5);
    await jornal(p, lote.id, 250);
    await pumpCrops(tester, p);
    final l10n = await l10nDe(tester);

    expect(find.byType(ExpansionTile), findsNothing);
    expect(find.textContaining(l10n.cohortKgLabel('250')), findsNothing,
        reason: 'con una edad no se abre nada');
  });

  testWidgets('el lote renovado muestra sus kilos, sin kg/planta ni 0 matas',
      (tester) async {
    final p = await makeProvider();
    final crop = await p.addCrop('Café', areaHa: 5, livePlants: 1000);
    final viejo = await p.addSowing(
        cropId: crop.id, date: DateTime(2020, 3, 12), plants: 1000, areaHa: 5);
    await p.addSowing(
      cropId: crop.id,
      date: DateTime(2026, 3, 12),
      plants: 300,
      areaHa: 1,
      replacesPlants: 1000,
      cohortSowingId: viejo.id,
    );
    await jornal(p, viejo.id, 250);
    await pumpCrops(tester, p);
    final l10n = await l10nDe(tester);

    await tester.tap(find.text(l10n.cohortsHistoryTitle));
    await tester.pumpAndSettle();

    // R3 · los kilos del lote cerrado no se esconden: siguen en la tarjeta.
    expect(find.textContaining(l10n.cohortKgLabel('250')), findsOneWidget);
    // Con 0 matas vivas el kg/planta no existe: no se inventa.
    expect(find.textContaining('kg/planta'), findsNothing);
    // Tampoco se lee «0 matas» en un lote que ya se cerró.
    expect(find.textContaining('0 matas'), findsNothing);
  });

  testWidgets('el lote renovado sin kilos no muestra 0 kg', (tester) async {
    final p = await makeProvider();
    final crop = await p.addCrop('Café', areaHa: 5, livePlants: 1000);
    final viejo = await p.addSowing(
        cropId: crop.id, date: DateTime(2020, 3, 12), plants: 1000, areaHa: 5);
    await p.addSowing(
      cropId: crop.id,
      date: DateTime(2026, 3, 12),
      plants: 300,
      areaHa: 1,
      replacesPlants: 1000,
      cohortSowingId: viejo.id,
    );
    await pumpCrops(tester, p);
    final l10n = await l10nDe(tester);

    await tester.tap(find.text(l10n.cohortsHistoryTitle));
    await tester.pumpAndSettle();

    expect(find.textContaining('0 kg'), findsNothing);
    expect(find.textContaining('kg/planta'), findsNothing);
  });

  testWidgets('con cosecha manual no hay kg por lote', (tester) async {
    final p = await dosLotes();
    await jornal(p, p.sowings.first.id, 250);
    await p.addHarvest(
      cropId: p.crops.single.id,
      date: DateTime(2026, 3, 20),
      amount: 100,
      unit: 'kg',
    );
    await pumpCrops(tester, p);
    final l10n = await l10nDe(tester);

    await tester.tap(find.text(l10n.cohortsCount(2)));
    await tester.pumpAndSettle();

    expect(find.textContaining(l10n.cohortKgLabel('250')), findsNothing);
    expect(p.harvests.where((h) => h.cropId == p.crops.single.id), isNotEmpty);
  });

  testWidgets('los kg por lote no cambian el chip de edades', (tester) async {
    final p = await dosLotes();
    await jornal(p, p.sowings.first.id, 250);
    await jornal(p, p.sowings.last.id, 180);
    await pumpCrops(tester, p);
    final l10n = await l10nDe(tester);

    expect(find.text(l10n.cohortsCount(2)), findsOneWidget);
    expect(p.crops.single.livePlants, 1000,
        reason: 'las matas no cambian por pesar kilos');
  });
}
