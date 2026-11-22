import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/screens/register_screen.dart';
import 'package:mi_cafetal/services/local_store.dart';

/// Fase 1 del plan de navegación: salir de Registrar con el formulario a
/// medias tiene que avisar. Sin datos, el atrás sale directo.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<TransactionProvider> makeProvider() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    return TransactionProvider(LocalStore(prefs));
  }

  /// Registrar vive en una ruta empujada: así el atrás tiene a dónde volver
  /// y se puede comprobar que «Descartar» de verdad sale.
  Future<void> pumpHost(WidgetTester tester, TransactionProvider provider) async {
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const Scaffold(body: RegisterScreen()),
                  ),
                ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('con datos, atrás pregunta antes de descartar', (tester) async {
    final provider = await makeProvider();
    await pumpHost(tester, provider);
    final l10n = stringsFor('es');

    await tester.enterText(
        find.widgetWithText(TextFormField, l10n.amountFieldLabel), '5000');
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text(l10n.discardTitle), findsOneWidget);

    // Seguir escribiendo: se queda y el borrador sigue ahí.
    await tester.tap(find.text(l10n.discardCancel));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterScreen), findsOneWidget);
    expect(find.text('5000'), findsOneWidget);

    // Descartar: sale de verdad.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.discardConfirm));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterScreen), findsNothing);
    expect(find.text('abrir'), findsOneWidget);
  });

  testWidgets('sin datos, atrás sale directo', (tester) async {
    final provider = await makeProvider();
    await pumpHost(tester, provider);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(RegisterScreen), findsNothing);
    expect(find.text('abrir'), findsOneWidget);
  });
}
