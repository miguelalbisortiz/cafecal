import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/models/crop.dart';
import 'package:mi_cafetal/models/harvest.dart';
import 'package:mi_cafetal/models/sowing.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/services/local_store.dart';
import 'package:mi_cafetal/widgets/per_hectare_panel.dart';

/// Etapa A · el kg/planta es **por cultivo**: cuando el cultivo tiene dos o más
/// edades vivas, el número mezcla lotes y hay que decirlo. La fórmula no
/// cambia y no se inventa un kg/planta por lote.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<TransactionProvider> provider() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    return TransactionProvider(LocalStore(prefs));
  }

  Widget wrap(TransactionProvider tx, Widget child) {
    return ChangeNotifierProvider.value(
      value: tx,
      child: MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
  }

  /// 1.000 matas en 2 ha: 50 kg del período dan 0,05 kg/planta.
  const crop = Crop(id: 'cafe', name: 'Café', areaHa: 2, livePlants: 1000);
  final cosecha = [
    Harvest(id: 'h1', cropId: 'cafe', date: DateTime(2026, 8, 10), amount: 50),
  ];

  final unaEdad = [
    Sowing(id: 's1', cropId: 'cafe', date: DateTime(2020, 3, 12), plants: 1000),
  ];
  final dosEdades = [
    ...unaEdad,
    Sowing(
      id: 's2',
      cropId: 'cafe',
      date: DateTime(2024, 5, 1),
      plants: 300,
      replacesPlants: 0,
    ),
  ];

  testWidgets('con dos edades agrega «promedio de 2 edades»', (tester) async {
    await tester.pumpWidget(wrap(
      await provider(),
      PerHectarePanel(
        crops: const [crop],
        periodTransactions: const [],
        periodHarvests: cosecha,
        allTransactions: const [],
        sowings: dosEdades,
      ),
    ));
    await tester.pump();

    expect(find.text('promedio de 2 edades'), findsOneWidget,
        reason: 'aclara que el kg/planta mezcla lotes distintos');
    expect(find.text('0.05 kg/planta'), findsOneWidget);
  });

  testWidgets('con una sola edad no agrega nada', (tester) async {
    await tester.pumpWidget(wrap(
      await provider(),
      PerHectarePanel(
        crops: const [crop],
        periodTransactions: const [],
        periodHarvests: cosecha,
        allTransactions: const [],
        sowings: unaEdad,
      ),
    ));
    await tester.pump();

    expect(find.text('promedio de 2 edades'), findsNothing);
    expect(find.text('0.05 kg/planta'), findsOneWidget);
  });

  testWidgets('el número de kg/planta no cambia de fórmula', (tester) async {
    await tester.pumpWidget(wrap(
      await provider(),
      PerHectarePanel(
        crops: const [crop],
        periodTransactions: const [],
        periodHarvests: cosecha,
        allTransactions: const [],
        sowings: dosEdades,
      ),
    ));
    await tester.pump();
    expect(find.text('0.05 kg/planta'), findsOneWidget);

    await tester.pumpWidget(wrap(
      await provider(),
      PerHectarePanel(
        crops: const [crop],
        periodTransactions: const [],
        periodHarvests: cosecha,
        allTransactions: const [],
        sowings: unaEdad,
      ),
    ));
    await tester.pump();
    expect(find.text('0.05 kg/planta'), findsOneWidget,
        reason: 'mismo número con una y con dos cohortes vivas');
  });

  // Guarda: sin la lista (llamadas viejas) tampoco aparece el rótulo.
  testWidgets('sin siembras no agrega el rótulo', (tester) async {
    await tester.pumpWidget(wrap(
      await provider(),
      PerHectarePanel(
        crops: const [crop],
        periodTransactions: const [],
        periodHarvests: cosecha,
        allTransactions: const [],
      ),
    ));
    await tester.pump();

    expect(find.text('promedio de 2 edades'), findsNothing);
  });
}
