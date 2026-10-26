import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/models/crop.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/services/local_store.dart';
import 'package:mi_cafetal/widgets/per_hectare_panel.dart';

/// R1 del PRD «cifras del reporte»: el panel «Por hectárea» gasta lo mismo
/// que el desglose. Un gasto cargado al lote entra a cada cultivo por su área;
/// si a alguno le falta el área, no se reparte y el panel lo dice.
Widget _wrap(TransactionProvider provider, Widget child) {
  return ChangeNotifierProvider.value(
    value: provider,
    child: MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

Future<TransactionProvider> _provider() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final prefs = await SharedPreferences.getInstance();
  return TransactionProvider(LocalStore(prefs));
}

Crop _crop(String id, String name, {double? area}) => Crop(
      id: id,
      name: name,
      areaHa: area,
      terrenoId: 'loma',
    );

Transaction _gasto(String id,
        {required double amount,
        String? cropId,
        String? terrenoId,
        String currency = 'COP'}) =>
    Transaction(
      id: id,
      cropId: cropId,
      terrenoId: terrenoId,
      type: TransactionType.expense,
      category: 'catManoObra',
      amount: amount,
      currency: currency,
      date: DateTime(2026, 10, 1),
      createdAt: DateTime(2026, 10, 1),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('reparte el gasto del lote entre los cultivos por su área',
      (tester) async {
    // 110.000 del lote entre 6 + 3 + 2 ha: café 60.000, plátano 30.000,
    // maíz 20.000. Con lo propio: 300.000 / 6 = 50.000; 120.000 / 3 = 40.000;
    // 60.000 / 2 = 30.000.
    await tester.pumpWidget(_wrap(
      await _provider(),
      PerHectarePanel(
        crops: [
          _crop('cafe', 'Café', area: 6),
          _crop('platano', 'Plátano', area: 3),
          _crop('maiz', 'Maíz', area: 2),
        ],
        periodTransactions: [
          _gasto('c1', amount: 240000, cropId: 'cafe'),
          _gasto('p1', amount: 90000, cropId: 'platano'),
          _gasto('m1', amount: 40000, cropId: 'maiz'),
          _gasto('lote', amount: 110000, terrenoId: 'loma'),
        ],
        periodHarvests: const [],
        allTransactions: const [],
      ),
    ));
    await tester.pump();

    expect(find.text('Gastos por ha'), findsNWidgets(3));
    expect(find.text('COP 50.000'), findsOneWidget);
    expect(find.text('COP 40.000'), findsOneWidget);
    expect(find.text('COP 30.000'), findsOneWidget);
  });

  testWidgets('si falta el área de un cultivo no reparte y lo dice',
      (tester) async {
    // Plátano sin área: el lote no se puede repartir. Café muestra solo lo
    // suyo (240.000 / 6 = 40.000) y aparece la nota.
    await tester.pumpWidget(_wrap(
      await _provider(),
      PerHectarePanel(
        crops: [
          _crop('cafe', 'Café', area: 6),
          _crop('platano', 'Plátano'),
        ],
        periodTransactions: [
          _gasto('c1', amount: 240000, cropId: 'cafe'),
          _gasto('lote', amount: 110000, terrenoId: 'loma'),
        ],
        periodHarvests: const [],
        allTransactions: const [],
      ),
    ));
    await tester.pump();

    expect(find.text('COP 40.000'), findsOneWidget);
    expect(find.text('COP 50.000'), findsNothing);
    expect(
        find.text('El lote no se reparte: falta el área de un cultivo.'),
        findsOneWidget);
  });

  testWidgets('una moneda del lote apaga el gasto por ha y avisa',
      (tester) async {
    // El lote trae 100 USD: al café le llegan COP y USD, así que el gasto por
    // ha no se puede sumar. Se oculta y se avisa con el número de monedas.
    await tester.pumpWidget(_wrap(
      await _provider(),
      PerHectarePanel(
        crops: [_crop('cafe', 'Café', area: 6)],
        periodTransactions: [
          _gasto('c1', amount: 240000, cropId: 'cafe'),
          _gasto('lote', amount: 100, terrenoId: 'loma', currency: 'USD'),
        ],
        periodHarvests: const [],
        allTransactions: const [],
      ),
    ));
    await tester.pump();

    expect(find.text('Gastos por ha'), findsNothing);
    expect(find.text('Margen por ha'), findsNothing);
    expect(find.text('Se muestra en 2 monedas'), findsOneWidget);
  });
}
