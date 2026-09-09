import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';

/// Tarjeta de bienvenida que se muestra hasta que la finca queda configurada
/// (gate `needsOnboarding` en next_step_service). Ofrece los dos caminos de
/// entrada: "ya tengo plantas produciendo" o "quiero empezar algo nuevo".
class WelcomeOnboardingCard extends StatelessWidget {
  /// Abrir la gestión de cultivos para registrar los que ya existen.
  final VoidCallback onExistingFarm;

  /// Abrir el registro de siembras (puede crear cultivos nuevos al vuelo).
  final VoidCallback onNewSowing;

  /// Abrir la guía (sección Ayuda).
  final VoidCallback onOpenGuide;

  const WelcomeOnboardingCard({
    super.key,
    required this.onExistingFarm,
    required this.onNewSowing,
    required this.onOpenGuide,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.welcomeTitle,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.welcomeSubtitle,
            style: TextStyle(
              fontSize: 13,
              color: scheme.onPrimaryContainer.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 12),
          _optionCard(
            context: context,
            icon: Icons.grass_outlined,
            title: l10n.welcomeExistingTitle,
            subtitle: l10n.welcomeExistingSubtitle,
            actionLabel: l10n.welcomeExistingAction,
            onPressed: onExistingFarm,
          ),
          const SizedBox(height: 8),
          _optionCard(
            context: context,
            icon: Icons.spa_outlined,
            title: l10n.welcomeNewTitle,
            subtitle: l10n.welcomeNewSubtitle,
            actionLabel: l10n.welcomeNewAction,
            onPressed: onNewSowing,
          ),
          const SizedBox(height: 8),
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
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lightbulb_outline,
                  size: 16, color: scheme.onPrimaryContainer.withOpacity(0.7)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.welcomeHint,
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onPrimaryContainer.withOpacity(0.75),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _optionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onPressed,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            onPressed: onPressed,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}