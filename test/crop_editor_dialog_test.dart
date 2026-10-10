import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/models/crop.dart';
import 'package:mi_cafetal/widgets/crop_editor_dialog.dart';

class _Holder {
  CropFormData? value;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<_Holder> openDialog(WidgetTester tester) async {
    final holder = _Holder();
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () async {
                holder.value = await showDialog<CropFormData>(
                  context: context,
                  builder: (_) => const CropEditorDialog(existingNames: []),
                );
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    return holder;
  }

  /// Abre el editor con [crop] y la sugerencia de *Inversión total* (F3).
  Future<_Holder> openCon(
    WidgetTester tester, {
    required Crop crop,
    double? sugerencia,
    List<String> existentes = const [],
    bool sowingsLocked = false,
  }) async {
    final holder = _Holder();
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () async {
                holder.value = await showDialog<CropFormData>(
                  context: context,
                  builder: (_) => CropEditorDialog(
                    crop: crop,
                    existingNames: existentes,
                    suggestedEstablishmentCost: sugerencia,
                    sowingsLocked: sowingsLocked,
                  ),
                );
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    return holder;
  }

  testWidgets('el campo de costo del establecimiento es opcional', (tester) async {
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final holder = await openDialog(tester);
    final l10n = AppLocalizations.of(
        tester.element(find.byType(CropEditorDialog)))!;
    expect(find.text(l10n.establishmentCostLabel), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'Café');
    await tester.tap(find.text(l10n.add));
    await tester.pumpAndSettle();
    expect(find.byType(CropEditorDialog), findsNothing,
        reason: 'el diálogo debe cerrarse al confirmar');
    expect(holder.value, isNotNull);
    expect(holder.value!.name, 'Café');
    expect(holder.value!.establishmentCost, isNull);
  });

  testWidgets('ingresar costo del establecimiento lo devuelve en el formulario', (tester) async {
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final holder = await openDialog(tester);
    final l10n = AppLocalizations.of(
        tester.element(find.byType(CropEditorDialog)))!;

    await tester.enterText(find.byType(TextField).at(0), 'Café');
    await tester.enterText(find.byType(TextField).at(3), '12500000');
    await tester.tap(find.text(l10n.add));
    await tester.pumpAndSettle();
    expect(holder.value!.establishmentCost, 12500000);
  });

  testWidgets('un nombre repetido explica que ya existe y no que falta', (tester) async {
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final holder = _Holder();
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () async {
                holder.value = await showDialog<CropFormData>(
                  context: context,
                  builder: (_) =>
                      const CropEditorDialog(existingNames: ['Café']),
                );
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
        tester.element(find.byType(CropEditorDialog)))!;

    await tester.enterText(find.byType(TextField).at(0), 'café');
    await tester.tap(find.text(l10n.add));
    await tester.pumpAndSettle();

    expect(find.byType(CropEditorDialog), findsOneWidget,
        reason: 'no debe cerrarse con un nombre repetido');
    expect(find.text(l10n.cropNameTaken), findsOneWidget);
    expect(find.text(l10n.cropNameRequired), findsNothing,
        reason: 'el mensaje de "falta el nombre" ya no corresponde (C3)');
    expect(holder.value, isNull);
  });

  testWidgets('L2.0: un cultivo nuevo nace en establecimiento, no en producción',
      (tester) async {
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final holder = await openDialog(tester);
    final l10n = AppLocalizations.of(
        tester.element(find.byType(CropEditorDialog)))!;

    // El dropdown trae la fase preseleccionada: no se puede "leer" el valor
    // inicial de otra forma, así que se comprueba lo que se ve y lo que sale.
    expect(find.text(l10n.phaseEstablecimiento), findsOneWidget,
        reason: 'valor inicial del selector: establecimiento (P3)');
    expect(find.text(l10n.phaseProduccion), findsNothing,
        reason: 'producción ya no viene marcada por defecto');
    expect(find.text(l10n.phaseRenovacion), findsNothing);

    await tester.enterText(find.byType(TextField).at(0), 'Café');
    await tester.tap(find.text(l10n.add));
    await tester.pumpAndSettle();

    expect(holder.value, isNotNull);
    expect(holder.value!.phase, CropPhase.establecimiento);
  });

  testWidgets('L2.0: el selector sigue ofreciendo las 3 fases y permite '
      'elegir producción a mano', (tester) async {
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final holder = await openDialog(tester);
    final l10n = AppLocalizations.of(
        tester.element(find.byType(CropEditorDialog)))!;

    await tester.tap(find.byType(DropdownButtonFormField<CropPhase>));
    await tester.pumpAndSettle();

    // Abierto: la opción preseleccionada también está en el botón, por eso
    // aparece dos veces; producción y renovación, una sola.
    expect(find.text(l10n.phaseEstablecimiento), findsNWidgets(2));
    expect(find.text(l10n.phaseProduccion), findsOneWidget);
    expect(find.text(l10n.phaseRenovacion), findsOneWidget);

    await tester.tap(find.text(l10n.phaseProduccion));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Café');
    await tester.tap(find.text(l10n.add));
    await tester.pumpAndSettle();

    expect(holder.value, isNotNull);
    expect(holder.value!.phase, CropPhase.produccion,
        reason: 'elegir producción a mano sigue funcionando');
  });

  testWidgets('L2.0: al editar un cultivo se respeta su fase (renovación)',
      (tester) async {
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final holder = _Holder();
    const crop =
        Crop(id: 'c1', name: 'Café viejo', phase: CropPhase.renovacion);
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () async {
                holder.value = await showDialog<CropFormData>(
                  context: context,
                  builder: (_) => const CropEditorDialog(
                      crop: crop, existingNames: ['Café viejo']),
                );
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
        tester.element(find.byType(CropEditorDialog)))!;
    expect(find.text(l10n.phaseRenovacion), findsOneWidget,
        reason: 'la fase preseleccionada debe ser la del cultivo editado');

    await tester.tap(find.text(l10n.add));
    await tester.pumpAndSettle();

    expect(holder.value, isNotNull);
    expect(holder.value!.phase, CropPhase.renovacion);
  });

  testWidgets('4: un cultivo anual que llegara con otra fase se guarda en producción',
      (tester) async {
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final holder = _Holder();
    // El caso que motivó la regla: un cultivo anual en establecimiento. El
    // selector de fase está oculto para los anuales, así que sin aplicar el
    // invariante al guardar quedaría atascado y no habría forma de corregirlo
    // desde la interfaz.
    const crop = Crop(
        id: 'c2',
        name: 'Maíz',
        phase: CropPhase.establecimiento,
        cycle: CropCycle.anual);
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () async {
                holder.value = await showDialog<CropFormData>(
                  context: context,
                  builder: (_) => const CropEditorDialog(
                      crop: crop, existingNames: ['Maíz']),
                );
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
        tester.element(find.byType(CropEditorDialog)))!;
    expect(find.text(l10n.cycleAnual), findsOneWidget,
        reason: 'el ciclo preseleccionado debe ser el del cultivo editado');
    expect(find.byType(DropdownButtonFormField<CropPhase>), findsNothing,
        reason: 'los anuales no tienen selector de fase: por eso el invariante '
            'tiene que aplicarse al guardar y no solo al cambiar el ciclo');

    await tester.enterText(find.byType(TextField).at(0), 'Maíz');
    await tester.tap(find.text(l10n.add));
    await tester.pumpAndSettle();

    expect(holder.value, isNotNull);
    expect(holder.value!.cycle, CropCycle.anual);
    expect(holder.value!.phase, CropPhase.produccion,
        reason: 'el invariante anual -> producción se aplica al guardar');
  });

  testWidgets('F3: se auto-rellena con la suma de los gastos de siembra',
      (tester) async {
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final holder = await openCon(tester,
        crop: const Crop(id: 'c1', name: 'Café'),
        existentes: ['Café'],
        sugerencia: 450000);
    final l10n =
        AppLocalizations.of(tester.element(find.byType(CropEditorDialog)))!;

    final campo = find.byType(TextField).at(3);
    expect(tester.widget<TextField>(campo).controller!.text, '450000',
        reason: 'él no tiene que escribir dos veces la misma plata');

    // Sigue editable: si falta preparación de tierra o cercas, lo cambia.
    await tester.enterText(campo, '500000');
    await tester.tap(find.text(l10n.add));
    await tester.pumpAndSettle();

    expect(holder.value!.establishmentCost, 500000,
        reason: 'lo que él escriba manda sobre la sugerencia');
  });

  testWidgets('F3: nunca pisa la inversión que ya estaba anotada',
      (tester) async {
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final holder = await openCon(tester,
        crop: const Crop(id: 'c1', name: 'Café', establishmentCost: 999.0),
        existentes: ['Café'],
        sugerencia: 450000);
    final l10n =
        AppLocalizations.of(tester.element(find.byType(CropEditorDialog)))!;

    final campo = find.byType(TextField).at(3);
    expect(tester.widget<TextField>(campo).controller!.text, '999',
        reason: 'la sugerencia solo entra si el campo viene vacío');

    await tester.tap(find.text(l10n.add));
    await tester.pumpAndSettle();
    expect(holder.value!.establishmentCost, 999.0);
  });

  testWidgets('F3: sin sugerencia ni inversión anotada el campo queda vacío, '
      'nunca en 0', (tester) async {
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final holder = await openCon(tester,
        crop: const Crop(id: 'c1', name: 'Café'),
        existentes: ['Café']);
    final l10n =
        AppLocalizations.of(tester.element(find.byType(CropEditorDialog)))!;

    final campo = find.byType(TextField).at(3);
    expect(tester.widget<TextField>(campo).controller!.text, isEmpty,
        reason: 'regla de oro: null → oculto, nunca 0');

    await tester.tap(find.text(l10n.add));
    await tester.pumpAndSettle();
    expect(holder.value!.establishmentCost, isNull);
  });

  /// Abre el calendario (que arranca en hoy, porque el campo viene vacío) y
  /// lo confirma. El rótulo del botón se lee de las localizaciones de
  /// Material para no depender del idioma de la prueba.
  Future<void> confirmarFechaDeHoy(WidgetTester t, String campoVacio) async {
    await t.tap(find.text(campoVacio));
    await t.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget,
        reason: 'el campo de C1 abre el calendario');
    final mat =
        MaterialLocalizations.of(t.element(find.byType(DatePickerDialog)));
    await t.tap(find.text(mat.okButtonLabel));
    await t.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsNothing);
  }

