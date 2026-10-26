import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/screens/report_screen.dart';
import 'package:mi_cafetal/services/local_store.dart';
import 'package:mi_cafetal/theme.dart';

/// Contraste del reporte en modo oscuro.
///
/// Las filas de «Siembras» y «Nómina del período» se pintaban con colores
/// fijos: `Colors.black87` para el valor y `Colors.grey.shade700` para la
/// etiqueta. En la tarjeta blanca se leían; en la oscura el valor
/// desaparecía. El color de cada texto tiene que salir del tema.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<TransactionProvider> datos() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final p = TransactionProvider(LocalStore(prefs));
    final crop = await p.addCrop('Café', areaHa: 6, livePlants: 700);
    final hoy = DateTime.now();
    await p.addSowing(cropId: crop.id, date: hoy, plants: 700, areaHa: 6);
    await p.addTransaction(
      type: TransactionType.expense,
      category: 'mano_obra',
      amount: 100000,
      cropId: crop.id,
      provider: 'Juan',
      quantity: 2,
      date: hoy,
    );
    await p.addTransaction(
      type: TransactionType.expense,
      category: 'mano_obra',
      amount: 50000,
      cropId: crop.id,
      provider: 'Pedro',
      quantity: 1,
      date: hoy,
    );
    return p;
  }

  Future<ColorScheme> pintar(WidgetTester tester, Brightness brightness) async {
    tester.view.physicalSize = const Size(900, 8000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final provider = await datos();
    final theme = buildAppTheme(brightness);
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: theme,
        darkTheme: theme,
        home: const ReportScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    return theme.colorScheme;
  }

  /// Los textos que pinta la tarjeta que contiene [titulo].
  List<Text> textosDe(WidgetTester tester, String titulo) {
    final card =
        find.ancestor(of: find.text(titulo), matching: find.byType(Card)).first;
    return tester
        .widgetList<Text>(find.descendant(of: card, matching: find.byType(Text)))
        .toList();
  }

  /// Ningún texto de la tarjeta puede usar un color fijo oscuro: en la
  /// tarjeta oscura desaparece y en la clara tampoco es el color del tema.
  void sinColoresFijos(List<Text> textos, String tarjeta) {
    for (final t in textos) {
      final c = t.style?.color;
      expect(c, isNot(Colors.black87),
          reason: '«$tarjeta» pinta «${t.data}» con black87');
      expect(c, isNot(Colors.grey.shade700),
          reason: '«$tarjeta» pinta «${t.data}» con grey.shade700');
    }
  }

  TextStyle? estiloDe(WidgetTester tester, String titulo, String texto) {
    final card =
        find.ancestor(of: find.text(titulo), matching: find.byType(Card)).first;
    final t = find.descendant(of: card, matching: find.text(texto)).first;
    return tester.widget<Text>(t).style;
  }

  testWidgets('en oscuro la nómina no usa colores fijos y el valor se ve',
      (tester) async {
    final scheme = await pintar(tester, Brightness.dark);
    final l10n = stringsFor('es');

    expect(find.text(l10n.reportPayrollSection), findsOneWidget);
    sinColoresFijos(
        textosDe(tester, l10n.reportPayrollSection), l10n.reportPayrollSection);

    expect(estiloDe(tester, l10n.reportPayrollSection, 'COP 100.000')?.color,
        scheme.onSurface,
        reason: 'el valor tiene que ser el color de texto del tema');
    expect(estiloDe(tester, l10n.reportPayrollSection, 'Juan')?.color,
        scheme.onSurfaceVariant,
        reason: 'la etiqueta es texto secundario del tema');
  });

  testWidgets('en oscuro las siembras no usan colores fijos', (tester) async {
    final scheme = await pintar(tester, Brightness.dark);
    final l10n = stringsFor('es');

    expect(find.text(l10n.reportSowingsSection), findsOneWidget);
    sinColoresFijos(
        textosDe(tester, l10n.reportSowingsSection), l10n.reportSowingsSection);

    final valor = '700 ${l10n.reportSowingsPlantMany}';
    expect(estiloDe(tester, l10n.reportSowingsSection, valor)?.color,
        scheme.onSurface);
  });

  testWidgets('en claro los mismos textos siguen legibles', (tester) async {
    final scheme = await pintar(tester, Brightness.light);
    final l10n = stringsFor('es');

    sinColoresFijos(
        textosDe(tester, l10n.reportPayrollSection), l10n.reportPayrollSection);
    expect(estiloDe(tester, l10n.reportPayrollSection, 'COP 100.000')?.color,
        scheme.onSurface);
    expect(estiloDe(tester, l10n.reportPayrollSection, 'Juan')?.color,
        scheme.onSurfaceVariant);
  });
}
