import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/transaction.dart';

/// A2 · estado vacío de la sección de dinero del Resumen.
///
/// Cuando la app todavía no tiene ni un movimiento, pintar tres "$0" sería
/// presentar como **medido** algo que en realidad es **no registrado** — la
/// misma confusión que prohíbe la regla de `null` → oculto. Esta tarjeta
/// dice qué falta y ofrece las dos puertas de entrada.
///
/// Se oculta sola en cuanto existe un registro: no hace falta descartarla.
class SummaryEmptyCard extends StatelessWidget {
  /// Abre la pestaña Registrar prefijando [type].
  final void Function(TransactionType type) onRegister;

  const SummaryEmptyCard({super.key, required this.onRegister});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: Column(
          children: [
            const Icon(
              Icons.markunread_mailbox_outlined,
              size: 44,
              color: Colors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.summaryEmptyTitle,
              textAlign: TextAlign.center,
              style:
                  text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.summaryEmptyBody,
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(
                color: text.bodySmall?.color,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: () => onRegister(TransactionType.expense),
                  icon: const Icon(Icons.trending_down, size: 18),
                  label: Text(l10n.recordExpense),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => onRegister(TransactionType.income),
                  icon: const Icon(Icons.trending_up, size: 18),
                  label: Text(l10n.recordIncome),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
