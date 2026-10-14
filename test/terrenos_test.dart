import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/models/crop.dart';
import 'package:mi_cafetal/models/employee.dart';
import 'package:mi_cafetal/models/harvest.dart';
import 'package:mi_cafetal/models/settings.dart';
import 'package:mi_cafetal/models/terreno.dart';
import 'package:mi_cafetal/providers/sync_provider.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/screens/crops_screen.dart';
import 'package:mi_cafetal/services/backup_service.dart';
import 'package:mi_cafetal/services/local_store.dart';
import 'package:mi_cafetal/services/supabase_service.dart';
import 'package:mi_cafetal/widgets/crop_editor_dialog.dart';
import 'package:mi_cafetal/widgets/terreno_editor_dialog.dart';

/// W1-a · El terreno.
///
/// Lo que estos tests cuidan, por orden de caridad:
///   1. Un terreno **opcional**. Sin terrenos la app es la de antes.
///   2. Borrar un terreno **no borra ningún cultivo** — solo lo deja sin
///      terreno. Es el miedo fundado de cualquier productor al ver un ícono
///      de tacho junto a un nombre de su tierra.
///   3. Un respaldo escrito **antes** de W1 sigue restaurando entero.
///   4. La subida respeta el orden de las claves foráneas: el terreno antes
///      que el cultivo que apunta a él, o Supabase tira el cultivo entero.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<({LocalStore store, TransactionProvider provider})> newProvider(
      {String? uid}) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final store = LocalStore(prefs, uid: uid);
    return (store: store, provider: TransactionProvider(store));
  }

  group('Terreno · modelo', () {
    test('round-trip conserva id, nombre, área y pendingSync', () {
      const original = Terreno(
        id: 't1',
        name: 'Lote de arriba',
        areaHa: 2.5,
        pendingSync: true,
      );
      final restored = Terreno.fromJson(original.toJson());
      expect(restored.id, 't1');
      expect(restored.name, 'Lote de arriba');
      expect(restored.areaHa, 2.5);
      expect(restored.pendingSync, isTrue);
    });

    test('retrocompat: JSON sin area_ha ni pending_sync', () {
      final legacy = Terreno.fromJson({'id': 't2', 'name': 'Potrero'});
      expect(legacy.name, 'Potrero');
      expect(legacy.areaHa, isNull, reason: 'él no midió el terreno');
      expect(legacy.pendingSync, isFalse);
    });

    test('sin área la clave no aparece: null oculto, nunca 0', () {
      const plain = Terreno(id: 't3', name: 'La vuelta');
      expect(plain.toJson().containsKey('area_ha'), isFalse);
    });

    test('copyWith puede BORRAR el área (centinela, no ??)', () {
      const conArea = Terreno(id: 't4', name: 'Alto', areaHa: 1.2);
      final sinArea = conArea.copyWith(areaHa: null);
      expect(sinArea.areaHa, isNull,
          reason: 'con `double?` a secas no habría forma de quitarla');
      // Y lo que no se le pisa se conserva.
      final renombrado = conArea.copyWith(name: 'Alto 2');
      expect(renombrado.areaHa, 1.2);
      expect(renombrado.name, 'Alto 2');
    });
  });

  group('Crop.terrenoId', () {
    test('round-trip lo conserva', () {
      const crop = Crop(id: 'c1', name: 'Café', terrenoId: 't1');
      expect(Crop.fromJson(crop.toJson()).terrenoId, 't1');
    });

    test('retrocompat: respaldo anterior a W1 no trae la clave', () {
      final legacy =
          Crop.fromJson({'id': 'c2', 'name': 'Plátano', 'icon': '🌱'});
      expect(legacy.terrenoId, isNull, reason: 'sin terreno, como siempre');
    });

    test('copyWith puede sacar el cultivo de su terreno', () {
      const crop = Crop(id: 'c3', name: 'Café', terrenoId: 't1');
      expect(crop.copyWith(terrenoId: null).terrenoId, isNull);
    });
  });

  group('Provider · terrenos', () {
    test('addTerreno mete exactamente los cultivos marcados', () async {
      final p = await newProvider();
      final cafe = await p.provider.addCrop('Café');
      final platano = await p.provider.addCrop('Plátano');

      await p.provider.addTerreno('Lote de arriba',
          cropIds: [cafe.id, platano.id]);

      expect(p.provider.terrenos.single.name, 'Lote de arriba');
      expect(p.provider.crops.every((c) => c.terrenoId != null), isTrue);
    });

    test('los cultivos NO marcados quedan fuera', () async {
      final p = await newProvider();
      final cafe = await p.provider.addCrop('Café');
      await p.provider.addCrop('Plátano');

      await p.provider.addTerreno('Lote', cropIds: [cafe.id]);

      final platanoo = p.provider.crops.firstWhere((c) => c.name == 'Plátano');
      expect(platanoo.terrenoId, isNull);
    });

    test('un cultivo marcado se MUEVE desde otro terreno, no se duplica',
        () async {
      final p = await newProvider();
      final cafe = await p.provider.addCrop('Café');
      await p.provider.addTerreno('A', cropIds: [cafe.id]);
      await p.provider.addTerreno('B', cropIds: [cafe.id]);

      expect(p.provider.terrenos, hasLength(2));
      expect(p.provider.crops.single.terrenoId, p.provider.terrenos.last.id,
          reason: 'está en B y solo en B');
    });

    test('desmarcar en la edición lo saca y lo deja sin terreno', () async {
      final p = await newProvider();
      final cafe = await p.provider.addCrop('Café');
      final a = await p.provider.addTerreno('A', cropIds: [cafe.id]);

      await p.provider
          .updateTerrenoWithCrops(a.copyWith(name: 'A 2'), const []);

      expect(p.provider.crops.single.terrenoId, isNull);
      expect(p.provider.terrenos.single.name, 'A 2');
    });

    test('desmarcar en un terreno NO desaloja a un cultivo de otro', () async {
      final p = await newProvider();
      final cafe = await p.provider.addCrop('Café');
      final platano = await p.provider.addCrop('Plátano');
      await p.provider.addTerreno('A', cropIds: [cafe.id]);
      final b = await p.provider.addTerreno('B', cropIds: [platano.id]);

      // Editamos B sin marcar nada: el café está en A y no tiene que verse.
      await p.provider.updateTerrenoWithCrops(b, const []);

      expect(p.provider.crops.firstWhere((c) => c.name == 'Café').terrenoId,
          p.provider.terrenos.first.id,
          reason: 'el café nunca vino de este lado');
      expect(p.provider.crops.firstWhere((c) => c.name == 'Plátano').terrenoId,
          isNull);
    });

    test('BORRAR el terreno deja los cultivos vivos y sin terreno', () async {
      final p = await newProvider();
      final cafe = await p.provider.addCrop('Café', livePlants: 200);
      await p.provider
          .addHarvest(cropId: cafe.id, amount: 40, date: DateTime(2026, 9, 1));
      final a = await p.provider.addTerreno('A', cropIds: [cafe.id]);

      await p.provider.deleteTerreno(a.id);

      expect(p.provider.terrenos, isEmpty);
      expect(p.provider.crops.single.id, cafe.id, reason: 'no se borró nada');
      expect(p.provider.crops.single.terrenoId, isNull);
      expect(p.provider.crops.single.livePlants, 200, reason: 'intacto');
      expect(p.provider.harvests, hasLength(1), reason: 'las cosechas siguen');
    });

    test('el cambio sobrevive a recargar desde el store', () async {
      final p = await newProvider();
      final cafe = await p.provider.addCrop('Café');
      final a = await p.provider.addTerreno('A', areaHa: 1.5, cropIds: [
        cafe.id
      ]);
      await p.provider.deleteTerreno(a.id);

      final reloaded = TransactionProvider(p.store);
      expect(reloaded.terrenos, isEmpty);
      expect(reloaded.crops.single.terrenoId, isNull,
          reason: 'el cultivo quedó sin terreno también al recargar');
    });

    test('los terrenos se guardan y se vuelven a leer', () async {
      final p = await newProvider();
      await p.provider.addTerreno('A', areaHa: 2);

      final reloaded = TransactionProvider(p.store);
      expect(reloaded.terrenos.single.name, 'A');
      expect(reloaded.terrenos.single.areaHa, 2);
    });

    test('mergeRemoteTerrenos junta por id y por nombre', () async {
      final p = await newProvider();
      await p.provider.addTerreno('Lote de arriba');
      final localId = p.provider.terrenos.single.id;

      p.provider.mergeRemoteTerrenos([
        // Mismo id que el local: ya está, no vuelve a entrar.
        Terreno(id: localId, name: 'Nombre viejo'),
        // El mismo nombre visto desde otro equipo: es el mismo terreno.
        const Terreno(id: 'distinto-id', name: '  LOTE DE ARRIBA '),
        // Id y nombre nuevos: es otro terreno de verdad.
        const Terreno(id: 'otro', name: 'Potrero'),
      ]);

      expect(p.provider.terrenos.map((t) => t.name),
          ['Lote de arriba', 'Potrero'],
          reason: 'el id decide, el nombre normalizado decide, el que es '
              'nuevo entra una sola vez');
    });
  });

  group('Respaldo · terrenos', () {
    final crops = [const Crop(id: 'c1', name: 'Café', terrenoId: 't1')];
    final terrenos = [const Terreno(id: 't1', name: 'Lote')];

    String build() => encodeBackup(
          crops: crops,
          employees: const [Employee(id: 'e1', name: 'Pedro')],
          harvests: [Harvest(id: 'h1', cropId: 'c1', amount: 1, date: DateTime(2026, 9, 1))],
          sowings: const [],
          transactions: const [],
          settings: const FarmSettings(),
          terrenos: terrenos,
          uid: 'uid-1',
          now: DateTime(2026, 10, 12),
        );

    test('el archivo trae terrenos y el conteo los cuenta', () {
      final map = jsonDecode(build()) as Map<String, dynamic>;
      expect((map['terrenos'] as List).length, 1);
      final conteo = map['conteo'] as Map<String, dynamic>;
      expect(conteo['terrenos'], 1);
      expect(conteo['cultivos'], 1);
      expect(conteo['empleados'], 1);
      expect(conteo['total'], isNull,
          reason: 'total es un getter, no vive en el JSON');
      expect(conteo.values.fold<int>(0, (a, b) => a + (b as int)),
          4,
          reason: 'cultivos + empleados + cosechas + terrenos');
    });

    test('roundtrip conserva el terreno y su cultivo apuntándole', () {
      final payload = decodeBackup(build());
      expect(payload.terrenos.single.name, 'Lote');
      expect(payload.crops.single.terrenoId, 't1');
    });

    test(
        'RETROCOMPAT: un respaldo escrito ANTES de W1 se importa entero '
        '(no lanza "incompleto")', () {
      final map = jsonDecode(build()) as Map<String, dynamic>;
      map.remove('terrenos');

      final payload = decodeBackup(jsonEncode(map));

      expect(payload.terrenos, isEmpty, reason: 'esa versión no los conocía');
      expect(payload.crops.single.terrenoId, 't1',
          reason: 'el resto del archivo llegó completo');
      expect(payload.conteo.terrenos, 0);
    });

    test('la clave existe pero viene malformada: sí se rechaza', () {
      final map = jsonDecode(build()) as Map<String, dynamic>;
      map['terrenos'] = 'no es una lista';

      expect(
          () => decodeBackup(jsonEncode(map)),
          throwsA(isA<BackupFormatException>()
              .having((e) => e.kind, 'kind', BackupErrorKind.incompleto)));
    });

    test('importBackup fusiona los terrenos y no pisa lo local', () async {
      final p = await newProvider();
      await p.provider.addTerreno('Lote local');

      final summary = await p.provider.importBackup(decodeBackup(build()));

      expect(p.provider.terrenos, hasLength(2),
          reason: 'el local se conserva y el del archivo entra al lado');
      expect(summary.agregados.terrenos, 1);
    });

    test('un cultivo y su terreno entran juntos, sin huérfanos', () async {
      final p = await newProvider();
      final summary = await p.provider.importBackup(decodeBackup(build()));

      expect(summary.huerfanos, 0,
          reason: 'el archivo trae el terreno y el cultivo que apunta a él');
      expect(p.provider.terrenos.single.id, 't1');
      expect(p.provider.crops.single.terrenoId, 't1',
          reason: 'quedaron enlazados los dos, no se perdió el enlace');
    });
  });

  group('Subida · orden de claves foráneas', () {
    const terrenoUuid = '22222222-3333-4444-5555-666666666666';
    const cropUuid = '5df76f69-06ee-4b42-8dfd-5b676100109d';

    test('el terreno sube ANTES que el cultivo que apunta a él', () async {
      final p = await newProvider();
      p.provider.mergeRemoteTerrenos(const [
        Terreno(id: terrenoUuid, name: 'Lote', pendingSync: true),
      ]);
      p.provider.mergeRemoteCrops(const [
        Crop(
            id: cropUuid,
            name: 'Café',
            terrenoId: terrenoUuid,
            pendingSync: true),
      ]);

      final tables = SyncProvider(p.provider)
          .buildPushStages(SupabaseService.instance)
          .map((s) => s.table)
          .toList();

      expect(tables, contains('terrenos'));
      expect(tables.indexOf('terrenos'), lessThan(tables.indexOf('crops')),
          reason: 'una clave foránea a un terreno inexistente tira el cultivo');
      expect(tables.indexOf('settings'), lessThan(tables.indexOf('terrenos')));
    });

    test('buildCropPayload manda terreno_id: faltando, PGRST204 tumba la '
        'subida entera', () async {
      final p = await newProvider();
      p.provider.mergeRemoteCrops(const [
        Crop(id: cropUuid, name: 'Café', terrenoId: terrenoUuid),
      ]);

      final payload = SyncProvider(p.provider)
          .buildCropPayload(p.provider.crops.single, 'uid-1');

      expect(payload.containsKey('terreno_id'), isTrue);
      expect(payload['terreno_id'], terrenoUuid);
    });
  });

  group('Interfaz · diálogo de terreno', () {
    Future<void> pumpEditor(
      WidgetTester tester, {
      Terreno? terreno,
      List<Crop> crops = const [],
      List<String> initialCropIds = const [],
      List<String> existingNames = const [],
    }) async {
      tester.view.physicalSize = const Size(900, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: TerrenoEditorDialog(
            terreno: terreno,
            crops: crops,
            initialCropIds: initialCropIds,
            existingNames: existingNames,
          ),
        ),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('sin cultivos no hay casillas, solo el aviso', (tester) async {
      await pumpEditor(tester);
      final l10n = AppLocalizations.of(
          tester.element(find.byType(TerrenoEditorDialog)))!;

      expect(find.byType(CheckboxListTile), findsNothing);
      expect(find.text(l10n.terrenoCropsEmpty), findsOneWidget);
    });

    testWidgets('con cultivos salen una casilla por cada uno',
        (tester) async {
      await pumpEditor(tester, crops: const [
        Crop(id: 'c1', name: 'Café'),
        Crop(id: 'c2', name: 'Plátano'),
      ]);

      expect(find.byType(CheckboxListTile), findsNWidgets(2));
    });

    testWidgets('el área empieza vacía y se puede dejar así (opcional)',
        (tester) async {
      await pumpEditor(tester);
      final l10n = AppLocalizations.of(
          tester.element(find.byType(TerrenoEditorDialog)))!;

      await tester.enterText(find.byType(TextField).first, 'Potrero');
      await tester.tap(find.text(l10n.add));
      await tester.pumpAndSettle();

      expect(find.byType(TerrenoEditorDialog), findsNothing,
          reason: 'acepta guardar sin haber medido las hectáreas');
    });

    testWidgets('pide nombre: sin él no cierra', (tester) async {
      await pumpEditor(tester);
      final l10n = AppLocalizations.of(
          tester.element(find.byType(TerrenoEditorDialog)))!;

      await tester.tap(find.text(l10n.add));
      await tester.pumpAndSettle();

      expect(find.byType(TerrenoEditorDialog), findsOneWidget);
      expect(find.text(l10n.terrenoNameRequired), findsOneWidget);
    });

    testWidgets('rechaza repetir el nombre de otro terreno', (tester) async {
      await pumpEditor(tester, existingNames: const ['Lote de arriba']);
      final l10n = AppLocalizations.of(
          tester.element(find.byType(TerrenoEditorDialog)))!;

      await tester.enterText(find.byType(TextField).first, 'lote de ARRIBA');
      await tester.tap(find.text(l10n.add));
      await tester.pumpAndSettle();

      expect(find.text(l10n.terrenoNameTaken), findsOneWidget);
    });

    testWidgets('editar el propio terreno no cuenta como repetido',
        (tester) async {
      await pumpEditor(tester,
          terreno: const Terreno(id: 't1', name: 'Lote'));
      final l10n = AppLocalizations.of(
          tester.element(find.byType(TerrenoEditorDialog)))!;

      await tester.tap(find.text(l10n.saveChanges));
      await tester.pumpAndSettle();

      expect(find.byType(TerrenoEditorDialog), findsNothing);
    });

    testWidgets('la hectárea ilegible no se guarda a medias', (tester) async {
      await pumpEditor(tester);
      final l10n = AppLocalizations.of(
          tester.element(find.byType(TerrenoEditorDialog)))!;

      await tester.enterText(find.byType(TextField).first, 'Potrero');
      await tester.enterText(find.byType(TextField).at(1), 'mucho');
      await tester.tap(find.text(l10n.add));
      await tester.pumpAndSettle();

      expect(find.byType(TerrenoEditorDialog), findsOneWidget);
      expect(find.text(l10n.terrenoAreaInvalid), findsOneWidget);
    });
  });

  group('Interfaz · pantalla de Cultivos', () {
    Future<TransactionProvider> seeded({bool withTerreno = true}) async {
      final p = await newProvider();
      final cafe = await p.provider.addCrop('Café');
      final platano = await p.provider.addCrop('Plátano');
      if (withTerreno) {
        await p.provider
            .addTerreno('Lote de arriba', cropIds: [cafe.id, platano.id]);
      }
      return p.provider;
    }

    Future<void> pumpCrops(WidgetTester tester, TransactionProvider tx) async {
      tester.view.physicalSize = const Size(900, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(ChangeNotifierProvider.value(
        value: tx,
        child: const MaterialApp(
          locale: Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CropsScreen(),
        ),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('sin terrenos la pantalla es la de siempre: sin sección',
        (tester) async {
      final tx = await seeded(withTerreno: false);
      await pumpCrops(tester, tx);
      final l10n =
          AppLocalizations.of(tester.element(find.byType(CropsScreen)))!;

      expect(find.text(l10n.terrenosSection), findsNothing);
      expect(find.text('Café'), findsOneWidget);
    });

    testWidgets('con terreno aparece la sección con sus datos', (tester) async {
      final tx = await seeded();
      await pumpCrops(tester, tx);
      final l10n =
          AppLocalizations.of(tester.element(find.byType(CropsScreen)))!;

      expect(find.text(l10n.terrenosSection), findsOneWidget);
      expect(find.text('Lote de arriba'), findsOneWidget);
      // Sin hectáreas medidas no se pinta un "0,00 ha" inventado.
      expect(find.textContaining('0,00'), findsNothing);
      expect(
          find.text(l10n.terrenoCropCount(2)), findsOneWidget);
    });

    testWidgets('crear un terreno desde la barra asigna los cultivos marcados',
        (tester) async {
      final tx = await seeded(withTerreno: false);
      await pumpCrops(tester, tx);
      final l10n =
          AppLocalizations.of(tester.element(find.byType(CropsScreen)))!;

      await tester.tap(find.byTooltip(l10n.terrenoNew));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Lote de arriba');
      // La primera casilla es la del primer cultivo de la lista.
      await tester.tap(find.byType(CheckboxListTile).first);
      await tester.pump();
      await tester.tap(find.text(l10n.add));
      await tester.pumpAndSettle();

      expect(tx.terrenos.single.name, 'Lote de arriba');
      expect(tx.crops.where((c) => c.terrenoId != null), hasLength(1));
    });

    testWidgets(
        'BORRAR un terreno avisa que no se borra ningún cultivo '
        'y los deja vivos', (tester) async {
      final tx = await seeded();
      await pumpCrops(tester, tx);
      final l10n =
          AppLocalizations.of(tester.element(find.byType(CropsScreen)))!;

      await tester.tap(find.byTooltip(l10n.terrenoDelete));
      await tester.pumpAndSettle();

      expect(find.text(l10n.deleteTerrenoTitle), findsOneWidget);
      expect(
          find.descendant(
              of: find.byType(AlertDialog),
              matching: find.textContaining('Lote de arriba')),
          findsOneWidget,
          reason: 'el aviso nombra el terreno, la lista de detrás no cuenta');
      expect(find.text(l10n.cropsEmpty), findsNothing,
          reason: 'los cultivos siguen listados');

      await tester.tap(find.text(l10n.delete));
      await tester.pumpAndSettle();

      expect(tx.terrenos, isEmpty);
      expect(tx.crops, hasLength(2), reason: 'NINGÚN cultivo se borró');
      expect(tx.crops.every((c) => c.terrenoId == null), isTrue);
    });
  });

  group('Interfaz · desplegable de terreno en el editor de cultivo', () {
    Future<void> pumpCropsWith(
      WidgetTester tester,
      TransactionProvider tx,
    ) async {
      tester.view.physicalSize = const Size(900, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(ChangeNotifierProvider.value(
        value: tx,
        child: const MaterialApp(
          locale: Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CropsScreen(),
        ),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('si no hay ningún terreno, no se le pide uno',
        (tester) async {
      final p = await newProvider();
      await p.provider.addCrop('Café');
      await pumpCropsWith(tester, p.provider);
      final l10n =
          AppLocalizations.of(tester.element(find.byType(CropsScreen)))!;

      await tester.tap(find.byTooltip(l10n.edit).first);
      await tester.pumpAndSettle();

      expect(find.text(l10n.cropTerrenoLabel), findsNothing);
    });

    testWidgets('si hay terreno, se enseña y se puede elegir',
        (tester) async {
      final p = await newProvider();
      await p.provider.addCrop('Café');
      await p.provider.addTerreno('Lote de arriba');
      await pumpCropsWith(tester, p.provider);
      final l10n =
          AppLocalizations.of(tester.element(find.byType(CropsScreen)))!;

      await tester.tap(find.byTooltip(l10n.edit).first);
      await tester.pumpAndSettle();
      final dialogL10n = AppLocalizations.of(
          tester.element(find.byType(CropEditorDialog)))!;

      expect(find.text(dialogL10n.cropTerrenoLabel), findsOneWidget);
      expect(find.text(dialogL10n.cropTerrenoNone), findsOneWidget);

      // Se busca por su texto actual y no por `.last`: en el editor, la
      // moneda es otro DropdownButtonFormField<String> y va DESPUÉS en el
      // árbol, así que `.last` le daría a ella.
      await tester.tap(find.widgetWithText(
          DropdownButtonFormField<String>, dialogL10n.cropTerrenoNone));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lote de arriba').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text(dialogL10n.save));
      await tester.pumpAndSettle();

      expect(p.provider.crops.single.terrenoId,
          p.provider.terrenos.single.id);
    });

    testWidgets('se puede sacar el cultivo de su terreno', (tester) async {
      final p = await newProvider();
      final cafe = await p.provider.addCrop('Café');
      await p.provider.addTerreno('Lote', cropIds: [cafe.id]);
      await pumpCropsWith(tester, p.provider);
      final l10n =
          AppLocalizations.of(tester.element(find.byType(CropsScreen)))!;

      await tester.tap(find.byTooltip(l10n.edit).first);
      await tester.pumpAndSettle();
      final dialogL10n = AppLocalizations.of(
          tester.element(find.byType(CropEditorDialog)))!;

      // Igual que arriba: por el texto actual, porque `.last` apuntaría a
      // la moneda.
      await tester.tap(find.widgetWithText(
          DropdownButtonFormField<String>, p.provider.terrenos.single.name));
      await tester.pumpAndSettle();
      await tester.tap(find.text(dialogL10n.cropTerrenoNone).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text(dialogL10n.save));
      await tester.pumpAndSettle();

      expect(p.provider.crops.single.terrenoId, isNull);
    });
  });
}
