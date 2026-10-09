import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/models/categories.dart';
import 'package:mi_cafetal/models/sowing.dart';
import 'package:mi_cafetal/models/transaction.dart';
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
    await tester.pump();
  }

  testWidgets('con cultivos vacios ofrece crear un cultivo nuevo desde el formulario',
      (tester) async {
    final provider = await makeProvider();
    await pumpScreen(tester, provider);
    final l10n = AppLocalizations.of(tester.element(find.byType(SowingScreen)))!;

    expect(find.text(l10n.sowingAdd), findsOneWidget);
    await tester.tap(find.text(l10n.sowingAdd));
    await tester.pumpAndSettle();

    // Abre el selector de cultivo para ver la opción de crear uno nuevo.
    await tester.tap(find.byType(DropdownButtonFormField<String?>));
    await tester.pumpAndSettle();
    expect(find.text(l10n.sowingNewCropOption).last, findsOneWidget);
  });

  // El formulario es largo: lo agrandamos para poder tocar todo sin scroll.
  void agrandar(WidgetTester tester) {
    tester.view.physicalSize = const Size(900, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  testWidgets('F2: el campo de costo aparece también en la resiembra',
      (tester) async {
    agrandar(tester);
    final provider = await makeProvider();
    await provider.addCrop('Café');
    await pumpScreen(tester, provider);
    final l10n =
        AppLocalizations.of(tester.element(find.byType(SowingScreen)))!;

    await tester.tap(find.text(l10n.sowingAdd));
    await tester.pumpAndSettle();

    // Siembra inicial: plantas · área · costo
    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(find.text(l10n.sowingCostLabel), findsOneWidget);

    await tester.tap(find.text(l10n.sowingKindResiembra));
    await tester.pumpAndSettle();

    // Resiembra: plantas nuevas · perdidas · motivo · costo
    expect(find.byType(TextFormField), findsNWidgets(4));
    expect(find.text(l10n.sowingCostLabel), findsOneWidget,
        reason: 'la resiembra también cuesta: colinos, jornal, trasplante');
  });

  testWidgets('F2: guardar una resiembra con costo crea el gasto vinculado',
      (tester) async {
    agrandar(tester);
    final provider = await makeProvider();
    final crop = await provider.addCrop('Café');
    await pumpScreen(tester, provider);
    final l10n =
        AppLocalizations.of(tester.element(find.byType(SowingScreen)))!;

    await tester.tap(find.text(l10n.sowingAdd));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.sowingKindResiembra));
    await tester.pumpAndSettle();

    final campos = find.byType(TextFormField);
    await tester.enterText(campos.at(0), '200'); // plantas nuevas
    await tester.enterText(campos.at(1), '50'); // perdidas
    await tester.enterText(campos.at(3), '75000'); // costo
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, l10n.add));
    await tester.pumpAndSettle();

    expect(provider.sowings, hasLength(1));
    expect(provider.sowings.single.kind, SowingKind.resiembra);

    final gastos = provider.transactions
        .where((t) => !t.deleted && t.type == TransactionType.expense)
        .toList();
    expect(gastos, hasLength(1), reason: 'un solo gasto, sin duplicarlo');
    expect(gastos.first.amount, 75000);
    expect(gastos.first.category, kExpenseCategorySowing);
    expect(gastos.first.sowingId, provider.sowings.single.id,
        reason: 'el vínculo es lo que hace entrar al costo por kilo');
    expect(gastos.first.cropId, crop.id);
  });

  testWidgets('F2: una resiembra sin costo no inventa gasto', (tester) async {
    agrandar(tester);
    final provider = await makeProvider();
    await provider.addCrop('Café');
    await pumpScreen(tester, provider);
    final l10n =
        AppLocalizations.of(tester.element(find.byType(SowingScreen)))!;

    await tester.tap(find.text(l10n.sowingAdd));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.sowingKindResiembra));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), '200');
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, l10n.add));
    await tester.pumpAndSettle();

    expect(provider.sowings, hasLength(1));
    expect(
      provider.transactions.where((t) => t.type == TransactionType.expense),
      isEmpty,
      reason: 'el costo sigue siendo opcional',
    );
  });

  testWidgets('F4: la resiembra permite 0 plantas nuevas si hay pérdidas',
      (tester) async {
    agrandar(tester);
    final provider = await makeProvider();
    await provider.addCrop('Café');
    await pumpScreen(tester, provider);
    final l10n =
        AppLocalizations.of(tester.element(find.byType(SowingScreen)))!;

    await tester.tap(find.text(l10n.sowingAdd));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.sowingKindResiembra));
    await tester.pumpAndSettle();

    final campos = find.byType(TextFormField);
    await tester.enterText(campos.at(0), '0'); // plantas nuevas
    await tester.enterText(campos.at(1), '50'); // perdidas
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, l10n.add));
    await tester.pumpAndSettle();

    expect(find.byType(SowingScreen), findsOneWidget,
        reason: 'el formulario se cierra: guardó');
    expect(provider.sowings, hasLength(1));
    expect(provider.sowings.single.plants, 0,
        reason: 'antes esto estaba prohibido y la mortandad se perdía');
    expect(provider.sowings.single.lostPlants, 50);
  });

  testWidgets('F4: la siembra inicial sigue exigiendo plantar algo',
      (tester) async {
    agrandar(tester);
    final provider = await makeProvider();
    await provider.addCrop('Café');
    await pumpScreen(tester, provider);
    final l10n =
        AppLocalizations.of(tester.element(find.byType(SowingScreen)))!;

    await tester.tap(find.text(l10n.sowingAdd));
    await tester.pumpAndSettle();

    // Por defecto es siembra inicial.
    await tester.enterText(find.byType(TextFormField).at(0), '0');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, l10n.add));
    await tester.pumpAndSettle();

    expect(find.text(l10n.plantsInvalid), findsOneWidget);
    expect(provider.sowings, isEmpty);
  });

  testWidgets('F4: en resiembra, ni plantas ni pérdidas no se guarda',
      (tester) async {
    agrandar(tester);
    final provider = await makeProvider();
    await provider.addCrop('Café');
    await pumpScreen(tester, provider);
    final l10n =
        AppLocalizations.of(tester.element(find.byType(SowingScreen)))!;

    await tester.tap(find.text(l10n.sowingAdd));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.sowingKindResiembra));
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, l10n.add));
    await tester.pumpAndSettle();

    expect(find.text(l10n.sowingPlantsOrLost), findsOneWidget,
        reason: 'hay que decirnos algo: o siembras o mueren');
    expect(provider.sowings, isEmpty);
  });
}