  testWidgets('F4: con siembra inicial, área y plantas quedan en solo lectura',
      (tester) async {
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final holder = await openCon(
      tester,
      crop: const Crop(id: 'c1', name: 'Café', areaHa: 0.5, livePlants: 500),
      sowingsLocked: true,
    );
    final l10n =
        AppLocalizations.of(tester.element(find.byType(CropEditorDialog)))!;

    final nombre = tester.widget<TextField>(find.byType(TextField).at(0));
    final area = tester.widget<TextField>(find.byType(TextField).at(1));
    final plantas = tester.widget<TextField>(find.byType(TextField).at(2));

    // `TextField.enabled` es nullable: null = hereda (es decir, editable).
    expect(nombre.enabled ?? true, isTrue, reason: 'el nombre sí lo escribe él');
    expect(area.enabled ?? true, isFalse,
        reason: 'la fija la siembra: escribirla aquí no tendría efecto');
    expect(plantas.enabled ?? true, isFalse,
        reason: 'lo que teclee lo borraría la próxima siembra');
    expect(find.text(l10n.cropLockedHint), findsNWidgets(2));

    // Y la puerta de salida está ahí, no se queda encerrado.
    expect(find.text(l10n.cropLossRegister), findsOneWidget);

    await tester.tap(find.text(l10n.add));
    await tester.pumpAndSettle();

    expect(holder.value!.livePlants, 500, reason: 'se conserva el calculado');
    expect(holder.value!.areaHa, 0.5);
  });

