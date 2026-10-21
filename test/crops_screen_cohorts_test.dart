import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/models/sowing.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/screens/crops_screen.dart';
import 'package:mi_cafetal/services/local_store.dart';
import 'package:mi_cafetal/utils/format.dart';

/// Etapa A · la tarjeta del cultivo con varias edades.
///
/// Con **una** cohorte viva la tarjeta se ve exactamente como siempre. Con dos
/// o más no hay «una» edad: se dice cuántas y se despliegan, sin promedio.
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

  Future<AppLocalizations> l10nDe(WidgetTester tester) async {
    return AppLocalizations.of(tester.element(find.byType(CropsScreen)))!;
  }

  /// 1.000 matas de 2020 en 5 ha.
  Future<TransactionProvider> unLote({double? area = 5}) async {
    final p = await makeProvider();
    final crop = await p.addCrop('Café', areaHa: area);
    await p.addSowing(
        cropId: crop.id,
        date: DateTime(2020, 3, 12),
        plants: 1000,
        areaHa: area);
    return p;
  }

  testWidgets('una sola edad: la tarjeta se ve como siempre', (tester) async {
    final provider = await unLote();
    await pumpCrops(tester, provider);
    final l10n = await l10nDe(tester);

    expect(find.textContaining(l10n.cropAge(6)), findsWidgets,
        reason: 'la edad de la única cohorte, como hoy');
    expect(find.text(l10n.cohortsCount(2)), findsNothing);
    expect(find.text(l10n.cohortsHistoryTitle), findsNothing);
    expect(find.text(l10n.cohortsNoLivingPlants), findsNothing);
    expect(find.byType(ExpansionTile), findsNothing);
  });

  testWidgets('dos edades: dice cuántas y no inventa un promedio',
      (tester) async {
    final provider = await unLote();
    await provider.addSowing(
        cropId: provider.crops.single.id,
        date: DateTime(2024, 5, 1),
        plants: 300,
        areaHa: 1,
        replacesPlants: 0);

    await pumpCrops(tester, provider);
    final l10n = await l10nDe(tester);

    expect(find.text(l10n.cohortsCount(2)), findsOneWidget);
    expect(find.textContaining(l10n.cropAge(6)), findsNothing,
        reason: 'ninguna edad suelta: hay dos');
    expect(find.textContaining(l10n.cropAge(2)), findsNothing);
  });

  testWidgets('el desglose lista cada lote con su edad, matas y área',
      (tester) async {
    final provider = await unLote();
    await provider.addSowing(
        cropId: provider.crops.single.id,
        date: DateTime(2024, 5, 1),
        plants: 300,
        areaHa: 1,
        replacesPlants: 0);
    await pumpCrops(tester, provider);
    final l10n = await l10nDe(tester);
    final material =
        MaterialLocalizations.of(tester.element(find.byType(CropsScreen)));

    await tester.tap(find.text(l10n.cohortsCount(2)));
    await tester.pumpAndSettle();

    expect(
        find.textContaining(material.formatShortDate(DateTime(2020, 3, 12))),
        findsOneWidget);
    expect(
        find.textContaining(material.formatShortDate(DateTime(2024, 5, 1))),
        findsOneWidget);
    expect(find.textContaining(l10n.cropAge(6)), findsOneWidget);
    expect(find.textContaining(l10n.cropAge(2)), findsOneWidget);
    expect(find.textContaining(l10n.cohortOpen), findsNWidgets(2));
  });

  testWidgets('los lotes renovados quedan en el historial', (tester) async {
    final provider = await unLote();
    final vieja = provider.sowings.single.id;
    await provider.addSowing(
        cropId: provider.crops.single.id,
        date: DateTime(2024, 5, 1),
        plants: 400,
        areaHa: 1,
        replacesPlants: 1000,
        cohortSowingId: vieja);
    await pumpCrops(tester, provider);
    final l10n = await l10nDe(tester);
    final material =
        MaterialLocalizations.of(tester.element(find.byType(CropsScreen)));

    expect(find.text(l10n.cohortsHistoryTitle), findsOneWidget);

    await tester.tap(find.text(l10n.cohortsHistoryTitle));
    await tester.pumpAndSettle();

    expect(find.textContaining(l10n.cohortRenewedOn('05/2024')), findsOneWidget,
        reason: 'se ve el día en que la dejó en 0 el reemplazo');
    expect(
        find.textContaining(material.formatShortDate(DateTime(2020, 3, 12))),
        findsOneWidget);
  });

  testWidgets('sin matas vivas se dice, no se oculta', (tester) async {
    final provider = await unLote(area: 5);
    await provider.addSowing(
        cropId: provider.crops.single.id,
        date: DateTime(2024, 5, 1),
        kind: SowingKind.resiembra,
        plants: 0,
        lostPlants: 1000);

    await pumpCrops(tester, provider);
    final l10n = await l10nDe(tester);

    expect(find.text(l10n.cohortsNoLivingPlants), findsOneWidget);
    expect(find.text(l10n.cohortsCount(2)), findsNothing);
  });

  testWidgets('avisa cuando falta el área de un lote', (tester) async {
    final provider = await unLote();
    await provider.addSowing(
        cropId: provider.crops.single.id,
        date: DateTime(2024, 5, 1),
        plants: 300,
        replacesPlants: 0);

    await pumpCrops(tester, provider);
    final l10n = await l10nDe(tester);

    expect(find.text(l10n.cohortsAreaFallback), findsOneWidget,
        reason: 'el área del cultivo es la que él escribió');
  });

  testWidgets('avisa cuando los lotes ya superan el área del cultivo',
      (tester) async {
    final provider = await unLote();
    await provider.addSowing(
        cropId: provider.crops.single.id,
        date: DateTime(2024, 5, 1),
        plants: 300,
        areaHa: 2,
        replacesPlants: 0);
    // El área del cultivo escrita a mano (5 ha) no coincide con la suma de los
    // lotes (7 ha): se avisa, nunca se bloquea.
    await provider.updateCrop(provider.crops.single.copyWith(areaHa: 5));

    await pumpCrops(tester, provider);
    final l10n = await l10nDe(tester);
    final locale = provider.settings.numberLocale;

    expect(
      find.text(l10n.cohortsAreaMismatch(
        formatAreaHa(7, locale),
        formatAreaHa(5, locale),
      )),
      findsOneWidget,
      reason: '5 + 2 supera las 5 ha del cultivo: se avisa, no se bloquea',
    );
  });
}
