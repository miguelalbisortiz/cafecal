import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/models/categories.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/screens/register_screen.dart';
import 'package:mi_cafetal/services/local_store.dart';

AppLocalizations get _es => stringsFor('es');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<TransactionProvider> makeProvider() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    return TransactionProvider(LocalStore(prefs));
  }

  Future<void> pumpRegister(WidgetTester tester, TransactionProvider provider,
      {Transaction? editing, TransactionType? initialType}) async {
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: RegisterScreen(editing: editing, initialType: initialType)),
      ),
    ));
    await tester.pumpAndSettle();
  }

  Finder dropdownWithValue(String value) => find.byWidgetPredicate((w) =>
      w is DropdownButton<String> &&
      (w.items ?? const []).any((i) => i.value == value));

  testWidgets('ingreso: la opción de venta toma el nombre del cultivo',
      (tester) async {
    final provider = await makeProvider();
    final crop = await provider.addCrop('Plátano');
    await pumpRegister(tester, provider,
        initialType: TransactionType.income);

    // Elegir el cultivo en el dropdown de Cultivo.
    await tester.tap(dropdownWithValue(crop.id));
    await tester.pumpAndSettle();
    await tester.tap(find.text('🌱 Plátano').last);
    await tester.pumpAndSettle();

    // Abrir el dropdown de Categoría (los ingresos siempre ofrecen 'venta').
    await tester.tap(dropdownWithValue(kIncomeCategorySale));
    await tester.pumpAndSettle();

    // La venta toma el nombre del cultivo elegido arriba.
    expect(find.text('🌱 Venta Plátano'), findsWidgets);
    expect(find.textContaining(_es.catSubvenciones), findsWidgets);
    expect(find.textContaining(_es.catVentaOtro), findsWidgets);
    // Nunca se ofrecen ventas de cultivos que no existen.
    expect(find.textContaining('Venta café'), findsNothing);
    expect(find.textContaining('Venta plátano'), findsNothing);
  });

  testWidgets('sin cultivo la opción de venta es "Venta" a secas',
      (tester) async {
    final provider = await makeProvider();
    await pumpRegister(tester, provider,
        initialType: TransactionType.income);

    await tester.tap(dropdownWithValue(kIncomeCategorySale));
    await tester.pumpAndSettle();

    expect(find.text('💰 ${_es.catVenta}'), findsWidgets);
    expect(find.textContaining('Venta café'), findsNothing);
    expect(find.textContaining('Venta plátano'), findsNothing);
  });

  testWidgets('editar un registro legado muestra "Venta café" sin romper',
      (tester) async {
    final provider = await makeProvider();
    final legacy = Transaction(
      id: 'old1',
      type: TransactionType.income,
      category: 'venta_cafe',
      amount: 900,
      date: DateTime(2026, 9, 1),
      createdAt: DateTime(2026, 9, 1),
    );
    await pumpRegister(tester, provider, editing: legacy);

    // El valor legado sigue siendo un ítem válido del dropdown.
    expect(find.text('☕ Venta café'), findsWidgets);
  });

  testWidgets('el campo cultivo explica cómo crear una variedad nueva',
      (tester) async {
    final provider = await makeProvider();
    await pumpRegister(tester, provider);

    expect(find.text(_es.cropGroupHint), findsOneWidget);
    expect(_es.cropGroupHint, contains('+ Nueva variedad…'));
  });
}
