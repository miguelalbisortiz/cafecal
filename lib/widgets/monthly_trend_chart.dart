import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/strings.dart';
import '../models/currencies.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../services/currency_totals.dart';
import '../utils/format.dart';

/// Puntos de la curva "tu plata en {año}".
///
/// El primer punto `(-1, 0)` es el 1 de enero y cada punto posterior es el
/// saldo al cerrar ese mes: `ingresos − gastos` corridido. Como arranca en
/// cero, **el último punto es exactamente el resultado del año**, la misma
/// cifra que pinta la tarjeta de Resultado del panel.
///
/// Termina en el último mes que tiene movimiento, no en el mes calendario:
/// una cola plana hacia los meses vacíos diría "aquí no pasó nada" cuando en
/// realidad todavía no existe.
///
/// Devuelve lista vacía si el año no tiene ni un movimiento: entonces no se
/// dibuja ningún valor, porque cero registrado y cero sin registrar se ven
/// igual en pantalla y no son lo mismo.
List<FlSpot> accumulatedSpots(Iterable<Transaction> records, int year) {
  final net = List<double>.filled(12, 0);
  var lastMonth = 0;

  for (final t in records) {
    if (t.deleted || t.date.year != year) continue;
    final month = t.date.month;
    if (month > lastMonth) lastMonth = month;
    if (t.type == TransactionType.income) {
      net[month - 1] += t.amount;
    } else if (t.type == TransactionType.expense) {
      net[month - 1] -= t.amount;
    }
  }

  if (lastMonth == 0) return const [];

  final spots = <FlSpot>[const FlSpot(-1, 0)];
  var running = 0.0;
  for (var i = 0; i < lastMonth; i++) {
    running += net[i];
    spots.add(FlSpot(i.toDouble(), running));
  }
  return spots;
}

/// Escala amable para el eje: 1, 2, 5, 10, 20… sobre la magnitud del rango.
/// Sin esto el eje imprime cifras caprichosas como "Bs2,3k".
double _niceStep(double span) {
  final raw = span / 4;
  if (!(raw > 0)) return 1;
  final mag = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
  final norm = raw / mag;
  final factor =
      norm <= 1 ? 1.0 : (norm <= 2 ? 2.0 : (norm <= 5 ? 5.0 : 10.0));
  return factor * mag;
}

/// "Tu plata en {año} — acumulado": la curva de una cartera.
///
/// Una sola línea, sin restar dos barras con la vista: encima de la línea
/// punteada del cero estás ganando, debajo estás perdiendo. Ese cero es la
/// única referencia del eje vertical, así que la señal no depende solo del
/// color — la acompaña la flecha del pie y el texto de la línea base.
class MonthlyTrendChart extends StatelessWidget {
  const MonthlyTrendChart({super.key, required this.year});

  final int year;

  @override
  Widget build(BuildContext context) {
    final tx = context.watch<TransactionProvider>();
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final locale = tx.settings.numberLocale;

    final title = Text(
      l10n.chartCumulativeTitle(year),
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.bold),
    );

