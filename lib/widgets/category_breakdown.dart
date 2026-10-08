import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/strings.dart';
import '../models/categories.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../services/crop_totals.dart';
import '../services/currency_totals.dart';
import '../utils/format.dart';

/// Muestra las categorías de un período ordenadas de mayor a menor.
/// Siempre enseña las 5 más grandes; con más de 5 ofrece expandir el resto
/// ("Ver N más") para que la sección no crezca sin límite con más datos.
class CategoryBreakdown extends StatefulWidget {
  final int year;
  final int? month;
  final TransactionType type;
  final String? periodLabel;
  final VoidCallback? onAddTap;

  /// Cuántas categorías se muestran antes de plegar el resto.
  final int topCount;

  const CategoryBreakdown({
    super.key,
    required this.year,
    this.month,
    required this.type,
    this.periodLabel,
    this.onAddTap,
    this.topCount = 5,
  });

  @override
  State<CategoryBreakdown> createState() => _CategoryBreakdownState();
}

class _CategoryBreakdownState extends State<CategoryBreakdown> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final tx = context.watch<TransactionProvider>();
    final l10n = AppLocalizations.of(context)!;
    final rows = _groupByCategory(tx, l10n);

    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              widget.type.isExpense
                  ? Icons.trending_down
                  : Icons.payments_outlined,
              size: 40,
              color: Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              widget.type.isExpense
                  ? l10n.noExpensesPeriod
                  : l10n.noIncomesPeriod,
            ),
            if (widget.onAddTap != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: widget.onAddTap,
                icon: const Icon(Icons.add),
                label: Text(widget.type.isExpense
                    ? l10n.recordExpense
                    : l10n.recordIncome),
              ),
            ],
          ],
        ),
      );
    }

    final total = rows.fold<double>(0, (s, r) => s + r.amount);
    // Totales por moneda del mismo período: si mezcla monedas no se suman.
    final byCurrency = amountsByCurrency(
        tx.where(type: widget.type, year: widget.year, month: widget.month));
    final mixed = byCurrency.length > 1;
    // Solo con moneda única hay un total y un máximo comparables entre filas.
    final maxAmount = mixed ? 0.0 : rows.first.amount;
    final typeColor =
        widget.type.isExpense ? Colors.red.shade600 : Colors.green.shade700;
    final hasMore = rows.length > widget.topCount;
    final visible = _expanded ? rows : rows.take(widget.topCount).toList();
    final hidden = rows.length - widget.topCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(
                widget.type.isExpense
                    ? l10n.expensesByCategory
                    : l10n.incomesByCategory,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            if (widget.periodLabel != null)
              Text(
                widget.periodLabel!,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration:
                  BoxDecoration(color: typeColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              // Moneda mixta: no se suma una sola cifra (sería falsa),
              // se lista el total de cada moneda por separado.
              mixed
                  ? '${l10n.currencyMixedHint(byCurrency.length)}: ${byCurrency.entries.map((e) => '${formatAmount(e.value, currency: e.key, locale: tx.settings.locale)} ${e.key}').join(' · ')}'
                  : l10n.categoryBreakdownTotal(formatMoney(context, total)),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: typeColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: visible.map((row) {
              // Con moneda mixta no hay % sobre un total falso ni barra
              // proporcional: la fila lista sus montos moneda por moneda.
              final width =
                  mixed ? 0.0 : (row.amount / maxAmount).clamp(0.04, 1.0);
              final pct = total > 0 ? row.amount / total * 100 : 0.0;
              final pctText =
                  pct >= 10 ? pct.toStringAsFixed(0) : pct.toStringAsFixed(1);
              final amountText = mixed
                  ? byCurrencyText(
                      row.byCurrency,
                      (v, c) =>
                          formatAmount(v, currency: c, locale: tx.settings.locale),
                    )
                  : formatMoney(context, row.amount);
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${row.icon} ${row.label}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!mixed) ...[
                          Text(
                            '$pctText%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            amountText,
                            style: TextStyle(
                              fontSize: mixed ? 12 : 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Sin barra que sugiera proporciones sobre monedas que
                    // no se pueden sumar.
                    if (!mixed) ...[
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: LinearProgressIndicator(
                          value: width,
                          minHeight: 10,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation(row.color),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        if (hasMore)
          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _expanded = !_expanded),
              icon: Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                size: 18,
              ),
              label: Text(_expanded
                  ? l10n.categoryBreakdownShowLess
                  : l10n.categoryBreakdownShowMore(hidden)),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: typeColor,
              ),
            ),
          ),
      ],
    );
  }

  List<_CategoryRow> _groupByCategory(
      TransactionProvider provider, AppLocalizations l10n) {
    final records =
        provider.where(type: widget.type, year: widget.year, month: widget.month);
    final crops = provider.crops;
    final isExpense = widget.type.isExpense;
    // Cada categoría guarda sus montos **por moneda** y ya viene ordenada de
    // mayor a menor (la suma que ordena no se muestra nunca).
    final totals = groupAmountsByCurrency(
      records,
      keyOf: (t) =>
          isExpense ? t.category : incomeGroupKey(t.category, t.cropId),
    );

    final rows = totals.entries.map((e) {
      final key = e.key;
      String icon;
      String color;
      String label;
      if (isExpense) {
        final cat = expenseCategories.firstWhere((c) => c.key == key,
            orElse: () => const ExpenseCategory(
                key: 'otro', name: 'Otro', icon: '📦', color: '#757575'));
        icon = cat.icon;
        color = cat.color;
        label = l10n.expenseCategory(key);
      } else {
        final sep = key.indexOf('|');
        if (sep != -1) {
          // Grupo "Venta <cultivo>": toma icono y color del cultivo.
          final crop = cropOf(crops, key.substring(sep + 1));
          icon = crop?.icon ?? '💰';
          color = crop?.color ?? '#2E7D32';
        } else {
          final cat = incomeCategories.firstWhere((c) => c.key == key,
              orElse: () => const IncomeCategory(
                  key: 'venta_otro',
                  name: 'Venta otros',
                  icon: '💰',
                  color: '#2E7D32'));
          icon = cat.icon;
          color = cat.color;
        }
        label = l10n.incomeGroupLabel(key, crops);
      }
      return _CategoryRow(
        label: label,
        icon: icon,
        color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
        byCurrency: e.value,
      );
    }).toList();

    return rows;
  }
}

class _CategoryRow {
  final String label;
  final String icon;
  final Color color;

  /// Montos de la categoría **separados por moneda** (clave = código ISO).
  /// Con una sola moneda es la cifra de siempre; con dos o más se listan por
  /// separado: sumarlos cruzaría monedas distintas.
  final Map<String, double> byCurrency;

  const _CategoryRow({
    required this.label,
    required this.icon,
    required this.color,
    required this.byCurrency,
  });

  /// Suma aritmética de [byCurrency]. Con moneda única es el monto que se
  /// pinta; con mezcla **solo** sirve para ordenar las filas: nunca se muestra.
  double get amount => amountsTotal(byCurrency);
}