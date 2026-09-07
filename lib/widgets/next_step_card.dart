import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../providers/transaction_provider.dart';
import '../services/next_step_service.dart';

/// Tarjeta "Tu próximo paso": guía derivada del estado actual de los datos
/// (sin estado guardado). Se oculta sola cuando no hay pasos pendientes.
class NextStepCard extends StatelessWidget {
  /// Qué hacer cuando el usuario pulsa la acción del paso.
  final void Function(NextStepType type) onAction;

  /// Qué hacer al pulsar "Ver guía completa" (sección Ayuda).
  final VoidCallback onOpenGuide;

  const NextStepCard({
    super.key,
    required this.onAction,
    required this.onOpenGuide,
  });

  @override
  Widget build(BuildContext context) {
    final tx = context.watch<TransactionProvider>();
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final step = nextStepFor(
      crops: tx.crops,
      sowings: tx.sowings,
      harvests: tx.harvests,
      transactions: tx.transactions,
      year: now.year,
    );
    if (step == null) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final hasOnlyDefaultCrops = tx.crops.length == 3 && tx.crops.every((c) => {
          'café',
          'plátano',
          'otro',
        }.contains(c.name.trim().toLowerCase()));
    final (title, subtitle) = switch (step.type) {
      NextStepType.crop => (
          hasOnlyDefaultCrops
              ? l10n.nextStepCropSetupTitle
              : l10n.nextStepCropTitle,
          hasOnlyDefaultCrops
              ? l10n.nextStepCropSetupSubtitle
              : l10n.nextStepCropSubtitle,
        ),
      NextStepType.sowing => (
          l10n.nextStepSowingTitle(_cropName(tx, l10n, step.cropId!)),
          l10n.nextStepSowingSubtitle,
        ),
      NextStepType.expenses => (
          l10n.nextStepExpensesTitle,
          l10n.nextStepExpensesSubtitle,
        ),
      NextStepType.harvest => (
          l10n.nextStepHarvestTitle,
          l10n.nextStepHarvestSubtitle,
        ),
      NextStepType.sale => (
          l10n.nextStepSaleTitle,
          l10n.nextStepSaleSubtitle,
        ),
    };
    final icon = switch (step.type) {
      NextStepType.crop => Icons.grass_outlined,
      NextStepType.sowing => Icons.spa_outlined,
      NextStepType.expenses => Icons.trending_down_outlined,
      NextStepType.harvest => Icons.inventory_2_outlined,
      NextStepType.sale => Icons.sell_outlined,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: scheme.onPrimaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onPrimaryContainer.withOpacity(0.75),
                  ),
                ),
                const SizedBox(height: 2),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: onOpenGuide,
                    icon: const Icon(Icons.menu_book_outlined, size: 14),
                    label: Text(l10n.nextStepGuideLink),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: () => onAction(step.type),
            child: Text(l10n.nextStepAction),
          ),
        ],
      ),
    );
  }

  String _cropName(TransactionProvider tx, AppLocalizations l10n, String id) {
    for (final c in tx.crops) {
      if (c.id == id) return c.name;
    }
    return l10n.cropUnspecified;
  }
}