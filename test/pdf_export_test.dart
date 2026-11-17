import 'dart:convert';
import 'dart:io' show ZLibDecoder;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/models/crop.dart';
import 'package:mi_cafetal/models/harvest.dart';
import 'package:mi_cafetal/models/settings.dart';
import 'package:mi_cafetal/models/terreno.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/services/pdf_export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('buildReport genera un PDF válido con resumen y cultivos', () async {
    final txns = [
      Transaction(
        id: '1',
        type: TransactionType.expense,
        category: 'fertilizante',
        amount: 200000,
        cropId: 'cafe',
        date: DateTime(2026, 6, 5),
        createdAt: DateTime(2026, 6, 5),
      ),
      Transaction(
        id: '2',
        type: TransactionType.income,
        category: 'venta_cafe',
        amount: 500000,
        cropId: 'cafe',
        date: DateTime(2026, 6, 10),
        createdAt: DateTime(2026, 6, 10),
      ),
    ];

    final bytes = await PdfExportService().buildReport(
      settings: const FarmSettings(farmName: 'Finca La Esperanza'),
      transactions: txns,
      crops: _crops(),
      year: 2026,
      month: 5,
      period: ReportPeriod.month,
      periodName: 'Junio de 2026',
      l10n: stringsFor('es'),
    );

    expect(bytes, isA<Uint8List>());
    expect(bytes.length, greaterThan(1000));
    final header = String.fromCharCodes(bytes.take(5).toList());
    expect(header, '%PDF-');
  });

  test('la sección Caja menor crece el PDF (mismo dato, solo cambia el monto)',
      () async {
    final txns = [
      Transaction(
        id: '1',
        type: TransactionType.expense,
        category: 'mano_obra',
        amount: 400000,
        quantity: 8,
        unit: 'día',
        pricePerUnit: 50000,
        provider: 'Juan Pérez',
        date: DateTime(2026, 6, 5),
        createdAt: DateTime(2026, 6, 5),
      ),
      Transaction(
        id: '2',
        type: TransactionType.expense,
        category: 'energia',
        amount: 100000,
        date: DateTime(2026, 6, 10),
        createdAt: DateTime(2026, 6, 10),
      ),
    ];
    final sinCaja = await _build(settings: const FarmSettings(), txns: txns);
    final conCaja = await _build(
        settings: const FarmSettings(cajaMenorMensual: 600000),
        txns: txns);
    expect(String.fromCharCodes(conCaja.take(5)), '%PDF-');
    expect(conCaja.length, greaterThan(sinCaja.length),
        reason: 'con presupuesto configurado se dibuja la tabla mensual');
  });

  test('la sección Nómina crece el PDF (gasto con trabajador vs sin él)',
      () async {
    final sin = await _build(
      settings: const FarmSettings(),
      txns: [
        Transaction(
          id: '1',
          type: TransactionType.expense,
          category: 'mano_obra',
          amount: 500000,
          date: DateTime(2026, 6, 5),
          createdAt: DateTime(2026, 6, 5),
        ),
      ],
    );
    final con = await _build(
      settings: const FarmSettings(),
      txns: [
        Transaction(
          id: '1',
          type: TransactionType.expense,
          category: 'mano_obra',
          amount: 500000,
          quantity: 10,
          unit: 'día',
          pricePerUnit: 50000,
          provider: 'Juan Pérez',
          date: DateTime(2026, 6, 5),
          createdAt: DateTime(2026, 6, 5),
        ),
      ],
    );
    expect(String.fromCharCodes(con.take(5)), '%PDF-');
    expect(con.length, greaterThan(sin.length),
        reason: 'la tabla de nómina añade filas, total y empleados');
  });

  test('Nómina y caja va en anexo con salto de página solo si hay contenido',
      () async {
    // Gasto que no es mano de obra, con venta y cosecha que cuadran: ni el
    // anexo ni «Qué hacer» tienen nada que pintar, así que el PDF cabe en una
    // página. Sin la venta, la alerta de «gastos sin ventas» suma su acción y
    // el número de páginas deja de medir solo el anexo.
    //
    // Tanda 3 · hito 1: la venta y la cosecha van **sin cultivo** a propósito.
    // Si se ligan a uno, aparece `deficitCrop`; si solo se liga la cosecha,
    // aparece la fila de stock sin vender. Cualquiera de las dos añade una
    // línea a «Qué hacer» y el guarda dejaría de medir solo el anexo. El stock
    // y el déficit ya tienen sus propios tests; aquí se aísla la paginación.
    final hoy = DateTime.now();
    final sinAnexo = await _build(
      settings: const FarmSettings(),
      txns: [
        Transaction(
          id: '1',
          type: TransactionType.expense,
          category: 'fertilizante',
          amount: 100000,
          date: DateTime(2026, 6, 5),
          createdAt: DateTime(2026, 6, 5),
        ),
        Transaction(
          id: '2',
          type: TransactionType.income,
          category: 'venta',
          amount: 200000,
          quantity: 100,
          unit: 'kg',
          date: hoy,
          createdAt: hoy,
        ),
      ],
      harvests: [
        Harvest(
          id: 'h1',
          date: hoy,
          amount: 100,
          unit: 'kg',
        ),
      ],
    );
    // El mismo monto como jornal: hay nómina y planilla, así que el anexo
    // aparece y arranca en página nueva.
    final conAnexo = await _build(
      settings: const FarmSettings(),
      txns: [
        Transaction(
          id: '1',
          type: TransactionType.expense,
          category: 'mano_obra',
          amount: 100000,
          quantity: 2,
          unit: 'día',
          pricePerUnit: 50000,
          provider: 'Juan Pérez',
          date: DateTime(2026, 6, 5),
          createdAt: DateTime(2026, 6, 5),
        ),
      ],
    );

    expect(_pdfPages(sinAnexo), 1,
        reason: 'sin contenido no se cuela un salto de página');
    expect(_pdfPages(conAnexo), greaterThan(_pdfPages(sinAnexo)),
        reason: 'el anexo arranca en página nueva');
  });
  test('cosechas con personal y kilos generan un PDF válido', () async {
    final bytes = await _build(
      settings: const FarmSettings(cajaMenorMensual: 600000),
      txns: [
        Transaction(
          id: '1',
          type: TransactionType.expense,
          category: 'mano_obra',
          amount: 600000,
          quantity: 12,
          unit: 'día',
          pricePerUnit: 50000,
          provider: 'Juan Pérez',
          date: DateTime(2026, 6, 5),
          createdAt: DateTime(2026, 6, 5),
        ),
      ],
      harvests: [
        Harvest(
          id: 'h1',
          cropId: 'cafe',
          date: DateTime(2026, 6, 8),
          amount: 30,
          unit: 'racimo',
          workers: 3,
          equivalentKg: 420,
        ),
      ],
    );
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(1000));
  });

  // ---- W1-c · el PDF con bandas por terreno ------------------------------

  test('W1-c: un reporte con terrenos y lote sin repartir sigue siendo PDF',
      () async {
    final txns = [
      Transaction(
        id: '1',
        type: TransactionType.expense,
        category: 'mano_obra',
        amount: 30000,
        cropId: 'cafe',
        date: DateTime(2026, 6, 3),
        createdAt: DateTime(2026, 6, 3),
      ),
      // Lote sin hectáreas: no se puede repartir y sale como fila propia.
      Transaction(
        id: '2',
        type: TransactionType.expense,
        category: 'mano_obra',
        amount: 70000,
        terrenoId: 'l2',
        date: DateTime(2026, 6, 4),
        createdAt: DateTime(2026, 6, 4),
      ),
    ];

    final bytes = await PdfExportService().buildReport(
      settings: const FarmSettings(farmName: 'Finca La Esperanza'),
      transactions: txns,
      crops: const [
        Crop(
            id: 'cafe',
            name: 'Café',
            icon: 'X',
            color: '#6D4C41',
            areaHa: 1.2,
            terrenoId: 'l1'),
        Crop(
            id: 'maiz',
            name: 'Maíz',
            icon: 'X',
            color: '#FBC02D',
            terrenoId: 'l2'),
      ],
      terrenos: const [
        Terreno(id: 'l1', name: 'Lote Alto', areaHa: 2),
        Terreno(id: 'l2', name: 'Lote Bajo'),
      ],
      year: 2026,
      month: 6,
      period: ReportPeriod.month,
      periodName: 'Junio de 2026',
      l10n: stringsFor('es'),
    );

    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(1000));
  });

  test('«Qué hacer» del PDF lleva la acción, no solo el diagnóstico', () async {
    final bytes = await _build(
      settings: const FarmSettings(lowPriceThresholdPerKg: 80000),
      txns: [
        Transaction(
          id: 'venta_enero',
          type: TransactionType.income,
          category: 'venta',
          amount: 50000,
          quantity: 1,
          unit: 'kg',
          date: DateTime(2026, 1, 10),
          createdAt: DateTime(2026, 1, 10),
        ),
      ],
    );

    // El espaciado del PDF va en los ajustes `TJ`, no en glifos: al decodificar
    // queda «Comparaprecios…». Se compara sin espacios para no confundir la
    // puntuación tipográfica con la acción que sí está en el archivo.
    final texto = _pdfText(bytes).replaceAll(RegExp(r'\s'), '');
    expect(texto.contains('Comparapreciosconotroscompradores'),
        isTrue,
        reason: 'el PDF es lo que el agricultor comparte: no puede callar la acción');
  });
}

