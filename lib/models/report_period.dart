/// El período que cubre un reporte.
///
/// Vive en `models/` y **no** en el servicio de PDF a propósito: lo usan el
/// informe de nómina, el Excel y la pantalla de Reportes. Cuando vivía dentro
/// de `pdf_export_service.dart`, cualquiera que necesitara el enum —incluidas
/// las alertas— arrastraba `package:pdf` al arranque de la app.
enum ReportPeriod { week, month, year, yearToDate }
