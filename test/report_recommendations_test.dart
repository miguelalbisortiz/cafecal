import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cafetal/models/farm_alert.dart';
import 'package:mi_cafetal/services/recommendations.dart';

FarmAlert _alert(String id, AlertRule rule, AlertSeverity severity) {
  return FarmAlert(
    id: id,
    rule: rule,
    severity: severity,
    title: 'Título $id',
    message: 'Mensaje $id',
    suggestion: 'Sugerencia $id',
  );
}

void main() {
  const svc = RecommendationService();

  test('deriva recomendaciones de las mismas alertas activas', () {
    final alerts = [
      _alert('a1', AlertRule.deficitCrop, AlertSeverity.danger),
      _alert('a2', AlertRule.noIncome, AlertSeverity.warning),
    ];
    final recs = svc.derive(alerts, 4);
    expect(recs.length, 2);
    expect(recs[0].rule, AlertRule.deficitCrop); // mayor severidad primero
    expect(recs[1].rule, AlertRule.noIncome);
    expect(recs[0].message, 'Mensaje a1');
  });

  test('no duplica reglas y respeta el máximo', () {
    final alerts = [
      _alert('a1', AlertRule.deficitCrop, AlertSeverity.danger),
      _alert('a2', AlertRule.deficitCrop, AlertSeverity.warning), // duplicado
      _alert('a3', AlertRule.noIncome, AlertSeverity.warning),
      _alert('a4', AlertRule.lowPrice, AlertSeverity.info),
    ];
    final recs = svc.derive(alerts, 2);
    expect(recs.length, 2);
    expect(recs.map((r) => r.rule).toSet().length, 2);
  });

  test('vacío cuando no hay alertas', () {
    expect(svc.derive(const [], 4), isEmpty);
  });
}
