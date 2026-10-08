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

      // Monedas del período de este cultivo: si mezcla, el margen no se
      // calcula (sería restar pesos con dólares) y se avisa con el recuento.
      // Lo que sí es de una sola moneda sigue mostrándose, con esa moneda.
      final incomeCurrencies = periodTxs
          .where((t) => !t.deleted && !t.type.isExpense)
          .map((t) => t.currency)
          .toSet();
      final expenseCurrencies = periodTxs
          .where((t) => !t.deleted && t.type.isExpense)
          .map((t) => t.currency)
          .toSet();
      final moneyCurrencies = {...incomeCurrencies, ...expenseCurrencies};
      final moneyMixed = moneyCurrencies.length > 1;
      // Si el período mezcla y un lado es de una sola moneda, su cifra es
      // válida: se muestra con ESA moneda (no con la de Ajustes). Con una
      // sola moneda en el período no se toca nada, va como siempre.
      final incomeCurrency = moneyMixed && incomeCurrencies.length == 1
          ? incomeCurrencies.first
          : null;
      final expenseCurrency = moneyMixed && expenseCurrencies.length == 1
          ? expenseCurrencies.first
          : null;

      final yieldPerHa = metrics.yieldPerArea(periodHs, c.areaHa);
      final revenue = metrics.revenuePerHa(periodTxs, c.areaHa);
      final cost = metrics.costPerHa(periodTxs, c.areaHa);
      // El margen resta ingresos y gastos: solo es cierto si las dos cifras
      // están en la misma moneda (o no hay ninguna de las dos).
      final margin = moneyMixed ? null : metrics.marginPerHa(revenue, cost);
      final hasKpis = yieldPerHa != null ||
          revenue != null ||
          cost != null ||
          moneyMixed;
      final hasInvestment = c.establishmentCost != null && c.establishmentCost! > 0;
      if (!hasKpis && !hasInvestment) continue;

      final cumulative = _cumulativeMargin(c.id);
      rows.add(_CropMetrics._(
        crop: c,
        yieldPerHa: yieldPerHa,
        revenuePerHa: revenue,
        costPerHa: cost,
        marginPerHa: margin,
        periodCurrencies: moneyCurrencies,
        incomeCurrency: incomeCurrency,
        expenseCurrency: expenseCurrency,
        cumulativeMargin: cumulative.margin,
        cumulativeCurrencies: cumulative.currencies,
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
          // Cada cifra de dinero solo se pinta si salió de una sola moneda y
          // con ESA moneda al lado; el aviso explica lo que no se suma.
          if (r.revenuePerHa != null)
            _line(l10n.perHaRevenueLabel,
                _money(context, r.revenuePerHa!, r.incomeCurrency)),
          if (r.costPerHa != null)
            _line(l10n.perHaCostLabel,
                _money(context, r.costPerHa!, r.expenseCurrency)),
          if (r.marginPerHa != null)
            _line(
              l10n.perHaMarginLabel,
              _money(context, r.marginPerHa!, null),
              bold: true,
              color: r.marginPerHa! < 0 ? scheme.error : scheme.primary,
            ),
          if (r.periodMixed)
            _hint(l10n.currencyMixedHint(r.periodCurrencies.length)),
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

    // Margen histórico en moneda mixta: no hay un porcentaje cierto, se
    // muestra la inversión con el aviso en vez de un % inventado.
    if (r.cumulativeMixed) {
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
            _hint(l10n.currencyMixedHint(r.cumulativeCurrencies.length)),
          ],
        ),
      );
    }

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

  /// Formato de una cifra del panel.
  ///
  /// Sin [currency] usa el formato de siempre (período de una sola moneda).
  /// Con [currency] —solo en período mixto— la cifra lleva la moneda en la
  /// que está realmente medida y su código al lado.
  String _money(BuildContext context, double value, String? currency) {
    if (currency == null) return formatMoney(context, value);
    return '${formatMoneyFor(context, value, currency: currency)} $currency';
  }

  /// Aviso de moneda mixta: explica por qué no hay una cifra única, sin
  /// inventar ningún total.
  Widget _hint(String text) {    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.monetization_on_outlined, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  /// Margen histórico del cultivo **por moneda**.
  ///
  /// Si las operaciones mezclan monedas, el margen llega como null junto con
  /// las monedas encontradas: la UI muestra el aviso en vez de una cifra
  /// falsa sumando pesos con dólares.
  ({double? margin, Set<String> currencies}) _cumulativeMargin(String cropId) {
    final byCurrency = <String, double>{};
    for (final t in allTransactions) {
      if (t.deleted || t.cropId != cropId) continue;
      final signed = t.type.isExpense ? -t.amount : t.amount;
      byCurrency[t.currency] = (byCurrency[t.currency] ?? 0) + signed;
    }
    if (byCurrency.isEmpty) return (margin: null, currencies: const {});
    if (byCurrency.length > 1) {
      return (margin: null, currencies: byCurrency.keys.toSet());
    }
    return (margin: byCurrency.values.first, currencies: byCurrency.keys.toSet());
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

  /// Monedas de los movimientos de dinero del período de este cultivo.
  final Set<String> periodCurrencies;

  /// Moneda del lado de ingresos si el período mezcla y ese lado es de una
  /// sola moneda (null = no toca etiquetar: o es moneda única o está mezclado).
  final String? incomeCurrency;

  /// Igual que [incomeCurrency] para el lado de gastos.
  final String? expenseCurrency;

  /// Monedas de los movimientos históricos (todos) de este cultivo.
  final Set<String> cumulativeCurrencies;

  const _CropMetrics._({
    required this.crop,
    required this.yieldPerHa,
    required this.revenuePerHa,
    required this.costPerHa,
    required this.marginPerHa,
    required this.cumulativeMargin,
    required this.yearsWithData,
    this.periodCurrencies = const {},
    this.incomeCurrency,
    this.expenseCurrency,
    this.cumulativeCurrencies = const {},
  });

  /// El período de este cultivo toca más de una moneda.
  bool get periodMixed => periodCurrencies.length > 1;

  /// El histórico de este cultivo toca más de una moneda.
  bool get cumulativeMixed => cumulativeCurrencies.length > 1;
}