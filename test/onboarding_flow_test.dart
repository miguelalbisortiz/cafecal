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
import 'package:mi_cafetal/widgets/summary_card.dart';
import 'package:mi_cafetal/widgets/welcome_onboarding_card.dart';

/// Smoke E2E del onboarding: cuenta nueva ve solo las dos cards de primer paso
/// (siembra/cultivo), sin restos de la app; al completar cualquiera de los dos
/// caminos se desbloquea el dashboard completo.
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

  testWidgets('finca vacía: solo las dos cards, sin resumen ni pestañas',
      (tester) async {
    final (tx, auth) = await makeProviders();

    await pumpHome(tester, tx, auth);

    // Lo único visible: las dos cards de primer paso.
    expect(find.byType(WelcomeOnboardingCard), findsOneWidget);
    expect(find.text('Registrar siembra'), findsOneWidget);
    expect(find.text('Registrar cultivo'), findsOneWidget);
    expect(find.byType(NextStepCard), findsNothing);

    // Nada del resto de la app: sin resumen, sin pestañas Registrar/Historial.
    expect(find.byType(SummaryCard), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Registrar'), findsNothing);
    expect(find.text('Historial'), findsNothing);
  });

  testWidgets('volver sin completar el primer paso mantiene bloqueado',
      (tester) async {
    final (tx, auth) = await makeProviders();

    await pumpHome(tester, tx, auth);
    expect(find.byType(WelcomeOnboardingCard), findsOneWidget);

    // Entra al registro de cultivos y vuelve sin crear nada.
    await tester.tap(find.text('Registrar cultivo'));
    await tester.pumpAndSettle();
    expect(find.byType(CropsScreen), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // Sigue bloqueado: solo las cards.
    expect(find.byType(WelcomeOnboardingCard), findsOneWidget);
    expect(find.byType(SummaryCard), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('camino A: registrar el primer cultivo desbloquea la app',
      (tester) async {
    final (tx, auth) = await makeProviders();

    await pumpHome(tester, tx, auth);
    expect(find.byType(WelcomeOnboardingCard), findsOneWidget);

    // Card "registrar cultivo" → gestión de cultivos.
    await tester.tap(find.text('Registrar cultivo'));
    await tester.pumpAndSettle();
    expect(find.byType(CropsScreen), findsOneWidget);

    // Crea el primer cultivo.
    await tester.tap(find.text('+ Nueva variedad…'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Café');
    await tester.tap(find.text('Agregar'));
    await tester.pumpAndSettle();

    expect(find.text('Cultivo agregado'), findsOneWidget);
    await tester.tap(find.text('Entrar, terminé'));
    await tester.pumpAndSettle();

    expect(tx.crops.map((c) => c.name), contains('Café'));

    // Vuelve al dashboard: el gate ya está satisfecho.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.byType(WelcomeOnboardingCard), findsNothing);
    expect(find.byType(NextStepCard), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('camino B: registrar la siembra desbloquea la app',
      (tester) async {
    final (tx, auth) = await makeProviders();

    await pumpHome(tester, tx, auth);
    expect(find.byType(WelcomeOnboardingCard), findsOneWidget);

    // Card "registrar siembra" → registro de siembras.
    await tester.tap(find.text('Registrar siembra'));
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
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}