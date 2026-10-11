import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/strings.dart';
import '../providers/transaction_provider.dart';
import '../services/crop_totals.dart';
import '../services/pdf_export_service.dart' show ReportPeriod;
import '../services/report_payroll_metrics.dart';
import '../utils/format.dart';

/// Tarjeta del **presupuesto de obra** del mes (E3): barra de progreso de la
/// mano de obra contra el monto configurado en Ajustes.
///
/// Existe aparte de [CashBoxCard] a propósito. "Gasté mucho en trabajadores"
/// y "gasté mucho en misceláneos" son señales opuestas — la primera dice que
/// hubo producción, la segunda que se escapó plata — y antes compartían una
/// sola barra: al 80 % no se sabía cuál de las dos había pasado.
///
/// Solo descuenta `category == 'mano_obra'`. El saldo NO se acumula entre
/// meses: al llegar al 1 de mes la tarjeta vuelve a cero.
/// Sin `presupuestoObraMensual` configurado no se renderiza: la separación
/// es opt-in, y quien no la pide sigue viendo la caja de siempre.
///
/// **Moneda**: la mano de obra se acumula por moneda. Si el mes salió en una
/// sola moneda y coincide con la del presupuesto, la tarjeta es la de siempre
/// (barra, % y restante). Si no, cada moneda sale con su código y no se
/// compara con el presupuesto.
class WorkBudgetCard extends StatelessWidget {
  const WorkBudgetCard({super.key});

  @override
  Widget build(BuildContext context) {
    final tx = context.watch<TransactionProvider>();
    final budget = tx.settings.presupuestoObraMensual;
    if (budget == null || budget <= 0) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final locale = tx.settings.locale;
    final budgetCurrency = tx.settings.currency;

    final rows = const ReportPayrollMetrics().workBudgetByMonth(
      periodTx: tx.transactionsInMonth(now.year, now.month),
      budget: budget,
      period: ReportPeriod.month,
      year: now.year,
      month: now.month,
      now: now,
    );
    if (rows.isEmpty) return const SizedBox.shrink();
    final row = rows.first;

    String money(double v, String currency) =>
        formatAmount(v, currency: currency, locale: locale);

    final monthLabel = '${l10n.monthFull[now.month - 1]} ${now.year}';
    final scheme = Theme.of(context).colorScheme;

    final title = Row(
      children: [
        const Text('👥', style: TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${l10n.workBudgetTitle} — $monthLabel',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );

    // Moneda única: la tarjeta de siempre.
    if (!row.isMixed) {
      final currency = row.currencies.isEmpty
          ? budgetCurrency
          : row.currencies.first;
      final used = row.used;
      final ratio = used / budget;
      final percent = (ratio * 100).toStringAsFixed(0);

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
                        l10n.workBudgetOf(
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
                  '${l10n.workBudgetRemaining}: '
                  '${money(budget - used, currency)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Mezcla de monedas: cada una con su código, sin barra ni % (restar
    // pesos de dólares daría un restante falso).
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
              Text(
                l10n.currencyMixedByCurrencyNote(row.currencies.length),
                style: TextStyle(fontSize: 12, height: 1.3, color: scheme.primary),
              ),
              const SizedBox(height: 6),
              Text(
                '${l10n.jornalTotalLabel}: '
                '${byCurrencyText(row.laborByCurrency, (v, c) => money(v, c))}'
                ' · ${l10n.reportCashBoxBudget}: '
                '${money(budget, budgetCurrency)}',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
