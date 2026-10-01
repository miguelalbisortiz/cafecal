import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/screens/report_screen.dart';
import 'package:mi_cafetal/services/local_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'el mes por defecto del reporte coincide con el mes actual (sin off-by-one)',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final provider = TransactionProvider(LocalStore(prefs));

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: provider,
      child: const MaterialApp(
        locale: Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ReportScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    final now = DateTime.now();
    final mesActual = stringsFor('es').monthFull[now.month - 1];
    // El mes siguiente, girando de diciembre a enero.
    final mesSiguiente = stringsFor('es').monthFull[now.month % 12];

    expect(find.textContaining(mesActual), findsWidgets,
        reason: 'debe mostrar el mes actual ($mesActual)');
    expect(find.textContaining(mesSiguiente), findsNothing,
        reason: 'no debe mostrar el mes siguiente ($mesSiguiente)');
  });
}