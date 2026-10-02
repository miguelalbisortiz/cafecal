import 'package:flutter_test/flutter_test.dart';

import 'package:mi_cafetal/services/metric_signal.dart';

void main() {
  group('marginVerdict — umbrales aprobados el 2026-10-02', () {
    test('sin ingresos no se calcula', () {
      expect(marginVerdict(null), MarginVerdict.noSales);
      expect(signalOfMargin(MarginVerdict.noSales), MetricSignal.none);
    });

    test('margen negativo es pérdida y va en rojo', () {
      expect(marginVerdict(-12), MarginVerdict.loss);
      expect(signalOfMargin(MarginVerdict.loss), MetricSignal.negative);
    });

    test('margen 0 exacto es empate, sin color de alarma', () {
      expect(marginVerdict(0), MarginVerdict.breakEven);
      expect(signalOfMargin(MarginVerdict.breakEven), MetricSignal.none);
    });

    test('por debajo de 10% es margen bajo y va en rojo', () {
      expect(marginVerdict(9.9), MarginVerdict.low);
      expect(signalOfMargin(MarginVerdict.low), MetricSignal.negative);
    });

    test('10% en adelante es margen justo y va en neutro', () {
      expect(marginVerdict(10), MarginVerdict.fair);
      expect(marginVerdict(19.9), MarginVerdict.fair);
      expect(signalOfMargin(MarginVerdict.fair), MetricSignal.neutral);
    });

    test('20% en adelante es buen margen y va en verde', () {
      expect(marginVerdict(20), MarginVerdict.good);
      expect(marginVerdict(35), MarginVerdict.good);
      expect(signalOfMargin(MarginVerdict.good), MetricSignal.positive);
    });
  });

  group('ratioVerdict — gastos vs ingresos (menor es mejor)', () {
    test('sin ingresos no se calcula', () {
      expect(ratioVerdict(null), RatioVerdict.noSales);
      expect(signalOfRatio(RatioVerdict.noSales), MetricSignal.none);
    });

    test('hasta 70% es control sano y va en verde', () {
      expect(ratioVerdict(70), RatioVerdict.healthy);
      expect(ratioVerdict(0), RatioVerdict.healthy);
      expect(signalOfRatio(RatioVerdict.healthy), MetricSignal.positive);
    });

    test('entre 70% y 90% se gasta bastante y va en neutro', () {
      expect(ratioVerdict(70.1), RatioVerdict.high);
      expect(ratioVerdict(90), RatioVerdict.high);
      expect(signalOfRatio(RatioVerdict.high), MetricSignal.neutral);
    });

    test('más de 90% se gasta casi todo y va en rojo', () {
      expect(ratioVerdict(90.1), RatioVerdict.critical);
      expect(ratioVerdict(150), RatioVerdict.critical);
      expect(signalOfRatio(RatioVerdict.critical), MetricSignal.negative);
    });
  });

  test('los tres estados buenos/neutros/malos son distinguibles sin color', () {
    // H10: la señal no puede depender solo del color, así que cada estado
    // necesita su propia identidad (en la UI se traduce en icono + texto).
    final signals = {
      signalOfMargin(MarginVerdict.good),
      signalOfMargin(MarginVerdict.fair),
      signalOfMargin(MarginVerdict.loss),
    };
    expect(signals.length, 3,
        reason: 'buena, justa y pérdida deben producir señales distintas');
  });
}
