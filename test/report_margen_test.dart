import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/screens/report_screen.dart';
import 'package:mi_cafetal/services/local_store.dart';
import 'package:mi_cafetal/theme.dart';

/// La fila de cada cultivo mostraba «ROI 150%», una cifra que se lee como
/// «por cada 100 invertidos vuelven 250». El productor pregunta otra cosa:
/// de cada 100 que vende, cuánto le queda. Ahora dice «Margen 60%» con la
/// misma fórmula del «Margen sobre ventas» del Resumen.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('la fila del cultivo dice margen, no ROI', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final provider = TransactionProvider(LocalStore(prefs));
    final crop = await provider.addCrop('Café', areaHa: 6);
    final hoy = DateTime.now();
    await provider.addTransaction(
      type: TransactionType.income,
      category: 'venta_cafe',
      amount: 5000,
      cropId: crop.id,
      date: hoy,
    );
    await provider.addTransaction(
      type: TransactionType.expense,
      category: 'fertilizante',
      amount: 2000,
      cropId: crop.id,
      date: hoy,
    );

    tester.view.physicalSize = const Size(900, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAppTheme(Brightness.light),
        home: const ReportScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    // 3.000 de resultado sobre 5.000 vendidos = 60%.
    expect(find.text('Margen 60%'), findsOneWidget);
    expect(find.textContaining('ROI'), findsNothing,
        reason: 'la sigla ya no se pinta en el reporte');
  });
}
