import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mi_cafetal/models/crop.dart';
import 'package:mi_cafetal/screens/crops_screen.dart';
import 'package:mi_cafetal/screens/report_screen.dart';
import 'package:mi_cafetal/screens/sowing_screen.dart';

import 'helpers/l2_common.dart';

/// L2.3 — la fase se ve (icono + frase, patrón H10) y un cultivo que sigue
/// en establecimiento dice con palabras que todavía no rinde.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Cultivos: cada fase se ve con icono distinto y texto',
      (tester) async {
    bigScreen(tester);
    final provider = await makeTx();
    final cafe = await provider.addCrop('Café'); // nace en establecimiento
    await provider.addCrop('Plátano', phase: CropPhase.produccion);

    await tester.pumpWidget(appWith(provider, const CropsScreen()));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.spa_outlined), findsOneWidget);
    expect(find.text(es.phaseEstablecimiento), findsOneWidget);
    expect(find.byIcon(Icons.agriculture_outlined), findsOneWidget);
    expect(find.text(es.phaseProduccion), findsOneWidget);

    await provider.updateCrop(cafe.copyWith(phase: CropPhase.renovacion));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.autorenew), findsOneWidget);
    expect(find.text(es.phaseRenovacion), findsOneWidget);
    expect(find.byIcon(Icons.spa_outlined), findsNothing);
  });

  testWidgets('Siembras: "aún no rinde" solo para establecimiento',
      (tester) async {
    bigScreen(tester);
    final provider = await makeTx();
    final cafe = await provider.addCrop('Café');
    await provider.addSowing(
        cropId: cafe.id, date: DateTime.now(), plants: 100, areaHa: 0.4);

    await tester.pumpWidget(appWith(provider, const SowingScreen()));
    await tester.pumpAndSettle();

    expect(find.text(es.cropPhaseNoYield), findsOneWidget);

    await provider.updateCrop(cafe.copyWith(phase: CropPhase.produccion));
    await tester.pumpAndSettle();

    expect(find.text(es.cropPhaseNoYield), findsNothing,
        reason: 'en producción la frase no aparece');
  });

  testWidgets('Reporte: la sección Siembras también avisa que no rinde',
      (tester) async {
    tester.view.physicalSize = const Size(900, 8000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final provider = await makeTx();
    final cafe = await provider.addCrop('Café');
    await provider.addSowing(
        cropId: cafe.id, date: DateTime.now(), plants: 400, areaHa: 0.5);

    await tester.pumpWidget(appWith(provider, const ReportScreen()));
    await tester.pumpAndSettle();

    expect(find.text(es.reportSowingsSection), findsOneWidget);
    expect(find.text(es.cropPhaseNoYield), findsOneWidget);

    await provider.updateCrop(cafe.copyWith(phase: CropPhase.produccion));
    await tester.pumpAndSettle();

    expect(find.text(es.cropPhaseNoYield), findsNothing);
  });
}
