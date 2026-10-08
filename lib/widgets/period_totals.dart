import 'package:flutter/widgets.dart';

import '../services/currency_conversion.dart';
import '../services/currency_totals.dart';

/// Permite inyectar el conversor de moneda (por ejemplo en tests, con un
/// cliente HTTP falso). Si no hay scope en el árbol, las pantallas usan
/// [CurrencyConversionService.fallback].
class CurrencyConversionScope extends InheritedWidget {
  final CurrencyConversionService service;

  const CurrencyConversionScope({
    super.key,
    required this.service,
    required super.child,
  });

  static CurrencyConversionService of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CurrencyConversionScope>()?.service ??
      CurrencyConversionService.fallback;

  @override
  bool updateShouldNotify(CurrencyConversionScope oldWidget) =>
      service != oldWidget.service;
}

/// Firma del builder de los totales de un período.
///
/// `converted` es null cuando el período tiene una sola moneda, mientras
/// cargan las tasas o cuando **falta alguna**: en esos casos la pantalla
/// muestra los totales por moneda y nunca una cifra global inventada.
typedef ConvertedTotalsBuilder = Widget Function(
  BuildContext context,
  ConvertedPeriodTotals? converted,
);

/// Resuelve la conversión de los totales de un período a la moneda de la
/// app **sin bloquear la UI**:
///
/// - Período de una sola moneda → no hace nada, `converted` queda en null y
///   la pantalla se pinta exactamente como siempre.
/// - Moneda mixta → pide las tasas en segundo plano. Mientras no lleguen
///   (o si falta alguna) `converted` es null → se muestran los totales por
///   moneda. Cuando están todas, llega `converted` y la pantalla pasa a
///   mostrar un único total en la moneda de Ajustes.
class PeriodTotalsBuilder extends StatefulWidget {
  final PeriodCurrencyTotals totals;
  final String targetCurrency;
  final ConvertedTotalsBuilder builder;

  const PeriodTotalsBuilder({
    super.key,
    required this.totals,
    required this.targetCurrency,
    required this.builder,
  });

  @override
  State<PeriodTotalsBuilder> createState() => _PeriodTotalsBuilderState();
}

class _PeriodTotalsBuilderState extends State<PeriodTotalsBuilder> {
  String? _signature;
  bool _running = false;
  ConvertedPeriodTotals? _converted;

  @override
  Widget build(BuildContext context) {
    if (!widget.totals.isMixed) {
      // Sin mezcla no hay nada que convertir: mismo comportamiento de siempre.
      if (_signature != null || _converted != null) {
        _signature = null;
        _converted = null;
        _running = false;
      }
      return widget.builder(context, null);
    }

    final currencies = widget.totals.currencies.toList()..sort();
    final signature = '${currencies.join(',')}>${widget.targetCurrency}';
    if (signature != _signature && !_running) {
      final service = CurrencyConversionScope.of(context);
      _signature = signature;
      _converted = null;
      _running = true;
      _resolve(service, currencies, signature);
    }
    return widget.builder(context, _converted);
  }

  Future<void> _resolve(
    CurrencyConversionService service,
    List<String> currencies,
    String signature,
  ) async {
    ConvertedPeriodTotals? converted;
    try {
      converted = await service.convert(widget.totals, widget.targetCurrency);
    } catch (_) {
      converted = null;
    }
    if (!mounted || signature != _signature) return;
    setState(() {
      _running = false;
      _converted = converted;
    });
  }
}
