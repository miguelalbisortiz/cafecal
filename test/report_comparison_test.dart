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

/// El Resumen compara el período con el anterior: tres renglones con la cifra
/// de antes y cuánto cambió. Si el período anterior no tiene datos, no se
/// pinta nada — ni un cero ni una cifra inventada.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  DateTime monthDate(int monthsAgo, int day) {
    final now = DateTime.now();
    return DateTime(now.year, now.month - monthsAgo, day);
  }

  Future<TransactionProvider> providerWith(
      List<List<Object>> movements) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final provider = TransactionProvider(LocalStore(prefs));
    for (final m in movements) {
      await provider.addTransaction(
        type: m[0] as TransactionType,
        category: m[1] as String,
        amount: m[2] as double,
        date: m[3] as DateTime,
      );
    }
    return provider;
  }

  Future<void> pumpReport(
      WidgetTester tester, TransactionProvider provider) async {
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
  }

  testWidgets('compara ingresos, gastos y resultado con el mes anterior',
      (tester) async {
    final provider = await providerWith([
      // Mes anterior: 2.000 ingresos, 800 gastos → 1.200 de resultado.
      [TransactionType.income, 'venta_cafe', 2000.0, monthDate(1, 5)],
      [TransactionType.expense, 'fertilizante', 800.0, monthDate(1, 6)],
      // Mes actual: 3.000 ingresos, 1.000 gastos → 2.000 de resultado.
      [TransactionType.income, 'venta_cafe', 3000.0, monthDate(0, 10)],
      [TransactionType.expense, 'fertilizante', 1000.0, monthDate(0, 11)],
    ]);

    await pumpReport(tester, provider);

    expect(find.text('Comparado con el mes anterior'), findsOneWidget);
    // Cifra de antes → cifra de ahora, con el código de moneda.
    expect(find.text('de COP 2.000 a COP 3.000'), findsOneWidget);
    expect(find.text('de COP 800 a COP 1.000'), findsOneWidget);
    expect(find.text('de COP 1.200 a COP 2.000'), findsOneWidget);
    // Cuánto cambió cada una.
    expect(find.text('+50%'), findsOneWidget);
    expect(find.text('+25%'), findsOneWidget);
    expect(find.text('+67%'), findsOneWidget);
  });

  testWidgets('sin datos del período anterior no se pinta el comparativo',
      (tester) async {
    final provider = await providerWith([
      [TransactionType.income, 'venta_cafe', 3000.0, monthDate(0, 10)],
      [TransactionType.expense, 'fertilizante', 1000.0, monthDate(0, 11)],
    ]);

    await pumpReport(tester, provider);

    expect(find.text('Comparado con el mes anterior'), findsNothing);
    expect(find.textContaining('Comparado con'), findsNothing);
  });
}
