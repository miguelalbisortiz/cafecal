import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/crop.dart';
import '../models/harvest.dart';
import '../models/transaction.dart';
import '../services/report_harvest_metrics.dart';
import '../utils/format.dart';

/// Panel "Por hectárea" del reporte: normaliza producción y finanzas de cada
/// cultivo por su área (kg/ha, ventas/ha, gastos/ha, margen/ha) y, si el
/// usuario registró el costo del establecimiento, muestra cuánto de esa
/// inversión se ha recuperado y en cuántos años (aprox.) se pagaría.
/// Funciona con datos ya registrados; si falta área o datos, oculta en vez
/// de inventar números (regla de oro).
class PerHectarePanel extends StatelessWidget {
  final List<Crop> crops;
  final List<Transaction> periodTransactions;
  final List<Harvest> periodHarvests;
  final List<Transaction> allTransactions;

  const PerHectarePanel({
    super.key,
    required this.crops,
    required this.periodTransactions,
    required this.periodHarvests,
    required this.allTransactions,
  });

  @override
  Widget build(BuildContext context) {
    const metrics = ReportHarvestMetrics();
    final l10n = AppLocalizations.of(context)!;

    final withArea = crops.where((c) => c.areaHa != null && c.areaHa! > 0);
    final rows = <_CropMetrics>[];
    for (final c in withArea) {
      final periodTxs =
          periodTransactions.where((t) => t.cropId == c.id).toList();
      final periodHs = periodHarvests.where((h) => h.cropId == c.id).toList();

      final yieldPerHa = metrics.yieldPerArea(periodHs, c.areaHa);
      final revenue = metrics.revenuePerHa(periodTxs, c.areaHa);
      final cost = metrics.costPerHa(periodTxs, c.areaHa);
      final margin = metrics.marginPerHa(revenue, cost);
      final hasKpis = yieldPerHa != null || revenue != null || cost != null;
      final hasInvestment = c.establishmentCost != null && c.establishmentCost! > 0;
      if (!hasKpis && !hasInvestment) continue;

      rows.add(_CropMetrics._(
        crop: c,
        yieldPerHa: yieldPerHa,
        revenuePerHa: revenue,
        costPerHa: cost,
        marginPerHa: margin,
        cumulativeMargin: _cumulativeMargin(c.id),
        yearsWithData: _yearsWithData(c.id),
      ));
    }

    final cropsWithData = crops.where((c) =>
        allTransactions.any((t) => t.cropId == c.id) ||
        periodHarvests.any((h) => h.cropId == c.id));
    final eligibleIsEmpty = rows.isEmpty;
    final anyData = cropsWithData.isNotEmpty;

    if (eligibleIsEmpty && !anyData) return const SizedBox.shrink();
    if (eligibleIsEmpty && anyData) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.square_foot_outlined, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(l10n.perHaNoAreaHint,
                    style: const TextStyle(fontSize: 12, height: 1.3)),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.perHaSection,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...rows.map((r) => _cropBlock(context, metrics, r, l10n)),
          ],
        ),
      ),
    );
  }

  Widget _cropBlock(BuildContext context, ReportHarvestMetrics metrics,
      _CropMetrics r, AppLocalizations l10n) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${r.crop.name} · ${r.crop.areaHa!.toStringAsFixed(2)} ha',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          if (r.yieldPerHa != null)
            _line(
              l10n.perHaYieldLabel,
              '${r.yieldPerHa!.toStringAsFixed(1)} kg/ha',
              color: scheme.primary,
            ),
          if (r.revenuePerHa != null)
            _line(l10n.perHaRevenueLabel, formatMoney(context, r.revenuePerHa!)),
          if (r.costPerHa != null)
            _line(l10n.perHaCostLabel, formatMoney(context, r.costPerHa!)),
          if (r.marginPerHa != null)
            _line(
              l10n.perHaMarginLabel,
              formatMoney(context, r.marginPerHa!),
              bold: true,
              color: r.marginPerHa! < 0 ? scheme.error : scheme.primary,
            ),
          if (r.crop.establishmentCost != null && r.crop.establishmentCost! > 0)
            _recoveryBlock(context, r, l10n),
        ],
      ),
    );
  }

  Widget _recoveryBlock(BuildContext context, _CropMetrics r,
      AppLocalizations l10n) {
    const metrics = ReportHarvestMetrics();
    final scheme = Theme.of(context).colorScheme;
    final investment = r.crop.establishmentCost!;
    final recovery = metrics.recoveryRate(investment, r.cumulativeMargin);
    final avgMargin = (r.cumulativeMargin != null && r.yearsWithData! > 0)
        ? r.cumulativeMargin! / r.yearsWithData!
        : null;
    final breakeven = metrics.breakevenYears(investment, avgMargin ?? 0);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _line(l10n.perHaInvestmentLabel, formatMoney(context, investment),
              bold: true),
          _line(
            l10n.perHaRecoveredLabel,
            recovery == null
                ? l10n.perHaRecoveryPending
                : '${(recovery * 100).round()}%',
            color: recovery != null && recovery >= 1
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
          if (breakeven != null)
            _line(
              l10n.perHaPaybackLabel,
              l10n.perHaPaybackYears(breakeven.toStringAsFixed(1)),
              color: scheme.primary,
            ),
        ],
      ),
    );
  }

  Widget _line(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  double? _cumulativeMargin(String cropId) {
    double margin = 0;
    var has = false;
    for (final t in allTransactions) {
      if (t.deleted || t.cropId != cropId) continue;
      has = true;
      if (t.type.isExpense) {
        margin -= t.amount;
      } else {
        margin += t.amount;
      }
    }
    return has ? margin : null;
  }

  int? _yearsWithData(String cropId) {
    final years = <int>{};
    for (final t in allTransactions) {
      if (t.deleted || t.cropId != cropId) continue;
      years.add(t.date.year);
    }
    return years.isEmpty ? null : years.length;
  }
}

class _CropMetrics {
  final Crop crop;
  final double? yieldPerHa;
  final double? revenuePerHa;
  final double? costPerHa;
  final double? marginPerHa;
  final double? cumulativeMargin;
  final int? yearsWithData;

  const _CropMetrics._({
    required this.crop,
    required this.yieldPerHa,
    required this.revenuePerHa,
    required this.costPerHa,
    required this.marginPerHa,
    required this.cumulativeMargin,
    required this.yearsWithData,
  });
}