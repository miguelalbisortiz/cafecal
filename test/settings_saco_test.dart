import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/screens/settings_screen.dart';
import 'package:mi_cafetal/services/local_store.dart';

/// El campo del saco se localiza por su etiqueta: es el único control con
/// ese texto en Ajustes.
Finder campoSaco() => find.ancestor(
      of: find.text(stringsFor('es').sacoKgLabel),
      matching: find.byType(TextField),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<TransactionProvider> pumpSettings(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final provider = TransactionProvider(LocalStore(prefs));

    tester.view.physicalSize = const Size(900, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

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
    return provider;
  }

  Future<void> guardar(WidgetTester tester) async {
    final save = find.text(stringsFor('es').saveButton);
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();
  }

  testWidgets('A2: el campo arranca en 70 y guarda el peso real', (tester) async {
    final tx = await pumpSettings(tester);

    expect(campoSaco(), findsOneWidget);
    expect(find.text('70'), findsWidgets, reason: 'llega con el de la norma');

    await tester.enterText(campoSaco(), '60');
    await guardar(tester);

    expect(tx.settings.sacoKg, 60);
  });

  testWidgets('A2: un campo ilegible no parte los kg a la mitad', (tester) async {
    final tx = await pumpSettings(tester);

    await tester.enterText(campoSaco(), 'abc');
    await guardar(tester);

    expect(tx.settings.sacoKg, 70,
        reason: 'nunca un 0: se conserva el que había');
  });

  testWidgets('A2: en inglés existe el mismo campo', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final provider = TransactionProvider(LocalStore(prefs));

    tester.view.physicalSize = const Size(900, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: provider,
      child: const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SettingsScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    final en = stringsFor('en');
    expect(
      find.ancestor(
        of: find.text(en.sacoKgLabel),
        matching: find.byType(TextField),
      ),
      findsOneWidget,
    );
  });
}
