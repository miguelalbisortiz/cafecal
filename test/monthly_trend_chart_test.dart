import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/services/local_store.dart';
import 'package:mi_cafetal/utils/format.dart';
import 'package:mi_cafetal/widgets/monthly_trend_chart.dart';

Future<TransactionProvider> _provider() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final prefs = await SharedPreferences.getInstance();
  return TransactionProvider(LocalStore(prefs));
}

Widget _wrap(TransactionProvider provider, int year) =>
    ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: MonthlyTrendChart(year: year),
          ),
        ),
      ),
    );

/// Tendencia mensual: con una sola moneda grafica como siempre; con dos o
/// más no dibuja barras que sumarían monedas distintas.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('moneda única: la tendencia se grafica igual que siempre',
      (tester) async {
    tester.view.physicalSize = const Size(900, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final provider = await _provider();
    final year = DateTime.now().year;
    await provider.addTransaction(
        type: TransactionType.income,
        category: 'venta_cafe',
        amount: 5000,
        date: DateTime(year, 3, 10));
    await provider.addTransaction(
        type: TransactionType.expense,
        category: 'fertilizante',
        amount: 1000,
        date: DateTime(year, 4, 10));

    await tester.pumpWidget(_wrap(provider, year));
    await tester.pumpAndSettle();

    final l10n = stringsFor('es');
    expect(find.text(l10n.chartTitle(year)), findsOneWidget);
    expect(find.byType(BarChart), findsOneWidget,
        reason: 'con una sola moneda las barras siguen ahí');
    expect(find.textContaining(l10n.currencyMixedHint(1)), findsNothing);
  });

  testWidgets(
      'mezcla sin tasa: no dibuja barras ni imprime una cifra que cruce '
      'monedas', (tester) async {
    tester.view.physicalSize = const Size(900, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final provider = await _provider();
    final year = DateTime.now().year;
    await provider.addTransaction(
        type: TransactionType.income,
        category: 'venta_cafe',
        amount: 5000,
        date: DateTime(year, 3, 10));
    await provider.addTransaction(
        type: TransactionType.expense,
        category: 'transporte',
        amount: 1000,
        currency: 'EUR',
        date: DateTime(year, 4, 10));

    await tester.pumpWidget(_wrap(provider, year));
    await tester.pumpAndSettle();

    final l10n = stringsFor('es');
    final locale = provider.settings.locale;
    expect(find.byType(BarChart), findsNothing,
        reason: 'las barras sumarían pesos con euros: no se grafica');
    expect(find.textContaining(l10n.currencyMixedHint(2)), findsOneWidget,
        reason: 'un aviso breve explica por qué no hay gráfica');

    // Cada moneda con su total, por separado.
    expect(
      find.text(
          'COP · ${l10n.incomeLabel} ${formatAmount(5000, currency: 'COP', locale: locale)}'),
      findsOneWidget,
    );
    expect(
      find.text(
          'EUR · ${l10n.expensesLabel} ${formatAmount(1000, currency: 'EUR', locale: locale)}'),
      findsOneWidget,
    );
    expect(
      find.textContaining(
          formatAmount(6000, currency: 'COP', locale: locale)),
      findsNothing,
        reason: '5.000 + 1.000 es la suma falsa que ya no se imprime');
  });
}
