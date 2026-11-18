/// Estado del café en el punto de la cadena en que se vende (Fase 1).
///
/// El mismo grano vale muy distinto en cereza que en tueste, y el productor
/// decide dónde vender según su capacidad de beneficiar. Sin esta marca, una
/// venta de cereza y una de tueste se veían iguales en el historial y en los
/// reportes: dos filas «Venta Café» con precios que no se pueden comparar.
///
/// `null` (no un valor «otro») significa **no se anotó**: plátano, otros
/// cultivos y todos los movimientos anteriores a esta fase. La app no
/// inventa un estado.
enum ProductState {
  cereza,
  pergamino,
  verde,
  tueste;

  /// Texto que se guarda en disco y en Supabase. Se guarda la clave y no la
  /// etiqueta porque el nombre cambia con el idioma.
  String get serialize => name;

  /// Clave guardada → estado. Desconocida o vacía → `null`, nunca una
  /// excepción: un respaldo de otra versión no puede tumbar la carga.
  static ProductState? parse(String? raw) =>
      raw == null ? null : values.asNameMap()[raw];
}
