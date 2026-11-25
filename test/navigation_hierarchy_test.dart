import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/main.dart';
import 'package:mi_cafetal/models/settings.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/providers/alert_provider.dart';
import 'package:mi_cafetal/providers/auth_provider.dart';
import 'package:mi_cafetal/providers/sync_provider.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/screens/finca_screen.dart';
import 'package:mi_cafetal/screens/home_screen.dart';
import 'package:mi_cafetal/screens/register_screen.dart';
import 'package:mi_cafetal/screens/settings_screen.dart';
import 'package:mi_cafetal/services/local_store.dart';
import 'package:mi_cafetal/widgets/summary_card.dart';

/// Fases 3, 5 y 6 · jerarquía de retorno, layout a 360 px y accesibilidad.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final l10n = stringsFor('es');

  void medida(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Future<TransactionProvider> pumpHome(WidgetTester tester,
      {bool conDatos = false}) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final store = LocalStore(prefs);
    final tx = TransactionProvider(store);
    final auth = AuthProvider(store);
    // Un cultivo saca la puerta E6 y la de moneda: se mide a alguien que ya
    // trabaja, que es quien ve las tres tarjetas.
    await tx.addCrop('Café');
    if (conDatos) {
      final hoy = DateTime.now();
      await tx.addTransaction(
          type: TransactionType.income,
          category: 'venta_cafe',
          amount: 5000,
          date: hoy);
      await tx.addTransaction(
          type: TransactionType.expense,
          category: 'fertilizante',
          amount: 1000,
          date: hoy);
    }
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
    return tx;
  }

  Finder navTab(String label) => find.descendant(
      of: find.byType(NavigationBar), matching: find.text(label));

  group('Fase 3 · retorno y jerarquía', () {
    testWidgets('las pestañas no muestran flecha; las rutas de salida sí',
        (tester) async {
      await pumpHome(tester);

      expect(find.byType(BackButton), findsNothing,
          reason: 'una pestaña no es una salida: no lleva flecha');

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.menuFinca));
      await tester.pumpAndSettle();
      expect(find.byType(FincaScreen), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget,
          reason: 'Finca es una ruta empujada y tiene que poder volver');

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.menuSettings));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);
    });

    testWidgets('el AppBar dice «Balance» en las pestañas y Reportes gana '
        'su encabezado en el cuerpo', (tester) async {
      await pumpHome(tester);

      for (final etiqueta in [
        l10n.tabOverview,
        l10n.tabMovements,
        l10n.tabReports,
      ]) {
        await tester.tap(navTab(etiqueta));
        await tester.pumpAndSettle();
        expect(
          find.descendant(
              of: find.byType(AppBar), matching: find.text(l10n.appTitleFull)),
          findsOneWidget,
          reason: 'el AppBar no cambia de nombre al cambiar de pestaña',
        );
      }
      expect(find.text(l10n.menuReport), findsOneWidget,
          reason: 'Reportes se identifica en el cuerpo, no en el AppBar');
    });
  });

  group('Fase 2 · puertas', () {
    testWidgets('el FAB de Registrar está en las tres pestañas',
        (tester) async {
      await pumpHome(tester);
      for (final etiqueta in [
        l10n.tabOverview,
        l10n.tabMovements,
        l10n.tabReports,
      ]) {
        await tester.tap(navTab(etiqueta));
        await tester.pumpAndSettle();
        expect(find.byType(FloatingActionButton), findsOneWidget,
            reason: 'Registrar tiene que estar a un toque desde "$etiqueta"');
      }
    });
  });

  group('Fase 5 · layout a 360 px', () {
    testWidgets('las tres tarjetas KPI se apilan y no truncan la etiqueta',
        (tester) async {
      medida(tester, const Size(360, 640));
      await pumpHome(tester, conDatos: true);

      expect(tester.takeException(), isNull);
      final tarjetas = find.byType(SummaryCard);
      expect(tarjetas, findsNWidgets(3));
      final alturas = <double>[
        for (var i = 0; i < 3; i++) tester.getTopLeft(tarjetas.at(i)).dy,
      ];
      expect(alturas.toSet().length, 3,
          reason: 'a 360 px cada tarjeta ocupa su propia fila');
    });

    testWidgets('el segmentado del Reporte mide una sola línea', (tester) async {
      medida(tester, const Size(360, 640));
      await pumpHome(tester);
      await tester.tap(navTab(l10n.tabReports));
      await tester.pumpAndSettle();

      final segmentado =
          find.byWidgetPredicate((w) => w is SegmentedButton);
      expect(segmentado, findsOneWidget);
      expect(tester.getSize(segmentado).height, lessThan(56),
          reason: 'a 360 px el control no puede romper en dos líneas');
      expect(tester.takeException(), isNull);
    });

    testWidgets('el campo de proveedor no repite la etiqueta', (tester) async {
      await pumpHome(tester);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.byType(RegisterScreen), findsOneWidget);
      expect(find.text(l10n.providerFieldLabel), findsOneWidget,
          reason: 'la etiqueta va una sola vez, en el propio campo');
    });

    testWidgets('5.5 · el formulario todavía scrollea a 360×640',
        (tester) async {
      // Aceptación del plan «cabe sin scroll»: NO alcanzada (2026-11-24).
      // Se mide para que la afirmación del reporte tenga artefacto. Si algún
      // día el formulario cabe, este test falla: actualizar plan y reporte.
      medida(tester, const Size(360, 640));
      await pumpHome(tester);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      final lista = find
          .descendant(
              of: find.byType(RegisterScreen),
              matching: find.byType(Scrollable))
          .first;
      final posicion = tester.state<ScrollableState>(lista).position;
      expect(posicion.maxScrollExtent, greaterThan(0),
          reason: 'la aceptación 5.5 sigue sin cumplirse; si ya cabe, '
              'actualiza el plan y el reporte en vez de borrar este test');
    });

    testWidgets('el rail entra en 840 px, no en 839', (tester) async {
      medida(tester, const Size(839, 900));
      await pumpHome(tester);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);

      medida(tester, const Size(840, 900));
      await pumpHome(tester);
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });
  });

  group('Fase 6 · accesibilidad y limpieza', () {
    testWidgets('la barra expone sus tres destinos al lector de pantalla',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pumpHome(tester);

      for (final etiqueta in [
        l10n.tabOverview,
        l10n.tabMovements,
        l10n.tabReports,
      ]) {
        final nodo = tester.semantics.find(navTab(etiqueta));
        final datos = nodo.getSemanticsData();
        expect(datos.label, contains(etiqueta),
            reason: 'un lector tiene que oír "$etiqueta"');
        expect(datos.hasAction(SemanticsAction.tap), isTrue,
            reason: '"$etiqueta" tiene que poder activarse sin tocar la pantalla');
      }
      handle.dispose();
    });

    test('el idioma por defecto es español', () {
      const ajustes = FarmSettings();
      expect(ajustes.language, 'es');
      expect(ajustes.numberLocale, 'es_CO');
    });

    testWidgets('con el teléfono en inglés la app arranca en español',
        (tester) async {
      tester.platformDispatcher.localesTestValue = const [Locale('en', 'US')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);

      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final store = LocalStore(prefs);

      await tester.pumpWidget(MiCafetalApp(store: store));
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.locale, const Locale('es'),
          reason: 'el público es colombiano: el sistema no manda el idioma');
    });

    testWidgets('si él ya eligió inglés, se respeta su elección',
        (tester) async {
      tester.platformDispatcher.localesTestValue = const [Locale('es', 'CO')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);

      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final store = LocalStore(prefs);
      await store.saveSettings(const FarmSettings(language: 'en'));

      await tester.pumpWidget(MiCafetalApp(store: store));
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.locale, const Locale('en'));
    });
  });
}
