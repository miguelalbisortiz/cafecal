import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/strings.dart';
import '../models/categories.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../services/crop_totals.dart';
import '../utils/format.dart';

/// Tarjeta de caja menor del mes en curso: barra de progreso contra el
/// monto configurado, con desglose de jornales y extras.
///
/// Solo descuentan `discountsCashBox(category)` (mano de obra + extras).
/// El saldo NO se acumula entre meses: al llegar al 1 de mes la tarjeta
/// vuelve a cero porque suma los gastos del mes calendario vigente.
/// Sin `cajaMenorMensual` configurado no se renderiza (SizedBox.shrink).
///
/// **Moneda**: los gastos se acumulan por moneda. Si el mes salió en una
/// sola moneda y coincide con la del presupuesto, la tarjeta es la de
/// siempre (barra, % y restante). Si no, cada moneda sale con su código y
/// no se compara con el presupuesto: restar pesos con dólares daría un
/// restante falso.
class CashBoxCard extends StatelessWidget {
  const CashBoxCard({super.key});

  @override
  Widget build(BuildContext context) {
    final tx = context.watch<TransactionProvider>();
    final budget = tx.settings.cajaMenorMensual;
    if (budget == null || budget <= 0) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final locale = tx.settings.locale;
    final budgetCurrency = tx.settings.currency;

    // Gastos de caja del mes **por moneda**: nunca se suman monedas distintas.
    final jornales = <String, double>{};
    final extras = <String, double>{};
    for (final t in tx.transactionsInMonth(now.year, now.month)) {
      if (t.type != TransactionType.expense) continue;
      if (!discountsCashBox(t.category)) continue;
      final target = t.category == 'mano_obra' ? jornales : extras;
      target[t.currency] = (target[t.currency] ?? 0) + t.amount;
    }

    final currencies = {...jornales.keys, ...extras.keys}.toList()..sort();
    final mixed = currencies.length > 1;
    final usedByCurrency = <String, double>{};
    jornales.forEach(
        (c, v) => usedByCurrency[c] = (usedByCurrency[c] ?? 0) + v);
    extras.forEach((c, v) => usedByCurrency[c] = (usedByCurrency[c] ?? 0) + v);

    // Solo se descuenta del presupuesto (moneda de Ajustes) lo gastado en
    // esa misma moneda; con dos o más no hay porcentaje que mostrar.
    final singleCurrency = currencies.length == 1 ? currencies.first : null;
    final comparable = currencies.isEmpty || singleCurrency == budgetCurrency;

    String money(double v, String currency) =>
        formatAmount(v, currency: currency, locale: locale);
    String byCur(Map<String, double> amounts) =>
        byCurrencyText(amounts, (v, c) => money(v, c));

    final monthLabel = '${l10n.monthFull[now.month - 1]} ${now.year}';
    final scheme = Theme.of(context).colorScheme;

    final title = Row(
      children: [
        const Text('💵', style: TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${l10n.cashBoxTitle} — $monthLabel',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );

    if (!comparable) {
      // Gastos en otra moneda o en varias: cada moneda con su código, sin
      // barra ni % (compararlos con el presupuesto sería mentira).
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,
                const SizedBox(height: 12),
                if (mixed) ...[
                  Text(
                    l10n.currencyMixedByCurrencyNote(currencies.length),
                    style: TextStyle(
                        fontSize: 12, height: 1.3, color: scheme.primary),
                  ),
                  const SizedBox(height: 6),
                ],
                Text(
                  '${l10n.jornalTotalLabel}: ${byCur(usedByCurrency)}',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${l10n.cashBoxLabor}: ${byCur(jornales)}'
                  '${extras.isEmpty ? '' : ' · ${l10n.cashBoxExtras}: ${byCur(extras)}'}'
                  ' · ${l10n.reportCashBoxBudget}: ${money(budget, budgetCurrency)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Moneda única: la tarjeta de siempre.
    final currency = singleCurrency ?? budgetCurrency;
    final labor =
        jornales.values.fold<double>(0, (a, b) => a + b);
    final extraTotal = extras.values.fold<double>(0, (a, b) => a + b);
    final used = labor + extraTotal;
    final ratio = used / budget;
    final percent = (ratio * 100).toStringAsFixed(0);
    final remaining = budget - used;

    // Verde <80% · ámbar 80–100% · rojo >100%.
    final Color barColor;
    if (ratio < 0.8) {
      barColor = Colors.green;
    } else if (ratio <= 1.0) {
      barColor = Colors.amber;
    } else {
      barColor = Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: ratio.clamp(0.0, 1.0),
                  minHeight: 10,
                  backgroundColor: scheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.cashBoxOf(
                        money(used, currency),
                        money(budget, budgetCurrency),
                      ),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    '$percent%',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: barColor,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${l10n.cashBoxRemaining}: '
                '${money(remaining, currency)}'
                ' · ${l10n.cashBoxLabor}: '
                '${money(labor, currency)}'
                ' · ${l10n.cashBoxExtras}: '
                '${money(extraTotal, currency)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
