import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/models/tasks.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/screens/register_screen.dart';
import 'package:mi_cafetal/services/local_store.dart';

AppLocalizations get _es => stringsFor('es');

/// Etapa B · el selector de lote en el jornal de «Cosechar».
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<TransactionProvider> makeProvider() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    return TransactionProvider(LocalStore(prefs));
  }

  Future<void> pumpRegister(WidgetTester tester, TransactionProvider provider,
      {Transaction? editing}) async {
    tester.view.physicalSize = const Size(900, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: RegisterScreen(editing: editing)),
      ),
    ));
    await tester.pumpAndSettle();
  }

  Finder campo(String label) => find.ancestor(
        of: find.text(label),
        matching: find.byType(DropdownButtonFormField<String>),
      );

  Future<void> elegir(WidgetTester tester, String label, Finder opcion) async {
    final f = campo(label);
    await tester.ensureVisible(f);
    await tester.tap(f);
    await tester.pumpAndSettle();
    await tester.tap(opcion.last);
    await tester.pumpAndSettle();
  }

  /// Jornal de «Cosechar» de 250 kg guardado en el proveedor.
  Future<Transaction> jornal(TransactionProvider p, String? lote) async {
    final crop = p.crops.single;
    return p.addTransaction(
      type: TransactionType.expense,
      category: 'mano_obra',
      amount: 100000,
      cropId: crop.id,
      quantity: 2,
      pricePerUnit: 50000,
      provider: 'Juan',
      task: kTaskCosechar,
      harvestedKg: 250,
      cohortSowingId: lote,
    );
  }

  Future<TransactionProvider> conDosLotes() async {
    final p = await makeProvider();
    final crop = await p.addCrop('Café', areaHa: 5, livePlants: 1000);
    await p.addSowing(
        cropId: crop.id, date: DateTime(2020, 3, 12), plants: 700, areaHa: 4);
    await p.addSowing(
        cropId: crop.id, date: DateTime(2026, 3, 12), plants: 300, areaHa: 1);
    return p;
  }

  testWidgets('jornal Cosechar con dos lotes vivos muestra el selector',
      (tester) async {
    final p = await conDosLotes();
    await jornal(p, null);
    await pumpRegister(tester, p, editing: p.transactions.single);

    expect(find.text(_es.jornalHarvestedKgLotLabel), findsOneWidget);
    final f = campo(_es.jornalHarvestedKgLotLabel);
    await tester.ensureVisible(f);
    await tester.tap(f);
    await tester.pumpAndSettle();

    expect(find.text(_es.jornalHarvestedKgLotNone), findsWidgets);
    expect(find.textContaining('700 matas'), findsWidgets);
    expect(find.textContaining('300 matas'), findsWidgets);
  });

  testWidgets('con un lote vivo lo preselecciona en un jornal nuevo',
      (tester) async {
    final p = await makeProvider();
    final crop = await p.addCrop('Café', areaHa: 5, livePlants: 1000);
    await p.addSowing(
        cropId: crop.id, date: DateTime(2020, 3, 12), plants: 1000, areaHa: 5);
    await pumpRegister(tester, p);

    await elegir(tester, _es.categoryFieldLabel,
        find.textContaining(_es.expenseCategory('mano_obra')));
    await elegir(tester, _es.cropFieldLabel, find.text('🌱 Café'));
    await elegir(tester, _es.taskFieldLabel, find.text('🍒 Cosechar'));

    expect(find.text(_es.jornalHarvestedKgLotLabel), findsOneWidget);
    expect(find.textContaining('1000 matas'), findsOneWidget,
        reason: 'el único lote queda elegido sin tocar el selector');
  });

  testWidgets('sin lotes vivos el selector no aparece y guarda null',
      (tester) async {
    final p = await makeProvider();
    final crop = await p.addCrop('Café', areaHa: 5, livePlants: 1000);
    final lote = await p.addSowing(
        cropId: crop.id, date: DateTime(2020, 3, 12), plants: 1000, areaHa: 5);
    await p.deleteSowing(lote.id);
    final t = await jornal(p, null);
    await pumpRegister(tester, p, editing: t);

    expect(find.text(_es.jornalHarvestedKgLotLabel), findsNothing);
    expect(p.transactions.single.cohortSowingId, isNull);
    expect(crop.id, isNotNull);
  });

  testWidgets('con kilos y sin lote muestra el aviso y guarda igual',
      (tester) async {
    final p = await conDosLotes();
    // Dos lotes vivos: el formulario arranca en «Sin lote».
    await jornal(p, null);
    await pumpRegister(tester, p, editing: p.transactions.single);

    expect(find.text(_es.jornalHarvestedKgLotMissing), findsOneWidget);

    final guardar = find.text(_es.saveChanges);
    await tester.ensureVisible(guardar);
    await tester.tap(guardar);
    await tester.pumpAndSettle();

    expect(p.transactions.single.cohortSowingId, isNull,
        reason: 'guardar sin lote es válido');
    expect(p.transactions.single.harvestedKg, 250);
  });

  testWidgets('cambiar la labor limpia el lote y no lo restaura',
      (tester) async {
    final p = await conDosLotes();
    final viejo = p.sowings.first.id;
    await jornal(p, viejo);
    await pumpRegister(tester, p, editing: p.transactions.single);

    expect(find.textContaining('700 matas'), findsOneWidget);

    final abonar = farmTasks.firstWhere((t) => t.key == 'abonar');
    await elegir(
        tester, _es.taskFieldLabel, find.text('${abonar.icon} ${abonar.name}'));
    expect(find.text(_es.jornalHarvestedKgLotLabel), findsNothing);

    final cosechar = farmTasks.firstWhere((t) => t.key == kTaskCosechar);
    await elegir(tester, _es.taskFieldLabel,
        find.text('${cosechar.icon} ${cosechar.name}'));
    expect(find.text(_es.jornalHarvestedKgLotLabel), findsOneWidget);
    expect(find.text(_es.jornalHarvestedKgLotNone), findsOneWidget,
        reason: 'lo que se ocultó no vuelve solo');
    expect(find.textContaining('700 matas'), findsNothing);
  });

  testWidgets('editar un jornal con un lote ya renovado conserva la atribución',
      (tester) async {
    final p = await makeProvider();
    final crop = await p.addCrop('Café', areaHa: 5, livePlants: 1000);
    final viejo = await p.addSowing(
        cropId: crop.id, date: DateTime(2020, 3, 12), plants: 700, areaHa: 4);
    await p.addSowing(
      cropId: crop.id,
      date: DateTime(2026, 3, 12),
      plants: 700,
      areaHa: 4,
      replacesPlants: 700,
      cohortSowingId: viejo.id,
    );
    final t = await jornal(p, viejo.id);
    await pumpRegister(tester, p, editing: t);

    expect(find.text(_es.jornalHarvestedKgLotLabel), findsOneWidget);
    expect(find.textContaining('renovado'), findsOneWidget);

    final guardar = find.text(_es.saveChanges);
    await tester.ensureVisible(guardar);
    await tester.tap(guardar);
    await tester.pumpAndSettle();

    expect(p.transactions.single.cohortSowingId, viejo.id,
        reason: 'no se pierde el puntero al editar');
  });
}
