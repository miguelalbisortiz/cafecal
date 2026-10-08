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

  testWidgets('un registro en otra moneda se pinta con su moneda, no con la de ajustes',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final provider = TransactionProvider(LocalStore(prefs));
    // Ajustes queda en COP (0 decimales). El registro está en USD (2 decimales):
    // comparten el símbolo "$", así que la única forma de distinguirlos es
    // por los decimales que se pintan. En español el decimal va con coma.
    expect(provider.settings.currency, 'COP');
    await provider.addTransaction(
      type: TransactionType.expense,
      category: 'fertilizante',
      amount: 500,
      description: 'Abono USD',
      date: DateTime(2026, 9, 1),
      currency: 'USD',
    );

    await pumpScreen(tester, provider);

    expect(find.textContaining('Abono USD'), findsOneWidget);
    expect(find.textContaining('\$500,00'), findsOneWidget,
        reason: 'debe pintar los 2 decimales de USD (coma en español). En COP, '
            'que tiene 0 decimales, el mismo monto saldría como "\$500" suelto, '
            'así que ver la coma ya demuestra que manda la moneda del registro.');
  });

  testWidgets('asigna cultivo a un registro sin cultivo', (tester) async {
    final provider = await makeProvider();
    expect(provider.transactions.single.cropId, isNull);

    await pumpScreen(tester, provider);

    // La fila del gasto sin cultivo aparece con su descripción.
    expect(find.textContaining('Abono'), findsOneWidget);

    // Abre el selector y crea un cultivo nuevo (ya no hay precargados).
    await tester.tap(find.byType(DropdownButtonFormField<String?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nuevo cultivo…').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Café');
    await tester.tap(find.text('Agregar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    expect(provider.transactions.single.cropId, isNotNull);
    expect(provider.crops.single.name, 'Café');
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