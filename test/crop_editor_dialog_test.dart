import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/widgets/crop_editor_dialog.dart';

class _Holder {
  CropFormData? value;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<_Holder> openDialog(WidgetTester tester) async {
    final holder = _Holder();
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () async {
                holder.value = await showDialog<CropFormData>(
                  context: context,
                  builder: (_) => const CropEditorDialog(existingNames: []),
                );
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    return holder;
  }

  testWidgets('el campo de costo del establecimiento es opcional', (tester) async {
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final holder = await openDialog(tester);
    final l10n = AppLocalizations.of(
        tester.element(find.byType(CropEditorDialog)))!;
    expect(find.text(l10n.establishmentCostLabel), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'Café');
    await tester.tap(find.text(l10n.add));
    await tester.pumpAndSettle();
    expect(find.byType(CropEditorDialog), findsNothing,
        reason: 'el diálogo debe cerrarse al confirmar');
    expect(holder.value, isNotNull);
    expect(holder.value!.name, 'Café');
    expect(holder.value!.establishmentCost, isNull);
  });

  testWidgets('ingresar costo del establecimiento lo devuelve en el formulario', (tester) async {
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final holder = await openDialog(tester);
    final l10n = AppLocalizations.of(
        tester.element(find.byType(CropEditorDialog)))!;

    await tester.enterText(find.byType(TextField).at(0), 'Café');
    await tester.enterText(find.byType(TextField).at(3), '12500000');
    await tester.tap(find.text(l10n.add));
    await tester.pumpAndSettle();
    expect(holder.value!.establishmentCost, 12500000);
  });
}