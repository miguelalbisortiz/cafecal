import 'package:flutter/material.dart';

import '../services/metric_signal.dart';
import '../utils/format.dart';

class SummaryCard extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;

  /// Si es `true`, la tarjeta se renderiza con fondo del color y texto blanco
  /// para resaltar el dato clave (el resultado del período).
  final bool highlighted;

  /// Moneda para formatear el monto. Si es null usa la de settings.
  final String? currency;

  /// Locale para formatear. Si es null usa la de settings.
  final String? locale;

  /// B · variación contra el mes anterior ("subieron 12%"). `null` → la
  /// línea no se pinta: nada que comparar, o tocaría cruzar monedas.
  final String? deltaText;

  /// Señal de esa variación. La UI la acompaña siempre de un icono de forma
  /// distinta: el color nunca comunica solo (H10).
  final MetricSignal? deltaSignal;

  /// "vs. septiembre" — dice contra qué se compara el delta. `null` → oculta.
  final String? comparisonLabel;

  const SummaryCard({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.highlighted = false,
    this.currency,
    this.locale,
    this.deltaText,
    this.deltaSignal,
    this.comparisonLabel,
  });

  String _displayValue(BuildContext context) {
    if (currency != null) {
      return formatCompactExplicit(value, currency: currency!, locale: locale ?? 'es_CO');
    }
    return formatCompact(context, value);
  }

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
                _displayValue(context),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: foreground ?? scheme.onSurface,
                ),
              ),
            ),
            if (deltaText != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(_deltaIcon, size: 13, color: _deltaColor(isDark)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      deltaText!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _deltaColor(isDark),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (comparisonLabel != null) ...[
              const SizedBox(height: 2),
              Text(
                comparisonLabel!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.white54 : Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Icono distinto por señal: el color nunca va solo (H10).
  IconData get _deltaIcon => switch (deltaSignal ?? MetricSignal.none) {
        MetricSignal.positive => Icons.arrow_upward,
        MetricSignal.negative => Icons.arrow_downward,
        MetricSignal.neutral || MetricSignal.none => Icons.remove,
      };

  Color _deltaColor(bool isDark) =>
      switch (deltaSignal ?? MetricSignal.none) {
        MetricSignal.positive =>
          isDark ? Colors.green.shade300 : Colors.green.shade700,
        MetricSignal.negative =>
          isDark ? Colors.red.shade300 : Colors.red.shade600,
        MetricSignal.neutral || MetricSignal.none =>
          isDark ? Colors.white70 : Colors.grey[600]!,
      };
}