List<Crop> _crops() => const [
      Crop(id: 'cafe', name: 'Café', icon: '☕', color: '#6D4C41'),
    ];

Future<Uint8List> _build({
  required FarmSettings settings,
  required List<Transaction> txns,
  List<Harvest> harvests = const [],
}) =>
    PdfExportService().buildReport(
      settings: settings,
      transactions: txns,
      crops: _crops(),
      year: 2026,
      month: 6,
      period: ReportPeriod.month,
      periodName: 'Junio de 2026',
      l10n: stringsFor('es'),
      harvests: harvests,
    );

/// Texto de los streams FlateDecode del PDF, ya inflado. El `pdf` 3.11.3
/// comprime por defecto (`defaultDeflate = zlib.encode`), así que buscar el
/// texto sobre los bytes crudos daría un falso negativo.
String _pdfStreams(Uint8List bytes) {
  final comoTexto = latin1.decode(bytes, allowInvalid: true);
  final salida = StringBuffer();
  for (final m in RegExp(r'stream\r?\n').allMatches(comoTexto)) {
    final inicio = m.end;
    final fin = comoTexto.indexOf('endstream', inicio);
    if (fin < 0) continue;
    var trozo = bytes.sublist(inicio, fin);
    while (trozo.isNotEmpty && (trozo.last == 10 || trozo.last == 13)) {
      trozo = trozo.sublist(0, trozo.length - 1);
    }
    try {
      salida.write(
          latin1.decode(ZLibDecoder().convert(trozo), allowInvalid: true));
    } catch (_) {
      // Un stream que no es Flate (p. ej. datos binarios) no es texto.
    }
  }
  return salida.toString();
}

