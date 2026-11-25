import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/providers/alert_provider.dart';
import 'package:mi_cafetal/providers/auth_provider.dart';
import 'package:mi_cafetal/providers/sync_provider.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/screens/finca_screen.dart';
import 'package:mi_cafetal/screens/home_screen.dart';
import 'package:mi_cafetal/screens/register_screen.dart';
import 'package:mi_cafetal/services/local_store.dart';
import 'package:mi_cafetal/widgets/summary_empty_card.dart';

/// Fase 2 · la navegación nueva tiene que caber en el móvil más estrecho que
/// se vende hoy (360 px de ancho lógico). El agricultor no tiene una tablet:
/// si la barra, el FAB o el hub Finca se salen, se pierde una puerta.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// 360×640 lógicos, la pantalla de un gama baja.
  void telefonoEstrecho(WidgetTester tester) {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Future<void> pumpHome(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final store = LocalStore(prefs);
    final tx = TransactionProvider(store);
    final auth = AuthProvider(store);
    // Un cultivo alcanza para salir de la puerta E6 y de la de moneda: el
    // recorrido que se mide aquí es el de alguien que ya trabaja.
    await tx.addCrop('Café');
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

  final l10n = stringsFor('es');

  testWidgets('a 360 px caben la barra, el FAB y el Resumen vacío',
      (tester) async {
    telefonoEstrecho(tester);
    await pumpHome(tester);

    expect(tester.takeException(), isNull,
        reason: 'el Resumen no debe desbordarse a 360 px');
    for (final etiqueta in [
      l10n.tabOverview,
      l10n.tabMovements,
      l10n.tabReports,
    ]) {
      expect(
        find.descendant(
            of: find.byType(NavigationBar), matching: find.text(etiqueta)),
        findsOneWidget,
        reason: 'la barra tiene que nombrar "$etiqueta" a 360 px',
      );
    }
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byType(SummaryEmptyCard), findsOneWidget);
  });

  testWidgets('a 360 px el menú y el hub Finca se leen enteros',
      (tester) async {
    telefonoEstrecho(tester);
    await pumpHome(tester);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull,
        reason: 'el menú de 4 entradas no se desborda a 360 px');

    for (final etiqueta in [
      l10n.menuFinca,
      l10n.menuSettings,
      l10n.menuHelp,
      l10n.menuLogout,
    ]) {
      expect(find.text(etiqueta), findsOneWidget);
    }

    await tester.tap(find.text(l10n.menuFinca));
    await tester.pumpAndSettle();

    expect(find.byType(FincaScreen), findsOneWidget);
    expect(tester.takeException(), isNull,
        reason: 'el hub Finca no se desborda a 360 px');
    for (final etiqueta in [
      l10n.menuCrops,
      l10n.menuSowings,
      l10n.menuWorkers,
    ]) {
      expect(find.text(etiqueta), findsOneWidget,
          reason: '"$etiqueta" sigue visible a 360 px');
    }
  });

  testWidgets('a 360 px Registrar entra como ruta y no desborda',
      (tester) async {
    telefonoEstrecho(tester);
    await pumpHome(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.byType(RegisterScreen), findsOneWidget);
    expect(tester.takeException(), isNull,
        reason: 'el formulario de Registrar no se desborda a 360 px');

    // El título va en el AppBar de la ruta: no se duplica en el cuerpo.
    expect(find.text(l10n.registerTitle), findsOneWidget,
        reason: '`showTitle: false` evita el título repetido en el cuerpo');
    expect(
        find.descendant(
            of: find.byType(AppBar), matching: find.text(l10n.registerTitle)),
        findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
