import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/screens/assign_crops_screen.dart';
import 'package:mi_cafetal/services/local_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<TransactionProvider> makeProvider() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final provider = TransactionProvider(LocalStore(prefs));
    await provider.addTransaction(
      type: TransactionType.expense,
      category: 'fertilizante',
      amount: 500000,
      description: 'Abono',
      date: DateTime(2026, 9, 1),
    );
    return provider;
  }

  Future<void> pumpScreen(WidgetTester tester, TransactionProvider provider) async {
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () =>
                    Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const AssignCropsScreen(),
                )),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('asigna cultivo a un registro sin cultivo', (tester) async {
    final provider = await makeProvider();
    expect(provider.transactions.single.cropId, isNull);

    await pumpScreen(tester, provider);

    // La fila del gasto sin cultivo aparece con su descripción.
    expect(find.textContaining('Abono'), findsOneWidget);

    // Abre el selector y elige Café.
    await tester.tap(find.byType(DropdownButtonFormField<String?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('☕ Café').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    expect(provider.transactions.single.cropId, 'cafe');
  });

  testWidgets('muestra estado vacío cuando no hay registros sin cultivo',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final provider = TransactionProvider(LocalStore(prefs));

    await pumpScreen(tester, provider);

    expect(find.text('Ya no hay registros sin cultivo. ¡Todo asignado!'),
        findsOneWidget);
  });
}