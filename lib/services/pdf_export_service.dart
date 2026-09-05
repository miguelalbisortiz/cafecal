import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../l10n/generated/app_localizations.dart';
import '../l10n/strings.dart';
import '../models/crop.dart';
import '../models/currencies.dart';
import '../models/settings.dart';
import '../models/transaction.dart';

enum ReportPeriod { month, year, yearToDate }

const _pdfPositive = PdfColor.fromInt(0xFF1F5E3F);
const _pdfPositiveSoft = PdfColor.fromInt(0xFFE7F0EA);
const _pdfNegative = PdfColor.fromInt(0xFFB3261E);
const _pdfNegativeSoft = PdfColor.fromInt(0xFFF9E4E2);

class PdfExportService {
  static pw.Font? _cachedRegular;
  static pw.Font? _cachedBold;

  static Future<pw.Font> _regularFont() async {
    return _cachedRegular ??= pw.Font
        .ttf(await rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
  }

  static Future<pw.Font> _boldFont() async {
    return _cachedBold ??= pw.Font
        .ttf(await rootBundle.load('assets/fonts/Roboto-Bold.ttf'));
  }

  /// Genera un reporte PDF del período indicado.
  /// Devuelve los bytes listos para guardar/compartir.
  Future<Uint8List> buildReport({
    required FarmSettings settings,
    required List<Transaction> transactions,
    required List<Crop> crops,
    required int year,
    int? month,
    required ReportPeriod period,
    required String periodName,
    required AppLocalizations l10n,
  }) async {
    final active = transactions.where((t) => !t.deleted).toList();

    double sum(List<Transaction> list, TransactionType type) =>
        list.where((t) => t.type == type).fold(0.0, (a, t) => a + t.amount);

    final now = DateTime.now();
    final periodTx = switch (period) {
      ReportPeriod.month => active
          .where((t) => t.date.year == year && t.date.month == (month ?? now.month))
          .toList(),
      ReportPeriod.year => active.where((t) => t.date.year == year).toList(),
      ReportPeriod.yearToDate => active
          .where((t) =>
              t.date.year == year &&
              !t.date.isAfter(
                  year < now.year ? DateTime(year, 12, 31) : now))
          .toList(),
    };
    final expenses = sum(periodTx, TransactionType.expense);
    final incomes = sum(periodTx, TransactionType.income);
    final balance = incomes - expenses;

    final currency = settings.currency;
    final showYearAnnex = period != ReportPeriod.year;

    final incomeTotals = _groupTotals(
        periodTx.where((t) => t.type == TransactionType.income).toList());
    final expenseTotals = _groupTotals(
        periodTx.where((t) => t.type == TransactionType.expense).toList());
    final margen = incomes > 0 ? (balance / incomes) * 100 : null;
    final ratio = incomes > 0 ? (expenses / incomes) * 100 : null;
    final resultColor = balance < 0 ? _pdfNegative : _pdfPositive;

    final regular = await _regularFont();
    final bold = await _boldFont();
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: regular,
          bold: bold,
        ),
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Text(
            settings.farmName,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 20),
          ),
          pw.Text(
            l10n.pdfIncomeStatement(periodName),
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 13,
              color: PdfColors.brown600,
            ),
          ),
          pw.Text(
            l10n.pdfGeneratedOn(
              DateTime.now().toIso8601String().split('T').first,
              currency,
            ),
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 16),
          _statementRow(l10n.pdfIncomesHeader, formatPdfMoney(incomes, currency),
              bold: true, valueColor: _pdfPositive),
          if (incomeTotals.isEmpty)
            _statementRow(l10n.pdfNoIncomeSub, '',
                small: true, valueColor: PdfColors.grey700),
          ...incomeTotals.entries.map((e) => _statementRow(
                '    ${l10n.incomeCategory(e.key)}',
                '${_pctOf(e.value, incomes)}%   '
                '${formatPdfMoney(e.value, currency)}',
                small: true,
                valueColor: _pdfPositive,
              )),
          _statementRow(l10n.pdfExpensesHeader,
              formatPdfMoney(-expenses, currency),
              bold: true, valueColor: _pdfNegative),
          if (expenseTotals.isEmpty)
            _statementRow(l10n.pdfNoExpensesSub, '',
                small: true, valueColor: PdfColors.grey700),
          ...expenseTotals.entries.map((e) => _statementRow(
                '    ${l10n.expenseCategory(e.key)}',
                '${_pctOf(e.value, expenses)}%   '
                '${formatPdfMoney(-e.value, currency)}',
                small: true,
                valueColor: _pdfNegative,
              )),
          pw.Divider(),
          _statementRow(l10n.resultPeriodLabel,
              formatPdfMoney(balance, currency),
              bold: true,
              valueColor: resultColor,
              background: balance < 0 ? _pdfNegativeSoft : _pdfPositiveSoft),
          _statementRow(
              l10n.marginLabel,
              margen != null ? '${_pctOf(margen, 1)}%' : '—',
              small: true,
              valueColor: resultColor),
          _statementRow(
              l10n.ratioLabel,
              ratio != null ? '${_pctOf(ratio, 1)}%' : '—',
              small: true,
              valueColor: PdfColors.grey700),
          pw.SizedBox(height: 20),
          pw.Text(
            l10n.pdfCropBreakdown(periodName),
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
          ),
          pw.SizedBox(height: 6),
          _cropTable(context, periodTx, crops, currency, l10n),
          if (showYearAnnex) ...[
            pw.SizedBox(height: 20),
            pw.Text(
              l10n.pdfYearAnnex(year),
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
            ),
            pw.SizedBox(height: 6),
            _cropTable(
                context, active.where((t) => t.date.year == year), crops, currency, l10n),
          ],
          pw.SizedBox(height: 12),
          pw.Text(
            l10n.pdfRoiFootnote,
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );

    return doc.save();
  }

  String _pctOf(double part, double total) {
    if (total <= 0) return '—';
    final v = part / total * 100;
    return v >= 10 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
  }

  Map<String, double> _groupTotals(List<Transaction> list) {
    final totals = <String, double>{};
    for (final t in list) {
      totals[t.category] = (totals[t.category] ?? 0) + t.amount;
    }
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return {for (final e in entries) e.key: e.value};
  }

  pw.Widget _statementRow(String label, String value,
      {bool bold = false,
      bool small = false,
      PdfColor? valueColor,
      PdfColor? background}) {
    final f = small ? 9.0 : 11.0;
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration:
          background != null ? pw.BoxDecoration(color: background) : null,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: f,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: f,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: valueColor ?? PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  String formatPdfMoney(double value, String currency) {
    final info = currencyInfo(currency);
    final s = '${info.symbol}${value.abs().toStringAsFixed(info.decimals)}';
    return value < 0 ? '($s)' : s;
  }

  pw.Widget _cropTable(pw.Context context, Iterable<Transaction> source,
      List<Crop> crops, String currency, AppLocalizations l10n) {
    return pw.TableHelper.fromTextArray(
      headers: [
        l10n.pdfColCrop,
        l10n.pdfColMov,
        l10n.pdfColExpenses,
        l10n.pdfColIncomes,
        l10n.pdfColResult,
        l10n.pdfColRoi,
      ],
      data: _cropRows(context, source, crops, currency, l10n),
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
        5: pw.Alignment.centerRight,
      },
    );
  }

  List<List<String>> _cropRows(pw.Context context, Iterable<Transaction> source,
      List<Crop> crops, String currency, AppLocalizations l10n) {
    final nameById = {for (final c in crops) c.id: c.name};
    final totals = <String?, _CropTotalRow>{
      null: _CropTotalRow(name: l10n.cropUnspecified),
    };
    for (final c in crops) {
      totals.putIfAbsent(c.id, () => _CropTotalRow(name: c.name));
    }

    for (final t in source) {
      final row = totals.putIfAbsent(t.cropId, () {
        final name = t.cropId == null
            ? l10n.cropUnspecified
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