  testWidgets('F4: sin siembras (ruta "ya está plantado") todo es editable',
      (tester) async {
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final holder = await openCon(tester,
        crop:
            const Crop(id: 'c1', name: 'Café', areaHa: 0.5, livePlants: 500));
    final l10n =
        AppLocalizations.of(tester.element(find.byType(CropEditorDialog)))!;

    expect(tester.widget<TextField>(find.byType(TextField).at(1)).enabled ??
        true, isTrue);
    expect(tester.widget<TextField>(find.byType(TextField).at(2)).enabled ??
        true, isTrue);
    expect(find.text(l10n.cropLockedHint), findsNothing);
    expect(find.text(l10n.cropLossRegister), findsNothing,
        reason: 'sin siembras no hay contador que corregir');

    await tester.enterText(find.byType(TextField).at(1), '1,5');
    await tester.enterText(find.byType(TextField).at(2), '800');
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.add));
    await tester.pumpAndSettle();

    expect(holder.value!.areaHa, 1.5);
    expect(holder.value!.livePlants, 800);
  });

  testWidgets('F5: el campo de fecha se ofrece en un perenne sin siembras',
      (tester) async {
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await openCon(tester, crop: const Crop(id: 'c1', name: 'Café'));
    final l10n =
        AppLocalizations.of(tester.element(find.byType(CropEditorDialog)))!;

    expect(find.text(l10n.plantedAtLabel), findsOneWidget);
    expect(find.text(l10n.plantedAtEmpty), findsOneWidget,
        reason: 'opcional: sin fecha dice "Sin fecha", no se inventa una');
  });

  testWidgets('F5: no se pide la fecha si el cultivo ya tiene siembras',
      (tester) async {
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await openCon(tester,
        crop: const Crop(id: 'c1', name: 'Café'),
        sowingsLocked: true);
    final l10n =
        AppLocalizations.of(tester.element(find.byType(CropEditorDialog)))!;

    expect(find.text(l10n.plantedAtLabel), findsNothing,
        reason: 'ahí manda la fecha de la última siembra, la de la finca');
    expect(find.byType(DropdownButtonFormField<CropPhase>), findsOneWidget,
        reason: 'la fase sí sigue a la vista');
  });

  testWidgets('F5: un cultivo anual no pregunta cuándo está plantado',
      (tester) async {
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await openCon(tester, crop: const Crop(
        id: 'c1', name: 'Maíz', cycle: CropCycle.anual));
    final l10n =
        AppLocalizations.of(tester.element(find.byType(CropEditorDialog)))!;

    expect(find.text(l10n.plantedAtLabel), findsNothing,
        reason: 'la edad de cafetal no aplica al anual');
  });

  testWidgets('C2: al crear, la fecha que anota decide la fase',
      (tester) async {
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final holder = await openDialog(tester);
    final l10n =
        AppLocalizations.of(tester.element(find.byType(CropEditorDialog)))!;

    // A mano elige renovación…
    await tester.tap(find.byType(DropdownButtonFormField<CropPhase>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.phaseRenovacion));
    await tester.pumpAndSettle();

    // …pero al decirle que está plantado hoy (0 años) la fase la decide la
    // edad: recién plantado, no puede ser renovación.
    await confirmarFechaDeHoy(tester, l10n.plantedAtEmpty);

    await tester.enterText(find.byType(TextField).at(0), 'Café');
    await tester.tap(find.text(l10n.add));
    await tester.pumpAndSettle();

    expect(holder.value, isNotNull);
    expect(holder.value!.plantedAt, isNotNull,
        reason: 'C1: la fecha sí se guarda');
    expect(holder.value!.phase, CropPhase.establecimiento,
        reason: 'C2: en un cultivo nuevo la edad manda sobre lo tecleado');
  });

  testWidgets('C2: al editar, la fecha no re-deduces la fase',
      (tester) async {
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final holder = await openCon(tester,
        crop: const Crop(
            id: 'c1', name: 'Café', phase: CropPhase.produccion));
    final l10n =
        AppLocalizations.of(tester.element(find.byType(CropEditorDialog)))!;

    // Pone una fecha de hoy: si se re-dedujera, la bajaría a establecimiento.
    await confirmarFechaDeHoy(tester, l10n.plantedAtEmpty);

    await tester.tap(find.text(l10n.add));
    await tester.pumpAndSettle();

    expect(holder.value!.plantedAt, isNotNull);
    expect(holder.value!.phase, CropPhase.produccion,
        reason: 'editar nunca re-deduces: la fase sale de su historial');
  });
}