import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/models/crop.dart';
import 'package:mi_cafetal/widgets/crop_editor_dialog.dart';

class _Holder {
  CropFormData? value;
}

/// E5 · La vida del cultivo.
///
/// Dos decisiones que tomó el productor con el asistente:
///
/// 1. **La fecha de la primera cosecha la pone él**, no una tabla de
///    especies. Una tabla (Café→36 meses, Plátano→9) obligaría a adivinar la
///    especie por el nombre del cultivo y le impondría un número que no
///    aplica a su altitud ni a su lluvia — el mismo problema descartado en E4.
/// 2. **Una resiembra no reinicia la edad.** En la finca la resiembra repone
///    plantas muertas; la app misma lo dice con su aritmética
///    (vivas − muertas + nuevas). Un cafetal de 7 años con matas reponidas
///    sigue teniendo 7 años.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('primerCosechaEstimada', () {
    final hoy = DateTime(2026, 10, 11);

    test('sin fecha anotada no dice nada (null → oculto, nunca un 0)', () {
      const crop = Crop(id: 'platano', name: 'Plátano');
      expect(primerCosechaEstimada(crop, yaCosecho: false, hoy: hoy), isNull);
    });

    test('si ya cosechó de verdad, calla: manda lo que cosechó', () {
      final crop = Crop(
          id: 'platano',
          name: 'Plátano',
          primerCosechaEsperada: DateTime(2027, 4, 1));
      expect(
        primerCosechaEstimada(crop, yaCosecho: true, hoy: hoy),
        isNull,
        reason: 'la estimación es un sustituto de la cosecha, no un extra',
      );
    });

    test('una fecha futura cuenta los meses que faltan', () {
      final crop = Crop(
          id: 'platano',
          name: 'Plátano',
          primerCosechaEsperada: DateTime(2027, 4, 1));
      final e = primerCosechaEstimada(crop, yaCosecho: false, hoy: hoy)!;
      expect(e.monthsOut, 6);
      expect(e.overdue, isFalse);
      expect(e.date, DateTime(2027, 4, 1));
    });

    test('si cae este mismo mes, cuenta 0 meses y no está atrasada', () {
      final crop = Crop(
          id: 'durazno',
          name: 'Durazno',
          primerCosechaEsperada: DateTime(2026, 10, 25));
      final e = primerCosechaEstimada(crop, yaCosecho: false, hoy: hoy)!;
      expect(e.monthsOut, 0);
      expect(e.overdue, isFalse);
    });

    test('una fecha que ya pasó sin cosecha queda como atrasada, en 0', () {
      final crop = Crop(
          id: 'durazno',
          name: 'Durazno',
          primerCosechaEsperada: DateTime(2026, 3, 1));
      final e = primerCosechaEstimada(crop, yaCosecho: false, hoy: hoy)!;
      expect(e.overdue, isTrue,
          reason: 'es un dato ("debería estar rindiendo"), no una alerta');
      expect(e.monthsOut, 0);
    });

    test('ayer sí pasó, mañana no: se compara por día, no por mes', () {
      final ayer = Crop(
          id: 'c', name: 'C', primerCosechaEsperada: DateTime(2026, 10, 10));
      final manana = Crop(
          id: 'c', name: 'C', primerCosechaEsperada: DateTime(2026, 10, 12));
      expect(
          primerCosechaEstimada(ayer, yaCosecho: false, hoy: hoy)!.overdue,
          isTrue);
      expect(
          primerCosechaEstimada(manana, yaCosecho: false, hoy: hoy)!.overdue,
          isFalse);
    });

    test('el mismo día no cuenta como atrasada todavía', () {
      final crop = Crop(
          id: 'c', name: 'C', primerCosechaEsperada: DateTime(2026, 10, 11));
      expect(
          primerCosechaEstimada(crop, yaCosecho: false, hoy: hoy)!.overdue,
          isFalse);
    });
  });

  group('E5 · borrar la fecha estimada', () {
    test('copyWith(null) la borra de verdad (sentinela)', () {
      final crop = Crop(
          id: 'c', name: 'Café', primerCosechaEsperada: DateTime(2027, 4, 1));
      expect(crop.copyWith(primerCosechaEsperada: null).primerCosechaEsperada,
          isNull,
          reason: 'sin sentinela, copyWith(null) habría conservado la fecha '
              'y no habría forma de quitarla');
    });

    test('copyWith sin tocarla la conserva', () {
      final crop = Crop(
          id: 'c', name: 'Café', primerCosechaEsperada: DateTime(2027, 4, 1));
      expect(crop.copyWith(name: 'Café 2').primerCosechaEsperada,
          DateTime(2027, 4, 1));
    });

    test('sobrevive a la ida y vuelta por JSON local', () {
      final crop = Crop(
          id: 'c', name: 'Café', primerCosechaEsperada: DateTime(2027, 4, 1));
      expect(Crop.fromJson(crop.toJson()).primerCosechaEsperada,
          DateTime(2027, 4, 1));
    });
  });

  group('E5 · el editor', () {
    Future<_Holder> open(
      WidgetTester tester, {
      Crop? crop,
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
                    builder: (_) =>
                        CropEditorDialog(crop: crop, existingNames: const []),
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

    AppLocalizations l10nOf(WidgetTester tester) =>
        AppLocalizations.of(tester.element(find.byType(CropEditorDialog)))!;

    testWidgets('al CREAR no se pide: si se puede pedir después, no se pide '
        'ahora', (tester) async {
      tester.view.physicalSize = const Size(900, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await open(tester);
      expect(find.text(l10nOf(tester).firstHarvestLabel), findsNothing);
    });

    testWidgets('al EDITAR sí se pide, y viene de lo que ya tenía',
        (tester) async {
      tester.view.physicalSize = const Size(900, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await open(tester,
          crop: Crop(
              id: 'c1',
              name: 'Plátano',
              primerCosechaEsperada: DateTime(2027, 4, 1)));
      final l10n = l10nOf(tester);

      expect(find.text(l10n.firstHarvestLabel), findsOneWidget);
      expect(find.text(l10n.firstHarvestEmpty), findsNothing,
          reason: 'ya trae fecha, así que no dice "Sin fecha estimada"');
    });

    testWidgets('la fecha que anota en el editor llega al formulario',
        (tester) async {
      tester.view.physicalSize = const Size(900, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final holder =
          await open(tester, crop: const Crop(id: 'c1', name: 'Plátano'));
      final l10n = l10nOf(tester);

      // El campo es el último de un diálogo largo: sin desplazar, su centro
      // cae fuera del área pintada y el tap no llega.
      await tester.ensureVisible(find.text(l10n.firstHarvestEmpty));
      await tester.tap(find.text(l10n.firstHarvestEmpty));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);

      final mat =
          MaterialLocalizations.of(tester.element(find.byType(DatePickerDialog)));
      await tester.tap(find.text(mat.okButtonLabel));
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.save));
      await tester.pumpAndSettle();

      final hoy = DateTime.now();
      expect(holder.value?.primerCosechaEsperada,
          DateTime(hoy.year + 1, hoy.month, 1),
          reason: 'el calendario arranca un año más adelante, el día 1, y '
              'OK lo confirma tal cual');
    });

    testWidgets('se puede borrar: null en el formulario, no la fecha vieja',
        (tester) async {
      tester.view.physicalSize = const Size(900, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final holder = await open(tester,
          crop: Crop(
              id: 'c1',
              name: 'Plátano',
              primerCosechaEsperada: DateTime(2027, 4, 1)));
      final l10n = l10nOf(tester);

      await tester.ensureVisible(find.byTooltip(l10n.plantedAtClear));
      await tester.tap(find.byTooltip(l10n.plantedAtClear));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.save));
      await tester.pumpAndSettle();

      expect(holder.value?.primerCosechaEsperada, isNull,
          reason: 'el campo es opcional y borrable, como la meta de E4');
    });
  });
}
