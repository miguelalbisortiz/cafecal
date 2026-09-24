import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/strings.dart';
import '../models/categories.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../utils/format.dart';

/// Tarjeta de caja menor del mes en curso: barra de progreso contra el
/// monto configurado, con desglose de jornales y extras.
///
/// Solo descuentan `discountsCashBox(category)` (mano de obra + extras).
/// El saldo NO se acumula entre meses: al llegar al 1 de mes la tarjeta
/// vuelve a cero porque suma los gastos del mes calendario vigente.
/// Sin `cajaMenorMensual` configurado no se renderiza (SizedBox.shrink).
class CashBoxCard extends StatelessWidget {
  const CashBoxCard({super.key});

  @override
  Widget build(BuildContext context) {
    final tx = context.watch<TransactionProvider>();
    final budget = tx.settings.cajaMenorMensual;
    if (budget == null || budget <= 0) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();

    double jornales = 0;
    double extras = 0;
    for (final t in tx.transactionsInMonth(now.year, now.month)) {
      if (t.type != TransactionType.expense) continue;
      if (!discountsCashBox(t.category)) continue;
      if (t.category == 'mano_obra') {
        jornales += t.amount;
      } else {
        extras += t.amount;
      }
    }

    final used = jornales + extras;
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

    final currency = tx.settings.currency;
    final locale = tx.settings.locale;
    final monthLabel = '${l10n.monthFull[now.month - 1]} ${now.year}';

    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
              ),
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
                        formatAmount(used,
                            currency: currency, locale: locale),
                        formatAmount(budget,
                            currency: currency, locale: locale),
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
                '${formatAmount(remaining, currency: currency, locale: locale)}'
                ' · ${l10n.cashBoxLabor}: '
                '${formatAmount(jornales, currency: currency, locale: locale)}'
                ' · ${l10n.cashBoxExtras}: '
                '${formatAmount(extras, currency: currency, locale: locale)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
