import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/providers/alert_provider.dart';
import 'package:mi_cafetal/providers/auth_provider.dart';
import 'package:mi_cafetal/providers/sync_provider.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/screens/crops_screen.dart';
import 'package:mi_cafetal/screens/home_screen.dart';
import 'package:mi_cafetal/screens/sowing_screen.dart';
import 'package:mi_cafetal/services/local_store.dart';
import 'package:mi_cafetal/widgets/next_step_card.dart';
import 'package:mi_cafetal/widgets/welcome_onboarding_card.dart';

/// Smoke E2E del onboarding: cuenta nueva ve las dos cards de bienvenida,
/// registra su finca por cualquiera de los dos caminos y el gate desaparece.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<(TransactionProvider, AuthProvider)> makeProviders() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final store = LocalStore(prefs);
    return (TransactionProvider(store), AuthProvider(store));
  }

  Future<void> pumpHome(WidgetTester tester, TransactionProvider tx,
      AuthProvider auth) async {
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: tx),
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: AlertProvider(tx)),
        ChangeNotifierProvider.value(value: SyncProvider(tx)),
      ],
      child: const MaterialApp(
        locale: Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: HomeScreen(),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'camino A: finca existente en producción quita la bienvenida',
      (tester) async {
    final (tx, auth) = await makeProviders();

    await pumpHome(tester, tx, auth);

    // Cuenta nueva: la card de bienvenida es visible.
    expect(find.byType(WelcomeOnboardingCard), findsOneWidget);
    expect(find.byType(NextStepCard), findsNothing);

    // Entra por "ya tengo plantas produciendo" → gestión de cultivos.
    await tester.tap(find.text('Agregar cultivos existentes'));
    await tester.pumpAndSettle();
    expect(find.byType(CropsScreen), findsOneWidget);

    // Crea el primer cultivo (default: producción, perenne).
    await tester.tap(find.text('+ Nueva variedad…'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Café');
    await tester.tap(find.text('Agregar'));
    await tester.pumpAndSettle();

    // El onboarding invita a agregar otro cultivo existente.
    expect(find.text('Cultivo agregado'), findsOneWidget);
    expect(find.text('Agregar otro'), findsOneWidget);
    await tester.tap(find.text('Entrar, terminé'));
    await tester.pumpAndSettle();

    expect(tx.crops.map((c) => c.name), contains('Café'));

    // Vuelve al dashboard: el gate ya está satisfecho.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeOnboardingCard), findsNothing);
    expect(find.byType(NextStepCard), findsOneWidget);
  });

  testWidgets('camino B: siembra crea cultivo nuevo y quita la bienvenida',
      (tester) async {
    final (tx, auth) = await makeProviders();

    await pumpHome(tester, tx, auth);
    expect(find.byType(WelcomeOnboardingCard), findsOneWidget);

    // Entra por "quisiera empezar algo nuevo" → registro de siembras.
    await tester.tap(find.text('Registrar mis siembras'));
    await tester.pumpAndSettle();
    expect(find.byType(SowingScreen), findsOneWidget);

    await tester.tap(find.text('Nueva siembra'));
    await tester.pumpAndSettle();

    // Crea el cultivo al vuelo desde el formulario de siembra.
    await tester.tap(find.byType(DropdownButtonFormField<String?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('+ Crear nuevo cultivo…').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Tomate');
    await tester.tap(find.text('Agregar').last);
    await tester.pumpAndSettle();

    // Completa la siembra con 100 plantas y costo de siembra.
    await tester.enterText(find.byType(TextFormField).first, '100');
    await tester.enterText(find.byType(TextFormField).at(2), '50000');
    await tester.tap(find.text('Agregar').last);
    await tester.pumpAndSettle();

    expect(tx.crops.map((c) => c.name), contains('Tomate'));
    expect(tx.sowings, hasLength(1));
    expect(tx.transactions, hasLength(1));
    expect(tx.transactions.single.category, 'siembra');
    expect(tx.transactions.single.amount, 50000);

    // Vuelve al dashboard: el gate ya está satisfecho.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeOnboardingCard), findsNothing);
    expect(find.byType(NextStepCard), findsOneWidget);
  });
}
