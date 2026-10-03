import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/screens/assign_crops_screen.dart';
import 'package:mi_cafetal/screens/register_screen.dart';
import 'package:mi_cafetal/screens/sowing_screen.dart';

import 'helpers/l2_common.dart';

/// L2.5 — tres pendientes ya decididos: moneda coherente en las puertas
/// cortas, aviso descartable para completar el cultivo y área opcional con
/// aviso.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Finder dropdownWithNewOption() => find.byWidgetPredicate((w) =>
      w is DropdownButton<String> &&
      (w.items ?? const []).any((i) => i.value == '__new__'));

  group('(a) la moneda de ajustes llega a las puertas cortas', () {
    testWidgets('Siembras', (tester) async {
      bigScreen(tester);
      final provider = await makeTx();
      await provider.updateSettings(
          provider.settings.copyWith(currency: 'USD'));

      await tester.pumpWidget(appWith(provider, const SowingScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.text(es.sowingAdd));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(es.sowingNewCropOption).last);
      await tester.pumpAndSettle();
      await submitNewCrop(tester, 'Tomate');

      expect(provider.crops, hasLength(1));
      expect(provider.crops.single.currency, 'USD');
    });

    testWidgets('Asignar', (tester) async {
      bigScreen(tester);
      final provider = await makeTx();
      await provider.updateSettings(
          provider.settings.copyWith(currency: 'USD'));
      await provider.addTransaction(
        type: TransactionType.expense,
        category: 'fertilizante',
        amount: 500000,
        description: 'Abono',
        date: DateTime(2026, 9, 1),
      );

      await tester.pumpWidget(appWith(provider, Scaffold(
        body: Center(
          child: Builder(builder: (context) => ElevatedButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const AssignCropsScreen())),
            child: const Text('abrir'),
          )),
        ),
      )));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<String?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(es.assignCropsNewCrop).last);
      await tester.pumpAndSettle();
      await submitNewCrop(tester, 'Tomate');

      expect(provider.crops, hasLength(1));
      expect(provider.crops.single.currency, 'USD');
    });

    testWidgets('Registro ya la pasaba: se verifica sin duplicar',
        (tester) async {
      bigScreen(tester);
      final provider = await makeTx();
      await provider.updateSettings(
          provider.settings.copyWith(currency: 'USD'));

      await tester.pumpWidget(
          appWith(provider, const Scaffold(body: RegisterScreen())));
      await tester.pumpAndSettle();

      await tester.tap(dropdownWithNewOption());
      await tester.pumpAndSettle();
      await tester.tap(find.text(es.cropNewOption).last);
      await tester.pumpAndSettle();
      await submitNewCrop(tester, 'Tomate');

      expect(provider.crops, hasLength(1));
      expect(provider.crops.single.currency, 'USD');
    });
  });

  group('(b) aviso opcional para completar los datos', () {
    testWidgets('se descarta y no vuelve a preguntar', (tester) async {
      bigScreen(tester);
      final provider = await makeTx();
      await tester.pumpWidget(
          appWith(provider, const Scaffold(body: RegisterScreen())));
      await tester.pumpAndSettle();

      Future<void> crearCrop(String name) async {
        await tester.tap(dropdownWithNewOption());
        await tester.pumpAndSettle();
        await tester.tap(find.text(es.cropNewOption).last);
        await tester.pumpAndSettle();
        await submitNewCrop(tester, name);
      }

      await crearCrop('Café');
      expect(provider.crops, hasLength(1));
      expect(find.byType(MaterialBanner), findsOneWidget);
      expect(find.text(es.cropSetupPrompt), findsOneWidget);
      expect(find.text(es.cropSetupComplete), findsOneWidget);

      await tester.tap(find.text(es.cropSetupLater));
      await tester.pumpAndSettle();
      expect(find.byType(MaterialBanner), findsNothing,
          reason: '"Ahora no" cierra el aviso al instante');

      await crearCrop('Plátano');
      expect(provider.crops, hasLength(2));
      expect(find.byType(MaterialBanner), findsNothing,
          reason: 'quien dijo que no, ya no vuelve a ser preguntado');
      expect(find.text(es.cropSetupPrompt), findsNothing);
    });

    testWidgets('"Completar" abre el editor y guarda con updateCrop',
        (tester) async {
      bigScreen(tester);
      final provider = await makeTx();
      await tester.pumpWidget(
          appWith(provider, const Scaffold(body: RegisterScreen())));
      await tester.pumpAndSettle();

      await tester.tap(dropdownWithNewOption());
      await tester.pumpAndSettle();
      await tester.tap(find.text(es.cropNewOption).last);
      await tester.pumpAndSettle();
      await submitNewCrop(tester, 'Tomate');
      expect(find.byType(MaterialBanner), findsOneWidget);

      await tester.tap(find.text(es.cropSetupComplete));
      await tester.pumpAndSettle();

      expect(find.byType(MaterialBanner), findsNothing);
      expect(find.text(es.editCropTitle), findsOneWidget);

      // Cambia el área y guarda (el campo de área es el segundo TextField
      // del editor: nombre, área, plantas, costo).
      final area = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField));
      await tester.enterText(area.at(1), '1.5');
      await tester.tap(find.descendant(
          of: find.byType(AlertDialog), matching: find.text(es.add)));
      await tester.pumpAndSettle();

      expect(provider.crops.single.areaHa, 1.5);
    });
  });

  group('(c) área opcional con aviso', () {
    testWidgets('se puede guardar sin área y el aviso está presente',
        (tester) async {
      bigScreen(tester);
      final provider = await makeTx();
      final cafe = await provider.addCrop('Café');

      await tester.pumpWidget(appWith(provider, const SowingScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.text(es.sowingAdd));
      await tester.pumpAndSettle();

      expect(find.text(es.sowingAreaMissingWarning), findsOneWidget,
          reason: 'explica la consecuencia sin bloquear');
      expect(find.text(es.helpSowingAreaShort), findsNothing);

      await tester.enterText(find.byType(TextFormField).first, '100');
      await tester.tap(find.text(es.add).last);
      await tester.pumpAndSettle();

      expect(provider.sowings, hasLength(1));
      expect(provider.sowings.single.areaHa, isNull);
      expect(provider.sowings.single.cropId, cafe.id);
    });

    testWidgets('al escribir el área el aviso se quita', (tester) async {
      bigScreen(tester);
      final provider = await makeTx();
      await provider.addCrop('Café');

      await tester.pumpWidget(appWith(provider, const SowingScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.text(es.sowingAdd));
      await tester.pumpAndSettle();

      expect(find.text(es.sowingAreaMissingWarning), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).at(1), '0,4');
      await tester.pumpAndSettle();

      expect(find.text(es.sowingAreaMissingWarning), findsNothing);
      expect(find.text(es.helpSowingAreaShort), findsOneWidget);
    });
  });

  testWidgets('el aviso de completar datos se abre desde Siembras',
      (tester) async {
    bigScreen(tester);
    final provider = await makeTx();
    await tester.pumpWidget(appWith(provider, const SowingScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text(es.sowingAdd));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(es.sowingNewCropOption).last);
    await tester.pumpAndSettle();
    await submitNewCrop(tester, 'Tomate');
    // Mientras el formulario sigue abierto no se muestra (quedaría tapado).
    expect(find.byType(MaterialBanner), findsNothing);

    await tester.enterText(find.byType(TextFormField).first, '100');
    await tester.tap(find.text(es.add).last);
    await tester.pumpAndSettle();

    expect(provider.sowings, hasLength(1));
    expect(find.byType(MaterialBanner), findsOneWidget);
    expect(find.text(es.cropSetupPrompt), findsOneWidget);

    // Y el resto del formulario se sigue usando con el aviso arriba.
    expect(find.text(es.sowingAdd), findsOneWidget);
  });
}
