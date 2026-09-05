import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/strings.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart';
import '../services/pdf_export_service.dart';
import '../services/report_insights_service.dart';
import '../utils/format.dart';
import '../widgets/terminology_guide.dart';

enum _PeriodMode { month, year, yearToDate }

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  late int _year;
  late int _month;
  _PeriodMode _mode = _PeriodMode.month;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
  }

  @override
  Widget build(BuildContext context) {
    final tx = context.watch<TransactionProvider>();
    final l10n = AppLocalizations.of(context)!;
    final months = l10n.monthFull;
    final records = _recordsFor(tx);
    final prevRecords = _previousMonthRecords(tx);
    final inYear = tx.transactions
        .where((t) => !t.deleted && t.date.year == _year)
        .toList();
    final insights = const ReportInsightsService().build(
      now: DateTime.now(),
      current: records,
      previousMonth: prevRecords,
      yearRecords: inYear,
      year: _year,
      month: _mode == _PeriodMode.month ? _month : null,
      l10n: l10n,
      money: (v) => formatMoney(context, v),
    );
    final expenses = records
        .where((t) => t.type.isExpense)
        .fold<double>(0, (a, t) => a + t.amount);
    final incomes = records
        .where((t) => !t.type.isExpense)
        .fold<double>(0, (a, t) => a + t.amount);
    final balance = incomes - expenses;
    final incomeRows = _categoryRows(tx, TransactionType.income, l10n);
    final expenseRows = _categoryRows(tx, TransactionType.expense, l10n);
    final margen = incomes > 0 ? (balance / incomes) * 100 : null;
    final ratio = incomes > 0 ? (expenses / incomes) * 100 : null;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.menuReport)),
      body: RefreshIndicator(
        onRefresh: () async {},
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<_PeriodMode>(
              segments: [
                ButtonSegment(
                    value: _PeriodMode.month, label: Text(l10n.segMonth)),
                ButtonSegment(
                    value: _PeriodMode.year, label: Text(l10n.segYear)),
                ButtonSegment(
                    value: _PeriodMode.yearToDate,
                    label: Text(l10n.segYearToDate)),
              ],
              selected: {_mode},
              showSelectedIcon: false,
              onSelectionChanged: (s) =>
                  setState(() => _mode = s.first),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (_mode == _PeriodMode.month) ...[
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _month,
                      decoration: InputDecoration(
                        labelText: l10n.segMonth,
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        for (var i = 1; i <= 12; i++)
                          DropdownMenuItem(
                              value: i, child: Text(months[i - 1])),
                      ],
                      onChanged: (v) =>
                          setState(() => _month = v ?? _month),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _year,
                    decoration: InputDecoration(
                      labelText: l10n.segYear,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      for (var y = _year - 2; y <= _year; y++)
                        DropdownMenuItem(value: y, child: Text('$y')),
                    ],
                    onChanged: (v) => setState(() => _year = v ?? _year),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              _periodLabel(l10n),
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (insights.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome,
                              size: 18, color: Color(0xFF1976D2)),
                          const SizedBox(width: 8),
                          Text(
                            l10n.insightsTitle,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...insights.map((i) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 3),
                                  child: Icon(
                                    i.tone.isNegative
                                        ? Icons.error_outline
                                        : i.tone.isPositive
                                            ? Icons.check_circle_outline
                                            : Icons.info_outline,
                                    size: 15,
                                    color: _toneColor(i.tone),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    i.text,
                                    style:
                                        const TextStyle(fontSize: 13, height: 1.3),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.incomeStatementTitle,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          tooltip: l10n.glossaryTitle,
                          visualDensity: VisualDensity.compact,
                          onPressed: () =>
                              showTerminologyGuide(context, highlight: 'margen'),
                          icon: const Icon(Icons.info_outline, size: 18),
                        ),
                        _PeriodTag(label: _periodChipLabel(l10n)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _statementLine(context, tx, l10n.incomeLabel, incomes,
                        Theme.of(context).colorScheme.primary),
                    if (incomeRows.isEmpty)
                      _hintLine(l10n.noIncomePeriod),
                    ...incomeRows.map((r) => _categoryLine(context, tx, r,
                        incomes, Theme.of(context).colorScheme.primary)),
                    const SizedBox(height: 6),
                    _statementLine(context, tx, l10n.operatingExpensesLabel,
                        -expenses, Theme.of(context).colorScheme.error),
                    if (expenseRows.isEmpty)
                      _hintLine(l10n.noExpensesPeriod),
                    ...expenseRows.map((r) => _categoryLine(context, tx, r,
                        expenses, Theme.of(context).colorScheme.error)),
                    const Divider(height: 24),
                    _resultLine(context, tx, l10n, balance),
                    const SizedBox(height: 10),
                    _metricLine(
                      l10n.marginLabel,
                      margen != null ? '${_pct(margen)}%' : '—',
                    ),
                    _metricLine(
                      l10n.ratioLabel,
                      ratio != null ? '${_pct(ratio)}%' : '—',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.cropBreakdownTitle(_periodLabel(l10n)),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          tooltip: l10n.glossaryRoiTooltip,
                          visualDensity: VisualDensity.compact,
                          onPressed: () =>
                              showTerminologyGuide(context, highlight: 'ROI'),
                          icon: const Icon(Icons.info_outline, size: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._cropRows(tx, l10n).map((row) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(row.name,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600)),
                                    Text(
                                      '${l10n.movementsCount(row.count)} · '
                                      '${l10n.cropBreakdownSummaryG} '
                                      '${formatAmount(row.expenses,
                                          currency: tx.settings.currency,
                                          locale: tx.settings.locale)} · '
                                      '${l10n.cropBreakdownSummaryI} '
                                      '${formatAmount(row.incomes,
                                          currency: tx.settings.currency,
                                          locale: tx.settings.locale)} · '
                                      '${l10n.cropBreakdownSummaryR} '
                                      '${formatAmount(row.incomes - row.expenses,
                                          currency: tx.settings.currency,
                                          locale: tx.settings.locale)}',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                row.roiLabel,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: row.roi < -0.30
                                      ? Theme.of(context).colorScheme.error
                                      : Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        )),
                    if (_cropRows(tx, l10n).isEmpty)
                      Text(l10n.noCropData),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _exporting ? null : () => _export(tx, l10n),
              icon: _exporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf),
              label: Text(_exporting ? l10n.generating : l10n.exportPdf),
            ),
          ],
            ),
          ),
        ),
      ),
    );
  }

  List<Transaction> _recordsFor(TransactionProvider tx) {
    final inYear = tx.transactions
        .where((t) => !t.deleted && t.date.year == _year);
    switch (_mode) {
      case _PeriodMode.month:
        return inYear.where((t) => t.date.month == _month).toList();
      case _PeriodMode.year:
        return inYear.toList();
      case _PeriodMode.yearToDate:
        final today = DateTime.now();
        final end =
            _year < today.year ? DateTime(_year, 12, 31) : today;
        return inYear.where((t) => !t.date.isAfter(end)).toList();
    }
  }

  // Registros del mes anterior para la comparación de tendencia mensual.
  List<Transaction> _previousMonthRecords(TransactionProvider tx) {
    if (_mode != _PeriodMode.month) return const [];
    final prevYear = _month == 1 ? _year - 1 : _year;
    final prevMonth = _month == 1 ? 12 : _month - 1;
    return tx.transactions
        .where((t) =>
            !t.deleted &&
            t.date.year == prevYear &&
            t.date.month == prevMonth)
        .toList();
  }

  Color _toneColor(InsightTone tone) => switch (tone) {
        InsightTone.positive => const Color(0xFF2E7D32),
        InsightTone.negative => const Color(0xFFD32F2F),
        InsightTone.info => const Color(0xFF1976D2),
      };

  String _periodLabel(AppLocalizations l10n) => switch (_mode) {
        _PeriodMode.month =>
          l10n.reportPeriodMonth(l10n.monthFull[_month - 1], _year),
        _PeriodMode.year => l10n.yearLabel(_year),
        _PeriodMode.yearToDate => l10n.reportPeriodYtd(_year),
      };

  String _periodChipLabel(AppLocalizations l10n) => switch (_mode) {
        _PeriodMode.month => l10n.reportChipMonth(l10n.monthFull[_month - 1], _year),
        _PeriodMode.year => '$_year',
        _PeriodMode.yearToDate => l10n.reportChipYtd(_year),
      };

  List<_CropRow> _cropRows(TransactionProvider tx, AppLocalizations l10n) {
    final nameById = {for (final c in tx.crops) c.id: c.name};
    final totals = <String?, _CropRow>{
      null: _CropRow(name: l10n.cropUnspecified),
    };
    for (final c in tx.crops) {
      totals.putIfAbsent(c.id, () => _CropRow(name: c.name));
    }
    for (final t in _recordsFor(tx)) {
      final row = totals.putIfAbsent(t.cropId, () => _CropRow(
          name: t.cropId == null
              ? l10n.cropUnspecified
              : (nameById[t.cropId] ?? t.cropId!)));
      row.count++;
      if (t.type.isExpense) {
        row.expenses += t.amount;
      } else {
        row.incomes += t.amount;
      }
    }
    return totals.values
        .where((r) => r.expenses > 0 || r.incomes > 0)
        .toList()
      ..sort((a, b) => (b.expenses + b.incomes)
          .compareTo(a.expenses + a.incomes));
  }

  Future<void> _export(TransactionProvider tx, AppLocalizations l10n) async {
    setState(() => _exporting = true);
    try {
      final svc = PdfExportService();
      final bytes = await svc.buildReport(
        settings: tx.settings,
        transactions: tx.transactions,
        crops: tx.crops,
        year: _year,
        month: _mode == _PeriodMode.month ? _month : null,
        period: switch (_mode) {
          _PeriodMode.month => ReportPeriod.month,
          _PeriodMode.year => ReportPeriod.year,
          _PeriodMode.yearToDate => ReportPeriod.yearToDate,
        },
        periodName: _periodLabel(l10n),
        l10n: l10n,
      );

      final fileName =
          '${l10n.pdfFileNamePrefix}_$_year-${(_month + 1).toString().padLeft(2, '0')}.pdf';
      final result = await SharePlus.instance.share(ShareParams(
        files: [
          XFile.fromData(Uint8List.fromList(bytes),
              mimeType: 'application/pdf', name: fileName),
        ],
        subject: l10n.pdfShareSubject(_year),
      ));
      if (!mounted) return;
      if (result.status != ShareResultStatus.dismissed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.reportGeneratedSnack)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.exportError('$e'))),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Widget _statementLine(BuildContext context, TransactionProvider tx,
      String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Text(
            _accounting(context, tx, value),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryLine(BuildContext context, TransactionProvider tx,
      _CategoryRow row, double groupTotal, Color color) {
    final pct = groupTotal > 0 ? row.amount / groupTotal * 100 : 0.0;
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              row.label,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${_pct(pct)}%',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Text(
            _accounting(context, tx, row.isExpense ? -row.amount : row.amount),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultLine(
      BuildContext context, TransactionProvider tx, AppLocalizations l10n, double balance) {
    final scheme = Theme.of(context).colorScheme;
    final source = balance < 0
        ? scheme.error
        : balance > 0
            ? scheme.primary
            : Colors.grey;
    final color = balance < 0
        ? scheme.error
        : balance > 0
            ? scheme.primary
            : Colors.grey;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: source.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.resultPeriodLabel,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ),
          Text(
            _accounting(context, tx, balance),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _hintLine(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontStyle: FontStyle.italic,
          color: Colors.grey,
        ),
      ),
    );
  }

  String _accounting(BuildContext context, TransactionProvider tx, double value) {
    final s = formatAmount(value.abs(),
        currency: tx.settings.currency, locale: tx.settings.locale);
    return value < 0 ? '($s)' : s;
  }

  String _pct(double v) => v >= 10 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  List<_CategoryRow> _categoryRows(
      TransactionProvider tx, TransactionType type, AppLocalizations l10n) {
    final records = _recordsFor(tx).where((t) => t.type == type);
    final totals = <String, double>{};
    for (final t in records) {
      totals[t.category] = (totals[t.category] ?? 0) + t.amount;
    }
    return totals.entries.map((e) {
      final label = type.isExpense
          ? l10n.expenseCategory(e.key)
          : l10n.incomeCategory(e.key);
      return _CategoryRow(
        label: label,
        amount: e.value,
        isExpense: type.isExpense,
      );
    }).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
  }
}

class _PeriodTag extends StatelessWidget {
  final String label;

  const _PeriodTag({required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: scheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _CategoryRow {
  final String label;
  final double amount;
  final bool isExpense;

  const _CategoryRow({
    required this.label,
    required this.amount,
    required this.isExpense,
  });
}

class _CropRow {
  final String name;
  double expenses = 0;
  double incomes = 0;
  int count = 0;

  _CropRow({required this.name});

  double get roi => expenses <= 0 ? 0 : (incomes - expenses) / expenses;
  String get roiLabel =>
      expenses <= 0 ? '—' : 'ROI ${(roi * 100).toStringAsFixed(0)}%';
}