import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/models/sowing.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/services/local_store.dart';
import 'package:mi_cafetal/widgets/crop_loss_dialog.dart';

/// F4 · Puerta de salida del bloqueo de área/plantas.
///
/// El productor no escribe un número mágico: anota **cuántas plantas quedan**
/// y la app escribe la resiembra que corresponda. Así se cubren los dos casos:
/// la mortandad sin reponer plantas (que antes estaba prohibido) y el ajuste
/// por si sus cuentas no cuadraban con las de la app.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<TransactionProvider> setup({
    int plantas = 500,
    DateTime? siembra,
  }) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final provider = TransactionProvider(LocalStore(prefs));
    await provider.addCrop('Café');
    await provider.addSowing(
      cropId: provider.crops.single.id,
      date: siembra ?? DateTime(2026, 3, 1),
      plants: plantas,
    );
    return provider;
  }

  Future<void> pumpLoss(
      WidgetTester tester, TransactionProvider provider) async {
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final crop = provider.crops.single;
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => showDialog<int>(
                  context: context,
                  builder: (_) => CropLossDialog(
                    crop: crop,
                    currentPlants: crop.livePlants!,
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

  testWidgets('F4: anota la mortandad sin reponer plantas', (tester) async {
    final provider = await setup(plantas: 500);
    await pumpLoss(tester, provider);
    final l10n =
        AppLocalizations.of(tester.element(find.byType(CropLossDialog)))!;

    await tester.enterText(find.byType(TextFormField).at(0), '450');
    await tester.pumpAndSettle();
    expect(find.text(l10n.cropLossPreviewDied(50)), findsOneWidget,
        reason: 'dice qué va a quedar registrado antes de guardar');

    await tester.tap(find.widgetWithText(FilledButton, l10n.add));
    await tester.pumpAndSettle();

    expect(find.byType(CropLossDialog), findsNothing);
    expect(provider.sowings, hasLength(2));
    final resiembra = provider.sowings.last;
    expect(resiembra.kind, SowingKind.resiembra);
    expect(resiembra.plants, 0,
        reason: 'lo que antes estaba prohibido: 0 plantas nuevas');
    expect(resiembra.lostPlants, 50);
    expect(provider.crops.single.livePlants, 450);
  });

  testWidgets('F4: el ajuste de salida suma lo que faltaba en el recuento',
      (tester) async {
    final provider = await setup(plantas: 450);
    await pumpLoss(tester, provider);
    final l10n =
        AppLocalizations.of(tester.element(find.byType(CropLossDialog)))!;

    await tester.enterText(find.byType(TextFormField).at(0), '470');
    await tester.pumpAndSettle();
    expect(find.text(l10n.cropLossPreviewAdded(20)), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, l10n.add));
    await tester.pumpAndSettle();

    final resiembra = provider.sowings.last;
    expect(resiembra.plants, 20);
    expect(resiembra.lostPlants, isNull);
    expect(provider.crops.single.livePlants, 470,
        reason: 'si sus cuentas eran otras, manda lo que salga de las siembras');
  });

  testWidgets('F4: con el mismo número no se guarda nada', (tester) async {
    final provider = await setup(plantas: 500);
    await pumpLoss(tester, provider);
    final l10n =
        AppLocalizations.of(tester.element(find.byType(CropLossDialog)))!;

    await tester.enterText(find.byType(TextFormField).at(0), '500');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, l10n.add));
    await tester.pumpAndSettle();

    expect(find.text(l10n.cropLossNoChange), findsOneWidget);
    expect(find.byType(CropLossDialog), findsOneWidget,
        reason: 'el diálogo no se cierra con un cambio que no cambia');
    expect(provider.sowings, hasLength(1),
        reason: 'sigue habiendo solo la siembra inicial');
  });

  testWidgets('F4: un valor que no es número no pasa', (tester) async {
    final provider = await setup(plantas: 500);
    await pumpLoss(tester, provider);
    final l10n =
        AppLocalizations.of(tester.element(find.byType(CropLossDialog)))!;

    await tester.enterText(find.byType(TextFormField).at(0), 'muchas');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, l10n.add));
    await tester.pumpAndSettle();

    expect(find.text(l10n.cropLossInvalid), findsOneWidget);
    expect(provider.sowings, hasLength(1));
  });

  testWidgets('F4: el diálogo muestra el día de la pérdida', (tester) async {
    final provider = await setup(plantas: 500);
    await pumpLoss(tester, provider);
    final l10n =
        AppLocalizations.of(tester.element(find.byType(CropLossDialog)))!;
    final material = MaterialLocalizations.of(
        tester.element(find.byType(CropLossDialog)));

    expect(find.text(l10n.dateFieldLabel), findsOneWidget);
    expect(find.text(material.formatShortDate(DateTime.now())), findsOneWidget,
        reason: 'arranca en hoy: lo normal es que la pérdida sea de hoy');
  });

  // Guarda (no rojo/verde): fija que el valor por defecto sigue siendo hoy.
  testWidgets('F4: sin tocar la fecha, la pérdida queda de hoy',
      (tester) async {
    final provider = await setup(plantas: 500);
    await pumpLoss(tester, provider);
    final l10n =
        AppLocalizations.of(tester.element(find.byType(CropLossDialog)))!;

    await tester.enterText(find.byType(TextFormField).at(0), '450');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, l10n.add));
    await tester.pumpAndSettle();

    final ahora = DateTime.now();
    final guardada = provider.sowings.last.date;
    expect(
      DateTime(guardada.year, guardada.month, guardada.day),
      DateTime(ahora.year, ahora.month, ahora.day),
    );
  });

  testWidgets('F4: la pérdida se fecha el día que él elige', (tester) async {
    // La siembra arranca el 1 del mes pasado: así el selector deja navegar
    // hacia atrás sin depender del mes en que corran los tests.
    final ahora = DateTime.now();
    final primeraSiembra = DateTime(ahora.year, ahora.month - 1, 1);
    final provider = await setup(plantas: 500, siembra: primeraSiembra);
    await pumpLoss(tester, provider);
    final l10n =
        AppLocalizations.of(tester.element(find.byType(CropLossDialog)))!;
    final material = MaterialLocalizations.of(
        tester.element(find.byType(CropLossDialog)));

    await tester.tap(find.byIcon(Icons.calendar_today_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();
    await tester.tap(find.text('15'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(material.okButtonLabel));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), '450');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, l10n.add));
    await tester.pumpAndSettle();

    expect(provider.sowings.last.date, DateTime(ahora.year, ahora.month - 1, 15),
        reason: 'anota el día de la pérdida, no el día en que la escribe');
    expect(provider.crops.single.livePlants, 450);
  });

  // ── T15 · el lote de la pérdida ─────────────────────────────────────────

  /// Dos edades vivas: 1.000 matas del 2020 y 300 del 2024.
  Future<TransactionProvider> dosLotes({DateTime? segunda}) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final provider = TransactionProvider(LocalStore(prefs));
    final crop = await provider.addCrop('Café', areaHa: 5);
    await provider.addSowing(
        cropId: crop.id,
        date: DateTime(2020, 3, 12),
        plants: 1000,
        areaHa: 5);
    await provider.addSowing(
        cropId: crop.id,
        date: segunda ?? DateTime(2024, 5, 1),
        plants: 300,
        areaHa: 1,
        replacesPlants: 0);
    return provider;
  }

  String corta(DateTime d) => '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  testWidgets('T15: con dos edades la pérdida va al lote más viejo por defecto',
      (tester) async {
    final provider = await dosLotes();
    final vieja = provider.sowings.first.id;
    await pumpLoss(tester, provider);
    final l10n =
        AppLocalizations.of(tester.element(find.byType(CropLossDialog)))!;

    expect(find.text(l10n.sowingCohortLabel), findsOneWidget);
    expect(find.text(l10n.sowingCohortOption('12/03/2020', 1000)),
        findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), '1250');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, l10n.add));
    await tester.pumpAndSettle();

    final resiembra = provider.sowings.last;
    expect(resiembra.cohortSowingId, vieja);
    expect(resiembra.lostPlants, 50);
    expect(provider.crops.single.livePlants, 1250,
        reason: 'la pérdida bajó el total en 50');
  });

  testWidgets('T15: el lote elegido recibe la pérdida', (tester) async {
    final provider = await dosLotes();
    final nueva = provider.sowings.last.id;
    await pumpLoss(tester, provider);
    final l10n =
        AppLocalizations.of(tester.element(find.byType(CropLossDialog)))!;

    await tester.tap(find.text(l10n.sowingCohortOption('12/03/2020', 1000)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.sowingCohortOption('01/05/2024', 300)).last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), '1270');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, l10n.add));
    await tester.pumpAndSettle();

    expect(provider.sowings.last.cohortSowingId, nueva);
    expect(provider.crops.single.livePlants, 1270);
  });

  testWidgets('T15: la pérdida no se fecha antes de la siembra de su lote',
      (tester) async {
    final ahora = DateTime.now();
    final primeraDelMes = DateTime(ahora.year, ahora.month, 1);
    final provider = await dosLotes(segunda: primeraDelMes);
    await pumpLoss(tester, provider);
    final l10n =
        AppLocalizations.of(tester.element(find.byType(CropLossDialog)))!;
    final material = MaterialLocalizations.of(
        tester.element(find.byType(CropLossDialog)));

    bool mesAnteriorHabilitado() {
      final boton = tester.widget<IconButton>(find
          .ancestor(
            of: find.byIcon(Icons.chevron_left),
            matching: find.byType(IconButton),
          )
          .first);
      return boton.onPressed != null;
    }

    // Con el lote viejo (2020) se puede ir bien atrás.
    await tester.tap(find.byIcon(Icons.calendar_today_outlined));
    await tester.pumpAndSettle();
    expect(mesAnteriorHabilitado(), isTrue);
    await tester.tap(find.text(material.okButtonLabel));
    await tester.pumpAndSettle();

    // Con el lote que nació este mes, no hay mes anterior para elegir.
    await tester.tap(find.text(l10n.sowingCohortOption('12/03/2020', 1000)));
    await tester.pumpAndSettle();
    await tester.tap(find
        .text(l10n.sowingCohortOption(corta(primeraDelMes), 300))
        .last);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.calendar_today_outlined));
    await tester.pumpAndSettle();
    expect(mesAnteriorHabilitado(), isFalse,
        reason: 'la pérdida no puede ser anterior a esa siembra');
  });
}
