import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/models/crop.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/screens/crops_screen.dart';
import 'package:mi_cafetal/services/local_store.dart';
import 'package:mi_cafetal/widgets/crop_editor_dialog.dart';

/// Regresiones del lote 1 de correcciones (2026-10-03):
/// C1 guardar la moneda al editar, C2 botón de eliminar con confirmación
/// y C5 crear el cultivo con el formulario completo de una sola vez.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<TransactionProvider> makeProvider({bool seed = true}) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final provider = TransactionProvider(LocalStore(prefs));
    if (seed) await provider.addCrop('Café');
    return provider;
  }

  Future<void> pump(WidgetTester tester, TransactionProvider provider) async {
    // El diálogo de cultivo es largo: sin viewport alto varios campos
    // quedan fuera del área construida.
    tester.view.physicalSize = const Size(900, 3000);
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

  AppLocalizations l10nOf(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(CropsScreen)))!;

  testWidgets('C1: al editar un cultivo se guarda la moneda', (tester) async {
    final provider = await makeProvider();
    await pump(tester, provider);
    final l10n = l10nOf(tester);

    expect(find.byTooltip(l10n.edit), findsOneWidget,
        reason: 'el botón de lápiz ahora se llama "Editar" (C2)');
    await tester.tap(find.byTooltip(l10n.edit));
    await tester.pumpAndSettle();

    final dialogL10n =
        AppLocalizations.of(tester.element(find.byType(CropEditorDialog)))!;
    expect(find.text(dialogL10n.editCropTitle), findsOneWidget);

    // El campo de moneda es el último desplegable de tipo String.
    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('(USD)').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text(dialogL10n.add));
    await tester.pumpAndSettle();

    expect(find.byType(CropEditorDialog), findsNothing);
    expect(provider.crops.single.currency, 'USD',
        reason: 'C1: antes la moneda se descartaba en silencio al editar');
    expect(provider.crops.single.name, 'Café');
  });

  testWidgets('C5: crear un cultivo guarda fase y área desde el formulario',
      (tester) async {
    final provider = await makeProvider();
    await pump(tester, provider);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.byType(CropEditorDialog), findsOneWidget);

    final dialogL10n =
        AppLocalizations.of(tester.element(find.byType(CropEditorDialog)))!;

    await tester.enterText(find.byType(TextField).at(0), 'Plátano');
    await tester.enterText(find.byType(TextField).at(1), '1.5');

    await tester.tap(find.byType(DropdownButtonFormField<CropPhase>));
    await tester.pumpAndSettle();
    // "Establecimiento" ya viene preseleccionado (L2.0): aparece en el botón
    // y en el menú. `.last` es la opción del menú, la que se puede tocar.
    await tester.tap(find.text(dialogL10n.phaseEstablecimiento).last);
    await tester.pumpAndSettle();

    await tester.tap(find.text(dialogL10n.add));
    await tester.pumpAndSettle();

    // No debe salir el "¿Quieres agregar otro?" porque ya había cultivos.
    expect(find.byType(CropEditorDialog), findsNothing);
    expect(provider.crops, hasLength(2));

    final nuevo = provider.crops.firstWhere((c) => c.name == 'Plátano');
    expect(nuevo.phase, CropPhase.establecimiento);
    expect(nuevo.areaHa, 1.5);
    expect(nuevo.pendingSync, isTrue);
  });

  testWidgets('C2: eliminar pide confirmación y borra el cultivo',
      (tester) async {
    final provider = await makeProvider();
    final otras = await provider.addCrop('Plátano');
    await pump(tester, provider);
    final l10n = l10nOf(tester);

    expect(find.byTooltip(l10n.delete), findsNWidgets(2),
        reason: 'cada fila tiene su botón de eliminar (C2)');
    await tester.tap(find.byTooltip(l10n.delete).first);
    await tester.pumpAndSettle();

    // Confirmación.
    expect(find.text(l10n.deleteCropTitle), findsOneWidget);
    expect(find.text(l10n.deleteCropBodyEmpty('Café')), findsOneWidget,
        reason: 'sin siembras ni cosechas usa el texto corto');

    await tester.tap(find.text(l10n.cancel));
    await tester.pumpAndSettle();
    expect(provider.crops, hasLength(2), reason: 'cancelar no borra nada');

    // Ahora sí.
    await tester.tap(find.byTooltip(l10n.delete).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.delete));
    await tester.pumpAndSettle();

    expect(provider.crops.map((c) => c.id), [otras.id],
        reason: 'debe borrarse solo el cultivo elegido');
  });
}
