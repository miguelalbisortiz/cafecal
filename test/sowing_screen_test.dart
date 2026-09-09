import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/screens/sowing_screen.dart';
import 'package:mi_cafetal/services/local_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<TransactionProvider> makeProvider() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    return TransactionProvider(LocalStore(prefs));
  }

  Future<void> pumpScreen(
      WidgetTester tester, TransactionProvider provider) async {
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: provider,
      child: const MaterialApp(
        locale: Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SowingScreen(),
      ),
    ));
    await tester.pump();
  }

  testWidgets('con cultivos vacios ofrece crear un cultivo nuevo desde el formulario',
      (tester) async {
    final provider = await makeProvider();
    await pumpScreen(tester, provider);
    final l10n = AppLocalizations.of(tester.element(find.byType(SowingScreen)))!;

    expect(find.text(l10n.sowingAdd), findsOneWidget);
    await tester.tap(find.text(l10n.sowingAdd));
    await tester.pumpAndSettle();

    // Abre el selector de cultivo para ver la opción de crear uno nuevo.
    await tester.tap(find.byType(DropdownButtonFormField<String?>));
    await tester.pumpAndSettle();
    expect(find.text(l10n.sowingNewCropOption).last, findsOneWidget);
  });
}