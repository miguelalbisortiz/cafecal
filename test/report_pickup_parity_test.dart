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
import 'package:mi_cafetal/services/pdf_export_service.dart';

/// R2 del PRD «cifras del reporte»: el costo de recogida por kg suma la mano
/// de obra de «Cosechar», se calcula sobre el período y se lee igual en
/// pantalla, PDF y Excel.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('el PDF escribe el precio unitario con dos decimales', () {
    expect(PdfExportService().formatPdfMoney(21.9598, 'COP', decimals: 2),
        'COP 21,96');
    expect(PdfExportService().formatPdfMoney(21.9598, 'COP'), 'COP 22',
        reason: 'sin decimales, un costo de 21,96 se lee 22');
  });

  testWidgets('la pantalla suma los jornales de Cosechar y usa dos decimales',
      (tester) async {
    tester.view.physicalSize = const Size(900, 8000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final provider = TransactionProvider(LocalStore(prefs));
    final crop = await provider.addCrop('Café', areaHa: 1);
    final hoy = DateTime.now();
    // Dos jornales de Cosechar: 50.000 entre 150 kg medidos.
    await provider.addTransaction(
      type: TransactionType.expense,
      category: 'mano_obra',
      amount: 25000,
      cropId: crop.id,
      task: 'cosechar',
      harvestedKg: 100,
      date: hoy,
    );
    await provider.addTransaction(
      type: TransactionType.expense,
      category: 'mano_obra',
      amount: 25000,
      cropId: crop.id,
      task: 'cosechar',
      harvestedKg: 50,
      date: hoy,
    );

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

    expect(find.text(stringsFor('es').reportPickupCostPerKg), findsOneWidget);
    expect(find.text('COP 333,33'), findsOneWidget,
        reason: '50.000 ÷ 150 kg con dos decimales, no COP 0 ni COP 333');
  });
}
