import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/models/sowing.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/screens/report_screen.dart';
import 'package:mi_cafetal/services/local_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'el mes por defecto del reporte coincide con el mes actual (sin off-by-one)',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final provider = TransactionProvider(LocalStore(prefs));

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: provider,
      child: const MaterialApp(
        locale: Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ReportScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    final now = DateTime.now();
    final mesActual = stringsFor('es').monthFull[now.month - 1];
    // El mes siguiente, girando de diciembre a enero.
    final mesSiguiente = stringsFor('es').monthFull[now.month % 12];

    expect(find.textContaining(mesActual), findsWidgets,
        reason: 'debe mostrar el mes actual ($mesActual)');
    expect(find.textContaining(mesSiguiente), findsNothing,
        reason: 'no debe mostrar el mes siguiente ($mesSiguiente)');
  });

  testWidgets(
      'sin ventas, margen y ratio explican el guion largo en vez de dejarlo mudo',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final provider = TransactionProvider(LocalStore(prefs));

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: provider,
      child: const MaterialApp(
        locale: Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ReportScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text(stringsFor('es').metricNoSales), findsNWidgets(2),
        reason: 'tanto el margen como gastos vs ingresos deben decir por qué '
            'no se pueden calcular');
  });

  testWidgets(
      'la tarjeta de Siembras (P5) muestra el estado actual y las del período',
      (tester) async {
    // El reporte es una ListView larga: sin viewport alto la tarjeta de
    // Siembras queda fuera del área construida y no aparece.
    tester.view.physicalSize = const Size(900, 8000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final provider = TransactionProvider(LocalStore(prefs));

    final crop = await provider.addCrop('Café');
    final hoy = DateTime.now();
    await provider.addSowing(
        cropId: crop.id, date: hoy, plants: 400, areaHa: 0.5);
    await provider.addSowing(
      cropId: crop.id,
      date: hoy,
      kind: SowingKind.resiembra,
      plants: 50,
      lostPlants: 30,
      reason: 'sequía',
    );

    expect(provider.sowings, hasLength(2),
        reason: 'el provider debe conservar las siembras recién creadas');
    expect(provider.crops.map((c) => c.id), contains(crop.id),
        reason: 'el provider debe tener el cultivo creado');

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: provider,
      child: const MaterialApp(
        locale: Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ReportScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    final l10n = stringsFor('es');
    expect(find.text(l10n.reportSowingsSection), findsOneWidget,
        reason: 'la tarjeta de Siembras debe aparecer tras Cosechas');
    expect(find.text(l10n.reportSowingsNow), findsOneWidget,
        reason: 'debe mostrar qué tengo plantado hoy');
    expect(
      find.text('420 ${l10n.reportSowingsPlantMany}'),
      findsNWidgets(2),
      reason: '400 - 30 perdidas + 50 de resiembra = 420 plantas vivas, '
          'tanto en la fila del cultivo como en el total',
    );
    expect(
      find.text(l10n.reportSowingsLostLine(30, 'sequía')),
      findsOneWidget,
      reason: 'las pérdidas deben mostrar cantidad y motivo (A1)',
    );
    expect(find.textContaining('Siembras en '), findsOneWidget,
        reason: 'debe listar las siembras del período seleccionado');
  });

  testWidgets(
      'P5: el estado de resultados agrupa los gastos sin esconder el detalle',
      (tester) async {
    tester.view.physicalSize = const Size(900, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final provider = TransactionProvider(LocalStore(prefs));
    final hoy = DateTime.now();

    await provider.addTransaction(
      type: TransactionType.expense,
      category: 'fertilizante',
      amount: 1000.0,
      description: 'Fertilizante',
      date: hoy,
    );
    await provider.addTransaction(
      type: TransactionType.expense,
      category: 'transporte',
      amount: 500.0,
      description: 'Transporte',
      date: hoy,
    );
    await provider.addTransaction(
      type: TransactionType.expense,
      category: 'arriendo',
      amount: 300.0,
      description: 'Arriendo',
      date: hoy,
    );

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: provider,
      child: const MaterialApp(
        locale: Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ReportScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    final l10n = stringsFor('es');
    expect(find.text(l10n.expenseGroupProduccion), findsOneWidget);
    expect(find.text(l10n.expenseGroupVenta), findsOneWidget);
    expect(find.text(l10n.expenseGroupFijos), findsOneWidget);
    expect(find.text(l10n.expenseGroupOtros), findsNothing,
        reason: 'sin gastos "otro" no debe abrirse ese bloque');

    // Agrupar no esconde nada: las categorías siguen listadas debajo.
    expect(find.text(l10n.expenseCategory('fertilizante')), findsOneWidget);
    expect(find.text(l10n.expenseCategory('transporte')), findsOneWidget);
    expect(find.text(l10n.expenseCategory('arriendo')), findsOneWidget);
  });

  testWidgets('P2: el estado de resultados compara precio/kg con costo/kg',
      (tester) async {
    tester.view.physicalSize = const Size(900, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final provider = TransactionProvider(LocalStore(prefs));
    final hoy = DateTime.now();

    await provider.addTransaction(
      type: TransactionType.expense,
      category: 'fertilizante',
      amount: 1000.0,
      date: hoy,
    );
    await provider.addHarvest(
        cropId: null, date: hoy, amount: 10, unit: 'kg');
    await provider.addTransaction(
      type: TransactionType.income,
      category: 'venta_cafe',
      amount: 12000.0,
      quantity: 10,
      unit: 'kg',
      date: hoy,
    );

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: provider,
      child: const MaterialApp(
        locale: Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ReportScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    final l10n = stringsFor('es');
    // 1000 de gasto sobre 10 kg cosechados = $100/kg de costo;
    // 12000 sobre 10 kg vendidos = $1200/kg de precio.
    expect(find.text(l10n.metricCostPriceLabel), findsOneWidget);
    expect(find.textContaining('por encima de tu costo'), findsOneWidget,
        reason: 'precio > costo debe decirlo con palabras, no solo en verde');
  });

  testWidgets('P2: sin cosecha ni kilos anotados la línea ni aparece',
      (tester) async {
    tester.view.physicalSize = const Size(900, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final provider = TransactionProvider(LocalStore(prefs));

    await provider.addTransaction(
      type: TransactionType.expense,
      category: 'fertilizante',
      amount: 1000.0,
      date: DateTime.now(),
    );

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: provider,
      child: const MaterialApp(
        locale: Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ReportScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    final l10n = stringsFor('es');
    expect(find.text(l10n.metricCostPriceLabel), findsNothing,
        reason: 'no hay nada que comparar: no hay que llenar el reporte de '
            '"no se puede calcular"');
    // Las otras dos métricas siguen explicándose como antes.
    expect(find.text(l10n.metricNoSales), findsNWidgets(2));
  });
}