import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/models/sowing.dart';
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
}