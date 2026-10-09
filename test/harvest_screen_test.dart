import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/models/harvest.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/screens/harvest_screen.dart';
import 'package:mi_cafetal/services/local_store.dart';
import 'package:mi_cafetal/utils/format.dart';

/// P4 — aquí no hay bodega: todo lo cosechado se vende, así que el destino
/// "almacenado" dejan de ofrecerse. Los históricos siguen legibles y editables.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<TransactionProvider> makeProvider() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final provider = TransactionProvider(LocalStore(prefs));
    await provider.addCrop('Café');
    return provider;
  }

  Future<void> pump(WidgetTester tester, TransactionProvider provider) async {
    // El formulario es largo: sin viewport alto el desplegable de destino
    // queda fuera del área construida.
    tester.view.physicalSize = const Size(900, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: provider,
      child: const MaterialApp(
        locale: Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: HarvestScreen(),
      ),
    ));
    await tester.pumpAndSettle();
  }

  AppLocalizations l10nOf(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(HarvestScreen)))!;

  testWidgets('P4: registrar una cosecha ya no ofrece "Almacenado"',
      (tester) async {
    final provider = await makeProvider();
    await pump(tester, provider);
    final l10n = l10nOf(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.byType(DropdownButtonFormField<HarvestDestination>),
        findsOneWidget);

    await tester
        .tap(find.byType(DropdownButtonFormField<HarvestDestination>));
    await tester.pumpAndSettle();

    expect(find.text(l10n.harvestDstPerdida), findsWidgets,
        reason: 'el menú sí está abierto');
    expect(find.text(l10n.harvestDstAlmacenado), findsNothing,
        reason: 'no se puede elegir almacenado: aquí no hay bodega (P4)');
  });

  testWidgets(
      'P4: una cosecha histórica en "Almacenado" sigue visible y editable',
      (tester) async {
    final provider = await makeProvider();
    final crop = provider.crops.first;
    final vieja = await provider.addHarvest(
      cropId: crop.id,
      date: DateTime(2026, 3, 10),
      amount: 50,
      destination: HarvestDestination.almacenado,
    );
    await pump(tester, provider);
    final l10n = l10nOf(tester);

    expect(find.textContaining(l10n.harvestDstAlmacenado), findsOneWidget,
        reason: 'la lista sigue mostrando el destino histórico');

    // Tocar la fila abre el formulario en modo edición.
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();

    expect(find.byType(DropdownButtonFormField<HarvestDestination>),
        findsOneWidget);
    expect(find.text(l10n.harvestDstAlmacenado), findsOneWidget,
        reason: 'el desplegable debe poder seguir mostrando su valor actual');

    // Y al abrir el menú el ítem sigue ahí, o Flutter reventaría con
    // "value is not one of the items".
    await tester
        .tap(find.byType(DropdownButtonFormField<HarvestDestination>));
    await tester.pumpAndSettle();
    expect(find.text(l10n.harvestDstAlmacenado), findsWidgets);

    expect(vieja.destination, HarvestDestination.almacenado);
  });

  testWidgets('F1: el precio aparece cuando la cosecha es "Vendido"',
      (tester) async {
    final provider = await makeProvider();
    await pump(tester, provider);
    final l10n = l10nOf(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text(l10n.harvestPriceLabel(l10n.unitKg)), findsOneWidget,
        reason: 'por defecto el destino es vendido');
    // cantidad · precio · empleados
    expect(find.byType(TextFormField), findsNWidgets(3));
  });

  testWidgets('F1: el precio desaparece cuando la cosecha es "Pérdida"',
      (tester) async {
    final provider = await makeProvider();
    await pump(tester, provider);
    final l10n = l10nOf(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester
        .tap(find.byType(DropdownButtonFormField<HarvestDestination>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.harvestDstPerdida).last);
    await tester.pumpAndSettle();

    expect(find.text(l10n.harvestPriceLabel(l10n.unitKg)), findsNothing,
        reason: 'una pérdida no se vende, no hay precio que pedir');
    // cantidad · empleados
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets('F1: guardar con precio crea la venta ligada a la cosecha',
      (tester) async {
    final provider = await makeProvider();
    await pump(tester, provider);
    final l10n = l10nOf(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), '8');
    await tester.enterText(find.byType(TextFormField).at(1), '300000');
    await tester.pumpAndSettle();

    // La vista previa usa la moneda y el locale reales, no un formato fijo.
    final esperado = formatAmount(2400000,
        currency: provider.settings.currency,
        locale: provider.settings.locale);
    expect(find.text(l10n.harvestSalePreview(esperado)), findsOneWidget,
        reason: 'la vista previa se calcula sola: 8 × 300.000');

    await tester.tap(find.widgetWithText(FilledButton, l10n.add));
    await tester.pumpAndSettle();

    expect(provider.harvests, hasLength(1));
    final ventas = provider.transactions
        .where((t) => !t.deleted && t.type == TransactionType.income)
        .toList();
    expect(ventas, hasLength(1), reason: 'una sola venta, no duplicada');
    expect(ventas.first.amount, 2400000);
    expect(ventas.first.quantity, 8);
    expect(ventas.first.pricePerUnit, 300000);
    expect(ventas.first.harvestId, provider.harvests.first.id);
    expect(provider.totalIncomes(year: 2026), 2400000);
  });
}
