import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';

/// Vista de bienvenida que se muestra hasta que la finca queda configurada
/// (gate `needsOnboarding` en next_step_service). Es el primer paso obligado:
/// elegir registrar una siembra o registrar un cultivo. Mientras no se elija
/// ninguno, el resto de la app no se muestra.
class WelcomeOnboardingCard extends StatelessWidget {
  /// Abrir el registro de cultivos para crear el primero.
  final VoidCallback onRegisterCrop;

  /// Abrir el registro de siembras (puede crear cultivos nuevos al vuelo).
  final VoidCallback onRegisterSowing;

  const WelcomeOnboardingCard({
    super.key,
    required this.onRegisterCrop,
    required this.onRegisterSowing,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.welcomeTitle,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.welcomeSubtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: scheme.onPrimaryContainer.withOpacity(0.85),
                ),
              ),
              const SizedBox(height: 16),
              _choiceCard(
                context: context,
                icon: Icons.spa_outlined,
                title: l10n.welcomeNewTitle,
                badge: l10n.welcomeNewBadge,
                subtitle: l10n.welcomeNewSubtitle,
                onTap: onRegisterSowing,
              ),
              const SizedBox(height: 12),
              _choiceCard(
                context: context,
                icon: Icons.grass_outlined,
                title: l10n.welcomeExistingTitle,
                badge: l10n.welcomeExistingBadge,
                subtitle: l10n.welcomeExistingSubtitle,
                onTap: onRegisterCrop,
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: scheme.onPrimaryContainer.withOpacity(0.7),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.welcomeHint,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            scheme.onPrimaryContainer.withOpacity(0.75),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _choiceCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String badge,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 28, color: scheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: scheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}