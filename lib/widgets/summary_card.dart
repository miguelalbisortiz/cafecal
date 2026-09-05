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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isNegative = value < 0;
    final accent = isNegative ? scheme.error : color;
    final foreground = highlighted ? accent : null;
    final cardColor = highlighted ? accent.withOpacity(0.14) : null;
    final borderColor = highlighted ? accent.withOpacity(0.5) : null;
    final iconColor = highlighted ? accent : accent;
    final labelColor = highlighted
        ? accent
        : (isDark ? Colors.white70 : Colors.grey[600]);

    return Card(
      color: cardColor,
      elevation: highlighted ? 0 : 1,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: borderColor != null
            ? BorderSide(color: borderColor)
            : BorderSide.none,
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
                    color: accent.withOpacity(0.16),
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
                      color: labelColor,
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