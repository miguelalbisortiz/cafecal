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
}