/// Texto legible del PDF. Los streams no traen letras sino IDs de glifo
/// (`[<0001...>]TJ`) y un CMap `beginbfchar` que los traduce a UTF-16BE.
/// Buscar el texto sin pasar por ese mapa da falso negativo.
String _pdfText(Uint8List bytes) {
  final streams = _pdfStreams(bytes);
  final mapas = RegExp(r'beginbfchar(.*?)endbfchar', dotAll: true)
      .allMatches(streams)
      .map((m) => m.group(1)!)
      .toList();
  final salida = StringBuffer();
  for (final bloque in mapas) {
    final cmap = <String, String>{};
    for (final m in RegExp(r'<([0-9A-Fa-f]+)>\s*<([0-9A-Fa-f]+)>')
        .allMatches(bloque)) {
      final dst = m.group(2)!;
      final unidades = <int>[];
      for (var i = 0; i + 3 < dst.length; i += 4) {
        unidades.add(int.parse(dst.substring(i, i + 4), radix: 16));
      }
      cmap[m.group(1)!.toUpperCase()] = String.fromCharCodes(unidades);
    }
    for (final m in RegExp(r'<([0-9A-Fa-f]+)>\s*Tj').allMatches(streams)) {
      salida.write(_pdfGlifos(m.group(1)!, cmap));
    }
    for (final m in RegExp(r'\[(.*?)\]\s*TJ', dotAll: true)
        .allMatches(streams)) {
      for (final h
          in RegExp(r'<([0-9A-Fa-f]+)>').allMatches(m.group(1)!)) {
        salida.write(_pdfGlifos(h.group(1)!, cmap));
      }
    }
  }
  return salida.toString();
}

String _pdfGlifos(String hex, Map<String, String> cmap) {
  final salida = StringBuffer();
  for (var i = 0; i + 3 < hex.length; i += 4) {
    salida.write(cmap[hex.substring(i, i + 4).toUpperCase()] ?? '');
  }
  return salida.toString();
}

/// Páginas físicas del PDF: los objetos `/Type /Page` van sin comprimir en el
/// archivo, así que se pueden contar sobre los bytes. `/Type /Pages` (el nodo
/// de la colección) no coincide porque después de `Page` no viene `s`.
int _pdfPages(Uint8List bytes) {
  final text = latin1.decode(bytes, allowInvalid: true);
  return RegExp(r'/Type\s*/Page[^s]').allMatches(text).length;
}
