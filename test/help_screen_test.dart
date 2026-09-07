import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/screens/help_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpHelp(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      locale: Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: HelpScreen(),
    ));
    await tester.pump();
  }

  final l10n = stringsFor('es');

  testWidgets('la sección Ayuda muestra toda la guía', (tester) async {
    tester.view.physicalSize = const Size(900, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await pumpHelp(tester);

    expect(find.text(l10n.helpTitle), findsOneWidget);
    expect(find.text(l10n.helpWhereTitle), findsOneWidget);
    expect(find.text(l10n.helpCaseATitle), findsOneWidget);
    expect(find.text(l10n.helpCaseBTitle), findsOneWidget);
    expect(find.text(l10n.helpUnitsTitle), findsOneWidget);
    expect(find.text(l10n.helpGlossaryTitle), findsOneWidget);

    // La tabla de "dónde entro cada dato" usa las pantallas reales.
    expect(find.text(l10n.menuCrops), findsWidgets);
    expect(find.text(l10n.menuSowings), findsWidgets);

    // El glosario financiero abre su diálogo.
    await tester.tap(find.text(l10n.helpGlossaryFinance));
    await tester.pumpAndSettle();
    expect(find.text(l10n.glossaryTitle), findsOneWidget);
    expect(find.text(l10n.glossaryGotIt), findsOneWidget);
  });
}