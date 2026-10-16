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
///
/// Ordena por severidad y **no repite una misma regla**: si tres cultivos
/// están en pérdida sale un solo aviso de ese tipo, no tres.
///
/// [maxRecommendations] es opcional y por defecto **no hay tope**: la tarjeta
/// de Reportes, el PDF y el Excel enseñan exactamente lo que el banner de
/// Inicio enseña. Un informe que se queda en silencio sobre un aviso que sí
/// aparece en la portada es un informe que miente por omisión — y el PDF es
/// lo que el agricultor comparte. Se pasa un número solo en tests que quieran
/// comprobar que el corte funciona.
class RecommendationService {
  const RecommendationService();

  List<Recommendation> derive(
      List<FarmAlert> alerts, [int? maxRecommendations]) {
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
      if (maxRecommendations != null &&
          result.length >= maxRecommendations) {
        break;
      }
    }
    return result;
  }
}
