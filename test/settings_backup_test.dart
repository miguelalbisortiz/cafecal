import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/screens/settings_screen.dart';
import 'package:mi_cafetal/services/local_store.dart';

/// `FilledButton.icon`/`OutlinedButton.icon` se construyen como subclases
/// privadas, así que `byType(FilledButton)` no las ve: se buscan por `is`.
Finder filledWith(String label) => find.ancestor(
      of: find.text(label),
      matching: find.byWidgetPredicate(
        (w) => w is FilledButton,
        description: 'FilledButton',
      ),
    );

Finder outlinedWith(String label) => find.ancestor(
      of: find.text(label),
      matching: find.byWidgetPredicate(
        (w) => w is OutlinedButton,
        description: 'OutlinedButton',
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpSettings(WidgetTester tester, String lang) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final provider = TransactionProvider(LocalStore(prefs));

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(
        locale: Locale(lang),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SettingsScreen(),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('la sección Respaldo muestra los dos botones', (tester) async {
    tester.view.physicalSize = const Size(900, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await pumpSettings(tester, 'es');

    final l10n = stringsFor('es');
    expect(find.text(l10n.backupSectionTitle), findsOneWidget);
    expect(find.text(l10n.backupSectionSubtitle), findsOneWidget);
    expect(filledWith(l10n.backupExport), findsOneWidget,
        reason: 'exportar respaldo es la acción principal');
    expect(outlinedWith(l10n.backupRestore), findsOneWidget,
        reason: 'restaurar respaldo es secundario');
    // La sección vive debajo del botón de guardar, al final de Ajustes.
    expect(filledWith(l10n.saveButton), findsOneWidget);

    final title = find.text(l10n.backupSectionTitle);
    final save = find.text(l10n.saveButton);
    expect(tester.getCenter(save).dy, lessThan(tester.getCenter(title).dy),
        reason: 'el Respaldo va al final, debajo de Guardar');
  });

  testWidgets('la sección Respaldo también existe en inglés', (tester) async {
    tester.view.physicalSize = const Size(900, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await pumpSettings(tester, 'en');

    final l10n = stringsFor('en');
    expect(find.text(l10n.backupSectionTitle), findsOneWidget);
    expect(filledWith(l10n.backupExport), findsOneWidget);
    expect(outlinedWith(l10n.backupRestore), findsOneWidget);
  });
}
