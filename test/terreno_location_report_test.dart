import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/models/terreno.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/screens/report_screen.dart';
import 'package:mi_cafetal/services/excel_export_service.dart';
import 'package:mi_cafetal/services/local_store.dart';
import 'package:mi_cafetal/services/pdf_export_service.dart';

/// El anexo de ubicación en los tres pintadores.
///
/// Lo que cuidan, por orden de caridad:
///   1. Que los tres digan **exactamente lo mismo**: la misma coordenada,
///      con los mismos decimales, el mismo título y la misma fecha. Un
///      reporte que cambia de cifra al pasarlo a PDF no se puede creer.
///   2. Que **sin un solo punto no aparezca nada** — ni título, ni hueco.
///      Un anexo de ubicación vacío es ruido, y ruido en un reporte de
///      campo es gente que deja de leerlo.
///   3. Que un terreno **sin ubicar se vea igual de vivo**: su nombre está,
///      lo que no está es la coordenada que nunca se midió (`null` →
///      oculto, nunca un 0).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final es = stringsFor('es');

  const coordenada = '5.068421, -75.512387';
  final registrado = DateTime(2026, 10, 16);
  // Igual que en pantalla, en el PDF y en el Excel: `dd/MM/yyyy`.
  const fechaEsperada = '16/10/2026';

  Future<TransactionProvider> newProvider({
    bool conUbicacion = true,
    bool conTerreno = true,
  }) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final p = TransactionProvider(LocalStore(prefs));
    await p.addCrop('Café');
    if (conTerreno) {
      await p.addTerreno(
        'Lote El Alto',
        areaHa: 1.5,
        lat: conUbicacion ? 5.068421 : null,
        lng: conUbicacion ? -75.512387 : null,
        locatedAt: conUbicacion ? registrado : null,
        cropIds: [p.crops.single.id],
      );
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

  /// La coordenada que hay en pantalla, tal cual: el patrón solo puede ser
  /// un par lat, lng con decimales, así que no confunde con dinero ni con
  /// hectáreas.
  String? coordenadaEnPantalla(WidgetTester tester) {
    for (final w in tester.widgetList<Text>(find.byType(Text))) {
      final t = w.data ?? '';
      if (RegExp(r'^-?\d+\.\d+, -?\d+\.\d+$').hasMatch(t)) return t;
    }
    return null;
  }

  String textoDeHoja(Excel libro, String hoja) {
    final rows = libro.tables[hoja]?.rows ?? const [];
    return rows
        .map((r) => r.map((c) => c?.value?.toString() ?? '').join('|'))
        .join('\n');
  }

  String? coordenadaEnTexto(String texto) {
    for (final linea in texto.split('\n')) {
      for (final celda in linea.split('|')) {
        if (RegExp(r'^-?\d+\.\d+, -?\d+\.\d+$').hasMatch(celda.trim())) {
          return celda.trim();
        }
      }
    }
    return null;
  }

  Excel decodificarExcel(TransactionProvider p) {
    final now = DateTime.now();
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

  /// Genera el PDF. El texto va con subsetting de fuente y no se lee en
  /// claro, así que el PDF se compara por **tamaño** — es la misma manera
  /// en que el resto del repo comprueba una sección del PDF (Caja menor,
  /// nómina): si la sección está, el documento crece.
  Future<Uint8List> generarPdf(TransactionProvider p) {
    return PdfExportService().buildReport(
      settings: p.settings,
      transactions: p.transactions,
      crops: p.crops,
      year: DateTime.now().year,
      month: DateTime.now().month,
      period: ReportPeriod.month,
      periodName: 'Mes',
      l10n: es,
      harvests: p.harvests,
      sowings: p.sowings,
      terrenos: p.terrenos,
    );
  }

  group('Pantalla', () {
    testWidgets('pinta el título, la coordenada y el día en que se registró',
        (tester) async {
      final p = await newProvider();
      await pumpReport(tester, p);

      expect(find.text(es.reportTerrenosTitle), findsOneWidget);
      expect(coordenadaEnPantalla(tester), coordenada);
      expect(find.textContaining(fechaEsperada), findsOneWidget,
          reason: 'hay que poder decir cuándo se midió, no solo dónde');
      expect(find.text('Lote El Alto'), findsOneWidget);
      expect(find.textContaining('1.50 ha'), findsOneWidget,
          reason: 'misma forma que en el resto de la app');
    });

    testWidgets('sin ninguna coordenada en la finca, el anexo no aparece',
        (tester) async {
      final p = await newProvider(conUbicacion: false);
      await pumpReport(tester, p);

      expect(find.text(es.reportTerrenosTitle), findsNothing);
      expect(coordenadaEnPantalla(tester), isNull);
    });

    testWidgets('el terreno sin ubicar sale por su nombre, sin coordenada',
        (tester) async {
      final p = await newProvider();
      await p.addTerreno('Potrero B');
      await pumpReport(tester, p);

      // Los dos están: nadie cree que se le borró el segundo.
      expect(find.text('Lote El Alto'), findsOneWidget);
      expect(find.text('Potrero B'), findsOneWidget,
          reason: 'no tener GPS no es no existir');
      // Y solo hay UNA coordenada: la que sí se midió.
      final coords = tester
          .widgetList<Text>(find.byType(Text))
          .map((w) => w.data ?? '')
          .where((t) => RegExp(r'^-?\d+\.\d+, -?\d+\.\d+$').hasMatch(t))
          .toList();
      expect(coords, hasLength(1),
          reason: 'sin punto no se pinta ninguna coordenada, ni un 0');
    });
  });

  group('Los tres pintadores dicen lo mismo', () {
    test('el Excel pinta exactamente la coordenada que pinta la pantalla',
        () async {
      final p = await newProvider();
      final hoja = textoDeHoja(decodificarExcel(p), es.excelSheetSummary);

      expect(hoja, contains(es.reportTerrenosTitle),
          reason: 'mismo título que en pantalla');
      expect(hoja, contains(es.reportTerrenosHint));
      expect(hoja, contains('Lote El Alto'));
      expect(hoja, contains(fechaEsperada));
      expect(coordenadaEnTexto(hoja), coordenada,
          reason: 'la misma cadena, con los mismos decimales');
    });

    test('sin ninguna coordenada el Excel tampoco lleva el bloque', () async {
      final p = await newProvider(conUbicacion: false);
      final hoja = textoDeHoja(decodificarExcel(p), es.excelSheetSummary);

      expect(hoja, isNot(contains(es.reportTerrenosTitle)));
      expect(coordenadaEnTexto(hoja), isNull);
    });

    test('pantalla y Excel se quedan con la misma cadena, carácter por '
        'carácter', () async {
      final p = await newProvider();
      final enExcel = coordenadaEnTexto(
          textoDeHoja(decodificarExcel(p), es.excelSheetSummary));

      // Lo que mira el agricultor en el celular contra lo que se lleva en
      // el archivo: si difieren, una de las dos miente.
      expect(enExcel, coordenada);
      expect(enExcel, '5.068421, -75.512387',
          reason: '6 decimales, como los pide la EUDR');
    });

    test('el PDF crece cuando hay ubicación que anexar', () async {
      final con = await generarPdf(await newProvider());
      final sin = await generarPdf(await newProvider(conUbicacion: false));

      expect(String.fromCharCodes(con.take(5)), '%PDF-');
      expect(con.length, greaterThan(sin.length),
          reason: 'la sección de ubicación añade contenido al PDF');
    });

    test('sin ninguna coordenada el PDF no lleva nada del anexo', () async {
      // Mismo largo que una finca que ni siquiera tiene terrenos. Si el
      // anexo saliera aunque vacío —con su título y su separación—, el
      // documento crecería y esto lo pillaría.
      final sinUbicacion =
          await generarPdf(await newProvider(conUbicacion: false));
      final sinTerrenos = await generarPdf(await newProvider(conTerreno: false));

      expect(sinUbicacion.length, sinTerrenos.length,
          reason: 'sin un solo punto no se imprime ni el título');
    });
  });

  group('Retrocompatibilidad', () {
    test('el modelo de un terreno sin ubicar sigue siendo el de siempre', () {
      const t = Terreno(id: 't1', name: 'Lote');
      expect(t.lat, isNull);
      expect(t.lng, isNull);
      expect(t.locatedAt, isNull);
      expect(t.toJson().containsKey('lat'), isFalse);
    });
  });
}
