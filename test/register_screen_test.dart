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

  // B · el ítem nulo del desplegable.
  //
  // Se llamaba «Costos comunes» también en ingresos, y su aviso hablaba de
  // «cerca, camino, luz». Una venta podía quedar con ese texto debajo.
  testWidgets('un ingreso sin cultivo dice «Sin cultivo», no «Costos comunes»',
      (tester) async {
    final provider = await makeProvider();
    await pumpRegister(tester, provider,
        initialType: TransactionType.income);

    // En un desplegable cerrado solo se construye el ítem ELEGIDO. Con
    // `_cropId` vacío, el elegido es el nulo.
    expect(find.text(_es.noCropLabel), findsOneWidget,
        reason: 'un ingreso no tiene «costos comunes»: es un ingreso');
    expect(find.text(_es.commonCosts), findsNothing);
    expect(find.text(_es.noCropHint), findsOneWidget);
    expect(find.text(_es.commonCostsHint), findsNothing,
        reason: 'el aviso de una venta no puede hablar de cerca, camino y luz');
  });

  testWidgets('un gasto sin cultivo sigue siendo «Costos comunes»',
      (tester) async {
    final provider = await makeProvider();
    await pumpRegister(tester, provider);

    // El arreglo es solo para ingresos: en un gasto la etiqueta vieja es la
    // correcta y es la que lleva toda la vida.
    expect(find.text(_es.commonCosts), findsOneWidget);
    expect(find.text(_es.commonCostsHint), findsOneWidget);
    expect(find.text(_es.noCropLabel), findsNothing);
  });

  // C · la cantidad heredada.
  //
  // El campo de cantidad se oculta al cambiar de categoría, pero el texto se
  // queda en el controlador. Se escribía 50 en una Venta, se cambiaba a
  // SUBVENCIÓN, y esa subvención se guardaba con quantity=50 y unit=null.
  // report_harvest_metrics suma `quantity * unitToKg(unit)` a «kg vendidos»
  // sin comprobar que sea venta, y unitToKg(null) es 1: un millón de
  // subvención inflando cincuenta kilos vendidos.
  testWidgets(
      'cambiar de venta a subvención no hereda la cantidad: cero kilos fantasma',
      (tester) async {
    // El formulario es un ListView perezoso: lo que queda fuera de pantalla
    // no se construye, y el botón de Guardar cierra la lista. Se ensancha la
    // ventana ANTES de montar la pantalla para que el formulario entero entre.
    //
    // Va por `tester.view`: `binding.window.physicalSizeTestValue` ya no mueve
    // la vista en Flutter 3.24 y la ventana se quedaba en 800×600.
    tester.view.physicalSize = const Size(800, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final provider = await makeProvider();
    final crop = await provider.addCrop('Café');
    await pumpRegister(tester, provider,
        initialType: TransactionType.income);

    await tester.tap(dropdownWithValue(crop.id));
    await tester.pumpAndSettle();
    await tester.tap(find.text('🌱 Café').last);
    await tester.pumpAndSettle();

    // Venta: aparece el campo de cantidad.
    await tester.tap(dropdownWithValue(kIncomeCategorySale));
    await tester.pumpAndSettle();
    await tester.tap(find.text('🌱 Venta Café').last);
    await tester.pumpAndSettle();

    // `TextFormField.decoration` no es público en Flutter 3.24, así que se
    // va por el rótulo ya pintado: es un Text descendente del propio campo.
    Finder byLabel(String label) => find.ancestor(
        of: find.text(label), matching: find.byType(TextFormField));

    final qtyField = byLabel(_es.quantityFieldLabel);
    expect(qtyField, findsOneWidget);
    await tester.enterText(qtyField, '50');

    // Se equivoca de categoría: era una subvención, no una venta.
    await tester.tap(dropdownWithValue(kIncomeCategorySale));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining(_es.catSubvenciones).last);
    await tester.pumpAndSettle();

    // El campo DESAPARECE de la pantalla…
    expect(qtyField, findsNothing);

    // …pero el texto se queda en el controlador. Ese es el truco.
    await tester.enterText(byLabel(_es.amountFieldLabel), '1000000');

    // Se pica el rótulo y no el botón. Los dos apuntan al mismo sitio —el
    // texto está dentro del botón—, pero `find.byType(FilledButton)` da 0 en
    // el árbol aunque el botón esté ahí, mientras que `find.text` lo ve
    // seguro. Más vale lo que se puede medir.
    final guardar = find.text(_es.saveRecord);
    await tester.ensureVisible(guardar);
    await tester.tap(guardar);
    await tester.pumpAndSettle();

    final guardado = provider.transactions.single;
    expect(guardado.quantity, isNull,
        reason: 'una subvención no vende kilos: quantity heredado de una venta '
            'anterior inflaba «kg vendidos»');
    expect(guardado.unit, isNull);
  });

  // 3 · el jornal pertenece a la moneda de la cuenta.
  //
  // Un trabajador no tiene moneda propia: se registra y se pinta en la
  // moneda de Ajustes. Elegirlo en el formulario rellenaba su tarifa a
  // secas… también en un registro VIEJO que se edita conservando su moneda.
  // El 50.000 significaba pesos y quedaba escrito dentro de un gasto en
  // euros: la cifra crecía sola y ya no era de nadie.
  Future<void> elegirTrabajador(WidgetTester tester, TransactionProvider p,
      {required String moneda}) async {
    tester.view.physicalSize = const Size(900, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // El valor del ítem es el id del trabajador, no su nombre: el nombre es
    // solo el texto pintado.
    final juan = await p.addEmployee('Juan', dayRate: 50000);
    await pumpRegister(
      tester,
      p,
      editing: Transaction(
        id: 'viejo1',
        type: TransactionType.expense,
        category: 'mano_obra',
        amount: 100,
        currency: moneda,
        // Sin tarifa guardada: el único origen posible del número es la
        // ficha del trabajador.
        date: DateTime(2025, 3, 1),
        createdAt: DateTime(2025, 3, 1),
      ),
    );

    await tester.tap(dropdownWithValue(juan.id));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Juan').last);
    await tester.pumpAndSettle();
  }

  String tarifaEnPantalla(WidgetTester tester) => tester
      .widget<TextFormField>(find.ancestor(
          of: find.text(_es.workerDayRateShort),
          matching: find.byType(TextFormField)))
      .controller!
      .text;

  testWidgets(
      'elegir trabajador en un registro viejo en euros NO rellena el jornal',
      (tester) async {
    final provider = await makeProvider();
    await elegirTrabajador(tester, provider, moneda: 'EUR');

    expect(tarifaEnPantalla(tester), isEmpty,
        reason: 'la tarifa de Juan son 50.000 PESOS; este gasto está en '
            'euros, y meter ese número aquí sería presentar euros que no '
            'existen. El jornal no tiene moneda propia: es el de la cuenta.');
  });

  testWidgets(
      'elegir trabajador en un registro de la moneda de la cuenta SÍ lo rellena',
      (tester) async {
    final provider = await makeProvider();
    await elegirTrabajador(tester, provider, moneda: 'COP');

    // El control: el arreglo no puede haber sido apagar el autocompletado a
    // piñón. En la moneda de la cuenta —que es donde vive la tarifa— sigue
    // llegando solo.
    expect(tarifaEnPantalla(tester), '50000');
  });

  // Tanda 2 · los kilos recolectados del jornal.
  //
  // El campo es la única puerta a una medida independiente de la venta: solo
  // tiene sentido cuando hay un cultivo a quién atribuirla. Por eso aparece
  // únicamente con la labor «Cosechar» y un cultivo; con lote o sin cultivo se
  // oculta y se guarda `null` (nunca un 0 inventado).
  group('Kilos recolectados en el jornal', () {
    Future<Transaction> jornal(
      TransactionProvider p, {
      required String? cropId,
      String? terrenoId,
      String? task = kTaskCosechar,
      double? harvestedKg,
    }) =>
        p.addTransaction(
          type: TransactionType.expense,
          category: 'mano_obra',
          amount: 100000,
          cropId: cropId,
          terrenoId: terrenoId,
          quantity: 2,
          unit: 'día',
          pricePerUnit: 50000,
          provider: 'Juan',
          task: task,
          harvestedKg: harvestedKg,
          date: DateTime(2026, 10, 19),
        );

    Finder byLabel(String label) => find.ancestor(
        of: find.text(label), matching: find.byType(TextFormField));

    void tall(WidgetTester tester) {
      tester.view.physicalSize = const Size(900, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
    }

    testWidgets('aparece con un jornal de Cosechar y cultivo', (tester) async {
      tall(tester);
      final p = await makeProvider();
      final crop = await p.addCrop('Café');
      final j = await jornal(p, cropId: crop.id);
      await pumpRegister(tester, p, editing: j);

      expect(find.text(_es.jornalHarvestedKgLabel), findsOneWidget);
      expect(find.text(_es.jornalHarvestedKgHelp), findsOneWidget);
    });

    testWidgets('no aparece con otra labor', (tester) async {
      tall(tester);
      final p = await makeProvider();
      final crop = await p.addCrop('Café');
      final j = await jornal(p, cropId: crop.id, task: 'abonar');
      await pumpRegister(tester, p, editing: j);

      expect(find.text(_es.jornalHarvestedKgLabel), findsNothing);
      expect(find.text(_es.jornalHarvestedKgNoCrop), findsNothing);
    });

    testWidgets('sin cultivo no aparece y pide elegir el cultivo',
        (tester) async {
      tall(tester);
      final p = await makeProvider();
      final j = await jornal(p, cropId: null);
      await pumpRegister(tester, p, editing: j);

      expect(find.text(_es.jornalHarvestedKgLabel), findsNothing);
      expect(find.text(_es.jornalHarvestedKgNoCrop), findsOneWidget);
    });

    testWidgets('con lote no aparece', (tester) async {
      tall(tester);
      final p = await makeProvider();
      final lote = await p.addTerreno('Lote Alto');
      final j = await jornal(p, cropId: null, terrenoId: lote.id,
          harvestedKg: 120);
      await pumpRegister(tester, p, editing: j);

      expect(find.text(_es.jornalHarvestedKgLabel), findsNothing,
          reason: 'un lote no es un cultivo: no hay a quién atribuir los kg');
      expect(find.text(_es.jornalHarvestedKgNoCrop), findsOneWidget);
    });

    testWidgets('restaura los kilos guardados', (tester) async {
      tall(tester);
      final p = await makeProvider();
      final crop = await p.addCrop('Café');
      final j = await jornal(p, cropId: crop.id, harvestedKg: 123.5);
      await pumpRegister(tester, p, editing: j);

      expect(find.text('123.5'), findsWidgets);
    });

    testWidgets('guardar escribe los kilos', (tester) async {
      tall(tester);
      final p = await makeProvider();
      final crop = await p.addCrop('Café');
      final j = await jornal(p, cropId: crop.id, harvestedKg: 123.5);
      await pumpRegister(tester, p, editing: j);

      await tester.enterText(byLabel(_es.jornalHarvestedKgLabel), '120');
      final guardar = find.text(_es.saveChanges);
      await tester.ensureVisible(guardar);
      await tester.tap(guardar);
      await tester.pumpAndSettle();

      expect(p.transactions.single.harvestedKg, 120);
    });

    testWidgets('vacío guarda null, nunca 0', (tester) async {
      tall(tester);
      final p = await makeProvider();
      final crop = await p.addCrop('Café');
      final j = await jornal(p, cropId: crop.id, harvestedKg: 123.5);
      await pumpRegister(tester, p, editing: j);

      await tester.enterText(byLabel(_es.jornalHarvestedKgLabel), '');
      final guardar = find.text(_es.saveChanges);
      await tester.ensureVisible(guardar);
      await tester.tap(guardar);
      await tester.pumpAndSettle();

      expect(p.transactions.single.harvestedKg, isNull);
    });

    testWidgets('cero no pasa la validación y no guarda', (tester) async {
      tall(tester);
      final p = await makeProvider();
      final crop = await p.addCrop('Café');
      final j = await jornal(p, cropId: crop.id, harvestedKg: 123.5);
      await pumpRegister(tester, p, editing: j);

      await tester.enterText(byLabel(_es.jornalHarvestedKgLabel), '0');
      final guardar = find.text(_es.saveChanges);
      await tester.ensureVisible(guardar);
      await tester.tap(guardar);
      await tester.pumpAndSettle();

      expect(find.text(_es.jornalHarvestedKgInvalid), findsOneWidget);
      expect(p.transactions.single.harvestedKg, 123.5,
          reason: 'no se guardó nada');
    });

    testWidgets('al cambiar de labor se limpia y no vuelve sola',
        (tester) async {
      tall(tester);
      final p = await makeProvider();
      final crop = await p.addCrop('Café');
      final j = await jornal(p, cropId: crop.id, harvestedKg: 123.5);
      await pumpRegister(tester, p, editing: j);

      final abonar = farmTasks.firstWhere((t) => t.key == 'abonar');
      await tester.tap(dropdownWithValue('abonar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('${abonar.icon} ${abonar.name}').last);
      await tester.pumpAndSettle();
      expect(find.text(_es.jornalHarvestedKgLabel), findsNothing);

      final cosechar = farmTasks.firstWhere((t) => t.key == kTaskCosechar);
      await tester.tap(dropdownWithValue(kTaskCosechar));
      await tester.pumpAndSettle();
      await tester.tap(find.text('${cosechar.icon} ${cosechar.name}').last);
      await tester.pumpAndSettle();

      expect(find.text(_es.jornalHarvestedKgLabel), findsOneWidget);
      expect(find.text('123.5'), findsNothing,
          reason: 'lo oculto no se guarda ni se restaura (D12)');
    });
  });
}
