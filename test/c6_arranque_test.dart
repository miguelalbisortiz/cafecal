import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mi_cafetal/models/crop.dart';
import 'package:mi_cafetal/models/sowing.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/screens/sowing_screen.dart';

import 'helpers/l2_common.dart';

/// C6 — el cultivo se arrancó entero y se volvió a plantar.
///
/// La **edad** ya se reinicia sola (`edadDeCrop` toma la siembra más
/// reciente). Lo que no se reinicia solo son la **fase** y la **fecha de la
/// primera cosecha**, y eso es lo que hace esta casilla.
///
/// Regla de oro: **nunca se marca sola** y **no aparece si no puede ser un
/// arranque** — quien no arranca nada ve la pantalla siempre igual.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> openForm(WidgetTester tester) async {
    await tester.tap(find.text(es.sowingAdd));
    await tester.pumpAndSettle();
  }

  Finder casilla() => find.byType(CheckboxListTile);

  String? textoDeLaCasilla(WidgetTester tester) {
    final t = tester.widget<CheckboxListTile>(casilla()).title;
    return t is Text ? t.data : null;
  }

  /// El caso real de un lote que se va a arrancar: ya en "Dando", con la
  /// fecha de primera cosecha que él puso, y con una siembra previa.
  Future<TransactionProvider> loteListo() async {
    final provider = await makeTx();
    await provider.addCrop(
      'Café',
      phase: CropPhase.produccion,
      primerCosechaEsperada: DateTime(2024, 3, 1),
    );
    await provider.addSowing(
      cropId: provider.crops.single.id,
      date: DateTime(2019, 1, 1),
      plants: 100,
    );
    return provider;
  }

  testWidgets('en la primera siembra no hay casilla que marcar',
      (tester) async {
    bigScreen(tester);
    final provider = await makeTx();
    await provider.addCrop('Café');

    await tester.pumpWidget(appWith(provider, const SowingScreen()));
    await tester.pumpAndSettle();
    await openForm(tester);

    expect(casilla(), findsNothing);
  });

  testWidgets('la casilla aparece cuando ya hubo una siembra antes',
      (tester) async {
    bigScreen(tester);
    final provider = await loteListo();

    await tester.pumpWidget(appWith(provider, const SowingScreen()));
    await tester.pumpAndSettle();
    await openForm(tester);

    expect(casilla(), findsOneWidget);
    expect(
      tester.widget<CheckboxListTile>(casilla()).value,
      isFalse,
      reason: 'nunca viene marcada',
    );
    expect(textoDeLaCasilla(tester), es.sowingRestartCheckbox);
  });

  testWidgets('sin marcar, ni la fase ni la fecha se tocan', (tester) async {
    bigScreen(tester);
    final provider = await loteListo();

    await tester.pumpWidget(appWith(provider, const SowingScreen()));
    await tester.pumpAndSettle();
    await openForm(tester);

    await tester.enterText(find.byType(TextFormField).first, '80');
    await tester.tap(find.text(es.add).last);
    await tester.pumpAndSettle();

    expect(provider.sowings, hasLength(2));
    expect(provider.crops.single.phase, CropPhase.produccion);
    expect(
      provider.crops.single.primerCosechaEsperada,
      DateTime(2024, 3, 1),
      reason: 'la fecha sigue siendo la del ciclo anterior',
    );
  });

  testWidgets('marcada, vuelve a «Sin dar» y borra la fecha', (tester) async {
    bigScreen(tester);
    final provider = await loteListo();

    await tester.pumpWidget(appWith(provider, const SowingScreen()));
    await tester.pumpAndSettle();
    await openForm(tester);

    await tester.tap(casilla());
    await tester.pumpAndSettle();
    expect(
      tester.widget<CheckboxListTile>(casilla()).value,
      isTrue,
    );

    await tester.enterText(find.byType(TextFormField).first, '80');
    await tester.tap(find.text(es.add).last);
    await tester.pumpAndSettle();

    final crop = provider.crops.single;
    expect(provider.sowings, hasLength(2));
    expect(crop.phase, CropPhase.establecimiento);
    expect(
      crop.primerCosechaEsperada,
      isNull,
      reason: 'null → oculto, nunca una fecha inventada',
    );
    expect(crop.pendingSync, isTrue);
  });

  testWidgets('la edad se reinicia sola con la siembra nueva', (tester) async {
    bigScreen(tester);
    final provider = await loteListo();
    final antes = provider.crops.single;

    await tester.pumpWidget(appWith(provider, const SowingScreen()));
    await tester.pumpAndSettle();
    await openForm(tester);

    await tester.tap(casilla());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '80');
    await tester.tap(find.text(es.add).last);
    await tester.pumpAndSettle();

    final edad = edadDeCrop(provider.crops.single, provider.sowings);
    expect(
      edad,
      0,
      reason: 'la siembra más reciente manda: un cultivo recién arrancado '
          'no puede seguir con la edad del plantío anterior',
    );
    expect(antes.primerCosechaEsperada, isNotNull);
  });

  testWidgets('al pasar a resiembra, la de arrancar deja de estar',
      (tester) async {
    bigScreen(tester);
    final provider = await loteListo();

    await tester.pumpWidget(appWith(provider, const SowingScreen()));
    await tester.pumpAndSettle();
    await openForm(tester);

    expect(textoDeLaCasilla(tester), es.sowingRestartCheckbox);

    await tester.tap(find.text(es.sowingKindResiembra));
    await tester.pumpAndSettle();

    expect(casilla(), findsOneWidget);
    expect(
      textoDeLaCasilla(tester),
      es.sowingRenovacionCheckbox,
      reason: 'con resiembra solo queda la casilla de renovación',
    );
  });

  testWidgets('volver a siembra trae la de arrancar, desmarcada',
      (tester) async {
    bigScreen(tester);
    final provider = await loteListo();

    await tester.pumpWidget(appWith(provider, const SowingScreen()));
    await tester.pumpAndSettle();
    await openForm(tester);

    await tester.tap(casilla());
    await tester.pumpAndSettle();
    await tester.tap(find.text(es.sowingKindResiembra));
    await tester.pumpAndSettle();
    await tester.tap(find.text(es.sowingKindSiembra).last);
    await tester.pumpAndSettle();

    expect(textoDeLaCasilla(tester), es.sowingRestartCheckbox);
    expect(
      tester.widget<CheckboxListTile>(casilla()).value,
      isFalse,
      reason: 'cambiar de tipo no debe dejar marcada una casilla vieja',
    );
  });

  testWidgets('una resiembra normal no ofrece arrancar', (tester) async {
    bigScreen(tester);
    final provider = await makeTx();
    await provider.addCrop('Plátano');
    await provider.addSowing(
      cropId: provider.crops.single.id,
      date: DateTime(2025, 1, 1),
      plants: 50,
    );

    await tester.pumpWidget(appWith(provider, const SowingScreen()));
    await tester.pumpAndSettle();
    await openForm(tester);

    await tester.tap(find.text(es.sowingKindResiembra));
    await tester.pumpAndSettle();

    expect(casilla(), findsOneWidget);
    expect(textoDeLaCasilla(tester), es.sowingRenovacionCheckbox);
  });

  testWidgets('sin casilla marcada la pantalla guarda igual', (tester) async {
    bigScreen(tester);
    final provider = await loteListo();

    await tester.pumpWidget(appWith(provider, const SowingScreen()));
    await tester.pumpAndSettle();
    await openForm(tester);

    expect(casilla(), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, '60');
    await tester.tap(find.text(es.add).last);
    await tester.pumpAndSettle();

    expect(provider.sowings, hasLength(2));
    expect(provider.sowings.last.kind, SowingKind.siembra);
  });
}
