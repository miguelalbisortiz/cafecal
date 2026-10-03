import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/services/local_store.dart';
import 'package:mi_cafetal/widgets/new_crop_dialog.dart';

/// Traducciones en español, el idioma que usan los tests.
AppLocalizations get es => stringsFor('es');

/// Proveedor fresco con preferencias locales vacías (aisla cada test).
Future<TransactionProvider> makeTx() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final prefs = await SharedPreferences.getInstance();
  return TransactionProvider(LocalStore(prefs));
}

/// Árbol mínimo sin proveedor (para probar diálogos sueltos).
Widget plainApp(Widget home) => MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );

/// Árbol mínimo con el proveedor y locale 'es'.
Widget appWith(TransactionProvider provider, Widget home) =>
    ChangeNotifierProvider<TransactionProvider>.value(
      value: provider,
      child: plainApp(home),
    );

/// Ventana alta: los diálogos largos (siembra, cultivo) sin ella dejan
/// campos fuera del área construida.
void bigScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Busca dentro de [NewCropDialog]. Es el único alcance fiable: tanto el
/// formulario de siembra como el diálogo de cultivo son `AlertDialog`.
Finder inNewCrop(Finder matching) => find.descendant(
      of: find.byType(NewCropDialog),
      matching: matching,
    );

/// Escribe en el campo de nombre del diálogo de cultivo y pulsa "Agregar".
Future<void> submitNewCrop(WidgetTester tester, String name) async {
  await tester.enterText(inNewCrop(find.byType(TextField)), name);
  await tester.pumpAndSettle();
  await tester.tap(inNewCrop(find.text(es.add)));
  await tester.pumpAndSettle();
}
