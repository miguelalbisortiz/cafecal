import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/screens/help_screen.dart';
import 'package:mi_cafetal/services/local_store.dart';

/// La Ayuda nueva: tres pestañas, cuatro casos de ejemplo y memoria del caso.
/// No lee la finca: los textos son los mismos para todos.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<TransactionProvider> makeProvider({String? helpCase}) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      if (helpCase != null) 'help_case_v1': helpCase,
    });
    final prefs = await SharedPreferences.getInstance();
    return TransactionProvider(LocalStore(prefs));
  }

  Future<void> pumpHelp(WidgetTester tester, TransactionProvider provider,
      {Size size = const Size(900, 4000)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: provider,
      child: const MaterialApp(
        locale: Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: HelpScreen(),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('la portada tiene tres pestañas y los cuatro casos',
      (tester) async {
    final provider = await makeProvider();
    await pumpHelp(tester, provider);
    final l10n = stringsFor('es');

    expect(find.text(l10n.helpTabStart), findsOneWidget);
    expect(find.text(l10n.helpTabRoutine), findsOneWidget);
    expect(find.text(l10n.helpTabUnderstand), findsOneWidget);

    expect(find.text(l10n.helpCaseSellingTitle), findsOneWidget);
    expect(find.text(l10n.helpCaseStartingTitle), findsOneWidget);
    expect(find.text(l10n.helpCaseRenewTitle), findsOneWidget);
    expect(find.text(l10n.helpCaseWorkersTitle), findsOneWidget);

    // Sin caso elegido no se abre ningún camino: primero se elige.
    expect(find.text(l10n.helpSellingStep1), findsNothing);
  });

  testWidgets('elegir un caso muestra sus pasos y su ejemplo', (tester) async {
    final provider = await makeProvider();
    await pumpHelp(tester, provider);
    final l10n = stringsFor('es');

    await tester.tap(find.text(l10n.helpCaseSellingTitle));
    await tester.pumpAndSettle();

    expect(find.text(l10n.helpSellingStep1), findsOneWidget);
    expect(find.text(l10n.helpSellingStep4), findsOneWidget);
    expect(find.text(l10n.helpSellingExampleTitle), findsOneWidget);
    expect(find.text(l10n.helpSellingExample3), findsOneWidget);
    expect(find.text(l10n.helpSellingMulti), findsOneWidget);
    // El ejemplo se lee sin símbolo de moneda.
    expect(find.textContaining(r'$'), findsNothing);
  });

  testWidgets('cambiar de caso cambia el camino', (tester) async {
    final provider = await makeProvider();
    await pumpHelp(tester, provider);
    final l10n = stringsFor('es');

    await tester.tap(find.text(l10n.helpCaseSellingTitle));
    await tester.pumpAndSettle();
    expect(find.text(l10n.helpSellingStep2), findsOneWidget);

    await tester.tap(find.text(l10n.helpCaseWorkersTitle));
    await tester.pumpAndSettle();
    expect(find.text(l10n.helpSellingStep2), findsNothing);
    expect(find.text(l10n.helpWorkersStep2), findsOneWidget);
    expect(find.text(l10n.helpWorkersExample3), findsOneWidget);
  });

  testWidgets('el caso elegido se guarda para la próxima vez', (tester) async {
    final provider = await makeProvider();
    await pumpHelp(tester, provider);
    final l10n = stringsFor('es');

    await tester.tap(find.text(l10n.helpCaseRenewTitle));
    await tester.pumpAndSettle();

    expect(provider.helpCase, 'renew');
  });

  testWidgets('al volver, abre en el caso que ya estaba elegido',
      (tester) async {
    final provider = await makeProvider(helpCase: 'starting');
    await pumpHelp(tester, provider);
    final l10n = stringsFor('es');

    expect(find.text(l10n.helpStartingStep1), findsOneWidget);
    expect(find.text(l10n.helpSellingStep1), findsNothing);
  });

  testWidgets('un caso guardado que ya no existe abre en la portada',
      (tester) async {
    final provider = await makeProvider(helpCase: 'caso-viejo');
    await pumpHelp(tester, provider);
    final l10n = stringsFor('es');

    expect(find.text(l10n.helpCaseSellingTitle), findsOneWidget);
    expect(find.text(l10n.helpSellingStep1), findsNothing);
  });

  testWidgets('la pestaña Rutina tiene los cuatro momentos y las tres reglas',
      (tester) async {
    final provider = await makeProvider();
    await pumpHelp(tester, provider);
    final l10n = stringsFor('es');

    await tester.tap(find.text(l10n.helpTabRoutine));
    await tester.pumpAndSettle();

    expect(find.text(l10n.helpRoutineRow1When), findsOneWidget);
    expect(find.text(l10n.helpRoutineRow2What), findsOneWidget);
    expect(find.text(l10n.helpRoutineRow3Where), findsOneWidget);
    expect(find.text(l10n.helpRoutineRow4When), findsOneWidget);
    expect(find.text(l10n.helpRoutineTwice1), findsOneWidget);
    expect(find.text(l10n.helpRoutineTwice2), findsOneWidget);
    expect(find.text(l10n.helpRoutineTwice3), findsOneWidget);
  });

  testWidgets('la pestaña Entender explica los términos y abre el glosario',
      (tester) async {
    final provider = await makeProvider();
    await pumpHelp(tester, provider);
    final l10n = stringsFor('es');

    await tester.tap(find.text(l10n.helpTabUnderstand));
    await tester.pumpAndSettle();

    expect(find.text(l10n.glossaryIncomeTerm), findsOneWidget);
    expect(find.text(l10n.glossaryExpenseTerm), findsOneWidget);
    expect(find.text(l10n.glossaryCostPerKgTerm), findsOneWidget);
    expect(find.text(l10n.helpTrouble1Title), findsOneWidget);
    expect(find.text(l10n.helpUnitsTitle), findsOneWidget);

    await tester.ensureVisible(find.text(l10n.helpDictSeeAll));
    await tester.tap(find.text(l10n.helpDictSeeAll));
    await tester.pumpAndSettle();

    // El glosario completo se abre encima, con los mismos términos.
    expect(find.text(l10n.glossaryTitle), findsOneWidget);
    expect(find.text(l10n.glossaryIncomeTerm), findsWidgets);
    expect(find.text(l10n.glossarySoldVsHarvestedTerm), findsOneWidget);
  });
}
