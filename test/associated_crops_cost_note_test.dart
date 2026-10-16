import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/models/crop.dart';
import 'package:mi_cafetal/models/farm_alert.dart';
import 'package:mi_cafetal/models/harvest.dart';
import 'package:mi_cafetal/models/terreno.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/screens/report_screen.dart';
import 'package:mi_cafetal/services/alert_service.dart';
import 'package:mi_cafetal/services/crop_totals.dart';
import 'package:mi_cafetal/services/excel_export_service.dart';
import 'package:mi_cafetal/services/local_store.dart';
import 'package:mi_cafetal/services/pdf_export_service.dart';

/// Cultivos asociados y el peso de las alertas de cultivo.
///
/// Lo que cuidan estas pruebas, por orden de caridad:
///   1. Que la **finca sí cuadra y el reparto no**, y que los tres pintadores
///      lo digan con el MISMO texto y en el MISMO sitio. Un caficultor con
///      plátano en el mismo lote hace lo correcto: no puede ser la app la
///      que le diga que está perdiendo plata.
///   2. Que **los gastos sin cultivo asignado no salen en rojo**. Es la forma
///      real de trabajar de muchos productores: no etiquetar cada gasto. Un
///      `danger` permanente ahí es una alarma falsa que enseña a ignorar las
///      alertas de verdad.
///   3. Que la fase **nunca se inventa**: `Crop.phase` arranca en
///      `produccion` y no se puede dejar vacía, así que la ficha miente
///      sobre lo recién sembrado. Lo que manda es el campo — sin cosecha
///      registrada no hay rojo.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final es = stringsFor('es');
  final now = DateTime(2026, 6, 15);

  Transaction txn({
    required TransactionType type,
    required double amount,
    required DateTime date,
    String category = 'otro',
    String? cropId,
  }) {
    return Transaction(
      id: '${type.name}_${amount}_${date.millisecondsSinceEpoch}_$cropId',
      type: type,
      cropId: cropId,
      category: category,
      amount: amount,
      date: date,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  /// Finca de prueba. [asociados] decide si los dos cultivos comparten lote
  /// o cada uno tiene el suyo.
  Future<TransactionProvider> newProvider({bool asociados = true}) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final p = TransactionProvider(LocalStore(prefs));
    await p.addCrop('Café');
    await p.addCrop('Plátano');
    final ids = [p.crops[0].id, p.crops[1].id];
    if (asociados) {
      await p.addTerreno('Lote El Alto', cropIds: ids);
    } else {
      await p.addTerreno('Lote A', cropIds: [ids[0]]);
      await p.addTerreno('Lote B', cropIds: [ids[1]]);
    }
    return p;
  }

  Future<void> pumpReport(WidgetTester tester, TransactionProvider p) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: p,
      child: const MaterialApp(
        locale: Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ReportScreen(),
      ),
    ));
    await tester.pumpAndSettle();
  }

  String textoDeHoja(Excel libro, String hoja) {
    final rows = libro.tables[hoja]?.rows ?? const [];
    return rows
        .map((r) => r.map((c) => c?.value?.toString() ?? '').join('|'))
        .join('\n');
  }

  Excel decodificarExcel(TransactionProvider p) {
    final bytes = Uint8List.fromList(ExcelExportService().buildReport(
      settings: p.settings,
      transactions: p.transactions,
      crops: p.crops,
      year: now.year,
      month: now.month,
      period: ReportPeriod.month,
      periodName: 'Mes',
      l10n: es,
      harvests: p.harvests,
      sowings: p.sowings,
      terrenos: p.terrenos,
    ));
    return Excel.decodeBytes(bytes);
  }

  Future<Uint8List> generarPdf(TransactionProvider p) {
    return PdfExportService().buildReport(
      settings: p.settings,
      transactions: p.transactions,
      crops: p.crops,
      year: now.year,
      month: now.month,
      period: ReportPeriod.month,
      periodName: 'Mes',
      l10n: es,
      harvests: p.harvests,
      sowings: p.sowings,
      terrenos: p.terrenos,
    );
  }

  group('Detector de cultivos asociados', () {
    test('dos cultivos en el mismo terreno = asociados', () {
      const crops = [
        Crop(id: 'cafe', name: 'Café', icon: '☕', color: '#6D4C41',
            terrenoId: 't1'),
        Crop(id: 'platano', name: 'Plátano', icon: '🍌', color: '#F9A825',
            terrenoId: 't1'),
      ];
      expect(hasAssociatedCrops(crops), isTrue);
    });

    test('dos cultivos en terrenos distintos = no asociados', () {
      const crops = [
        Crop(id: 'cafe', name: 'Café', icon: '☕', color: '#6D4C41',
            terrenoId: 't1'),
        Crop(id: 'platano', name: 'Plátano', icon: '🍌', color: '#F9A825',
            terrenoId: 't2'),
      ];
      expect(hasAssociatedCrops(crops), isFalse);
    });

    test('un solo cultivo por terreno = no asociados', () {
      const crops = [
        Crop(id: 'cafe', name: 'Café', icon: '☕', color: '#6D4C41',
            terrenoId: 't1'),
      ];
      expect(hasAssociatedCrops(crops), isFalse);
    });

    test('los cultivos sin terreno no cuentan', () {
      const crops = [
        Crop(id: 'cafe', name: 'Café', icon: '☕', color: '#6D4C41'),
        Crop(id: 'platano', name: 'Plátano', icon: '🍌', color: '#F9A825'),
      ];
      expect(hasAssociatedCrops(crops), isFalse,
          reason: 'sin lote no hay terreno compartido del que hablar');
    });
  });

  group('Pantalla', () {
    testWidgets('con cultivos asociados avisa de que el costo es aproximado',
        (tester) async {
      final p = await newProvider(asociados: true);
      await pumpReport(tester, p);

      expect(find.text(es.associatedCropsCostTitle), findsOneWidget);
      expect(find.text(es.associatedCropsCostNote), findsOneWidget);
    });

    testWidgets('sin cultivos asociados la nota no aparece', (tester) async {
      final p = await newProvider(asociados: false);
      await pumpReport(tester, p);

      expect(find.text(es.associatedCropsCostTitle), findsNothing);
      expect(find.text(es.associatedCropsCostNote), findsNothing);
    });
  });

  group('Los tres pintadores dicen lo mismo', () {
    test('el Excel lleva la misma nota que la pantalla', () async {
      final p = await newProvider(asociados: true);
      final hoja = textoDeHoja(decodificarExcel(p), es.excelSheetCrops);

      expect(hoja, contains(es.associatedCropsCostTitle));
      expect(hoja, contains(es.associatedCropsCostNote));
    });

    test('sin cultivos asociados el Excel tampoco la lleva', () async {
      final p = await newProvider(asociados: false);
      final hoja = textoDeHoja(decodificarExcel(p), es.excelSheetCrops);

      expect(hoja, isNot(contains(es.associatedCropsCostTitle)));
    });

    test('el PDF crece cuando hay asociados que avisar', () async {
      final con = await generarPdf(await newProvider(asociados: true));
      final sin = await generarPdf(await newProvider(asociados: false));

      expect(String.fromCharCodes(con.take(5)), '%PDF-');
      expect(con.length, greaterThan(sin.length),
          reason: 'la nota añade contenido al PDF');
    });
  });

  group('Alertas de cultivo', () {
    test('los gastos sin cultivo asignado dejan de salir en rojo', () {
      final txns = [
        txn(
          type: TransactionType.expense,
          amount: 500,
          date: DateTime(2026, 6, 5),
        ),
      ];
      final alerts = AlertService(now: now)
          .evaluate(txns, const [Crop(id: 'cafe', name: 'Café', icon: '☕', color: '#6D4C41')], es);

      final a = alerts.firstWhere((a) => a.id == 'deficit_null');
      expect(a.severity, AlertSeverity.info,
          reason: 'no etiquetar cada gasto es la práctica real: se explica, '
              'no se acusa');
    });

    test('un cultivo que ya cosechó y sigue en números rojos sí está en rojo',
        () {
      final txns = [
        txn(
          type: TransactionType.expense,
          amount: 500,
          date: DateTime(2026, 6, 5),
          cropId: 'cafe',
        ),
      ];
      const crops = [
        Crop(id: 'cafe', name: 'Café', icon: '☕', color: '#6D4C41'),
      ];
      final harvests = [
        Harvest(
          id: 'h1',
          cropId: 'cafe',
          date: DateTime(2026, 5, 20),
          amount: 300,
        ),
      ];
      final alerts = AlertService(now: now)
          .evaluate(txns, crops, es, harvests: harvests);

      final a = alerts.firstWhere((a) => a.id == 'deficit_cafe');
      expect(a.severity, AlertSeverity.danger,
          reason: 'ya cosechó y aun así no recupera: eso sí es pérdida');
    });

    test('un cultivo en producción sin cosecha no sale en rojo', () {
      // `Crop.phase` arranca en `produccion` y no se puede dejar vacía, así
      // que la ficha miente sobre todo lo recién sembrado. Lo que manda es
      // el campo: si no hay cosecha registrada, no está produciendo.
      final txns = [
        txn(
          type: TransactionType.expense,
          amount: 500,
          date: DateTime(2026, 6, 5),
          cropId: 'cafe',
        ),
      ];
      const crops = [
        Crop(id: 'cafe', name: 'Café', icon: '☕', color: '#6D4C41'),
      ];
      final alerts = AlertService(now: now).evaluate(txns, crops, es);

      final a = alerts.firstWhere((a) => a.id == 'deficit_cafe');
      expect(a.severity, AlertSeverity.info,
          reason: 'aún no ha dado nada: es inversión, no pérdida confirmada');
    });

    test('un cultivo en establecimiento sigue siendo info', () {
      final txns = [
        txn(
          type: TransactionType.expense,
          amount: 500,
          date: DateTime(2026, 6, 5),
          cropId: 'cafe',
        ),
      ];
      const crops = [
        Crop(
          id: 'cafe',
          name: 'Café',
          icon: '☕',
          color: '#6D4C41',
          phase: CropPhase.establecimiento,
        ),
      ];
      final alerts = AlertService(now: now).evaluate(txns, crops, es);

      final a = alerts.firstWhere((a) => a.id == 'crop_establishment_cafe');
      expect(a.severity, AlertSeverity.info);
    });
  });

  group('Retrocompatibilidad', () {
    test('un terreno con un solo cultivo sigue sin ser asociado', () {
      const crops = [
        Crop(id: 'cafe', name: 'Café', icon: '☕', color: '#6D4C41',
            terrenoId: 't1'),
      ];
      expect(hasAssociatedCrops(crops), isFalse);
      expect(const Terreno(id: 't1', name: 'Lote').toJson().containsKey('lat'),
          isFalse,
          reason: 'el modelo del terreno no se toca con este cambio');
    });
  });
}
