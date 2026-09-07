import '../models/farm_alert.dart';

/// Una recomendación accionable de la sección "Qué hacer" del reporte.
class Recommendation {
  final AlertRule rule;
  final AlertSeverity severity;
  final String title;
  final String message;

  const Recommendation({
    required this.rule,
    required this.severity,
    required this.title,
    required this.message,
  });
}

/// Deriva recomendaciones del MISMO motor de alertas, garantizando que la
/// sección "Qué hacer" del reporte sea coherente con las alertas activas.
/// Devuelve una lista (se esperan entre 2 y 4 recomendaciones relevantes).
class RecommendationService {
  const RecommendationService();

  List<Recommendation> derive(
      List<FarmAlert> alerts,
      int maxRecommendations) {
    if (alerts.isEmpty) return const [];

    // Prioriza alertas de mayor severidad (danger > warning > info) sin
    // duplicar la misma regla, y limita el resultado al máximo pedido.
    final seen = <AlertRule>{};
    final sorted = [...alerts]
      ..sort((a, b) => b.severity.index.compareTo(a.severity.index));

    final result = <Recommendation>[];
    for (final a in sorted) {
      if (seen.contains(a.rule)) continue;
      seen.add(a.rule);
      result.add(Recommendation(
        rule: a.rule,
        severity: a.severity,
        title: a.title,
        message: a.message,
      ));
      if (result.length >= maxRecommendations) break;
    }
    return result;
  }
}
