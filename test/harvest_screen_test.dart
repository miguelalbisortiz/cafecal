import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/models/harvest.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/screens/harvest_screen.dart';
import 'package:mi_cafetal/services/local_store.dart';

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
}
