import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/models/crop.dart';
import 'package:mi_cafetal/models/sowing.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/screens/sowing_screen.dart';
import 'package:mi_cafetal/services/local_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<TransactionProvider> makeProvider() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    return TransactionProvider(LocalStore(prefs));
  }

  void agrandar(WidgetTester tester) {
    tester.view.physicalSize = const Size(900, 3600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Future<void> pumpScreen(
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
  }

  Future<AppLocalizations> abrirForm(
      WidgetTester tester, TransactionProvider provider) async {
    await pumpScreen(tester, provider);
    final l10n =
        AppLocalizations.of(tester.element(find.byType(SowingScreen)))!;
    await tester.tap(find.text(l10n.sowingAdd));
    await tester.pumpAndSettle();
    return l10n;
  }

  /// Un cultivo con un lote vivo de 1.000 matas en 5 ha.
  Future<TransactionProvider> conUnLote({double? area = 5}) async {
    final p = await makeProvider();
    final crop = await p.addCrop('Café', areaHa: area);
    await p.addSowing(
        cropId: crop.id,
        date: DateTime(2020, 3, 12),
        plants: 1000,
        areaHa: area);
    return p;
  }

  testWidgets('un cultivo sin cohortes muestra el formulario de siempre',
      (tester) async {
    agrandar(tester);
    final provider = await makeProvider();
    await provider.addCrop('Café');

    final l10n = await abrirForm(tester, provider);

    expect(find.text(l10n.sowingWhatHappensOldPlants), findsNothing);
    expect(find.text(l10n.sowingExpandOption), findsNothing);
    // Plantas, área y costo: los mismos tres campos de siempre.
    expect(find.byType(TextFormField), findsNWidgets(3));
  });

  testWidgets('un cultivo con cohortes muestra la pregunta', (tester) async {
    agrandar(tester);
    final provider = await conUnLote();

    final l10n = await abrirForm(tester, provider);

    expect(find.text(l10n.sowingWhatHappensOldPlants), findsOneWidget);
    expect(find.text(l10n.sowingExpandOption), findsOneWidget);
    expect(find.text(l10n.sowingRenewOption), findsOneWidget);
    expect(find.text(l10n.sowingRenewHint), findsNothing,
        reason: 'los detalles salen recién al elegir Renuevo');
  });

  testWidgets('«Amplío» guarda 0 explícito y la vieja no pierde matas',
      (tester) async {
    agrandar(tester);
    final provider = await conUnLote();

    final l10n = await abrirForm(tester, provider);
    await tester.enterText(find.byType(TextFormField).first, '300');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(1), '1');
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.add).last);
    await tester.pumpAndSettle();

    expect(provider.sowings, hasLength(2));
    final nueva = provider.sowings.last;
    expect(nueva.replacesPlants, 0, reason: 'nunca queda en null');
    expect(nueva.replacesAreaHa, isNull);
    expect(nueva.cohortSowingId, isNull);
    expect(provider.crops.single.livePlants, 1300);
    expect(provider.crops.single.areaHa, 6);
  });

  testWidgets('«Renuevo» sin matas no guarda; con matas guarda el valor',
      (tester) async {
    agrandar(tester);
    final provider = await conUnLote();

    final l10n = await abrirForm(tester, provider);
    await tester.enterText(find.byType(TextFormField).first, '300');
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.sowingRenewOption));
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.add).last);
    await tester.pumpAndSettle();
    expect(find.text(l10n.sowingReplacePlantsRequired), findsOneWidget);
    expect(provider.sowings, hasLength(1), reason: 'no guardó');

    await tester.enterText(find.byType(TextFormField).at(2), '300');
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.add).last);
    await tester.pumpAndSettle();

    expect(provider.sowings, hasLength(2));
    final nueva = provider.sowings.last;
    expect(nueva.replacesPlants, 300);
    expect(nueva.cohortSowingId, provider.sowings.first.id);
    expect(provider.crops.single.livePlants, 1000, reason: '700 + 300');
  });

  testWidgets('más matas de las que hay bloquea y ofrece «Todas»',
      (tester) async {
    agrandar(tester);
    final provider = await conUnLote();

    final l10n = await abrirForm(tester, provider);
    await tester.enterText(find.byType(TextFormField).first, '300');
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.sowingRenewOption));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(2), '1500');
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.add).last);
    await tester.pumpAndSettle();
    expect(find.text(l10n.sowingReplaceTooMany(1000)), findsOneWidget);
    expect(provider.sowings, hasLength(1));

    await tester.tap(find.text(l10n.sowingReplaceAll(1000)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.add).last);
    await tester.pumpAndSettle();

    expect(provider.sowings.last.replacesPlants, 1000);
    expect(provider.crops.single.livePlants, 300, reason: 'la vieja quedó en 0');
  });

  testWidgets('la precarga por área se ve con las dos áreas', (tester) async {
    agrandar(tester);
    final provider = await conUnLote();

    final l10n = await abrirForm(tester, provider);
    await tester.enterText(find.byType(TextFormField).first, '200');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(1), '1');
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.sowingRenewOption));
    await tester.pumpAndSettle();

    expect(find.text(l10n.sowingReplacePlantsPrefill(200, 1000)),
        findsOneWidget);
    expect(find.text('200'), findsWidgets,
        reason: 'la precarga llena el campo de matas');
  });

  testWidgets('sin área vieja no hay precarga y se avisa', (tester) async {
    agrandar(tester);
    final provider = await conUnLote(area: null);

    final l10n = await abrirForm(tester, provider);
    await tester.enterText(find.byType(TextFormField).first, '200');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(1), '1');
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.sowingRenewOption));
    await tester.pumpAndSettle();

    expect(find.text(l10n.sowingReplaceNoArea), findsOneWidget);
    expect(find.text(l10n.sowingReplacePlantsPrefill(200, 1000)), findsNothing);
  });

  testWidgets('editar una siembra vieja y pasar a «Amplío» guarda 0',
      (tester) async {
    agrandar(tester);
    final provider = await makeProvider();
    final crop = await provider.addCrop('Café', areaHa: 5);
    final s1 = await provider.addSowing(
        cropId: crop.id,
        date: DateTime(2020, 1, 1),
        plants: 1000,
        areaHa: 5);
    await provider.addSowing(
        cropId: crop.id,
        date: DateTime(2027, 1, 1),
        plants: 300,
        areaHa: 1,
        replacesPlants: 1000,
        replacesAreaHa: 5,
        cohortSowingId: s1.id);

    await pumpScreen(tester, provider);
    final l10n =
        AppLocalizations.of(tester.element(find.byType(SowingScreen)))!;
    // La lista va de más nueva a más vieja: la primera es la renovación.
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.sowingExpandOption));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.add).last);
    await tester.pumpAndSettle();

    final s2 = provider.sowings.last;
    expect(s2.replacesPlants, 0, reason: 'la corrección manda');
    expect(s2.cohortSowingId, isNull);
    expect(provider.crops.single.livePlants, 1300);
  });

  testWidgets('marcar el arranque completo guarda las vivas de la cohorte',
      (tester) async {
    agrandar(tester);
    final provider = await conUnLote();

    final l10n = await abrirForm(tester, provider);
    await tester.enterText(find.byType(TextFormField).first, '300');
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.add).last);
    await tester.pumpAndSettle();

    final nueva = provider.sowings.last;
    expect(nueva.replacesPlants, 1000, reason: 'arrancar = reemplazar todas');
    expect(nueva.cohortSowingId, provider.sowings.first.id);
    expect(provider.crops.single.livePlants, 300);
    expect(openCohorts(provider.crops.single.id, provider.sowings), hasLength(1),
        reason: 'una sola edad: la nueva');
  });

  testWidgets('con dos lotes vivos el arranque completo no se ofrece',
      (tester) async {
    agrandar(tester);
    final provider = await makeProvider();
    final crop = await provider.addCrop('Café', areaHa: 5);
    final s1 = await provider.addSowing(
        cropId: crop.id,
        date: DateTime(2020, 1, 1),
        plants: 1000,
        areaHa: 5);
    await provider.addSowing(
        cropId: crop.id,
        date: DateTime(2024, 1, 1),
        plants: 300,
        areaHa: 1,
        replacesPlants: 0);

    final l10n = await abrirForm(tester, provider);

    expect(find.byType(CheckboxListTile), findsNothing,
        reason: 'con dos edades no hay un «arranque» que reiniciar');
    expect(find.text(l10n.sowingWhatHappensOldPlants), findsOneWidget);
    expect(s1.id, provider.sowings.first.id);
    expect(provider.crops.single.phase, CropPhase.establecimiento);
  });

  // ── T15 · resiembra por lote, avisos y «sin lote» ───────────────────────

  testWidgets('una resiembra con un solo lote dice cuál y no ofrece selector',
      (tester) async {
    agrandar(tester);
    final provider = await conUnLote();

    final l10n = await abrirForm(tester, provider);
    await tester.tap(find.text(l10n.sowingKindResiembra));
    await tester.pumpAndSettle();

    expect(
      find.text('${l10n.sowingCohortLabel}: '
          '${l10n.sowingCohortOption('12/03/2020', 1000)}'),
      findsOneWidget,
      reason: 'con una edad no hay nada que elegir: se dice sola',
    );
    expect(find.text(l10n.sowingCohortNoneTitle), findsNothing);
    expect(provider.sowings, hasLength(1));
  });

  testWidgets('con dos lotes vivos la resiembra elige y arranca en el más viejo',
      (tester) async {
    agrandar(tester);
    final provider = await makeProvider();
    final crop = await provider.addCrop('Café', areaHa: 5);
    await provider.addSowing(
        cropId: crop.id,
        date: DateTime(2020, 3, 12),
        plants: 1000,
        areaHa: 5);
    await provider.addSowing(
        cropId: crop.id,
        date: DateTime(2024, 5, 1),
        plants: 300,
        areaHa: 1,
        replacesPlants: 0);

    final l10n = await abrirForm(tester, provider);
    await tester.tap(find.text(l10n.sowingKindResiembra));
    await tester.pumpAndSettle();

    expect(find.text(l10n.sowingCohortLabel), findsOneWidget);
    expect(find.text(l10n.sowingCohortOption('12/03/2020', 1000)),
        findsOneWidget,
        reason: 'por defecto, el lote más viejo vivo');
    expect(find.text(l10n.sowingCohortOption('01/05/2024', 300)),
        findsNothing,
        reason: 'el otro está en el menú, no elegido');
  });

  testWidgets('sin lotes vivos avisa y ofrece anotar como siembra',
      (tester) async {
    agrandar(tester);
    final provider = await makeProvider();
    final crop = await provider.addCrop('Café', areaHa: 5);
    await provider.addSowing(
        cropId: crop.id,
        date: DateTime(2020, 3, 12),
        plants: 100,
        areaHa: 5);
    await provider.addSowing(
        cropId: crop.id,
        date: DateTime(2024, 5, 1),
        kind: SowingKind.resiembra,
        plants: 0,
        lostPlants: 100);

    final l10n = await abrirForm(tester, provider);
    await tester.tap(find.descendant(
        of: find.byType(SegmentedButton<SowingKind>),
        matching: find.text(l10n.sowingKindResiembra)));
    await tester.pumpAndSettle();

    expect(find.text(l10n.sowingCohortNoneTitle), findsOneWidget);
    expect(find.text(l10n.sowingCohortNoneBody), findsOneWidget);
    expect(find.text(l10n.sowingCohortNoneSaveAs), findsOneWidget);

    await tester.tap(find.text(l10n.sowingCohortNoneSaveAs));
    await tester.pumpAndSettle();

    expect(find.text(l10n.sowingLostPlantsLabel), findsNothing,
        reason: 'pasó a siembra: ya no pide pérdidas');
    expect(find.text(l10n.sowingCohortNoneTitle), findsNothing);
  });

  testWidgets('borrar el lote viejo avisa con el total que queda',
      (tester) async {
    agrandar(tester);
    final provider = await makeProvider();
    final crop = await provider.addCrop('Café', areaHa: 5);
    final s1 = await provider.addSowing(
        cropId: crop.id,
        date: DateTime(2020, 1, 1),
        plants: 1000,
        areaHa: 5);
    await provider.addSowing(
        cropId: crop.id,
        date: DateTime(2024, 1, 1),
        plants: 400,
        areaHa: 1,
        replacesPlants: 400,
        cohortSowingId: s1.id);
    expect(provider.crops.single.livePlants, 1000);

    await pumpScreen(tester, provider);
    final l10n =
        AppLocalizations.of(tester.element(find.byType(SowingScreen)))!;
    // La lista va de más nueva a más vieja: la vieja es la última.
    await tester.tap(find.byIcon(Icons.delete_outline).last);
    await tester.pumpAndSettle();

    expect(find.text(l10n.sowingDeleteCohortBody(400)), findsOneWidget,
        reason: 'dice el total que va a quedar antes de borrar');

    await tester.tap(find.text(l10n.delete).last);
    await tester.pumpAndSettle();

    expect(provider.sowings, hasLength(1));
    expect(provider.crops.single.livePlants, 400);
    expect(provider.sowings.single.cohortSowingId, isNull,
        reason: 'el puntero a un lote borrado no queda colgado');
    expect(provider.sowings.single.pendingSync, isTrue);
  });

  testWidgets('una siembra con puntero roto se lista «sin lote»',
      (tester) async {
    agrandar(tester);
    final provider = await makeProvider();
    final crop = await provider.addCrop('Café', areaHa: 5);
    await provider.addSowing(
        cropId: crop.id,
        date: DateTime(2020, 1, 1),
        plants: 1000,
        areaHa: 5);
    await provider.addSowing(
        cropId: crop.id,
        date: DateTime(2024, 1, 1),
        plants: 400,
        areaHa: 1,
        replacesPlants: 400,
        cohortSowingId: 'no-existe');

    await pumpScreen(tester, provider);
    final l10n =
        AppLocalizations.of(tester.element(find.byType(SowingScreen)))!;

    expect(find.textContaining(l10n.sowingNoCohortTag), findsOneWidget,
        reason: 'no se adivina el lote por fecha: se dice que no tiene');
  });
}
