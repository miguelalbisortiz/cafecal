import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_cafetal/models/terreno.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/screens/register_screen.dart';
import 'package:mi_cafetal/screens/sowing_screen.dart';
import 'package:mi_cafetal/services/local_store.dart';
import 'package:mi_cafetal/widgets/crop_setup_prompt.dart';
import 'package:mi_cafetal/widgets/new_crop_dialog.dart';

import 'helpers/l2_common.dart';

/// Tanda 2A · el alta corta deja de crear cultivos ciegos: ofrece terreno,
/// área y unidad como opcionales, y "Ahora no" pospone por cultivo.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<TransactionProvider> makeProvider() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    return TransactionProvider(LocalStore(prefs));
  }

  Finder fieldWithLabel(String label) => find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.labelText == label);

  Finder dropdownWithLabel(String label) => find.byWidgetPredicate((w) =>
      w is DropdownButtonFormField<String> &&
      w.decoration.labelText == label);

  Finder dropdownWithNewOption() => find.byWidgetPredicate((w) =>
      w is DropdownButton &&
      (w.items ?? const []).any((i) => i.value == '__new__'));

  Future<void> fillQuickAdd(WidgetTester tester, String name) async {
    await tester.enterText(inNewCrop(fieldWithLabel(es.cropNameLabel)), name);
    await tester.pumpAndSettle();

    final terreno = inNewCrop(dropdownWithLabel(es.cropTerrenoLabel));
    expect(terreno, findsOneWidget,
        reason: 'si hay lotes, el alta corta tiene que ofrecerlos');
    await tester.tap(terreno);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lote Alto').last);
    await tester.pumpAndSettle();

    await tester.enterText(inNewCrop(fieldWithLabel(es.areaHaLabel)), '2,5');
    await tester.pumpAndSettle();

    final unidad = inNewCrop(dropdownWithLabel(es.defaultUnitLabel));
    expect(unidad, findsOneWidget);
    await tester.tap(unidad);
    await tester.pumpAndSettle();
    await tester.tap(find.text(es.unitArroba).last);
    await tester.pumpAndSettle();

    await tester.tap(inNewCrop(find.text(es.add)));
    await tester.pumpAndSettle();
  }

  testWidgets('el diálogo corto devuelve terreno, área y unidad', (tester) async {
    bigScreen(tester);
    NewCropResult? result;
    await tester.pumpWidget(plainApp(Scaffold(
      body: Center(
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDialog<NewCropResult>(
              context: context,
              builder: (_) => const NewCropDialog(
                crops: [],
                terrenos: [Terreno(id: 't1', name: 'Lote Alto')],
              ),
            ).then((r) => result = r),
            child: const Text('abrir'),
          ),
        ),
      ),
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    await fillQuickAdd(tester, 'Café de altura');

    expect(result, isNotNull);
    final created = result!;
    expect(created.name, 'Café de altura');
    expect(created.terrenoId, 't1');
    expect(created.areaHa, 2.5);
    expect(created.defaultUnit, 'arroba');
  });

  testWidgets('Registro guarda el contexto del alta corta', (tester) async {
    bigScreen(tester);
    final tx = await makeProvider();
    final lote = await tx.addTerreno('Lote Alto');
    await tester.pumpWidget(appWith(
        tx,
        const Scaffold(
            body: RegisterScreen(initialType: null))));
    await tester.pumpAndSettle();

    await tester.tap(dropdownWithNewOption());
    await tester.pumpAndSettle();
    await tester.tap(find.text(es.cropNewOption).last);
    await tester.pumpAndSettle();
    await fillQuickAdd(tester, 'Café de altura');

    final crop = tx.crops.single;
    expect(crop.name, 'Café de altura');
    expect(crop.terrenoId, lote.id, reason: 'el lote elegido no puede perderse');
    expect(crop.areaHa, 2.5);
    expect(crop.defaultUnit, 'arroba');
  });

  testWidgets('Siembras guarda el contexto del alta corta', (tester) async {
    bigScreen(tester);
    final tx = await makeProvider();
    final lote = await tx.addTerreno('Lote Alto');
    await tester.pumpWidget(appWith(tx, const SowingScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(dropdownWithNewOption());
    await tester.pumpAndSettle();
    await tester.tap(find.text(es.sowingNewCropOption).last);
    await tester.pumpAndSettle();
    await fillQuickAdd(tester, 'Café de altura');

    final crop = tx.crops.single;
    expect(crop.terrenoId, lote.id);
    expect(crop.areaHa, 2.5);
    expect(crop.defaultUnit, 'arroba');
  });

  test('«Ahora no» pospone por cultivo, no para siempre', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    const legacy = 'crop_setup_prompt_dismissed_v1';

    expect(await CropSetupPrompt.canAsk('c1'), isTrue);
    await CropSetupPrompt.markDismissed('c1');
    expect(await CropSetupPrompt.canAsk('c1'), isFalse);
    expect(await CropSetupPrompt.canAsk('c2'), isTrue,
        reason: 'decir que no en un cultivo no calla los demás');

    await prefs.setBool(legacy, true);
    expect(await CropSetupPrompt.canAsk('c3'), isTrue,
        reason: 'la preferencia vieja global no puede bloquear cultivos nuevos');
  });
}
