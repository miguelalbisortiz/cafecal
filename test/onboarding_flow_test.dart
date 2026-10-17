import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/models/crop.dart';
import 'package:mi_cafetal/providers/alert_provider.dart';
import 'package:mi_cafetal/providers/auth_provider.dart';
import 'package:mi_cafetal/providers/sync_provider.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/screens/home_screen.dart';
import 'package:mi_cafetal/services/local_store.dart';
import 'package:mi_cafetal/widgets/currency_setup_gate.dart';
import 'package:mi_cafetal/widgets/next_step_card.dart';
import 'package:mi_cafetal/widgets/summary_card.dart';
import 'package:mi_cafetal/widgets/welcome_onboarding_card.dart';

/// Smoke E2E de la puerta de bienvenida (E6): cuenta nueva ve **solo** la
/// puerta, empieza con una lista **vacía** (sin especies inventadas), monta
/// sus cultivos sin que la app lo expulse, y recién cuando toca
/// [Entrar a la app] se abre el dashboard.
///
/// Los usuarios que ya cultivaban no ven la puerta.
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

  AppLocalizations l10nOf(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(HomeScreen)))!;

  /// Escribe el nombre en la ficha corta y confirma con [Listo].
  Future<void> agregarCultivo(WidgetTester tester, String nombre) async {
    await tester.tap(find.text('Agregar el primero'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), nombre);
    await tester.tap(find.text('Listo'));
    await tester.pumpAndSettle();
  }

  /// Moneda única · la pregunta va antes de la puerta de cultivos: nadie
  /// llega al resto de la app sin haber elegido moneda.
  Future<void> elegirMoneda(WidgetTester tester) async {
    final l10n = l10nOf(tester);
    await tester.tap(find.text(l10n.currencyGateCta('Peso colombiano (COP)')));
    await tester.pumpAndSettle();
  }

  testWidgets('cuenta nueva: primero la moneda, y no se puede saltar',
      (tester) async {
    final (tx, auth) = await makeProviders();

    await pumpHome(tester, tx, auth);
    final l10n = l10nOf(tester);

    // Antes de todo dato está la moneda: sin elegir no hay puerta ni tablero.
    expect(find.byType(CurrencySetupGate), findsOneWidget);
    expect(find.text(l10n.currencyGateTitle), findsOneWidget);
    expect(find.byType(WelcomeOnboardingCard), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);

    await elegirMoneda(tester);

    expect(tx.settings.currency, 'COP');
    expect(find.byType(CurrencySetupGate), findsNothing);
    expect(find.byType(WelcomeOnboardingCard), findsOneWidget,
        reason: 'elegida la moneda recién aparece la puerta de cultivos');
  });

  testWidgets('la moneda elegida se guarda en Ajustes', (tester) async {
    final (tx, auth) = await makeProviders();

    await pumpHome(tester, tx, auth);
    final l10n = l10nOf(tester);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('(BOB)').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.currencyGateCta('Boliviano (BOB)')));
    await tester.pumpAndSettle();

    expect(tx.settings.currency, 'BOB',
        reason: 'una sola fuente de verdad: lo que elige aquí lo lee todo');
  });

  testWidgets('el desplegable nombra la moneda por su código, no por el símbolo',
      (tester) async {
    final (tx, auth) = await makeProviders();

    await pumpHome(tester, tx, auth);

    expect(find.text('Peso colombiano (COP)'), findsOneWidget,
        reason: 'la etiqueta dice lo mismo que el botón que la confirma, y el '
            'texto que queda bajo Monto');
    expect(find.text(r'$ Peso colombiano (COP)'), findsNothing,
        reason: 'El símbolo `\$` lo comparten COP, USD y CLP: no dice de qué '
            'moneda es; el código sí');
  });

  testWidgets('finca vacía: solo la puerta, sin resumen ni pestañas',
      (tester) async {
    final (tx, auth) = await makeProviders();

    await pumpHome(tester, tx, auth);
    final l10n = l10nOf(tester);
    await elegirMoneda(tester);

    expect(find.byType(WelcomeOnboardingCard), findsOneWidget);
    expect(find.text(l10n.welcomeTitle), findsOneWidget);

    // Nada del resto de la app: sin resumen, sin pestañas, sin próximos pasos.
    expect(find.byType(NextStepCard), findsNothing);
    expect(find.byType(SummaryCard), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Registrar'), findsNothing);
    expect(find.text('Historial'), findsNothing);

    // Los viejos caminos desaparecieron con R3: eso ya no es como se empieza.
    expect(find.text('Registrar cultivo'), findsNothing);
    expect(find.text('Registrar siembra'), findsNothing);
  });

  testWidgets('cancelar la ficha corta no deja nada montado', (tester) async {
    final (tx, auth) = await makeProviders();

    await pumpHome(tester, tx, auth);
    await elegirMoneda(tester);

    await tester.tap(find.text('Agregar el primero'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(tx.crops, isEmpty);
    expect(find.byType(WelcomeOnboardingCard), findsOneWidget);
    expect(find.byType(SummaryCard), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('agregar el primer cultivo NO cierra la puerta (G3)',
      (tester) async {
    final (tx, auth) = await makeProviders();

    await pumpHome(tester, tx, auth);
    final l10n = l10nOf(tester);
    await elegirMoneda(tester);

    await agregarCultivo(tester, 'Café');
    expect(tx.crops.map((c) => c.name), contains('Café'));

    // Recién con ≥1 cultivo aparece la salida… pero la puerta sigue abierta:
    // quien tiene café, plátano y mango los monta seguidos.
    expect(find.byType(WelcomeOnboardingCard), findsOneWidget);
    expect(find.text('Café'), findsOneWidget);
    expect(find.text(l10n.welcomeEnter), findsOneWidget);
    expect(find.byType(SummaryCard), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);

    // Y sigue pudiendo agregar otro sin salir.
    await tester.tap(find.text('Agregar otro'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Plátano');
    await tester.tap(find.text('Listo'));
    await tester.pumpAndSettle();

    expect(tx.crops, hasLength(2));
    expect(find.byType(WelcomeOnboardingCard), findsOneWidget);
  });

  testWidgets('[Completar datos…] abre el editor como "Completar cultivo"',
      (tester) async {
    final (tx, auth) = await makeProviders();

    await pumpHome(tester, tx, auth);
    final l10n = l10nOf(tester);
    await elegirMoneda(tester);

    await tester.tap(find.text('Agregar el primero'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Mango');
    await tester.tap(find.text(l10n.welcomeComplete));
    await tester.pumpAndSettle();

    // E6-a: el cultivo ya nació, así que el editor no dice "Editar" ni
    // ofrece "Agregar" — dice lo que él tocó y lo que va a pasar.
    expect(tx.crops.map((c) => c.name), contains('Mango'));
    expect(find.text(l10n.welcomeCompleteTitle), findsOneWidget);
    expect(find.text(l10n.editCropTitle), findsNothing);
    expect(find.text(l10n.save), findsOneWidget);
    expect(find.text(l10n.add), findsNothing);

    // Y la puerta sigue detrás: cancelar el editor no lo devuelve al tablero.
    await tester.tap(find.text(l10n.cancel));
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeOnboardingCard), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('[Entrar a la app] sí abre el dashboard', (tester) async {
    final (tx, auth) = await makeProviders();

    await pumpHome(tester, tx, auth);
    final l10n = l10nOf(tester);
    await elegirMoneda(tester);

    await agregarCultivo(tester, 'Café');

    await tester.tap(find.text(l10n.welcomeEnter));
    await tester.pumpAndSettle();

    expect(find.byType(WelcomeOnboardingCard), findsNothing);
    expect(find.byType(NextStepCard), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('quien ya cultivaba no ve la puerta', (tester) async {
    final (tx, auth) = await makeProviders();
    await tx.addCrop('Café', icon: '☕', cycle: CropCycle.perenne);

    await pumpHome(tester, tx, auth);

    // Quien ya tiene datos no se le vuelve a preguntar la moneda.
    expect(find.byType(CurrencySetupGate), findsNothing);
    expect(find.byType(WelcomeOnboardingCard), findsNothing);
    expect(find.byType(NextStepCard), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
