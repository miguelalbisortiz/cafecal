import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import 'crops_screen.dart';
import 'sowing_screen.dart';
import 'workers_screen.dart';

/// Fase 2 · los datos maestros dejan el menú y viven aquí.
///
/// Cultivos, Siembras y Trabajadores son cosas que se tocan de vez en cuando,
/// no todos los días: un hub las mantiene descubribles sin competir con el uso
/// diario. La flecha de cada pantalla vuelve **aquí**, no a Resumen.
class FincaScreen extends StatelessWidget {
  const FincaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.menuFinca)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                l10n.fincaHubTitle,
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.fincaHubSubtitle,
                style: text.bodyMedium?.copyWith(
                  color: text.bodySmall?.color,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              _HubCard(
                icon: Icons.grass_outlined,
                label: l10n.menuCrops,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const CropsScreen()),
                ),
              ),
              const SizedBox(height: 10),
              _HubCard(
                icon: Icons.eco_outlined,
                label: l10n.menuSowings,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const SowingScreen()),
                ),
              ),
              const SizedBox(height: 10),
              _HubCard(
                icon: Icons.people_outline,
                label: l10n.menuWorkers,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => const WorkersScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HubCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          child: Icon(icon),
        ),
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
