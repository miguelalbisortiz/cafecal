import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mi_cafetal/models/crop.dart';
import 'package:mi_cafetal/screens/sowing_screen.dart';

import 'helpers/l2_common.dart';

/// L2.4 — la resiembra ofrece pasar el cultivo a renovación; nunca sola y
/// nunca desde una siembra inicial.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> openForm(WidgetTester tester) async {
    await tester.tap(find.text(es.sowingAdd));
    await tester.pumpAndSettle();
  }

  testWidgets('la casilla solo aparece en resiembra', (tester) async {
    bigScreen(tester);
    final provider = await makeTx();
    await provider.addCrop('Café');

    await tester.pumpWidget(appWith(provider, const SowingScreen()));
    await tester.pumpAndSettle();
    await openForm(tester);

    // Siembra inicial: no hay casilla que marcar.
    expect(find.byType(CheckboxListTile), findsNothing);

    await tester.tap(find.text(es.sowingKindResiembra));
    await tester.pumpAndSettle();

    expect(find.byType(CheckboxListTile), findsOneWidget);
    expect(
      tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
      isFalse,
      reason: 'nunca viene marcada',
    );

    // Vuelta a siembra inicial: desaparece.
    await tester.tap(find.text(es.sowingKindSiembra).last);
    await tester.pumpAndSettle();
    expect(find.byType(CheckboxListTile), findsNothing);
  });

  testWidgets('sin marcar, la fase no cambia', (tester) async {
    bigScreen(tester);
    final provider = await makeTx();
    await provider.addCrop('Café');

    await tester.pumpWidget(appWith(provider, const SowingScreen()));
    await tester.pumpAndSettle();
    await openForm(tester);

    await tester.tap(find.text(es.sowingKindResiembra));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '50');
    await tester.tap(find.text(es.add).last);
    await tester.pumpAndSettle();

    expect(provider.sowings, hasLength(1));
    expect(provider.crops.single.phase, CropPhase.establecimiento);
  });

  testWidgets('marcada, la fase pasa a renovación', (tester) async {
    bigScreen(tester);
    final provider = await makeTx();
    await provider.addCrop('Café');

    await tester.pumpWidget(appWith(provider, const SowingScreen()));
    await tester.pumpAndSettle();
    await openForm(tester);

    await tester.tap(find.text(es.sowingKindResiembra));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    expect(
      tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
      isTrue,
    );

    await tester.enterText(find.byType(TextFormField).first, '30');
    await tester.tap(find.text(es.add).last);
    await tester.pumpAndSettle();

    expect(provider.sowings, hasLength(1));
    expect(provider.crops.single.phase, CropPhase.renovacion);
    expect(provider.crops.single.pendingSync, isTrue);
  });

  testWidgets('en siembra inicial la fase sigue sin tocarse', (tester) async {
    bigScreen(tester);
    final provider = await makeTx();
    await provider.addCrop('Café');

    await tester.pumpWidget(appWith(provider, const SowingScreen()));
    await tester.pumpAndSettle();
    await openForm(tester);

    expect(find.byType(CheckboxListTile), findsNothing);
    await tester.enterText(find.byType(TextFormField).first, '100');
    await tester.tap(find.text(es.add).last);
    await tester.pumpAndSettle();

    expect(provider.sowings, hasLength(1));
    expect(provider.sowings.single.kind.name, 'siembra');
    expect(provider.crops.single.phase, CropPhase.establecimiento);
  });
}
