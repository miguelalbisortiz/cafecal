import 'package:flutter/material.dart';

import '../utils/format.dart';

class SummaryCard extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;

  /// Si es `true`, la tarjeta se renderiza con fondo del color y texto blanco
  /// para resaltar el dato clave (el resultado del período).
  final bool highlighted;

  const SummaryCard({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isNegative = value < 0;
    final accent = isNegative ? scheme.error : color;
    final foreground = highlighted ? Colors.white : null;
    final cardColor = highlighted ? accent : null;
    final iconColor = highlighted ? Colors.white : accent;

    return Card(
      color: cardColor,
      elevation: highlighted ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: highlighted
                        ? Colors.white.withOpacity(0.25)
                        : accent.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: highlighted
                          ? Colors.white70
                          : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                formatCompact(context, value),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: foreground ?? scheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}