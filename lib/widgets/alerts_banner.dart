import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/farm_alert.dart';
import 'terminology_guide.dart';

class AlertsBanner extends StatelessWidget {
  final List<FarmAlert> alerts;

  const AlertsBanner({super.key, required this.alerts});

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final sorted = [...alerts]..sort(
        (a, b) => b.severity.index.compareTo(a.severity.index));
    final accent = sorted.first.severity.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.6), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.campaign, size: 20, color: accent),
              const SizedBox(width: 8),
              Text(
                l10n.alertsTitle,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                tooltip: l10n.alertsTooltip,
                visualDensity: VisualDensity.compact,
                onPressed: () =>
                    showTerminologyGuide(context, highlight: 'ROI'),
                icon: Icon(Icons.info_outline, size: 16, color: accent),
              ),
              const SizedBox(width: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${sorted.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...sorted.map((a) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.circle, size: 10, color: a.severity.color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.title,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            a.message,
                            style: const TextStyle(fontSize: 12),
                          ),
                          if (a.suggestion.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.lightbulb_outline,
                                    size: 13, color: a.severity.color),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    a.suggestion,
                                    style: TextStyle(
                                      fontSize: 12,
                                      height: 1.25,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.7),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}