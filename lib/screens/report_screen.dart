import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/strings.dart';
import '../providers/transaction_provider.dart';
import '../models/farm_alert.dart';
import '../models/crop.dart';
import '../models/harvest.dart';
import '../models/sowing.dart';
import '../models/top_accounts.dart';
import '../models/transaction.dart';
import '../models/units.dart';
import '../models/categories.dart';
import '../services/alert_service.dart';
import '../services/currency_conversion.dart';
import '../services/currency_totals.dart';
import '../services/excel_export_service.dart';
import '../services/pdf_export_service.dart';
import '../services/metric_signal.dart';
import '../services/recommendations.dart';
import '../services/report_harvest_metrics.dart';
import '../services/report_insights_service.dart';
import '../services/report_payroll_metrics.dart';
import '../services/week_utils.dart';
import '../utils/format.dart';
import '../widgets/currency_breakdown.dart';
import '../widgets/per_hectare_panel.dart';
import '../widgets/period_totals.dart';
import '../widgets/terminology_guide.dart';

enum _PeriodMode { week, month, year, yearToDate }

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  late int _year;
  late int _month;
  late int _week;
  _PeriodMode _mode = _PeriodMode.month;
  bool _exporting = false;
  bool _exportingExcel = false;
  bool _exportingBalance = false;
  String _effectiveCurrency = 'COP';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
    _week = currentWeekNumber(now);
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

    // Detectar moneda efectiva del período
    final currenciesInPeriod = records.map((t) => t.currency).toSet();
    _effectiveCurrency = currenciesInPeriod.length == 1
        ? currenciesInPeriod.first
        : tx.settings.currency;

    // A — totales por moneda: nunca se suman monedas distintas.
    final periodTotals = PeriodCurrencyTotals.fromRecords(records);

    final insights = const ReportInsightsService().build(
      now: DateTime.now(),
      current: records,
      previousMonth: prevRecords,
      yearRecords: inYear,
      year: _year,
      month: _mode == _PeriodMode.month ? _month : null,
      crops: tx.crops,
      l10n: l10n,
      // Con moneda mixta no se imprime un balance global: sería falso.
      mixedTotals: periodTotals.isMixed,
      money: (v) => formatMoneyFor(context, v, currency: _effectiveCurrency),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.menuReport)),
      body: PeriodTotalsBuilder(
        totals: periodTotals,
        targetCurrency: tx.settings.currency,
        builder: (context, converted) => RefreshIndicator(
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
                    value: _PeriodMode.week, label: Text(l10n.segWeek)),
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
                if (_mode == _PeriodMode.week) ...[
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => setState(() {
                      _week--;
                      if (_week < 1) {
                        _week = 52;
                        _year--;
                      }
                    }),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        l10n.reportChipWeek(_week),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => setState(() {
                      _week++;
                      final maxWeek = currentWeekNumber(DateTime(_year, 12, 28));
                      if (_week > maxWeek) {
                        _week = 1;
                        _year++;
                      }
                    }),
                  ),
                ],
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

            _statementCard(
                context, tx, l10n, records, periodTotals, converted),

            const SizedBox(height: 20),
            _TopAccountsCard(
                records: records,
                l10n: l10n,
                effectiveCurrency: _effectiveCurrency,
                locale: tx.settings.locale),
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
                    ..._cropRows(tx, l10n).map((row) => _CropBreakdownTile(
                          row: row,
                          l10n: l10n,
                          currency: row.currency,
                          locale: tx.settings.locale,
                          scheme: Theme.of(context).colorScheme,
                        )),
                    if (_cropRows(tx, l10n).isEmpty)
                      Text(l10n.noCropData),
                    if (_cropRows(tx, l10n).isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline,
                                size: 14,
                                color: Color(0xFF1976D2)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                l10n.cropBreakdownRoiHint,
                                style: TextStyle(
                                  fontSize: 11,
                                  height: 1.3,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            _builtHarvestCard(context, tx, l10n),
            const SizedBox(height: 20),
            _builtSowingCard(context, tx, l10n),
            const SizedBox(height: 20),
            _builtSoldVsHarvestedCard(context, tx, l10n),
            const SizedBox(height: 20),
            _builtPayrollCard(context, tx, l10n),
            const SizedBox(height: 20),
            _builtCashBoxCard(context, tx, l10n),
            const SizedBox(height: 20),
            PerHectarePanel(
              crops: tx.crops,
              periodTransactions: _recordsFor(tx),
              periodHarvests: _periodHarvests(tx),
              allTransactions: tx.transactions,
            ),
            const SizedBox(height: 20),
            _builtRecommendationsCard(context, tx, l10n),
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
            const SizedBox(height: 10),
            FilledButton.tonalIcon(
              onPressed:
                  _exportingExcel ? null : () => _exportExcel(tx, l10n),
              icon: _exportingExcel
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.table_chart),
              label: Text(_exportingExcel
                  ? l10n.generating
                  : l10n.exportExcel),
            ),
            const SizedBox(height: 10),
            FilledButton.tonalIcon(
              onPressed:
                  _exportingBalance ? null : () => _exportBalance(tx, l10n),
              icon: _exportingBalance
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.account_balance),
              label: Text(_exportingBalance
                  ? l10n.generating
                  : l10n.exportBalance),
            ),
          ],
            ),
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
      case _PeriodMode.week:
        final range = weekRange(_year, _week);
        return tx.transactions
            .where((t) =>
                !t.deleted &&
                !t.date.isBefore(range.start) &&
                !t.date.isAfter(range.end))
            .toList();
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

  // Registros del mes anterior para la comparaciÃ³n de tendencia mensual.
  List<Transaction> _previousMonthRecords(TransactionProvider tx) {
    if (_mode == _PeriodMode.week) {
      int prevWeek = _week - 1;
      int prevYear = _year;
      if (prevWeek < 1) {
        prevWeek = 52;
        prevYear--;
      }
      final range = weekRange(prevYear, prevWeek);
      return tx.transactions
          .where((t) =>
              !t.deleted &&
              !t.date.isBefore(range.start) &&
              !t.date.isAfter(range.end))
          .toList();
    }
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
        _PeriodMode.week =>
          l10n.reportPeriodWeek(_week, _year),
        _PeriodMode.month =>
          l10n.reportPeriodMonth(l10n.monthFull[_month - 1], _year),
        _PeriodMode.year => l10n.yearLabel(_year),
        _PeriodMode.yearToDate => l10n.reportPeriodYtd(_year),
      };

  /// Equivalente del modo de pantalla al periodo de exportación.
  ReportPeriod get _reportPeriod => switch (_mode) {
        _PeriodMode.week => ReportPeriod.week,
        _PeriodMode.month => ReportPeriod.month,
        _PeriodMode.year => ReportPeriod.year,
        _PeriodMode.yearToDate => ReportPeriod.yearToDate,
      };

  /// Mes (o número de semana en modo semana), como en la exportación PDF/Excel.
  int? get _reportPeriodArg => _mode == _PeriodMode.month
      ? _month
      : (_mode == _PeriodMode.week ? _week : null);

  String _periodChipLabel(AppLocalizations l10n) => switch (_mode) {
        _PeriodMode.week => l10n.reportChipWeek(_week),
        _PeriodMode.month => l10n.reportChipMonth(l10n.monthFull[_month - 1], _year),
        _PeriodMode.year => '$_year',
        _PeriodMode.yearToDate => l10n.reportChipYtd(_year),
      };

  List<_CropRow> _cropRows(TransactionProvider tx, AppLocalizations l10n) {
    const metrics = ReportHarvestMetrics();
    final nameById = {for (final c in tx.crops) c.id: c.name};
    final totals = <String?, _CropRow>{
      null: _CropRow(name: l10n.cropUnspecified),
    };
    for (final c in tx.crops) {
      totals.putIfAbsent(c.id, () => _CropRow(
          name: c.name, currency: c.currency ?? 'COP'));
    }
    for (final t in _recordsFor(tx)) {
      final row = totals.putIfAbsent(t.cropId, () => _CropRow(
          name: t.cropId == null
              ? l10n.cropUnspecified
              : (nameById[t.cropId] ?? t.cropId!),
          currency: t.currency));
      row.count++;
      if (t.type.isExpense) {
        row.expenses += t.amount;
        row.expenseTxs.add(t);
      } else {
        row.incomes += t.amount;
      }
    }
    // L2.1 — desglose de lo que ya se gastó: inversión inicial (siembras) y
    // operación del período suman exactamente lo mismo que `expenses`.
    for (final row in totals.values) {
      final split = metrics.splitInvestmentAndOperation(row.expenseTxs);
      row.investment = split.investment;
      row.operation = split.operation;
    }
    return totals.values
        .where((r) => r.expenses > 0 || r.incomes > 0)
        .toList()
      ..sort((a, b) => (b.expenses + b.incomes)
          .compareTo(a.expenses + a.incomes));
  }

  // ---- Nivel 2: secciÃ³n cosechas, vendido vs cosechado, y "QuÃ© hacer" ----

  List<Harvest> _periodHarvests(TransactionProvider tx) {
    return tx.harvests.where((h) {
      if (_mode == _PeriodMode.week) {
        final range = weekRange(_year, _week);
        return !h.date.isBefore(range.start) && !h.date.isAfter(range.end);
      }
      if (_mode == _PeriodMode.month) {
        return h.date.year == _year && h.date.month == _month;
      }
      if (_mode == _PeriodMode.year) {
        return h.date.year == _year;
      }
      final today = DateTime.now();
      final end = _year < today.year ? DateTime(_year, 12, 31) : today;
      return !h.date.isAfter(end);
    }).toList();
  }

  /// Siembras que caen dentro del período seleccionado. Mismo criterio que
  /// [_periodHarvests].
  List<Sowing> _periodSowings(TransactionProvider tx) {
    return tx.sowings.where((s) {
      if (_mode == _PeriodMode.week) {
        final range = weekRange(_year, _week);
        return !s.date.isBefore(range.start) && !s.date.isAfter(range.end);
      }
      if (_mode == _PeriodMode.month) {
        return s.date.year == _year && s.date.month == _month;
      }
      if (_mode == _PeriodMode.year) {
        return s.date.year == _year;
      }
      final today = DateTime.now();
      final end = _year < today.year ? DateTime(_year, 12, 31) : today;
      return !s.date.isAfter(end);
    }).toList();
  }

  /// P5 — "Siembras": arriba el estado actual (qué tengo plantado hoy) y
  /// abajo las siembras del período con sus pérdidas y motivo.
  ///
  /// Todo sale de datos que ya se registran (`Sowing.plants/areaHa/
  /// lostPlants/reason`) — sin migración ni campos nuevos.
  Widget _builtSowingCard(
      BuildContext context, TransactionProvider tx, AppLocalizations l10n) {
    final state = recomputeCropState(tx.sowings);
    final periodSowings = _periodSowings(tx);
    final scheme = Theme.of(context).colorScheme;

    String plantUnit(int n) =>
        n == 1 ? l10n.reportSowingsPlantOne : l10n.reportSowingsPlantMany;

    final nowRows = <Widget>[];
    var totalPlants = 0;
    var totalHa = 0.0;
    var hasArea = false;
    for (final c in tx.crops) {
      final s = state[c.id];
      final plants = s?.livePlants ?? c.livePlants;
      if (plants == null) continue;
      final ha = s?.areaHa ?? c.areaHa;
      totalPlants += plants;
      if (ha != null) {
        totalHa += ha;
        hasArea = true;
      }
      nowRows.add(_harvestLine(
        label: c.name,
        value: '$plants ${plantUnit(plants)}',
        extra: ha != null ? '${_num(ha)} ha' : null,
      ));
      // L2.3: un cultivo que sigue en establecimiento todavía no rinde; se
      // dice con una frase, no solo con un color.
      if (c.phase == CropPhase.establecimiento) {
        nowRows.add(_hintLine(l10n.cropPhaseNoYield));
      }
    }

    if (nowRows.isEmpty && periodSowings.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalLost =
        tx.sowings.fold<int>(0, (a, s) => a + (s.lostPlants ?? 0));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.reportSowingsSection,
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
                      showTerminologyGuide(context, highlight: 'siembra'),
                  icon: const Icon(Icons.info_outline, size: 18),
                ),
              ],
            ),
            if (nowRows.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                l10n.reportSowingsNow,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              ...nowRows,
              const SizedBox(height: 6),
              _harvestLine(
                label: l10n.reportSowingsTotal,
                value: '$totalPlants ${plantUnit(totalPlants)}',
                extra: hasArea ? '${_num(totalHa)} ha' : null,
                bold: true,
              ),
              if (totalLost > 0)
                _harvestLine(
                  label: l10n.reportSowingsLosses,
                  value: '$totalLost ${plantUnit(totalLost)}',
                  color: scheme.error,
                ),
            ],
            if (periodSowings.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                l10n.reportSowingsInPeriod(_periodLabel(l10n)),
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              ...periodSowings.map((s) {
                final name = cropNameOf(tx.crops, s.cropId) ??
                    l10n.assignCropsUnassigned;
                final kind = s.kind == SowingKind.resiembra
                    ? l10n.reportSowingsKindResiembra
                    : l10n.reportSowingsKindSiembra;
                final lost = s.lostPlants ?? 0;
                final reason = s.reason ?? '';
                String? note;
                if (lost > 0 && reason.isNotEmpty) {
                  note = l10n.reportSowingsLostLine(lost, reason);
                } else if (lost > 0) {
                  note = l10n.reportSowingsLostOnly(lost);
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _harvestLine(
                      label: '${_fmtDate(s.date)} · $name · $kind',
                      value: '${s.plants} ${plantUnit(s.plants)}',
                      extra:
                          s.areaHa != null ? '${_num(s.areaHa!)} ha' : null,
                    ),
                    if (note != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 16, bottom: 6),
                        child: Text(
                          note,
                          style: TextStyle(
                            fontSize: 11,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                );
              }),
            ] else if (nowRows.isNotEmpty) ...[
              const SizedBox(height: 10),
              _hintLine(l10n.reportSowingsNoPeriod),
            ],
          ],
        ),
      ),
    );
  }

  Widget _builtHarvestCard(
      BuildContext context, TransactionProvider tx, AppLocalizations l10n) {
    const metrics = ReportHarvestMetrics();
    final harvests = _periodHarvests(tx);
    final byCrop = metrics.totalsByCrop(harvests, tx.crops);
    final byDestination = metrics.totalsByDestination(harvests);
    final pickupKg = metrics.pickupCostPerKg(tx.transactions, harvests);
    final staffHarvests = harvests
        .where((h) => h.workers != null || h.equivalentKg != null)
        .toList();
    final nameById = {for (final c in tx.crops) c.id: c.name};
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.reportHarvestSection,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (harvests.isEmpty)
              Text(l10n.reportNoHarvestData)
            else ...[
              Text(
                l10n.reportHarvestedTotal,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              ...byCrop.map((c) => _harvestLine(
                    label: c.name,
                    value: '${_num(c.amount)} ${c.unit}',
                    extra: '${_numKg(c.kg)} kg',
                    color: scheme.primary,
                  )),
              // Métrica de cargas para café
              if (byCrop.any((c) =>
                  c.name.toLowerCase().contains('café') ||
                  c.name.toLowerCase().contains('cafe'))) ...[
                const SizedBox(height: 6),
                _harvestLine(
                  label: '☕ ${l10n.harvestCargasLabel}',
                  value: '${_numKg(byCrop
                      .where((c) =>
                          c.name.toLowerCase().contains('café') ||
                          c.name.toLowerCase().contains('cafe'))
                      .fold<double>(0, (a, c) => a + c.kg))} kg → ${kgToCargas(byCrop
                      .where((c) =>
                          c.name.toLowerCase().contains('café') ||
                          c.name.toLowerCase().contains('cafe'))
                      .fold<double>(0, (a, c) => a + c.kg))} ${l10n.harvestCargasLabel}',
                  color: scheme.primary,
                  bold: true,
                ),
                Text(
                  l10n.harvestCargasNote,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                l10n.reportHarvestDestinations,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              ...byDestination.entries.map((e) => _harvestLine(
                    label: _destinationLabel(e.key, l10n),
                    value: _num(e.value),
                    color: scheme.onSurfaceVariant,
                  )),
              if (pickupKg != null) ...[
                const SizedBox(height: 8),
                _harvestLine(
                  label: l10n.reportPickupCostPerKg,
                  help: 'costo',
                  value: formatMoneyFor(context, pickupKg,
                      currency: _effectiveCurrency),
                  bold: true,
                ),
              ],
              // Personal y kilos por cosecha (si se registraron).
              if (staffHarvests.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.reportHarvestStaff,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                ...staffHarvests.map((h) {
                  final name = h.cropId == null
                      ? l10n.cropUnspecified
                      : (nameById[h.cropId] ?? h.cropId!);
                  final parts = <String>[
                    if (h.workers != null)
                      '👷 ${l10n.harvestWorkersCount(h.workers!)}',
                    if (h.equivalentKg != null)
                      '≈ ${_numKg(h.equivalentKg!)} kg',
                  ];
                  return _harvestLine(
                    label: '${_fmtDate(h.date)} · $name',
                    value: parts.join(' · '),
                    color: scheme.onSurfaceVariant,
                  );
                }),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _builtPayrollCard(
      BuildContext context, TransactionProvider tx, AppLocalizations l10n) {
    final summary = const ReportPayrollMetrics().payroll(_recordsFor(tx));
    if (summary.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.reportPayrollSection,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...summary.rows.map((r) => _harvestLine(
                  label: r.provider.isEmpty
                      ? l10n.reportPayrollUnnamed
                      : r.provider,
                  extra: r.days > 0
                      ? '${_num(r.days)} ${l10n.reportPayrollDays.toLowerCase()}'
                      : null,
                  value: formatMoneyFor(context, r.subtotal,
                      currency: _effectiveCurrency),
                )),
            const Divider(height: 16),
            _harvestLine(
              label: l10n.reportPayrollTotal,
              help: 'nómina',
              value: formatMoneyFor(context, summary.total,
                  currency: _effectiveCurrency),
              bold: true,
            ),
            _harvestLine(
              label: l10n.reportPayrollEmployees(summary.distinctEmployees),
              value: '',
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _builtCashBoxCard(
      BuildContext context, TransactionProvider tx, AppLocalizations l10n) {
    final rows = const ReportPayrollMetrics().cashBoxByMonth(
      periodTx: _recordsFor(tx),
      budget: tx.settings.cajaMenorMensual,
      period: _reportPeriod,
      year: _year,
      month: _reportPeriodArg,
    );
    if (rows.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final multiYear = rows.map((r) => r.year).toSet().length > 1;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.cashBoxTitle,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  tooltip: l10n.glossaryTitle,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => showTerminologyGuide(context,
                      highlight: 'caja menor'),
                  icon: const Icon(Icons.info_outline, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...rows.map((r) {
              final monthLabel = multiYear
                  ? '${l10n.monthFull[r.month - 1]} ${r.year}'
                  : l10n.monthFull[r.month - 1];
              final negative = r.balance < 0;
              String money(double v) =>
                  formatMoneyFor(context, v, currency: _effectiveCurrency);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _harvestLine(
                      label: monthLabel,
                      extra: l10n.reportCashBoxBalance,
                      value: money(r.balance),
                      color: negative ? scheme.error : scheme.primary,
                      bold: true,
                    ),
                    Text(
                      '${l10n.reportCashBoxBudget} ${money(r.budget)}'
                      ' · ${l10n.cashBoxLabor} ${money(r.labor)}'
                      ' · ${l10n.cashBoxExtras} ${money(r.extras)}'
                      ' · ${l10n.jornalTotalLabel} ${money(r.total)}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _builtSoldVsHarvestedCard(
      BuildContext context, TransactionProvider tx, AppLocalizations l10n) {
    const metrics = ReportHarvestMetrics();
    final rows = metrics.soldVsHarvested(
        tx.transactions, _periodHarvests(tx), tx.crops, DateTime.now());
    if (rows.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.reportSoldVsHarvested,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...rows.map((r) {
              final mismatch = r.soldKg > r.harvestedKg * 1.1;
              final color = mismatch ? scheme.error : scheme.primary;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.name,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    _harvestLine(
                        label: l10n.reportSoldKg,
                        value: _numKg(r.soldKg),
                        color: color),
                    _harvestLine(
                        label: l10n.reportHarvestedKg,
                        value: _numKg(r.harvestedKg),
                        color: scheme.onSurfaceVariant),
                    if (mismatch) ...[
                      const SizedBox(height: 2),
                      Text(
                        r.harvestedKg > 0
                            ? l10n.soldVsHarvestedMismatch(_pct(
                                ((r.soldKg - r.harvestedKg) /
                                        r.harvestedKg) *
                                    100))
                            : l10n.soldVsHarvestedNoHarvest,
                        style: TextStyle(
                          fontSize: 11,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _builtRecommendationsCard(
      BuildContext context, TransactionProvider tx, AppLocalizations l10n) {
    final alerts = const AlertService().evaluate(
      tx.transactions,
      tx.crops,
      l10n,
      harvests: tx.harvests,
      sowings: tx.sowings,
    );
    final recommendations =
        const RecommendationService().derive(alerts, 4);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.reportWhatsNext,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (recommendations.isEmpty)
              Text(l10n.reportNoRecommendations)
            else
              ...[
                for (var i = 0; i < recommendations.length; i++) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 11,
                          backgroundColor: _severityColor(
                              recommendations[i].severity, scheme),
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                recommendations[i].title,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                recommendations[i].message,
                                style: const TextStyle(
                                    fontSize: 12, height: 1.3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i < recommendations.length - 1)
                    Divider(height: 8, color: scheme.outlineVariant),
                ],
              ],
          ],
        ),
      ),
    );
  }

  Color _severityColor(AlertSeverity s, ColorScheme scheme) => switch (s) {
        AlertSeverity.danger => scheme.error,
        AlertSeverity.warning => const Color(0xFFF9A825),
        AlertSeverity.info => const Color(0xFF1976D2),
      };

  String _num(double v) => v % 1 == 0
      ? v.toStringAsFixed(0)
      : v.toStringAsFixed(2);

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _numKg(double v) => v >= 100
      ? v.toStringAsFixed(0)
      : v.toStringAsFixed(v % 1 == 0 ? 0 : 2);

  Widget _harvestLine(
      {required String label,
      required String value,
      String? extra,
      Color? color,
      bool bold = false,
      String? help}) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                      color: color ?? Colors.grey.shade700,
                    ),
                  ),
                ),
                if (help != null) ...[
                  const SizedBox(width: 4),
                  Tooltip(
                    message: l10n.glossaryTitle,
                    child: InkWell(
                      onTap: () =>
                          showTerminologyGuide(context, highlight: help),
                      borderRadius: BorderRadius.circular(12),
                      child: const Icon(
                        Icons.help_outline,
                        size: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (extra != null) ...[
            Text(
              extra,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  String _destinationLabel(HarvestDestination d, AppLocalizations l10n) =>
      switch (d) {
        HarvestDestination.vendido => l10n.harvestDstVendido,
        HarvestDestination.almacenado => l10n.harvestDstAlmacenado,
        HarvestDestination.perdida => l10n.harvestDstPerdida,
      };

  Future<void> _export(TransactionProvider tx, AppLocalizations l10n) async {
    setState(() => _exporting = true);
    try {
      final svc = PdfExportService();
      final bytes = await svc.buildReport(
        settings: tx.settings,
        transactions: tx.transactions,
        crops: tx.crops,
        year: _year,
        month: _mode == _PeriodMode.month
            ? _month
            : (_mode == _PeriodMode.week ? _week : null),
        period: switch (_mode) {
          _PeriodMode.week => ReportPeriod.week,
          _PeriodMode.month => ReportPeriod.month,
          _PeriodMode.year => ReportPeriod.year,
          _PeriodMode.yearToDate => ReportPeriod.yearToDate,
        },
        periodName: _periodLabel(l10n),
        l10n: l10n,
        harvests: tx.harvests,
        sowings: tx.sowings,
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

  Future<void> _exportExcel(
      TransactionProvider tx, AppLocalizations l10n) async {
    setState(() => _exportingExcel = true);
    try {
      final svc = ExcelExportService();
      final bytes = svc.buildReport(
        settings: tx.settings,
        transactions: tx.transactions,
        crops: tx.crops,
        year: _year,
        month: _mode == _PeriodMode.month
            ? _month
            : (_mode == _PeriodMode.week ? _week : null),
        period: switch (_mode) {
          _PeriodMode.week => ReportPeriod.week,
          _PeriodMode.month => ReportPeriod.month,
          _PeriodMode.year => ReportPeriod.year,
          _PeriodMode.yearToDate => ReportPeriod.yearToDate,
        },
        periodName: _periodLabel(l10n),
        l10n: l10n,
        harvests: tx.harvests,
        sowings: tx.sowings,
      );

      final fileName =
          '${l10n.pdfFileNamePrefix}_$_year-${(_month + 1).toString().padLeft(2, '0')}.xlsx';
      final result = await SharePlus.instance.share(ShareParams(
        files: [
          XFile.fromData(Uint8List.fromList(bytes),
              mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
              name: fileName),
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
      if (mounted) setState(() => _exportingExcel = false);
    }
  }

  Future<void> _exportBalance(
      TransactionProvider tx, AppLocalizations l10n) async {
    setState(() => _exportingBalance = true);
    try {
      final svc = ExcelExportService();
      final bytes = svc.buildBalanceTemplate(
        settings: tx.settings,
        transactions: tx.transactions,
        year: _year,
        periodName: _periodLabel(l10n),
        l10n: l10n,
      );

      final fileName =
          '${l10n.pdfFileNamePrefix}_balance_$_year.csv';
      final result = await SharePlus.instance.share(ShareParams(
        files: [
          XFile.fromData(bytes,
              mimeType: 'text/csv', name: fileName),
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
      if (mounted) setState(() => _exportingBalance = false);
    }
  }

  /// Tarjeta de "Estado de resultados".
  ///
  /// Con **una sola moneda** pinta exactamente lo de siempre. Si el período
  /// mezcla monedas:
  ///  - sin tasa disponible (A) → no se imprimen ingresos, gastos ni
  ///    resultado globales (serían cifras falsas): se muestran los totales
  ///    de cada moneda por separado.
  ///  - con todas las tasas (B) → un único total convertido a la moneda de
  ///    Ajustes, marcado como "al cambio de hoy".
  Widget _statementCard(
    BuildContext context,
    TransactionProvider tx,
    AppLocalizations l10n,
    List<Transaction> records,
    PeriodCurrencyTotals periodTotals,
    ConvertedPeriodTotals? converted,
  ) {
    final showMixedTotals = periodTotals.isMixed && converted == null;
    // Con dos o más monedas en el período, las filas de categoría nunca
    // suman ni calculan % sobre un total que cruzaría monedas.
    final mixedRows = periodTotals.isMixed;

    final expenses = records
        .where((t) => t.type.isExpense)
        .fold<double>(0, (a, t) => a + t.amount);
    final incomes = records
        .where((t) => !t.type.isExpense)
        .fold<double>(0, (a, t) => a + t.amount);
    final totalIncomes = converted?.incomes ?? incomes;
    final totalExpenses = converted?.expenses ?? expenses;
    final balance = totalIncomes - totalExpenses;
    final incomeRows = _categoryRows(tx, TransactionType.income, l10n);
    final expenseRows = _categoryRows(tx, TransactionType.expense, l10n);
    final margen = totalIncomes > 0 ? (balance / totalIncomes) * 100 : null;
    final ratio = totalIncomes > 0 ? (totalExpenses / totalIncomes) * 100 : null;

    // P2: precio de venta por kilo vs costo por kilo. Dos datos que ya
    // existen en la app (solo salían en PDF y Excel, nunca en pantalla).
    const metrics = ReportHarvestMetrics();
    final costByKg =
        metrics.periodCostPerKg(totalExpenses, _periodHarvests(tx));
    final priceByKg = metrics.avgSalePricePerKg(records);

    final breakdown = CurrencyBreakdown(
      incomes: periodTotals.incomes,
      expenses: periodTotals.expenses,
      l10n: l10n,
      locale: tx.settings.locale,
    );

    return Card(
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
            // Moneda mixta sin tasa: los totales van por moneda arriba del
            // detalle y no se pinta ninguna cifra global.
            if (showMixedTotals) ...[
              breakdown,
              const SizedBox(height: 12),
            ],
            if (!showMixedTotals)
              _statementLine(context, tx, l10n.incomeLabel, totalIncomes,
                  Theme.of(context).colorScheme.primary),
            if (incomeRows.isEmpty)
              _hintLine(l10n.noIncomePeriod),
            ...incomeRows.map((r) => _categoryLine(
                context, tx, r, incomes, Theme.of(context).colorScheme.primary,
                mixed: mixedRows)),
            const SizedBox(height: 6),
            if (!showMixedTotals)
              _statementLine(context, tx, l10n.operatingExpensesLabel,
                  -totalExpenses, Theme.of(context).colorScheme.error),
            if (expenseRows.isEmpty)
              _hintLine(l10n.noExpensesPeriod),
            ..._groupedExpenseLines(
                context, tx, l10n, expenseRows, expenses,
                mixed: mixedRows),
            if (!showMixedTotals) ...[
              const Divider(height: 24),
              _resultLine(context, tx, l10n, balance,
                  valueLabel: converted == null
                      ? null
                      : l10n.currencyConvertedTotal(
                          _effectiveCurrency,
                          _accounting(context, tx, balance,
                              currency: _effectiveCurrency),
                        )),
              if (converted != null) ...[
                const SizedBox(height: 4),
                _hintLine(l10n.currencyRateNote),
              ],
              const SizedBox(height: 10),
              _metricLine(
                context,
                l10n.marginLabel,
                margen != null ? '${_pct(margen)}%' : '—',
                signal: signalOfMargin(marginVerdict(margen)),
                caption: _marginCaption(l10n, margen),
              ),
              _metricLine(
                context,
                l10n.ratioLabel,
                ratio != null ? '${_pct(ratio)}%' : '—',
                signal: signalOfRatio(ratioVerdict(ratio)),
                caption: _ratioCaption(l10n, ratio),
              ),
              // Si no hay nada que comparar (ni cosecha ni kilos en las
              // ventas) la línea se omite en vez de llenar el reporte de
              // "no se puede calcular".
              if (costByKg != null || priceByKg != null)
                _metricLine(
                  context,
                  l10n.metricCostPriceLabel,
                  priceByKg != null
                      ? _accounting(context, tx, priceByKg,
                          currency: _effectiveCurrency)
                      : '—',
                  signal: signalOfCostPrice(
                      costPriceVerdict(costByKg, priceByKg)),
                  caption: _costPriceCaption(
                    l10n,
                    costPriceVerdict(costByKg, priceByKg),
                    costByKg == null
                        ? ''
                        : _accounting(context, tx, costByKg,
                            currency: _effectiveCurrency),
                  ),
                ),
            ],
            // Con tasa, el desglose por moneda queda como referencia.
            if (periodTotals.isMixed && !showMixedTotals) ...[
              const SizedBox(height: 12),
              breakdown,
            ],
          ],
        ),
      ),
    );
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
            _accounting(context, tx, value, currency: _effectiveCurrency),
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

  /// Fila de una categoría del estado de resultados.
  ///
  /// [mixed] = el período mezcla monedas: entonces no se calcula un % sobre
  /// un total falso ni se pinta una cifra única; cada moneda va con su
  /// código al lado.
  Widget _categoryLine(BuildContext context, TransactionProvider tx,
      _CategoryRow row, double groupTotal, Color color,
      {required bool mixed}) {
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
          if (!mixed) ...[
            Text(
              '${_pct(pct)}%',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(width: 12),
          ],
          Text(
            mixed
                ? _byCurrencyText(
                    tx, row.byCurrency, negative: row.isExpense)
                : _accounting(context, tx, row.isExpense ? -row.amount : row.amount,
                    currency: _effectiveCurrency),
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

  /// Montos por moneda en una sola línea: `$5.000 COP · €200 EUR`.
  /// Nunca se suman entre sí: cada moneda conserva su cifra y su código.
  String _byCurrencyText(TransactionProvider tx, Map<String, double> byCurrency,
      {bool negative = false}) {
    final entries = byCurrency.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries
        .map((e) =>
            '${formatAmount(negative ? -e.value : e.value, currency: e.key, locale: tx.settings.locale)} ${e.key}')
        .join(' · ');
  }

  /// P5 — los gastos agrupados en bloques (producción / venta / fijos /
  /// otros). Cada bloque muestra su subtotal y **debajo sigue el detalle**:
  /// se agrupa sin esconder ninguna de las categorías existentes.
  ///
  /// El porcentaje de cada fila sigue calculándose sobre el total de gastos
  /// del período, igual que antes, para que la cifra no cambie de significado.
  List<Widget> _groupedExpenseLines(
      BuildContext context,
      TransactionProvider tx,
      AppLocalizations l10n,
      List<_CategoryRow> rows,
      double expensesTotal,
      {required bool mixed}) {
    if (rows.isEmpty) return const [];

    final byGroup = <ExpenseGroup, List<_CategoryRow>>{};
    for (final row in rows) {
      byGroup.putIfAbsent(expenseGroupOf(row.key), () => []).add(row);
    }

    String groupLabel(ExpenseGroup g) => switch (g) {
          ExpenseGroup.produccion => l10n.expenseGroupProduccion,
          ExpenseGroup.venta => l10n.expenseGroupVenta,
          ExpenseGroup.fijos => l10n.expenseGroupFijos,
          ExpenseGroup.otros => l10n.expenseGroupOtros,
        };

    const order = [
      ExpenseGroup.produccion,
      ExpenseGroup.venta,
      ExpenseGroup.fijos,
      ExpenseGroup.otros,
    ];

    final out = <Widget>[];
    for (final g in order) {
      final group = byGroup[g];
      if (group == null || group.isEmpty) continue;
      final total = group.fold<double>(0, (a, r) => a + r.amount);
      // Subtotal por moneda: la misma suma, solo que sin cruzar monedas.
      final totalByCurrency = <String, double>{};
      for (final r in group) {
        r.byCurrency.forEach((code, v) {
          totalByCurrency[code] = (totalByCurrency[code] ?? 0) + v;
        });
      }
      out.add(_groupLine(
        context,
        tx,
        label: groupLabel(g),
        amount: total,
        byCurrency: totalByCurrency,
        ofTotal: expensesTotal,
        mixed: mixed,
      ));
      out.addAll(group.map((r) => _categoryLine(
          context, tx, r, expensesTotal, Theme.of(context).colorScheme.error,
          mixed: mixed)));
    }
    return out;
  }

  /// Cabecera de un bloque de gastos: subtotal + % sobre el total del período.
  ///
  /// Con [mixed] no hay % (el total del período cruzaría monedas) y el
  /// subtotal sale moneda por moneda con su código.
  Widget _groupLine(
    BuildContext context,
    TransactionProvider tx, {
    required String label,
    required double amount,
    required Map<String, double> byCurrency,
    required double ofTotal,
    required bool mixed,
  }) {
    final pct = ofTotal > 0 ? amount / ofTotal * 100 : 0.0;
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 6, bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!mixed) ...[
            Text(
              '${_pct(pct)}%',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(width: 12),
          ],
          Text(
            mixed
                ? _byCurrencyText(tx, byCurrency, negative: true)
                : _accounting(context, tx, -amount,
                    currency: _effectiveCurrency),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  /// Cabecera de "RESULTADO DEL PERÍODO".
  ///
  /// [valueLabel] sustituye al importe pelado (se usa cuando el total viene
  /// convertido a la moneda de Ajustes: `currencyConvertedTotal`).
  Widget _resultLine(BuildContext context, TransactionProvider tx,
      AppLocalizations l10n, double balance,
      {String? valueLabel}) {
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
            valueLabel ??
                _accounting(context, tx, balance, currency: _effectiveCurrency),
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

  /// Fila de métrica con señal bueno/malo.
  ///
  /// La señal nunca es solo color: lleva icono de forma distinta (`[signal]`)
  /// y una frase en lenguaje llano (`[caption]`) que explica qué significa —
  /// es el hallazgo H1 del PRD de comprensibilidad.
  Widget _metricLine(
    BuildContext context,
    String label,
    String value, {
    MetricSignal signal = MetricSignal.none,
    String? caption,
  }) {
    final color = _signalColor(context, signal);
    final icon = switch (signal) {
      MetricSignal.positive => Icons.check_circle_outline,
      MetricSignal.neutral => Icons.info_outline,
      MetricSignal.negative => Icons.error_outline,
      MetricSignal.none => null,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
              if (icon != null) ...[
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
              ],
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: icon == null ? null : color,
                ),
              ),
            ],
          ),
          if (caption != null && caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 4),
              child: Text(
                caption,
                style: TextStyle(fontSize: 11, color: color),
              ),
            ),
        ],
      ),
    );
  }

  Color _signalColor(BuildContext context, MetricSignal signal) {
    final scheme = Theme.of(context).colorScheme;
    return switch (signal) {
      MetricSignal.positive => const Color(0xFF2E7D32),
      MetricSignal.neutral => const Color(0xFFED6C02),
      MetricSignal.negative => scheme.error,
      MetricSignal.none => Colors.grey,
    };
  }

  String _marginCaption(AppLocalizations l10n, double? margin) =>
      switch (marginVerdict(margin)) {
        MarginVerdict.good => l10n.metricMarginGood,
        MarginVerdict.fair => l10n.metricMarginFair,
        MarginVerdict.low => l10n.metricMarginLow,
        MarginVerdict.loss => l10n.metricMarginLoss,
        MarginVerdict.breakEven => l10n.metricMarginBreakEven,
        MarginVerdict.noSales => l10n.metricNoSales,
      };

  String _ratioCaption(AppLocalizations l10n, double? ratio) =>
      switch (ratioVerdict(ratio)) {
        RatioVerdict.healthy => l10n.metricRatioHealthy,
        RatioVerdict.high => l10n.metricRatioHigh,
        RatioVerdict.critical => l10n.metricRatioCritical,
        RatioVerdict.noSales => l10n.metricNoSales,
      };

  String _costPriceCaption(
          AppLocalizations l10n, CostPriceVerdict verdict, String costText) =>
      switch (verdict) {
        CostPriceVerdict.above => l10n.metricCostPriceAbove(costText),
        CostPriceVerdict.below => l10n.metricCostPriceBelow(costText),
        CostPriceVerdict.equal => l10n.metricCostPriceEqual(costText),
        CostPriceVerdict.noCost => l10n.metricCostPriceNoCost,
        CostPriceVerdict.noQty => l10n.metricCostPriceNoQty(costText),
      };

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

  String _accounting(BuildContext context, TransactionProvider tx, double value,
      {String? currency}) {
    final s = formatAmount(value.abs(),
        currency: currency ?? tx.settings.currency, locale: tx.settings.locale);
    return value < 0 ? '($s)' : s;
  }

  String _pct(double v) => v >= 10 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  List<_CategoryRow> _categoryRows(
      TransactionProvider tx, TransactionType type, AppLocalizations l10n) {
    final records = _recordsFor(tx).where((t) => t.type == type);
    // Cada categoría guarda sus montos **por moneda**: la suma con moneda
    // única es la de siempre; con mezcla solo se listan por separado.
    final totals = <String, Map<String, double>>{};
    for (final t in records) {
      // Ventas con cultivo: grupo aparte por cultivo (fila "Venta plátano").
      final key = type.isExpense ? t.category : incomeGroupKey(t.category, t.cropId);
      final byCurrency = totals.putIfAbsent(key, () => {});
      byCurrency[t.currency] = (byCurrency[t.currency] ?? 0) + t.amount;
    }
    return totals.entries.map((e) {
      final label = type.isExpense
          ? l10n.expenseCategory(e.key)
          : l10n.incomeGroupLabel(e.key, tx.crops);
      return _CategoryRow(
        label: label,
        // Solo para ordenar (con moneda mixta no es una cifra que se muestre).
        amount: e.value.values.fold<double>(0, (a, b) => a + b),
        byCurrency: Map.of(e.value),
        isExpense: type.isExpense,
        key: e.key,
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

  /// Montos de la categoría **separados por moneda** (clave = código ISO).
  final Map<String, double> byCurrency;

  /// Suma aritmética de [byCurrency]. Solo se usa para **ordenar** las
  /// filas: con moneda mixta no es una cifra que se pueda mostrar.
  final double amount;

  final bool isExpense;

  /// Clave cruda (p. ej. `fertilizante` o `venta|<cropId>`). Solo los gastos
  /// la usan: agruparlos por bloque (P5) necesita la clave, no la etiqueta.
  final String key;

  const _CategoryRow({
    required this.label,
    required this.amount,
    required this.byCurrency,
    required this.isExpense,
    this.key = '',
  });

  /// true cuando la categoría juntó más de una moneda.
  bool get isMixed => byCurrency.length > 1;
}

class _TopAccountsCard extends StatelessWidget {
  final List<Transaction> records;
  final AppLocalizations l10n;
  final String effectiveCurrency;
  final String locale;

  const _TopAccountsCard({
    required this.records,
    required this.l10n,
    required this.effectiveCurrency,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final accounts = TopAccounts.from(records);
    if (accounts.isEmpty) return const SizedBox.shrink();

    // Moneda mixta en el período: cada fila lleva sus monedas y se avisa
    // una vez, para que nadie lea una cifra global que no existe.
    final currencies = records.map((t) => t.currency).toSet();
    final mixed = currencies.length > 1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (mixed)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.monetization_on_outlined,
                        size: 16, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        l10n.currencyMixedHint(currencies.length),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (accounts.clients.isNotEmpty) ...[
              Text(
                l10n.topClientsTitle,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._rows(context, accounts.topClients(3)),
              const SizedBox(height: 14),
            ],
            if (accounts.providers.isNotEmpty) ...[
              Text(
                l10n.topProvidersTitle,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._rows(context, accounts.topProviders(3)),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _rows(
      BuildContext context, List<MapEntry<String, AccountTotal>> rows) {
    return rows.map((e) {
      // Moneda única → la cifra de siempre; mezcla → cada moneda con su
      // código, nunca un total que sume pesos con dólares.
      final amount = e.value.amount != null
          ? formatMoneyFor(context, e.value.amount!, currency: effectiveCurrency)
          : (e.value.byCurrency.entries.toList()
                ..sort((a, b) => a.key.compareTo(b.key)))
              .map((c) =>
                  '${formatAmount(c.value, currency: c.key, locale: locale)} ${c.key}')
              .join(' · ');
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${e.key} (${e.value.count})',
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              amount,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }).toList();
  }
}

class _CropRow {
  final String name;
  String currency;
  double expenses = 0;
  double incomes = 0;
  int count = 0;

  /// Gastos del período (sin borrados), para repartirlos en
  /// inversión inicial vs operación con [CropExpenseSplit].
  final List<Transaction> expenseTxs = [];
  double investment = 0;
  double operation = 0;

  _CropRow({required this.name, this.currency = 'COP'});

  double get net => incomes - expenses;
  double get roi => expenses <= 0 ? 0 : (incomes - expenses) / expenses;
  String get roiLabel =>
      expenses <= 0 ? 'â€”' : 'ROI ${(roi * 100).toStringAsFixed(0)}%';
}

class _CropBreakdownTile extends StatelessWidget {
  final _CropRow row;
  final AppLocalizations l10n;
  final String currency;
  final String locale;
  final ColorScheme scheme;

  const _CropBreakdownTile({
    required this.row,
    required this.l10n,
    required this.currency,
    required this.locale,
    required this.scheme,
  });

  static const _green = Color(0xFF2E7D32);

  String _amount(double v) =>
      formatAmount(v, currency: currency, locale: locale);

  @override
  Widget build(BuildContext context) {
    final net = row.net;
    final netColor = net >= 0 ? _green : scheme.error;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  row.name,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                row.roiLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: row.roi < -0.30 ? scheme.error : scheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.movementsCount(row.count),
            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          _miniLine(
            icon: Icons.trending_down,
            iconColor: scheme.onSurfaceVariant,
            label: l10n.cropBreakdownSummaryG,
            labelColor: scheme.onSurfaceVariant,
            value: _amount(row.expenses),
            valueColor: scheme.onSurfaceVariant,
          ),
          // L2.1 — inversión inicial y operación suman exactamente el
          // "Gastos" de arriba; solo se piden si hay monto que mostrar.
          if (row.investment > 0)
            _miniLine(
              icon: Icons.grass_outlined,
              iconColor: scheme.onSurfaceVariant,
              label: l10n.cropBreakdownInvestment,
              labelColor: scheme.onSurfaceVariant,
              value: _amount(row.investment),
              valueColor: scheme.onSurfaceVariant,
            ),
          if (row.operation > 0)
            _miniLine(
              icon: Icons.agriculture_outlined,
              iconColor: scheme.onSurfaceVariant,
              label: l10n.cropBreakdownOperation,
              labelColor: scheme.onSurfaceVariant,
              value: _amount(row.operation),
              valueColor: scheme.onSurfaceVariant,
            ),
          _miniLine(
            icon: Icons.trending_up,
            iconColor: _green,
            label: l10n.cropBreakdownSummaryI,
            labelColor: scheme.onSurfaceVariant,
            value: _amount(row.incomes),
            valueColor: _green,
          ),
          const SizedBox(height: 2),
          const Divider(height: 12),
          _miniLine(
            icon: net >= 0
                ? Icons.savings_outlined
                : Icons.warning_amber_outlined,
            iconColor: netColor,
            label: l10n.cropBreakdownSummaryR,
            labelColor: netColor,
            value: _amount(net),
            valueColor: netColor,
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _miniLine({
    required IconData icon,
    required Color iconColor,
    required String label,
    required Color labelColor,
    required String value,
    required Color valueColor,
    bool bold = false,
  }) {
    final w = TextStyle(
      fontSize: 12,
      color: labelColor,
      fontWeight: bold ? FontWeight.bold : FontWeight.w500,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 5),
          Expanded(
            child: Text(label, style: w),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

