import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/crop.dart';
import '../models/settings.dart';
import '../models/transaction.dart';

class PdfExportService {
  /// Genera un reporte PDF del período indicado.
  /// Devuelve los bytes listos para guardar/compartir.
  Future<Uint8List> buildReport({
    required FarmSettings settings,
    required List<Transaction> transactions,
    required List<Crop> crops,
    required int year,
    required int month,
    required String monthName,
  }) async {
    final active = transactions.where((t) => !t.deleted).toList();

    double sum(List<Transaction> list, TransactionType type) =>
        list.where((t) => t.type == type).fold(0.0, (a, t) => a + t.amount);

    final monthTx = active
        .where((t) => t.date.year == year && t.date.month == month)
        .toList();
    final expenses = sum(monthTx, TransactionType.expense);
    final incomes = sum(monthTx, TransactionType.income);
    final balance = incomes - expenses;

    final monthNameLower = '$monthName de $year';
    final currency = settings.currency;

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: pw.Font.helvetica(),
          bold: pw.Font.helveticaBold(),
        ),
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              '${settings.farmName} — Reporte $monthNameLower',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Generado el ${DateTime.now().toIso8601String().split('T').first}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 20),

          pw.Text('Resumen del mes',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
          pw.SizedBox(height: 8),
          _twoColumnTable(context, [
            ('Gastos del mes', formatPdfMoney(expenses, currency)),
            ('Ingresos del mes', formatPdfMoney(incomes, currency)),
            ('Balance del mes', formatPdfMoney(balance, currency)),
            ('% de gasto sobre movimiento',
                _percent(expenses, expenses + incomes)),
          ]),
          pw.SizedBox(height: 20),

          pw.Text('Gastos por categoría',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
          pw.SizedBox(height: 8),
          _categoryTable(
              context, monthTx.where((t) => t.type.isExpense).toList(), currency,
              expense: true),
          pw.SizedBox(height: 20),

          pw.Text('Ingresos por categoría',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
          pw.SizedBox(height: 8),
          _categoryTable(context,
              monthTx.where((t) => !t.type.isExpense).toList(), currency,
              expense: false),
          pw.SizedBox(height: 20),

          pw.Text('Desglose por cultivo (año $year)',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ['Cultivo', 'Gastos', 'Ingresos', 'Balance', 'ROI'],
            data: _cropRows(context, active, crops, year, currency),
            border: pw.TableBorder.all(color: PdfColors.grey400),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.brown600),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerRight,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
            },
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'ROI = (Ingresos − Gastos) / Gastos. Negativo > 30% sugiere revisar el cultivo.',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );

    return doc.save();
  }

  String _percent(double part, double total) =>
      total <= 0 ? '—' : '${((part / total) * 100).toStringAsFixed(0)}%';

  String formatPdfMoney(double value, String currency) {
    final symbol = currency == 'COP' || currency == 'USD' ? '\$' : '€';
    return '$symbol${value.toStringAsFixed(0)}';
  }

  pw.Widget _twoColumnTable(pw.Context context, List<(String, String)> rows) {
    return pw.TableHelper.fromTextArray(
      headers: ['Concepto', 'Valor'],
      data: rows
          .map((r) => [r.$1, r.$2])
          .toList(),
      border: pw.TableBorder.all(color: PdfColors.grey300),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
      },
    );
  }

  pw.Widget _categoryTable(pw.Context context, List<Transaction> list,
      String currency, {required bool expense}) {
    final totals = <String, double>{};
    for (final t in list) {
      totals[t.category] = (totals[t.category] ?? 0) + t.amount;
    }
    final rows = totals.entries
        .map((e) => [e.key, formatPdfMoney(e.value, currency)])
        .toList()
      ..sort((a, b) => b[1].compareTo(a[1]));
    if (rows.isEmpty) rows.add(['Sin registros', '—']);
    return pw.TableHelper.fromTextArray(
      headers: ['Categoría', expense ? 'Gasto' : 'Ingreso'],
      data: rows,
      border: pw.TableBorder.all(color: PdfColors.grey300),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
      },
    );
  }

  List<List<String>> _cropRows(pw.Context context, List<Transaction> active,
      List<Crop> crops, int year, String currency) {
    final nameById = {for (final c in crops) c.id: c.name};
    final totals = <String?, _CropTotalRow>{
      null: _CropTotalRow(name: 'Sin especificar'),
    };
    for (final c in crops) {
      totals.putIfAbsent(c.id, () => _CropTotalRow(name: c.name));
    }

    final yearTx = active.where((t) => t.date.year == year);
    for (final t in yearTx) {
      final row = totals.putIfAbsent(t.cropId, () {
        final name = t.cropId == null
            ? 'Sin especificar'
            : (nameById[t.cropId] ?? t.cropId!);
        return _CropTotalRow(name: name);
      });
      if (t.type.isExpense) {
        row.expenses += t.amount;
      } else {
        row.incomes += t.amount;
      }
    }

    return totals.values
        .where((r) => r.expenses > 0 || r.incomes > 0)
        .map((r) {
      final roi = r.expenses <= 0
          ? '—'
          : '${(((r.incomes - r.expenses) / r.expenses) * 100).toStringAsFixed(0)}%';
      return [
        r.name,
        formatPdfMoney(r.expenses, currency),
        formatPdfMoney(r.incomes, currency),
        formatPdfMoney(r.incomes - r.expenses, currency),
        roi,
      ];
    }).toList();
  }
}

class _CropTotalRow {
  final String name;
  double expenses = 0;
  double incomes = 0;

  _CropTotalRow({required this.name});
}