    final subtitle = Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        l10n.chartCumulativeSubtitle,
        style: TextStyle(
          fontSize: 12,
          color: scheme.onSurface.withOpacity(0.6),
        ),
      ),
    );

    // Moneda mixta en el año: la curva sumaría pesos con dólares y el eje
    // sería mentira. En su lugar se lista el total de cada moneda.
    final yearRecords = tx.transactions
        .where((t) => !t.deleted && t.date.year == year)
        .toList();
    final incomesByCurrency =
        amountsByCurrency(yearRecords, type: TransactionType.income);
    final expensesByCurrency =
        amountsByCurrency(yearRecords, type: TransactionType.expense);
    final currencies = {
      ...incomesByCurrency.keys,
      ...expensesByCurrency.keys,
    }.toList()
      ..sort();
    if (currencies.length > 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          const SizedBox(height: 16),
          _mixedHint(
            context,
            l10n.currencyMixedHint(currencies.length),
          ),
          const SizedBox(height: 8),
          for (final code in currencies)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                [
                  currencyInfo(code).code,
                  if (incomesByCurrency[code] != null)
                    '${l10n.incomeLabel} '
                    '${formatAmount(incomesByCurrency[code]!, currency: code, locale: locale)}',
                  if (expensesByCurrency[code] != null)
                    '${l10n.expensesLabel} '
                    '${formatAmount(expensesByCurrency[code]!, currency: code, locale: locale)}',
                ].join(' · '),
                style: const TextStyle(fontSize: 12),
              ),
            ),
        ],
      );
    }

    final spots = accumulatedSpots(yearRecords, year);
    if (spots.isEmpty) {
      // Sin ni un movimiento en el año no se pinta una línea plana en cero:
      // eso presentaría como *medido* algo que es *no registrado*.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          subtitle,
          const SizedBox(height: 16),
          Text(
            l10n.chartCumulativeEmpty(year),
            style: TextStyle(
              fontSize: 13,
              color: scheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      );
    }

    final currency =
        currencies.isNotEmpty ? currencies.first : tx.settings.currency;

    var pMax = spots.first.y;
    var pMin = spots.first.y;
    for (final s in spots) {
      if (s.y > pMax) pMax = s.y;
      if (s.y < pMin) pMin = s.y;
    }

    // El cero siempre queda dentro del rango: es la referencia de toda la
    // gráfica. El rango se redondea hacia afuera para que el eje caiga en
    // cifras redondas y las etiquetas coincidan con las guías.
    final step = _niceStep(math.max(pMax - pMin, 1));
    var minY = (math.min(pMin, 0) / step).floor() * step;
    var maxY = (math.max(pMax, 0) / step).ceil() * step;
    if (maxY - minY < step) maxY = minY + step;
    if (maxY <= minY) {
      minY = -step;
      maxY = step;
    }

    final gain = scheme.primary;
    final loss = scheme.error;
    final crossesZero = pMin < 0 && pMax > 0;
    // El gradiente se mide contra la caja de los puntos (que es como
    // fl_chart lo pinta), por eso se usa el máximo/mínimo de los datos y no
    // el rango ya redondeado del eje.
    final zeroFromTop = crossesZero ? pMax / (pMax - pMin) : 0.0;

    final now = DateTime.now();
    final markedMonth = year == now.year ? now.month - 1 : -1;
    final months = l10n.monthShort;

    final bar = LineChartBarData(
      spots: spots,
      isCurved: false,
      barWidth: 3,
      isStrokeCapRound: true,
      color: crossesZero ? null : (pMin >= 0 ? gain : loss),
      gradient: crossesZero
          ? LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [gain, loss],
              stops: [
                (zeroFromTop - 0.002).clamp(0.0, 1.0),
                (zeroFromTop + 0.002).clamp(0.0, 1.0),
              ],
            )
          : null,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          final isLast = index == spots.length - 1;
          return FlDotCirclePainter(
            color: spot.y >= 0 ? gain : loss,
            radius: isLast ? 6 : 3.5,
            strokeWidth: isLast ? 2.5 : 0,
            strokeColor: Theme.of(context).cardColor,
          );
        },
      ),
      // Zona verde entre la curva y el cero cuando estás arriba; zona roja
      // cuando estás abajo. El corte es lo que hace legible la pérdida sin
      // tener que mirar un número.
      belowBarData: BarAreaData(
        show: true,
        color: gain.withOpacity(0.14),
        cutOffY: 0,
        applyCutOffY: true,
      ),
      aboveBarData: BarAreaData(
        show: true,
        color: loss.withOpacity(0.14),
        cutOffY: 0,
        applyCutOffY: true,
      ),
    );

    final endValue = spots.last.y;
    final amount =
        formatAmount(endValue, currency: currency, locale: locale);
    final arrow = endValue > 0 ? '▲' : (endValue < 0 ? '▼' : '•');
    final verdictColor = endValue > 0
        ? gain
        : (endValue < 0 ? loss : scheme.onSurface.withOpacity(0.7));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        title,
        subtitle,
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              minX: -1,
              maxX: 11,
              minY: minY,
              maxY: maxY,
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipItems: (touchedSpots) => touchedSpots
                      .map((spot) => LineTooltipItem(
                            '${_pointLabel(l10n, spot.x)}\n'
                            '${formatAmount(spot.y, currency: currency, locale: locale)}',
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ))
                      .toList(),
                ),
              ),
              lineBarsData: [bar],
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    // A mano: sin esto fl_chart marca medios enteros y 0.5
                    // se redondea a enero, que sale dos veces.
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final idx = value.round();
                      if ((value - idx).abs() > 1e-6 ||
                          idx < 0 ||
                          idx >= months.length) {
                        return const SizedBox.shrink();
                      }
                      final isCurrent = idx == markedMonth;
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          isCurrent ? '${months[idx]}•' : months[idx],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isCurrent
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isCurrent
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 46,
                    interval: step,
                    getTitlesWidget: (value, meta) {
                      // El cero lo nombra la línea punteada; aquí solo la
                      // escala. Y solo múltiplos del paso: cualquier otra
                      // cifra saldría "Bs2,3k".
                      final n = value / step;
                      if (value == 0 || (n - n.round()).abs() > 1e-6) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(
                          formatCompactExplicit(value,
                              currency: currency, locale: locale),
                          style: TextStyle(
                            fontSize: 10,
                            color: scheme.onSurface.withOpacity(0.55),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: step,
              ),
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: 0,
                    color: scheme.onSurface.withOpacity(0.5),
                    strokeWidth: 1.2,
                    dashArray: const [6, 5],
                    label: HorizontalLineLabel(
                      show: true,
                      alignment: Alignment.topRight,
                      padding: const EdgeInsets.only(right: 4, bottom: 3),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface.withOpacity(0.7),
                      ),
                      labelResolver: (_) =>
                          '${formatAmount(0, currency: currency, locale: locale)}'
                          ' · ${l10n.chartStartLabel}',
                    ),
                  ),
                ],
              ),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '$arrow ${l10n.chartAccumDelta(amount)}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: verdictColor,
          ),
        ),
      ],
    );
  }

  String _pointLabel(AppLocalizations l10n, double x) {
    final idx = x.round();
    if (idx < 0 || idx >= l10n.monthShort.length) {
      return l10n.chartStartLabel;
    }
    return l10n.monthShort[idx];
  }

  /// Aviso breve de moneda mixta: el gráfico no se dibuja porque la curva
  /// sumaría monedas distintas. Nunca inventa una cifra.
  Widget _mixedHint(BuildContext context, String text) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.monetization_on_outlined, size: 16, color: scheme.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: scheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}
