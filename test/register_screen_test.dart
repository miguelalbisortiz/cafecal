import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/models/categories.dart';
import 'package:mi_cafetal/models/tasks.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/screens/register_screen.dart';
import 'package:mi_cafetal/services/local_store.dart';

AppLocalizations get _es => stringsFor('es');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<TransactionProvider> makeProvider() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    return TransactionProvider(LocalStore(prefs));
  }

  Future<void> pumpRegister(WidgetTester tester, TransactionProvider provider,
      {Transaction? editing, TransactionType? initialType}) async {
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: RegisterScreen(editing: editing, initialType: initialType)),
      ),
    ));
    await tester.pumpAndSettle();
  }

  Finder dropdownWithValue(String value) => find.byWidgetPredicate((w) =>
      w is DropdownButton<String> &&
      (w.items ?? const []).any((i) => i.value == value));

  testWidgets('ingreso: la opción de venta toma el nombre del cultivo',
      (tester) async {
    final provider = await makeProvider();
    final crop = await provider.addCrop('Plátano');
    await pumpRegister(tester, provider,
        initialType: TransactionType.income);

    // Elegir el cultivo en el dropdown de Cultivo.
    await tester.tap(dropdownWithValue(crop.id));
    await tester.pumpAndSettle();
    await tester.tap(find.text('🌱 Plátano').last);
    await tester.pumpAndSettle();

    // Abrir el dropdown de Categoría (los ingresos siempre ofrecen 'venta').
    await tester.tap(dropdownWithValue(kIncomeCategorySale));
    await tester.pumpAndSettle();

    // La venta toma el nombre del cultivo elegido arriba.
    expect(find.text('🌱 Venta Plátano'), findsWidgets);
    expect(find.textContaining(_es.catSubvenciones), findsWidgets);
    expect(find.textContaining(_es.catVentaOtro), findsWidgets);
    // Nunca se ofrecen ventas de cultivos que no existen.
    expect(find.textContaining('Venta café'), findsNothing);
    expect(find.textContaining('Venta plátano'), findsNothing);
  });

  testWidgets('sin cultivo la opción de venta es "Venta" a secas',
      (tester) async {
    final provider = await makeProvider();
    await pumpRegister(tester, provider,
        initialType: TransactionType.income);

    await tester.tap(dropdownWithValue(kIncomeCategorySale));
    await tester.pumpAndSettle();

    expect(find.text('💰 ${_es.catVenta}'), findsWidgets);
    expect(find.textContaining('Venta café'), findsNothing);
    expect(find.textContaining('Venta plátano'), findsNothing);
  });

  testWidgets('editar un registro legado muestra "Venta café" sin romper',
      (tester) async {
    final provider = await makeProvider();
    final legacy = Transaction(
      id: 'old1',
      type: TransactionType.income,
      category: 'venta_cafe',
      amount: 900,
      date: DateTime(2026, 9, 1),
      createdAt: DateTime(2026, 9, 1),
    );
    await pumpRegister(tester, provider, editing: legacy);

    // El valor legado sigue siendo un ítem válido del dropdown.
    expect(find.text('☕ Venta café'), findsWidgets);
  });

  testWidgets('sin cultivo elegido el aviso explica los costos de la finca',
      (tester) async {
    final provider = await makeProvider();
    await pumpRegister(tester, provider);

    // E2 · sin cultivo el movimiento es de toda la finca, y eso es lo que
    // hay que explicar. "Sin especificar" no le decía nada a nadie.
    expect(_es.commonCosts, 'Costos comunes');
    expect(find.text(_es.commonCostsHint), findsOneWidget);
    expect(find.text(_es.cropGroupHint), findsNothing);
  });

  testWidgets('con un cultivo elegido vuelve el aviso de crear variedades',
      (tester) async {
    final provider = await makeProvider();
    final crop = await provider.addCrop('Café');
    await pumpRegister(tester, provider,
        editing: Transaction(
          id: 't1',
          cropId: crop.id,
          type: TransactionType.expense,
          category: 'fertilizante',
          amount: 900,
          date: DateTime(2026, 9, 1),
          createdAt: DateTime(2026, 9, 1),
        ));

    expect(find.text(_es.cropGroupHint), findsOneWidget);
    expect(find.text(_es.commonCostsHint), findsNothing);
    expect(_es.cropGroupHint, contains('+ Nueva variedad…'));
  });

  testWidgets('el bloque jornal pregunta qué labor', (tester) async {
    tester.view.physicalSize = const Size(900, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final provider = await makeProvider();
    await pumpRegister(tester, provider,
        editing: Transaction(
          id: 't1',
          type: TransactionType.expense,
          category: 'mano_obra',
          amount: 100000,
          quantity: 2,
          unit: 'día',
          pricePerUnit: 50000,
          provider: 'Juan',
          task: 'abonar',
          date: DateTime(2026, 9, 1),
          createdAt: DateTime(2026, 9, 1),
        ));

    // La labor guardada se marca en la lista, con su icono.
    final abonar = farmTasks.firstWhere((t) => t.key == 'abonar');
    expect(find.text(_es.taskFieldLabel), findsOneWidget);
    expect(find.text('${abonar.icon} ${abonar.name}'), findsOneWidget);
    expect(find.text(_es.taskOtherLabel), findsNothing,
        reason: 'el campo de texto solo aparece con "Otra…"');
  });

  testWidgets('"Otra…" abre el campo y una labor libre se recarga ahí',
      (tester) async {
    tester.view.physicalSize = const Size(900, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final provider = await makeProvider();
    await pumpRegister(tester, provider,
        editing: Transaction(
          id: 't1',
          type: TransactionType.expense,
          category: 'mano_obra',
          amount: 100000,
          quantity: 2,
          unit: 'día',
          pricePerUnit: 50000,
          provider: 'Juan',
          // Una labor que no está en la lista: al editar no se pierde.
          task: 'desbrotar a mano',
          date: DateTime(2026, 9, 1),
          createdAt: DateTime(2026, 9, 1),
        ));

    final otra = farmTasks.firstWhere((t) => t.key == kTaskOther);
    expect(find.text('${otra.icon} ${otra.name}'), findsOneWidget);

    // El campo de texto cae más abajo que el viewport, y un ListView no
    // construye lo que no se ve: bajarlo antes de buscarlo.
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.text(_es.taskOtherLabel), findsOneWidget);
    expect(find.text('desbrotar a mano'), findsOneWidget);
  });

  testWidgets('al elegir una categoría confusa se explica cuál es cuál',
      (tester) async {
    tester.view.physicalSize = const Size(900, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final provider = await makeProvider();
    await pumpRegister(tester, provider,
        initialType: TransactionType.expense);

    // Cosecha y recolección: el gasto de la cosecha en sí, no el pago a
    // quien recoge. Ese pago es el que se perdía antes en la nómina.
    await tester.tap(dropdownWithValue(kExpenseCategoryHarvest));
    await tester.pumpAndSettle();
    await tester.tap(
        find.textContaining(_es.expenseCategory(kExpenseCategoryHarvest)).last);
    await tester.pumpAndSettle();
    expect(find.text(_es.harvestCategoryHint), findsOneWidget);
    expect(find.text(_es.sowingCategoryHint), findsNothing);

    // Mano de obra: confirma que ahí va el pago a las personas, aunque sea
    // por cosechar.
    await tester.tap(dropdownWithValue('mano_obra'));
    await tester.pumpAndSettle();
    await tester
        .tap(find.textContaining(_es.expenseCategory('mano_obra')).last);
    await tester.pumpAndSettle();
    expect(find.text(_es.laborCategoryHint), findsOneWidget);
    expect(find.text(_es.harvestCategoryHint), findsNothing);
  });

  testWidgets('los pares siembra/semillas y riego/agua se explican entre sí',
      (tester) async {
    tester.view.physicalSize = const Size(900, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final provider = await makeProvider();
    await pumpRegister(tester, provider,
        initialType: TransactionType.expense);

    // Etiqueta exacta del desplegable, no por subcadena: "Agua" aparece
    // dentro de la ayuda de Riego y "Riego" dentro de la de Agua, así que
    // buscar por subcadena elegiría el texto equivocado.
    Future<void> choose(String key) async {
      final icon = expenseCategories.firstWhere((c) => c.key == key).icon;
      await tester.tap(dropdownWithValue(key));
      await tester.pumpAndSettle();
      await tester.tap(find.text('$icon ${_es.expenseCategory(key)}').last);
      await tester.pumpAndSettle();
    }

    // Semillas e insumos: sólo Siembra cuenta como inversión, así que el
    // aviso manda a cambiar de categoría en vez de dejarse anotar mal.
    await choose('semillas_insumos');
    expect(find.text(_es.seedsCategoryHint), findsOneWidget);
    expect(find.text(_es.sowingCategoryHint), findsNothing);

    // Riego es lo que cuesta llevar agua al cultivo; la factura es Agua.
    await choose('riego');
    expect(find.text(_es.irrigationCategoryHint), findsOneWidget);
    expect(find.text(_es.seedsCategoryHint), findsNothing);

    // Agua es la factura de la finca; el costo del cultivo es Riego.
    await choose('agua');
    expect(find.text(_es.waterCategoryHint), findsOneWidget);
    expect(find.text(_es.irrigationCategoryHint), findsNothing);

    // De vuelta en Siembra vuelve su ayuda, que ya existía.
    await choose(kExpenseCategorySowing);
    expect(find.text(_es.sowingCategoryHint), findsOneWidget);
    expect(find.text(_es.waterCategoryHint), findsNothing);
  });

  // (b) · el lote va en el MISMO desplegable del cultivo y son mutuamente
  // excluyentes: un gasto es de un cultivo o sirve al lote, nunca de los dos.
  testWidgets('en un gasto se ofrecen los lotes dentro del desplegable',
      (tester) async {
    final provider = await makeProvider();
    await provider.addCrop('Café');
    final lote = await provider.addTerreno('Lote Alto');
    await pumpRegister(tester, provider);

    expect(dropdownWithValue(lote.id), findsOneWidget,
        reason: 'el lote se ofrece en la misma fila que los cultivos');

    await tester.tap(dropdownWithValue(lote.id));
    await tester.pumpAndSettle();
    expect(find.text(_es.terrenoGroupLabel), findsOneWidget,
        reason: 'los lotes van en grupo aparte, debajo de los cultivos');
    expect(find.text('Lote Alto'), findsWidgets);
  });

  testWidgets('en un ingreso no se ofrece ningún lote', (tester) async {
    final provider = await makeProvider();
    final lote = await provider.addTerreno('Lote Alto');
    await pumpRegister(tester, provider,
        initialType: TransactionType.income);

    // Un ingreso no se reparte por hectáreas: es de un cultivo o de la finca
    // entera. Si el grupo no está, tampoco se puede elegir.
    expect(dropdownWithValue(lote.id), findsNothing);
    expect(find.text(_es.terrenoGroupHint), findsNothing);
  });

  testWidgets('elegir lote deja el cultivo vacío, y a la inversa',
      (tester) async {
    final provider = await makeProvider();
    final crop = await provider.addCrop('Café');
    final lote = await provider.addTerreno('Lote Alto');
    await pumpRegister(tester, provider);

    await tester.tap(dropdownWithValue(lote.id));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lote Alto').last);
    await tester.pumpAndSettle();

    expect(find.text(_es.terrenoGroupHint), findsOneWidget,
        reason: 'con lote elegido el aviso habla del reparto, no del cultivo');
    expect(find.text(_es.cropGroupHint), findsNothing);
    expect(find.text(_es.commonCostsHint), findsNothing);

    // Un cultivo elegido desplaza al lote: los dos a la vez sería contar el
    // mismo peso dos veces.
    await tester.tap(dropdownWithValue(crop.id));
    await tester.pumpAndSettle();
    await tester.tap(find.text('🌱 Café').last);
    await tester.pumpAndSettle();

    expect(find.text(_es.cropGroupHint), findsOneWidget);
    expect(find.text(_es.terrenoGroupHint), findsNothing);
  });
}
