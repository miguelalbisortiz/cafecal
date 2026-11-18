import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/models/categories.dart';
import 'package:mi_cafetal/models/product_state.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/screens/report_screen.dart';
import 'package:mi_cafetal/services/local_store.dart';

Future<TransactionProvider> _pumpReport(WidgetTester tester) async {
  // El reporte es una ListView larga: sin un viewport alto, la tarjeta queda
  // fuera del área construida y no aparece.
  tester.view.physicalSize = const Size(900, 8000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

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
  return provider;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('las ventas con estado salen agrupadas en su tarjeta',
      (tester) async {
    final provider = await _pumpReport(tester);

    await provider.addTransaction(
      type: TransactionType.income,
      category: kIncomeCategorySale,
      amount: 600000,
      quantity: 100,
      unit: 'kg',
      date: DateTime.now(),
      productState: ProductState.cereza,
    );
    await provider.addTransaction(
      type: TransactionType.income,
      category: kIncomeCategorySale,
      amount: 900000,
      quantity: 50,
      unit: 'kg',
      date: DateTime.now(),
      productState: ProductState.pergamino,
    );
    await tester.pumpAndSettle();

    expect(find.text('Ventas por estado'), findsOneWidget);
    expect(find.text('Cereza'), findsOneWidget);
    expect(find.text('Pergamino'), findsOneWidget);
    expect(find.text('Precio medio por kg'), findsNWidgets(2));
    // 600.000 / 100 kg y 900.000 / 50 kg con el formato de la app.
    expect(find.textContaining('COP 6.000'), findsWidgets);
    expect(find.textContaining('COP 18.000'), findsWidgets);
  });

  testWidgets('sin ventas con estado la tarjeta no ocupa espacio',
      (tester) async {
    final provider = await _pumpReport(tester);

    await provider.addTransaction(
      type: TransactionType.income,
      category: kIncomeCategorySale,
      amount: 600000,
      date: DateTime.now(),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ventas por estado'), findsNothing);
  });
}
