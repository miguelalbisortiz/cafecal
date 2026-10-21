import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/models/crop.dart';
import 'package:mi_cafetal/models/harvest.dart';
import 'package:mi_cafetal/widgets/per_hectare_panel.dart';

/// T11 · kg/planta es un promedio del cultivo completo: incluye las matas que
/// todavía no producen. La nota lo dice; el cálculo no se toca.
void main() {
  testWidgets('el panel explica el kg/planta cuando lo muestra', (tester) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    const crop = Crop(id: 'c1', name: 'Café', areaHa: 1, livePlants: 100);
    final harvest = Harvest(
      id: 'h1',
      cropId: 'c1',
      date: DateTime(2026, 10, 1),
      amount: 500,
      unit: 'kg',
    );

    await tester.pumpWidget(MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: PerHectarePanel(
            crops: const [crop],
            periodTransactions: const [],
            periodHarvests: [harvest],
            allTransactions: const [],
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('5.00 kg/planta'), findsOneWidget);
    expect(find.text(stringsFor('es').perHaPerPlantNote), findsOneWidget);
  });

  testWidgets('sin kg/planta la nota no aparece', (tester) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    const crop = Crop(id: 'c1', name: 'Café', areaHa: 1);
    final harvest = Harvest(
      id: 'h1',
      cropId: 'c1',
      date: DateTime(2026, 10, 1),
      amount: 500,
      unit: 'kg',
    );

    await tester.pumpWidget(MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: PerHectarePanel(
            crops: const [crop],
            periodTransactions: const [],
            periodHarvests: [harvest],
            allTransactions: const [],
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text(stringsFor('es').perHaPerPlantNote), findsNothing,
        reason: 'sin plantas contadas no hay kg/planta que explicar');
  });
}
