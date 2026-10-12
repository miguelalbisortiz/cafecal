import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/screens/register_screen.dart';
import 'package:mi_cafetal/screens/settings_screen.dart';
import 'package:mi_cafetal/services/local_store.dart';

AppLocalizations get _es => stringsFor('es');

/// Moneda única por cuenta, la regla entera en una sola batería:
///  1. el formulario no ofrece moneda, solo dice en cuál queda;
///  2. un registro nuevo nace en la moneda de la cuenta;
///  3. un registro viejo en otra moneda NO se reescribe al editarlo;
///  4. Ajustes deja cambiar la moneda solo mientras no haya nada que ambiguar.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<TransactionProvider> makeProvider() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    return TransactionProvider(LocalStore(prefs));
  }

  /// El diálogo y las pantallas son largas: sin viewport alto varios campos
  /// quedan fuera del área construida.
  void viewportAlto(WidgetTester tester) {
    tester.view.physicalSize = const Size(900, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Future<void> pumpRegister(WidgetTester tester, TransactionProvider provider,
      {Transaction? editing}) async {
    viewportAlto(tester);
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: RegisterScreen(editing: editing)),
      ),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> pumpSettings(WidgetTester tester, TransactionProvider provider) async {
    viewportAlto(tester);
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: provider,
      child: const MaterialApp(
        locale: Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SettingsScreen(),
      ),
    ));
    await tester.pumpAndSettle();
  }

  Finder campoMonto() => find.ancestor(
        of: find.text(_es.amountFieldLabel),
        matching: find.byType(TextFormField),
      );

  testWidgets('el registro no ofrece moneda: solo dice en cuál queda',
      (tester) async {
    final provider = await makeProvider();
    await pumpRegister(tester, provider);

    expect(find.text(_es.currencyLabel), findsNothing,
        reason: 'moneda única: no hay nada que elegir en el formulario');
    expect(
      find.text(_es.currencyRegisterHint('Peso colombiano (COP)')),
      findsOneWidget,
      reason: 'pero sí se aclara en qué moneda queda lo que va a guardar',
    );
  });

  testWidgets('la moneda que enseña es la de la cuenta', (tester) async {
    final provider = await makeProvider();
    await provider.updateSettings(provider.settings.copyWith(currency: 'BOB'));
    await pumpRegister(tester, provider);

    expect(find.text(_es.currencyRegisterHint('Boliviano (BOB)')),
        findsOneWidget);
  });

  testWidgets('un registro nuevo nace en la moneda de la cuenta',
      (tester) async {
    final provider = await makeProvider();
    await provider.updateSettings(provider.settings.copyWith(currency: 'BOB'));
    await pumpRegister(tester, provider);

    await tester.enterText(campoMonto(), '5000');
    await tester.tap(find.text(_es.saveRecord));
    await tester.pumpAndSettle();

    expect(provider.transactions, hasLength(1));
    expect(provider.transactions.single.currency, 'BOB',
        reason: 'una sola fuente de verdad: la de Ajustes, no otra');
  });

  testWidgets('editar un registro viejo conserva su moneda', (tester) async {
    final provider = await makeProvider();
    await provider.updateSettings(provider.settings.copyWith(currency: 'BOB'));
    // Un registro legado, en otra moneda que la de la cuenta.
    await provider.addTransaction(
      type: TransactionType.expense,
      category: 'fertilizante',
      amount: 900,
      currency: 'COP',
      date: DateTime(2026, 9, 1),
    );
    final viejo = provider.transactions.single;

    await pumpRegister(tester, provider, editing: viejo);

    expect(find.text(_es.currencyRegisterHint('Peso colombiano (COP)')),
        findsOneWidget,
        reason: 'no se le cambia la moneda al registro antiguo');

    await tester.tap(find.text(_es.saveChanges));
    await tester.pumpAndSettle();

    expect(provider.transactions.single.currency, 'COP',
        reason: 'lo ya guardado no se reescribe, aunque la cuenta sea BOB');
  });

  testWidgets('Ajustes: con datos la moneda es de solo lectura', (tester) async {
    final provider = await makeProvider();
    await provider.addCrop('Café');
    await pumpSettings(tester, provider);

    expect(find.text(_es.currencyLockedHelper), findsOneWidget,
        reason: 'con algo guardado ya no se puede cambiar sin partirlo todo');
    expect(find.text(_es.currencyDisplayHelper), findsNothing);
  });

  testWidgets('Ajustes: sin nada guardado todavía se puede cambiar',
      (tester) async {
    final provider = await makeProvider();
    await pumpSettings(tester, provider);

    expect(find.text(_es.currencyDisplayHelper), findsOneWidget);
    expect(find.text(_es.currencyLockedHelper), findsNothing);
  });
}
