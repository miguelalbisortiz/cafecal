import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../l10n/generated/app_localizations.dart';
import '../l10n/strings.dart';
import '../models/crop.dart';
import '../models/currencies.dart';
import '../models/harvest.dart';
import '../models/settings.dart';
import '../models/sowing.dart';
import '../models/tasks.dart';
import '../models/terreno.dart';
import '../models/top_accounts.dart';
import '../models/transaction.dart';
import '../models/report_period.dart';
import '../utils/format.dart';
import 'alert_service.dart';
import 'crop_totals.dart';
import 'currency_totals.dart';
import 'derived_harvests.dart';
import 'metric_signal.dart';
import 'recommendations.dart';
import 'report_harvest_metrics.dart';
import 'report_payroll_metrics.dart';
import 'week_utils.dart';

export '../models/report_period.dart';

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
    List<Harvest> harvests = const [],
    List<Sowing> sowings = const [],
    List<Terreno> terrenos = const [],
  }) async {
    final active = transactions.where((t) => !t.deleted).toList();

    double sum(List<Transaction> list, TransactionType type) =>
        list.where((t) => t.type == type).fold(0.0, (a, t) => a + t.amount);

    final now = DateTime.now();
    final periodTx = switch (period) {
      ReportPeriod.week => () {
        final range = weekRange(year, month ?? 1);
        return active
            .where((t) =>
                !t.date.isBefore(range.start) && !t.date.isAfter(range.end))
            .toList();
      }(),
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

    final periodHarvests = switch (period) {
      ReportPeriod.week => () {
        final range = weekRange(year, month ?? 1);
        return harvests
            .where((h) =>
                !h.date.isBefore(range.start) && !h.date.isAfter(range.end))
            .toList();
      }(),
      ReportPeriod.month => harvests
          .where((h) =>
              h.date.year == year && h.date.month == (month ?? now.month))
          .toList(),
      ReportPeriod.year =>
        harvests.where((h) => h.date.year == year).toList(),
      ReportPeriod.yearToDate => harvests
          .where((h) =>
              h.date.year == year &&
              !h.date.isAfter(
                  year < now.year ? DateTime(year, 12, 31) : now))
          .toList(),
    };

    final currency = settings.currency;
    // Sin locale los exportadores imprimían `2400000` y `€200.00` donde la
    // misma app mostraba `2.400.000` y `€200,00` en pantalla.
    _locale = settings.numberLocale;
    final showYearAnnex = period != ReportPeriod.year;

    // Totales del período por moneda: la fuente de verdad del encabezado.
    // Con una sola moneda se imprime la cifra de siempre; con dos o más
    // cada total va con su código, sin %, sin margen ni ratio.
    final periodTotals = PeriodCurrencyTotals.fromRecords(periodTx);
    final mixedHeader = periodTotals.isMixed;

    final incomeGroups = groupAmountsByCurrency(
      periodTx.where((t) => t.type == TransactionType.income),
      keyOf: (t) => incomeGroupKey(t.category, t.cropId),
    );
    final expenseGroups = groupAmountsByCurrency(
      periodTx.where((t) => t.type == TransactionType.expense),
      keyOf: (t) => incomeGroupKey(t.category, t.cropId),
    );
    // Con moneda única cada grupo tiene una sola entrada: la cifra de siempre.
    final margen = incomes > 0 ? (balance / incomes) * 100 : null;
    final ratio = incomes > 0 ? (expenses / incomes) * 100 : null;

    // Precio, costo y margen por kilo: el veredicto que en pantalla ya se
    // pinta. Se repiten aqui con las mismas claves para que los tres
    // pintadores digan lo mismo. Solo con moneda unica: con mezcla el precio
    // por kilo cruzaria monedas y saldria una cifra inventada.
    final perKg = ReportHarvestMetrics(sacoKg: settings.sacoKg);
    final costByKg = perKg.periodCostPerKg(expenses, periodHarvests);
    final priceByKg = perKg.avgSalePricePerKg(periodTx);
    final marginPerKg = (costByKg != null && priceByKg != null)
        ? priceByKg - costByKg
        : null;
    // Lo vendido en el periodo que todavia no se ha cobrado.
    final receivables = receivablesByCurrency(periodTx);
    // Con mezcla el color del resultado mira cada moneda por separado: nunca
    // el signo de una suma que cruzaría monedas.
    final resultColor = mixedHeader
        ? (periodTotals.results.values.any((v) => v < 0)
            ? _pdfNegative
            : _pdfPositive)
        : (balance < 0 ? _pdfNegative : _pdfPositive);

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
        footer: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Mi Cafetal',
                style: const pw.TextStyle(
                    fontSize: 8, color: PdfColors.grey500),
              ),
              pw.Text(
                '${context.pageNumber} / ${context.pagesCount}',
                style: const pw.TextStyle(
                    fontSize: 8, color: PdfColors.grey500),
              ),
            ],
          ),
        ),
        build: (context) => [
          // ── Branding: ícono café + línea decorativa ──
          pw.Row(
            children: [
              pw.Text('☕', style: const pw.TextStyle(fontSize: 22)),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: pw.Container(
                  height: 2,
                  color: PdfColors.brown600,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
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

          // ── 3 Cards de resumen ──
          pw.Row(
            children: [
              pw.Expanded(
                child: _summaryCard(
                  label: l10n.pdfIncomesHeader,
                  // Mezcla → ingresos moneda por moneda, sin sumar.
                  amount: mixedHeader
                      ? byCurrencyText(periodTotals.incomes,
                          (v, c) => formatPdfMoney(v, c))
                      : formatPdfMoney(incomes, currency),
                  color: _pdfPositive,
                  bgColor: _pdfPositiveSoft,
                  smallText: mixedHeader,
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _summaryCard(
                  label: l10n.pdfExpensesHeader,
                  amount: mixedHeader
                      ? byCurrencyText(
                          {
                            for (final c in periodTotals.currencies)
                              c: -periodTotals.expenseOf(c),
                          },
                          (v, c) => formatPdfMoney(v, c),
                        )
                      : formatPdfMoney(-expenses, currency),
                  color: _pdfNegative,
                  bgColor: _pdfNegativeSoft,
                  smallText: mixedHeader,
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _summaryCard(
                  label: l10n.resultPeriodLabel,
                  amount: mixedHeader
                      ? byCurrencyText(
                          periodTotals.results,
                          (v, c) => formatPdfMoney(v, c),
                        )
                      : formatPdfMoney(balance, currency),
                  color: resultColor,
                  bgColor: mixedHeader
                      ? (periodTotals.results.values.any((v) => v < 0)
                          ? _pdfNegativeSoft
                          : _pdfPositiveSoft)
                      : (balance < 0 ? _pdfNegativeSoft : _pdfPositiveSoft),
                  smallText: mixedHeader,
                ),
              ),
            ],
          ),
          if (mixedHeader) _mixedNote(l10n, periodTotals.currencies.length),
          pw.SizedBox(height: 18),

          // ── Detalle de ingresos ──
          _sectionHeader(l10n.pdfIncomesHeader, _pdfPositive),
          if (incomeGroups.isEmpty)
            _statementRow(l10n.pdfNoIncomeSub, '',
                small: true, valueColor: PdfColors.grey700),
          ...incomeGroups.entries.map((e) => _statementRow(
                '    ${l10n.incomeGroupLabel(e.key, crops)}',
                // Con mezcla cada grupo va moneda por moneda y sin %:
                // el % sería sobre un total que cruzaría monedas.
                mixedHeader
                    ? byCurrencyText(e.value, (v, c) => formatPdfMoney(v, c))
                    : '${_pctOf(e.value.values.first, incomes)}%   '
                        '${formatPdfMoney(e.value.values.first, currency)}',
                small: true,
                valueColor: _pdfPositive,
              )),
          pw.SizedBox(height: 6),

          // ── Detalle de gastos ──
          _sectionHeader(l10n.pdfExpensesHeader, _pdfNegative),
          if (expenseGroups.isEmpty)
            _statementRow(l10n.pdfNoExpensesSub, '',
                small: true, valueColor: PdfColors.grey700),
          ...expenseGroups.entries.map((e) => _statementRow(
                '    ${l10n.expenseCategory(e.key)}',
                mixedHeader
                    ? byCurrencyText(
                        {
                          for (final c in e.value.entries) c.key: -c.value,
                        },
                        (v, c) => formatPdfMoney(v, c),
                      )
                    : '${_pctOf(e.value.values.first, expenses)}%   '
                        '${formatPdfMoney(-e.value.values.first, currency)}',
                small: true,
                valueColor: _pdfNegative,
              )),
          pw.Divider(),
          _statementRow(
              l10n.resultPeriodLabel,
              mixedHeader
                  ? byCurrencyText(
                      periodTotals.results, (v, c) => formatPdfMoney(v, c))
                  : formatPdfMoney(balance, currency),
              bold: true,
              valueColor: resultColor,
              background: mixedHeader
                  ? (periodTotals.results.values.any((v) => v < 0)
                      ? _pdfNegativeSoft
                      : _pdfPositiveSoft)
                  : (balance < 0 ? _pdfNegativeSoft : _pdfPositiveSoft)),
          _statementRow(
              l10n.marginLabel,
              (mixedHeader || margen == null)
                  ? '—'
                  : '${formatPct(margen)}%',
              small: true,
              valueColor: resultColor),
          _statementRow(
              l10n.ratioLabel,
              (mixedHeader || ratio == null) ? '—' : '${formatPct(ratio)}%',
              small: true,
              valueColor: PdfColors.grey700),
          // El veredicto por kilo: la cifra primero y la frase del veredicto
          // debajo. En papel no hay color ni icono que valga, asi que la
          // frase tiene que estar escrita. Solo con moneda unica.
          if (!mixedHeader && (costByKg != null || priceByKg != null)) ...[
            _statementRow(
                l10n.metricCostPriceLabel,
                priceByKg == null ? '—' : formatPdfMoney(priceByKg, currency),
                small: true,
                valueColor: _pdfPositive),
            _statementRow(
                costPriceCaption(
                  l10n,
                  costPriceVerdict(costByKg, priceByKg),
                  costByKg == null ? '' : formatPdfMoney(costByKg, currency),
                ),
                '',
                small: true,
                valueColor: PdfColors.grey700),
          ],
          if (!mixedHeader && marginPerKg != null)
            _statementRow(
                l10n.metricMarginPerKgLabel,
                formatPdfMoney(marginPerKg, currency),
                bold: true,
                small: true,
                valueColor: marginPerKg < 0 ? _pdfNegative : _pdfPositive),
          if (!mixedHeader && receivables.isNotEmpty) ...[
            _statementRow(
                l10n.metricReceivablesLabel,
                formatPdfMoney(receivables.values.first, currency),
                small: true,
                valueColor: PdfColors.grey700),
            _statementRow(l10n.metricReceivablesNote, '',
                small: true, valueColor: PdfColors.grey700),
          ],
          if (mixedHeader) _mixedNote(l10n, periodTotals.currencies.length),
          pw.SizedBox(height: 20),
          _topAccounts(periodTx, l10n, currency),
          pw.SizedBox(height: 20),
          pw.Text(
            l10n.pdfCropBreakdown(periodName),
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
          ),
          pw.SizedBox(height: 6),
          _cropTable(context, periodTx, crops, terrenos, currency, l10n),
          if (showYearAnnex) ...[
            pw.SizedBox(height: 20),
            pw.Text(
              l10n.pdfYearAnnex(year),
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
            ),
            pw.SizedBox(height: 6),
            _cropTable(context, active.where((t) => t.date.year == year), crops,
                terrenos, currency, l10n),
          ],
          // Cultivos asociados: la MISMA nota que en pantalla y en Excel, y
          // en el mismo sitio relativo al desglose por cultivo. Los tres
          // pintadores tienen que decir lo mismo.
          if (hasAssociatedCrops(crops)) ...[
            pw.SizedBox(height: 10),
            pw.Text(
              l10n.associatedCropsCostTitle,
              style:
                  pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              l10n.associatedCropsCostNote,
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
          ],
          pw.SizedBox(height: 20),
          _harvestSection(periodTx, periodHarvests, harvests, crops, sowings,
              currency, settings.sacoKg, l10n),
          pw.SizedBox(height: 20),
          _soldVsHarvestedSection(periodTx, periodHarvests, crops, sowings,
              currency, settings.sacoKg, l10n),
          pw.SizedBox(height: 20),
          _payrollSection(periodTx, currency, l10n),
          pw.SizedBox(height: 20),
          // E3 · con presupuesto de obra, la gente tiene su propia sección
          // en el PDF: contarla también en la caja inflaría el gasto de caja.
          _cashBoxSection(
            periodTx,
            settings.cajaMensualEfectiva,
            period,
            year,
            month,
            now,
            currency,
            l10n,
            budgetHistory: settings.cashBudgetHistory,
            includeLabor: (settings.presupuestoObraMensual ?? 0) <= 0,
          ),
          pw.SizedBox(height: 20),
          _workBudgetSection(
            periodTx,
            settings.presupuestoObraMensual,
            period,
            year,
            month,
            now,
            currency,
            l10n,
          ),
          pw.SizedBox(height: 20),
          _workSheetSection(periodTx, crops, currency, l10n),
          pw.SizedBox(height: 20),
          // El MISMO motor, con la MISMA ventana y los MISMOS ajustes que
          // Inicio: histórico completo (no solo el período exportado) y la
          // caja/umbral que puso en Ajustes. Antes el PDF podía decir
          // «Sin recomendaciones» con el banner encendido en la portada.
          _recommendationsSection(
              active, crops, harvests, sowings, settings, l10n),
          // Anexo de ubicación: el mismo y en el mismo sitio que en
          // Reportes y en Excel. Sin un solo punto, no aparece — y con él
          // desaparece también el hueco que dejaría su separación.
          if (terrenos.any((t) => t.lat != null && t.lng != null)) ...[
            pw.SizedBox(height: 20),
            _terrenosSection(terrenos, l10n),
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

  String _pctOf(double part, double total) =>
      total <= 0 ? '—' : formatPct(part / total * 100);

  /// Card de resumen con fondo coloreado — Ingresos / Gastos / Resultado.
  ///
  /// [smallText] baja la fuente cuando el monto es una lista de monedas
  /// (moneda mixta): son varias cifras en la misma tarjeta.
  pw.Widget _summaryCard({
    required String label,
    required String amount,
    required PdfColor color,
    required PdfColor bgColor,
    bool smallText = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            amount,
            style: pw.TextStyle(
              fontSize: smallText ? 9 : 14,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Header de sección con línea de color debajo.
  pw.Widget _sectionHeader(String label, PdfColor color) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 11,
              color: color,
            ),
          ),
          pw.Container(
            height: 1.5,
            color: color,
          ),
        ],
      ),
    );
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

  /// Locale del export que se está construyendo.
  ///
  /// El servicio se crea por cada export (uno por llamada a [buildReport]) y
  /// la app no exporta dos cosas a la vez: esto es el idioma de UN solo PDF.
  /// Se fija al empezar y no cambia durante él.
  String _locale = 'es';

  String formatPdfMoney(double value, String currency, {int? decimals}) =>
      formatMoneyLabel(value, currency, locale: _locale, decimals: decimals);

  /// Sección "Principales compradores / proveedores" del período.
  /// Solo se muestra si hay ventas con cliente o gastos con proveedor.
  pw.Widget _topAccounts(Iterable<Transaction> source,
      AppLocalizations l10n, String currency) {
    final accounts = TopAccounts.from(source.toList());
    if (accounts.isEmpty) return pw.SizedBox.shrink();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (accounts.clients.isNotEmpty)
          _topAccountBlock(l10n.topClientsTitle, accounts.topClients(3),
              currency),
        if (accounts.providers.isNotEmpty)
          _topAccountBlock(l10n.topProvidersTitle, accounts.topProviders(3),
              currency),
        pw.SizedBox(height: 6),
      ],
    );
  }

  pw.Widget _topAccountBlock(
      String title, List<MapEntry<String, AccountTotal>> rows, String currency) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title,
            style:
                pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
        ...rows.map((e) {
          // Moneda única → cifra de siempre; mezcla → cada moneda por
          // separado con su código (nunca un total cruzando monedas).
          final value = e.value.amount != null
              ? formatPdfMoney(e.value.amount!, currency)
              : (e.value.byCurrency.entries.toList()
                    ..sort((a, b) => a.key.compareTo(b.key)))
                  .map((c) => formatPdfMoney(c.value, c.key))
                  .join(' · ');
          return _statementRow(
            '    ${e.key} (${e.value.count})',
            value,
            small: true,
          );
        }),
        pw.SizedBox(height: 6),
      ],
    );
  }

  pw.Widget _cropTable(pw.Context context, Iterable<Transaction> source,
      List<Crop> crops, List<Terreno> terrenos, String currency,
      AppLocalizations l10n) {
    final data = _cropRows(context, source, crops, terrenos, currency, l10n);
    if (data.isEmpty) return pw.SizedBox.shrink();

    final headerStyle = pw.TextStyle(
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
      fontSize: 9,
    );
    const cellStyle = pw.TextStyle(fontSize: 9);
    final bandStyle =
        pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold);
    // Mismo gris cálido que la banda del Excel: se lee como cabecera de lote,
    // no como una fila de cultivo más.
    const bandBg = PdfColor.fromInt(0xFFEFEBE9);
    final headers = [
      l10n.pdfColCrop, l10n.pdfColMov, l10n.pdfColExpenses,
      l10n.pdfColIncomes, l10n.pdfColResult, l10n.pdfColRoi,
    ];

    return pw.Table(
      columnWidths: {
        0: const pw.FlexColumnWidth(2.5),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(2),
        4: const pw.FlexColumnWidth(2),
        5: const pw.FlexColumnWidth(1.2),
      },
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.brown600),
          children: headers
              .map((h) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 6, vertical: 5),
                    child: pw.Text(h, style: headerStyle),
                  ))
              .toList(),
        ),
        // Data rows with ROI-based coloring
        ...data.map((line) {
          final cells = line.cells;
          final roiText = cells[5];
          final roiNum = roiText == '—'
              ? 0.0
              : (double.tryParse(roiText.replaceAll('%', '')) ?? 0);
          PdfColor? rowBg;
          if (line.isBand) {
            rowBg = bandBg;
          } else if (roiNum > 0) {
            rowBg = const PdfColor.fromInt(0xFFF1F8E9); // verde suave
          } else if (roiNum < 0) {
            rowBg = const PdfColor.fromInt(0xFFFFF3E0); // naranja suave
          }
          return pw.TableRow(
            decoration:
                rowBg != null ? pw.BoxDecoration(color: rowBg) : null,
            children: List.generate(cells.length, (i) {
              return pw.Padding(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: pw.Text(cells[i],
                    style: line.isBand ? bandStyle : cellStyle),
              );
            }),
          );
        }),
      ],
    );
  }

  /// Filas de la tabla "Por cultivo". Mismo criterio que la pantalla y el
  /// Excel ([cropBreakdownRows]): moneda única → la cifra de siempre; con
  /// dos o más monedas cada monto sale con su código y la fila no lleva
  /// neto ni ROI (serían sumas cruzando monedas).
  ///
  /// W1-c · la agrupación también es la misma (`cropBreakdownLayout`): cada
  /// terreno es una fila de banda con su total, y sus cultivos van debajo.
  /// «Sin terreno» y «Costos comunes» cierran la tabla, en ese orden.
  List<_PdfCropLine> _cropRows(pw.Context context, Iterable<Transaction> source,
      List<Crop> crops, List<Terreno> terrenos, String currency,
      AppLocalizations l10n) {
    final rows = cropBreakdownRows(
      records: source,
      crops: crops,
      terrenos: terrenos,
      unspecifiedName: l10n.commonCosts,
      loteNoRepartidoName: l10n.loteNoRepartido,
    );
    final layout = cropBreakdownLayout(
      rows: rows,
      crops: crops,
      terrenos: terrenos,
      sinTerrenoName: l10n.cropTerrenoNone,
    );

    _PdfCropLine fila(CropBreakdownRow r) {
      if (r.isMixed) {
        return _PdfCropLine([
          '${r.name}\n${l10n.cropMixedCurrencyNote(r.currencies.length)}',
          r.count.toString(),
          byCurrencyText(r.expenses, (v, c) => formatPdfMoney(v, c)),
          byCurrencyText(r.incomes, (v, c) => formatPdfMoney(v, c)),
          '—',
          '—',
        ]);
      }
      final exp = r.expensesTotal;
      final inc = r.incomesTotal;
      final roi = exp <= 0
          ? '—'
          : '${(((inc - exp) / exp) * 100).toStringAsFixed(0)}%';
      return _PdfCropLine([
        r.name,
        r.count.toString(),
        formatPdfMoney(exp, currency),
        formatPdfMoney(inc, currency),
        formatPdfMoney(inc - exp, currency),
        roi,
      ]);
    }

    if (!layout.hasBands) {
      return rows.where((r) => r.hasAnyAmount).map(fila).toList();
    }

    return [
      for (final band in layout.bands) ...[
        _PdfCropLine(
          [
            '${band.name}'
                '${band.areaHa == null ? '' : '\n${formatAreaHa(band.areaHa!, _locale)} ha'}',
            '—',
            band.isMixed
                ? byCurrencyText(band.expenses, (v, c) => formatPdfMoney(v, c))
                : formatPdfMoney(band.expensesTotal, currency),
            band.isMixed
                ? byCurrencyText(band.incomes, (v, c) => formatPdfMoney(v, c))
                : formatPdfMoney(band.incomesTotal, currency),
            '—',
            '—',
          ],
          isBand: true,
        ),
        for (final r in band.rows) fila(r),
      ],
      if (layout.commonCosts != null) fila(layout.commonCosts!),
    ];
  }

  // ---- Nivel 2: cosechas, rendimiento, conciliación y "Qué hacer" ----

  pw.Widget _harvestSection(
      Iterable<Transaction> source,
      List<Harvest> periodHarvests,
      // E4 · TODAS las cosechas. El promedio anual necesita años cerrados y
      // el período del reporte puede ser una semana: no se promedia con lo
      // mismo con lo que se mide el período.
      List<Harvest> allHarvests,
      List<Crop> crops,
      List<Sowing> sowings,
      String currency,
      double sacoKg,
      AppLocalizations l10n) {
    final metrics = ReportHarvestMetrics(sacoKg: sacoKg);
    if (periodHarvests.isEmpty) return pw.SizedBox.shrink();

    final srcTx = source.toList();
    final byCrop = metrics.totalsByCrop(periodHarvests, crops);
    final byDestination = metrics.totalsByDestination(periodHarvests);
    final pickupKg = metrics.pickupCostPerKg(srcTx, periodHarvests);
    // El costo por kg solo es válido si todos los montos que lo componen
    // son de una moneda; con mezcla la fila sale en guion y se explica.
    final pickupMixed = metrics.pickupCostCurrencies(srcTx).length > 1;
    final mixedCurrencies = <String>{
      if (pickupMixed) ...metrics.pickupCostCurrencies(srcTx),
    };

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          l10n.reportHarvestSection,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          l10n.reportHarvestedTotal,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
        ),
        ...byCrop.map((c) => _statementRow(
              '    ${c.name}',
              '${_num(c.amount)} ${c.unit}   '
              '(${_numKg(c.kg)} ${l10n.reportHarvestKg})',
              small: true,
            )),
        pw.SizedBox(height: 4),
        pw.Text(
          l10n.reportHarvestDestinations,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
        ),
        ...byDestination.entries.map((e) => _statementRow(
              '    ${_destinationLabel(e.key, l10n)}',
              _num(e.value),
              small: true,
            )),
        if (pickupKg != null || pickupMixed) ...[
          pw.SizedBox(height: 2),
          _statementRow(
            l10n.reportPickupCostPerKg,
            pickupMixed
                ? '—'
                : formatPdfMoney(pickupKg!, currency, decimals: 2),
            small: true,
            bold: true,
          ),
        ],
        // Costo total por kg e indicadores por cultivo (producción).
        ..._perCropHarvestRows(byCrop, crops, periodHarvests, allHarvests,
            srcTx, sowings,
            currency, sacoKg, l10n, mixedCurrencies),
        // Personal y kilos por cosecha (si se registraron).
        ..._staffHarvestRows(periodHarvests, crops, l10n),
        if (mixedCurrencies.isNotEmpty)
          _mixedNote(l10n, mixedCurrencies.length),
      ],
    );
  }

  List<pw.Widget> _perCropHarvestRows(
      List<CropHarvestTotal> byCrop,
      List<Crop> crops,
      List<Harvest> harvests,
      // E4 · el histórico, aparte del período, para el promedio anual.
      List<Harvest> allHarvests,
      List<Transaction> transactions,
      List<Sowing> sowings,
      String currency,
      double sacoKg,
      AppLocalizations l10n,
      Set<String> mixedCurrencies) {
    final metrics = ReportHarvestMetrics(sacoKg: sacoKg);
    final cropById = {for (final c in crops) c.id: c};
    final out = <pw.Widget>[];

    for (final c in byCrop) {
      final crop = c.cropId == null ? null : cropById[c.cropId];
      if (crop == null) continue;
      final cropHarvests =
          harvests.where((h) => h.cropId == crop.id).toList();
      final cropExpenses = cropExpensesOf(transactions, crop.id);
      final hasResiembra =
          sowings.any((s) => s.cropId == crop.id && s.kind == SowingKind.resiembra);
      // Monedas de los montos del cultivo: con dos o más no hay ni costo
      // por kilo ni inversión en una sola cifra.
      final cropCurrencies = metrics.cropAmountCurrencies(cropExpenses);
      final cropMixed = cropCurrencies.length > 1;
      if (cropMixed) mixedCurrencies.addAll(cropCurrencies);

      if (crop.phase == CropPhase.establecimiento ||
          crop.phase == CropPhase.renovacion) {
        out.add(_statementRow(
          '    ${crop.name} — ${l10n.reportInvestmentEstablecimiento}',
          cropMixed
              ? byCurrencyText(
                  amountsByCurrency(cropExpenses), (v, cur) => formatPdfMoney(v, cur))
              : formatPdfMoney(metrics.accumulatedInvestment(cropExpenses), currency),
          small: true,
        ));
      } else {
        final totalKg = metrics.totalCostPerKg(
            crop, cropExpenses, cropHarvests);
        if (totalKg != null || cropMixed) {
          out.add(_statementRow(
            '    ${crop.name} — ${l10n.reportTotalCostPerKg}',
            cropMixed ? '—' : formatPdfMoney(totalKg!, currency),
            small: true,
          ));
        }
        final yieldArea = metrics.yieldPerArea(cropHarvests, crop.areaHa);
        if (yieldArea != null) {
          out.add(_statementRow(
            '    ${crop.name} — ${l10n.reportYieldPerArea}',
            '${_numKg(yieldArea)}${hasResiembra ? ' ${l10n.reportApprox}' : ''}',
            small: true,
          ));
        }
        final yieldPlant = metrics.yieldPerPlant(cropHarvests, crop.livePlants);
        if (yieldPlant != null) {
          out.add(_statementRow(
            '    ${crop.name} — ${l10n.reportYieldPerPlant}',
            '${_numKg(yieldPlant)}${hasResiembra ? ' ${l10n.reportApprox}' : ''}',
            small: true,
          ));
        }
        // E4 · la referencia no es una tabla: es la finca del productor y
        // la meta que puso él. Va en el export igual que en pantalla — si
        // uno decía y el otro no, alguno estaría mintiendo.
        final hist = metrics.historicalYield(
          harvests: allHarvests.where((h) => h.cropId == crop.id).toList(),
          areaHa: crop.areaHa,
          livePlants: crop.livePlants,
        );
        if (hist.kgPerHa != null) {
          out.add(_statementRow(
            '    ${crop.name} — ${l10n.yieldAvgHaLabel(hist.years)}',
            _numKg(hist.kgPerHa!),
            small: true,
          ));
        }
        if (hist.kgPerPlant != null) {
          out.add(_statementRow(
            '    ${crop.name} — ${l10n.yieldAvgPlantLabel(hist.years)}',
            _numKg(hist.kgPerPlant!),
            small: true,
          ));
        }
        if (crop.expectedYieldPerHa != null) {
          out.add(_statementRow(
            '    ${crop.name} — ${l10n.yieldGoalLabel}',
            _numKg(crop.expectedYieldPerHa!),
            small: true,
          ));
        }
      }
    }
    return out;
  }

  pw.Widget _soldVsHarvestedSection(
      Iterable<Transaction> source,
      List<Harvest> periodHarvests,
      List<Crop> crops,
      List<Sowing> sowings,
      String currency,
      double sacoKg,
      AppLocalizations l10n) {
    final metrics = ReportHarvestMetrics(sacoKg: sacoKg);
    final rows = metrics.soldVsHarvested(
        source.toList(), periodHarvests, crops, DateTime.now());
    if (rows.isEmpty) return pw.SizedBox.shrink();

    // D5 · Mientras la única fuente de los kilos sea la venta, esto es
    // comparar un número consigo mismo. Misma puerta que en pantalla y en
    // Excel, para que los tres digan lo mismo.
    if (!hasIndependentHarvest(periodHarvests)) return pw.SizedBox.shrink();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          l10n.reportSoldVsHarvested,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
        ),
        pw.SizedBox(height: 6),
        ...rows.map((r) => _statementRow(
              '    ${r.name} — ${l10n.reportSoldKg}',
              _numKg(r.soldKg),
              small: true,
            )),
        ...rows.map((r) => _statementRow(
              '    ${r.name} — ${l10n.reportHarvestedKg}',
              _numKg(r.harvestedKg),
              small: true,
            )),
      ],
    );
  }

  /// Sección "Nómina del período": tabla por trabajador (días, subtotal),
  /// total de nómina y cantidad de empleados distintos.
  /// Solo se muestra si hay gastos de mano de obra en el período.
  pw.Widget _payrollSection(
      Iterable<Transaction> source, String currency, AppLocalizations l10n) {
    final summary = const ReportPayrollMetrics().payroll(source);
    if (summary.isEmpty) return pw.SizedBox.shrink();

    // Mano de obra sobre el gasto del periodo. Solo con una sola moneda en
    // nomina y en gastos: cruzar monedas daria un porcentaje falso. Sin
    // senal bueno/malo, porque no hay umbral de referencia que valga para
    // todas las fincas.
    final payrollTotal =
        summary.totalByCurrency.values.fold<double>(0, (a, b) => a + b);
    final expenseCurrencies = <String>{};
    var periodExpenses = 0.0;
    for (final t in source) {
      if (t.deleted || !t.type.isExpense) continue;
      expenseCurrencies.add(t.currency);
      periodExpenses += t.amount;
    }
    final laborShare = (!summary.isMixed &&
            expenseCurrencies.length == 1 &&
            periodExpenses > 0 &&
            payrollTotal > 0)
        ? (payrollTotal / periodExpenses) * 100
        : null;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          l10n.reportPayrollSection,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
        ),
        pw.SizedBox(height: 6),
        pw.Table(
          columnWidths: const {
            0: pw.FlexColumnWidth(3),
            1: pw.FlexColumnWidth(1.2),
            2: pw.FlexColumnWidth(2),
          },
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.brown600),
              children: [
                _payrollCell(l10n.reportPayrollWorker, _payrollHeaderStyle),
                _payrollCell(l10n.reportPayrollDays, _payrollHeaderStyle),
                _payrollCell(l10n.reportPayrollSubtotal, _payrollHeaderStyle),
              ],
            ),
            for (final r in summary.rows)
              pw.TableRow(
                children: [
                  _payrollCell(r.provider.isEmpty
                      ? l10n.reportPayrollUnnamed
                      : r.provider, _payrollCellStyle),
                  _payrollCell(
                      r.days > 0 ? _num(r.days) : '—', _payrollCellStyle),
                  // Trabajador que cobró en varias monedas → cada moneda
                  // con su código, nunca un subtotal cruzando monedas.
                  _payrollCell(
                      r.isMixed
                          ? byCurrencyText(
                              r.byCurrency, (v, c) => formatPdfMoney(v, c))
                          : formatPdfMoney(r.subtotal, currency),
                      _payrollCellStyle),
                ],
              ),
          ],
        ),
        pw.SizedBox(height: 4),
        _statementRow(
          l10n.reportPayrollTotal,
          summary.isMixed
              ? byCurrencyText(summary.totalByCurrency,
                  (v, c) => formatPdfMoney(v, c))
              : formatPdfMoney(summary.total, currency),
          bold: true,
        ),
        if (laborShare != null) ...[
          _statementRow(
            l10n.metricLaborShareLabel,
            '${formatPct(laborShare)}%',
            small: true,
            valueColor: PdfColors.grey700,
          ),
          _statementRow(l10n.metricLaborShareNote, '',
              small: true, valueColor: PdfColors.grey700),
        ],
        if (summary.isMixed) _mixedNote(l10n, summary.totalByCurrency.length),
        _statementRow(
          l10n.reportPayrollEmployees(summary.distinctEmployees),
          '',
          small: true,
        ),
      ],
    );
  }

  static final _payrollHeaderStyle = pw.TextStyle(
    fontWeight: pw.FontWeight.bold,
    color: PdfColors.white,
    fontSize: 9,
  );
  static const _payrollCellStyle = pw.TextStyle(fontSize: 9);

  pw.Widget _payrollCell(String text, pw.TextStyle style) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: pw.Text(text, style: style),
      );

  /// Aviso genérico de moneda mixta (cada monto con su moneda; nunca se
  /// suman ni se comparan entre sí).
  pw.Widget _mixedNote(AppLocalizations l10n, int currencies) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: pw.Text(
          l10n.currencyMixedByCurrencyNote(currencies),
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
      );

  /// Sección "Caja menor": una fila por mes del período con presupuesto,
  /// jornales, extras, total y saldo. Solo con monto configurado
  /// (el saldo no se acumula entre meses: cada mes reinicia).
  /// E3 · la planilla en el PDF: en qué se gastó la gente, agrupada por
  /// labor y cultivo. Mismo criterio que la pantalla y el Excel — si los
  /// tres calculan distinto, uno de los tres miente.
  pw.Widget _workSheetSection(Iterable<Transaction> source, List<Crop> crops,
      String currency, AppLocalizations l10n) {
    final rows = const ReportPayrollMetrics().workSheetRows(
      periodTx: source,
      cropNames: {for (final c in crops) c.id: c.name},
      unlabeledTaskName: l10n.workSheetUnlabeled,
    );
    if (rows.isEmpty) return pw.SizedBox.shrink();

    pw.Widget cell(String text, {bool bold = false}) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: pw.Text(
            text,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        );

    String daysLabel(double d) {
      final n = d % 1 == 0 ? d.toInt().toString() : '$d';
      return '$n ${d == 1 ? l10n.workSheetDayPlural : l10n.workSheetDayOther}';
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          l10n.workSheetTitle,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
        ),
        pw.SizedBox(height: 6),
        pw.Table(
          columnWidths: const {
            0: pw.FlexColumnWidth(2.2),
            1: pw.FlexColumnWidth(1.6),
            2: pw.FlexColumnWidth(1.4),
            3: pw.FlexColumnWidth(1.4),
            4: pw.FlexColumnWidth(1.8),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey300),
              children: [
                cell(l10n.taskFieldLabel, bold: true),
                cell(l10n.pdfColCrop, bold: true),
                cell(l10n.reportPayrollWorker, bold: true),
                cell(l10n.reportPayrollDays, bold: true),
                cell(l10n.reportPayrollSubtotal, bold: true),
              ],
            ),
            for (final r in rows)
              pw.TableRow(
                children: [
                  cell('${taskIcon(r.task)} ${taskLabel(r.task)}'),
                  cell(r.cropName),
                  cell(r.workers > 0 ? '${r.workers}' : '—'),
                  cell(r.days > 0 ? daysLabel(r.days) : '—'),
                  r.isMixed
                      ? cell(byCurrencyText(
                          r.byCurrency, (v, c) => formatMoneyLabel(v, c, locale: _locale)))
                      : cell(formatMoneyLabel(r.total, currency,
                          locale: _locale)),
                ],
              ),
          ],
        ),
      ],
    );
  }

  /// E3 · sección de presupuesto de obra en el PDF: solo mano de obra,
  /// contra su propio presupuesto. Si no está configurado no se imprime.
  pw.Widget _workBudgetSection(
    Iterable<Transaction> source,
    double? budget,
    ReportPeriod period,
    int year,
    int? month,
    DateTime now,
    String currency,
    AppLocalizations l10n,
  ) {
    final rows = const ReportPayrollMetrics().workBudgetByMonth(
      periodTx: source,
      budget: budget,
      period: period,
      year: year,
      month: month,
      now: now,
    );
    if (rows.isEmpty) return pw.SizedBox.shrink();
    final multiYear = rows.map((r) => r.year).toSet().length > 1;
    final mixed = <String>{
      for (final r in rows)
        if (r.isMixed) ...r.currencies,
    };

    pw.Widget cell(String text, {bool bold = false}) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: pw.Text(
            text,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          l10n.workBudgetTitle,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
        ),
        pw.SizedBox(height: 6),
        pw.Table(
          columnWidths: const {
            0: pw.FlexColumnWidth(1.8),
            1: pw.FlexColumnWidth(1.6),
            2: pw.FlexColumnWidth(1.6),
            3: pw.FlexColumnWidth(1.4),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey300),
              children: [
                cell(l10n.segMonth, bold: true),
                cell(l10n.reportCashBoxBudget, bold: true),
                cell(l10n.jornalTotalLabel, bold: true),
                cell(l10n.workBudgetBalance, bold: true),
              ],
            ),
            for (final r in rows)
              pw.TableRow(
                children: [
                  cell(multiYear
                      ? '${l10n.monthFull[r.month - 1]} ${r.year}'
                      : l10n.monthFull[r.month - 1]),
                  cell(formatMoneyLabel(r.budget, currency,
                      locale: _locale)),
                  // Misma regla que Reportes y el Excel: solo hay saldo si
                  // el mes gastó en la moneda del presupuesto. Con una moneda
                  // ajena esto imprimía pesos menos euros.
                  comparableToBudget(r.currencies, currency)
                      ? cell(formatMoneyLabel(r.used, currency,
                          locale: _locale))
                      : cell(byCurrencyText(r.laborByCurrency,
                          (v, c) => formatMoneyLabel(v, c, locale: _locale))),
                  comparableToBudget(r.currencies, currency)
                      ? cell(formatMoneyLabel(r.balance, currency,
                          locale: _locale))
                      : cell('—'),
                ],
              ),
          ],
        ),
        if (mixed.isNotEmpty) ...[
          pw.SizedBox(height: 4),
          pw.Text(
            l10n.currencyMixedByCurrencyNote(mixed.length),
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.blue700),
          ),
        ],
      ],
    );
  }

  pw.Widget _cashBoxSection(
    Iterable<Transaction> source,
    double? budget,
    ReportPeriod period,
    int year,
    int? month,
    DateTime now,
    String currency,
    AppLocalizations l10n, {
    Map<String, double> budgetHistory = const {},
    bool includeLabor = true,
  }) {
    final rows = const ReportPayrollMetrics().cashBoxByMonth(
      periodTx: source,
      budget: budget,
      budgetHistory: budgetHistory,
      period: period,
      year: year,
      month: month,
      now: now,
      includeLabor: includeLabor,
    );
    if (rows.isEmpty) return pw.SizedBox.shrink();
    final multiYear = rows.map((r) => r.year).toSet().length > 1;

    // Monedas que aparecen mezcladas en algún mes del período (para el
    // aviso de que esos montos van por separado).
    final mixedCurrencies = <String>{
      for (final r in rows)
        if (r.isMixed) ...r.currencies,
    };

    pw.Widget cell(String text, {PdfColor? color, bool bold = false}) =>
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: pw.Text(
            text,
            style: pw.TextStyle(
              fontSize: 9,
              color: color ?? PdfColors.black,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          l10n.cashBoxTitle,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
        ),
        pw.SizedBox(height: 6),
        pw.Table(
          columnWidths: const {
            0: pw.FlexColumnWidth(1.8),
            1: pw.FlexColumnWidth(1.6),
            2: pw.FlexColumnWidth(1.4),
            3: pw.FlexColumnWidth(1.4),
            4: pw.FlexColumnWidth(1.4),
            5: pw.FlexColumnWidth(1.5),
          },
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.brown600),
              children: [
                cell(l10n.segMonth, color: PdfColors.white, bold: true),
                cell(l10n.reportCashBoxBudget, color: PdfColors.white, bold: true),
                cell(l10n.cashBoxLabor, color: PdfColors.white, bold: true),
                cell(l10n.cashBoxExtras, color: PdfColors.white, bold: true),
                cell(l10n.jornalTotalLabel, color: PdfColors.white, bold: true),
                cell(l10n.reportCashBoxBalance,
                    color: PdfColors.white, bold: true),
              ],
            ),
            for (final r in rows)
              pw.TableRow(
                children: [
                  cell(multiYear
                      ? '${l10n.monthFull[r.month - 1]} ${r.year}'
                      : l10n.monthFull[r.month - 1]),
                  cell(formatPdfMoney(r.budget, currency)),
                  // Misma regla que Reportes y el Excel ([comparableToBudget]):
                  // solo hay saldo si el mes gastó en la moneda del
                  // presupuesto. Con una moneda ajena —aunque fuera una sola,
                  // así que isMixed era false— esto imprimía pesos menos euros.
                  comparableToBudget(r.currencies, currency)
                      ? cell(formatPdfMoney(r.labor, currency))
                      : cell(byCurrencyText(r.laborByCurrency,
                          (v, c) => formatPdfMoney(v, c))),
                  comparableToBudget(r.currencies, currency)
                      ? cell(formatPdfMoney(r.extras, currency))
                      : cell(byCurrencyText(r.extrasByCurrency,
                          (v, c) => formatPdfMoney(v, c))),
                  comparableToBudget(r.currencies, currency)
                      ? cell(formatPdfMoney(r.total, currency))
                      : cell(byCurrencyText(r.totalByCurrency,
                          (v, c) => formatPdfMoney(v, c))),
                  cell(
                    comparableToBudget(r.currencies, currency)
                        ? formatPdfMoney(r.balance, currency)
                        : '—',
                    color: (comparableToBudget(r.currencies, currency) &&
                            r.balance < 0)
                        ? _pdfNegative
                        : _pdfPositive,
                    bold: true,
                  ),
                ],
              ),
          ],
        ),
        if (mixedCurrencies.isNotEmpty)
          _mixedNote(l10n, mixedCurrencies.length),
      ],
    );
  }

  /// Filas por cosecha con 👷 empleados y kilos equivalentes (si existen).
  List<pw.Widget> _staffHarvestRows(
      List<Harvest> harvests, List<Crop> crops, AppLocalizations l10n) {
    final nameById = {for (final c in crops) c.id: c.name};
    final withStaff = harvests
        .where((h) => h.workers != null || h.equivalentKg != null)
        .toList();
    if (withStaff.isEmpty) return const [];
    return [
      pw.SizedBox(height: 4),
      pw.Text(
        l10n.reportHarvestStaff,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
      ),
      ...withStaff.map((h) {
        final crop = h.cropId == null ? null : nameById[h.cropId];
        final date =
            '${h.date.day.toString().padLeft(2, '0')}/${h.date.month.toString().padLeft(2, '0')}/${h.date.year}';
        final parts = <String>[
          if (h.workers != null) '👷 ${l10n.harvestWorkersCount(h.workers!)}',
          if (h.equivalentKg != null) '${_numKg(h.equivalentKg!)} kg',
        ];
        return _statementRow(
          '    $date${crop != null ? ' · $crop' : ''}',
          parts.join(' · '),
          small: true,
        );
      }),
    ];
  }

  pw.Widget _recommendationsSection(
      Iterable<Transaction> history,
      List<Crop> crops,
      List<Harvest> harvests,
      List<Sowing> sowings,
      FarmSettings settings,
      AppLocalizations l10n) {
    final alerts = evaluateAlerts(
      transactions: history,
      crops: crops,
      l10n: l10n,
      settings: settings,
      harvests: harvests,
      sowings: sowings,
    );
    // Sin tope: lo que se enseña acá es lo que enseña el banner de Inicio.
    final recommendations = const RecommendationService().derive(alerts);
    if (recommendations.isEmpty) return pw.SizedBox.shrink();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          l10n.reportWhatsNext,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
        ),
        pw.SizedBox(height: 6),
        for (var i = 0; i < recommendations.length; i++) ...[
          _statementRow(
            '${i + 1}. ${recommendations[i].title}',
            '',
            small: true,
            bold: true,
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 12, bottom: 4),
            child: pw.Text(
              recommendations[i].message,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ),
        ],
      ],
    );
  }

  /// El anexo de ubicación del PDF — mismo texto y mismo orden que en
  /// Reportes y en Excel: los tres pintadores tienen que decir lo mismo.
  ///
  /// Un terreno sin punto se lista igual por su nombre, pero sin línea de
  /// coordenada. `null` → oculto, nunca un 0 que pondría el lote en el
  /// ecuador y el meridiano de Greenwich.
  pw.Widget _terrenosSection(List<Terreno> terrenos, AppLocalizations l10n) {
    if (!terrenos.any((t) => t.lat != null && t.lng != null)) {
      return pw.SizedBox.shrink();
    }

    final children = <pw.Widget>[
      pw.Text(
        l10n.reportTerrenosTitle,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
      ),
      pw.SizedBox(height: 3),
      pw.Text(
        l10n.reportTerrenosHint,
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
      ),
      pw.SizedBox(height: 6),
    ];

    for (var i = 0; i < terrenos.length; i++) {
      final t = terrenos[i];
      if (i > 0) {
        children.add(pw.Container(
          height: 0.5,
          margin: const pw.EdgeInsets.only(top: 4, bottom: 4),
          color: PdfColors.grey300,
        ));
      }
      children.add(pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Text(
              t.name,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            ),
          ),
          // Misma forma que en el resto de la app: `2.00 ha`. Sin medir,
          // no se imprime nada.
          if (t.areaHa != null)
            pw.Text(
              '${t.areaHa!.toStringAsFixed(2)} ha',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
        ],
      ));
      if (t.lat != null && t.lng != null) {
        children.add(pw.Text(
          '${t.lat!.toStringAsFixed(6)}, ${t.lng!.toStringAsFixed(6)}',
          style: const pw.TextStyle(fontSize: 10),
        ));
        if (t.locatedAt != null) {
          children.add(pw.Text(
            l10n.terrenoLocationDate(_fmtDate(t.locatedAt!)),
            style: const pw.TextStyle(
                fontSize: 8, color: PdfColors.grey600),
          ));
        }
      }
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: children,
    );
  }

  /// Igual que en Reportes y en Excel (`dd/MM/yyyy`): los tres pintadores
  /// tienen que poner la misma fecha.
  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _destinationLabel(HarvestDestination d, AppLocalizations l10n) =>
      switch (d) {
        HarvestDestination.vendido => l10n.harvestDstVendido,
        HarvestDestination.almacenado => l10n.harvestDstAlmacenado,
        HarvestDestination.perdida => l10n.harvestDstPerdida,
      };

  String _num(double v) => v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  String _numKg(double v) => v >= 100
      ? v.toStringAsFixed(0)
      : v.toStringAsFixed(v % 1 == 0 ? 0 : 2);
}

/// Una fila de la tabla «Por cultivo»: sus celdas y si es cabecera de banda.
class _PdfCropLine {
  final List<String> cells;
  final bool isBand;

  const _PdfCropLine(this.cells, {this.isBand = false});
}