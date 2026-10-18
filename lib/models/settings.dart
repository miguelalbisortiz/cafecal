class FarmSettings {
  final String farmName;
  final String currency;

  /// Idioma de la app: `es` o `en`.
  final String language;

  /// La notación de las cifras —separador de miles y de decimales— **sigue al
  /// idioma**: quien pone la app en inglés lee los números en inglés.
  ///
  /// Antes era un campo aparte que nadie editaba, así que se quedaba clavado en
  /// `es_CO`: con el idioma en inglés salían las fechas y los conteos en
  /// inglés, pero la plata y los kilos con la notación del español. Ahora hay un
  /// solo origen —el idioma— y los ajustes viejos se curan al leerlos.
  String get numberLocale => language == 'en' ? 'en_US' : 'es_CO';

  /// Último cultivo elegido al registrar: se preselecciona al abrir
  /// "Registrar" para agilizar gastos recurrentes del mismo cultivo.
  final String? lastCropId;

  /// Último lote elegido al registrar, para agilizar los gastos que sirven a
  /// varios cultivos del mismo terreno (una limpieza compartida, el abono de
  /// todo el lote).
  ///
  /// Existe aparte de [lastCropId] porque los dos son mutuamente excluyentes:
  /// un gasto es de un cultivo o del lote, nunca de los dos.
  ///
  /// Sin este campo, registrar un gasto de lote dejaba `_cropId` en `null` y
  /// el `copyWith(lastCropId: null)` **borraba** el recordatorio a propósito.
  /// El siguiente gasto compartido arrancaba en "Costos comunes" y dejaba de
  /// repartirse por hectáreas, sin que nadie lo viera.
  final String? lastTerrenoId;

  /// Umbral manual de alerta de precio bajo (moneda activa por kg).
  /// Si se define, se dispara una alerta cuando una venta con cantidad
  /// se registra por debajo de este precio por kilogramo.
  /// `null` = desactivado (solo se compara contra el histórico propio).
  final double? lowPriceThresholdPerKg;

  /// Monto de la caja menor destinado **cada mes** a jornales y gastos extras.
  /// Se reinicia solo con el calendario (el saldo no se acumula al siguiente
  /// mes). `null` = desactivado (sin widget de caja ni alerta).
  final double? cajaMenorMensual;

  /// E3 · presupuesto de obra del mes: cuánto se pensaba gastar en **gente**
  /// (mano de obra) durante el mes.
  ///
  /// Existe aparte porque "gasté mucho en trabajadores" y "gasté mucho en
  /// misceláneos" son señales opuestas, y la caja menor mezclaba las dos en
  /// una sola barra: al 80% no se sabía cuál de las dos había pasado.
  ///
  /// **Opt-in**: `null` = no configurado, y en ese caso la caja menor sigue
  /// contando jornales + extras **exactamente igual que siempre**. La
  /// separación solo aparece quien la pide. `null` también se reinicia solo
  /// con el calendario, igual que la caja.
  final double? presupuestoObraMensual;

  /// A2 · peso real de un saco de café, en kg.
  ///
  /// La norma dice 70, pero en la finca el costal puede pesar 60. Este número
  /// manda para pasar **todo** a kilogramos (reportes, PDF, Excel y alertas).
  /// Nunca es `null`: si no lo tocó, vale 70.
  ///
  /// Es retroactivo **a propósito**: el kg no se guarda por registro, se
  /// recalcula al vuelo, así que cambiarlo reescribe el histórico entero de
  /// una. Si algún día se quiere congelar lo ya registrado, haría falta
  /// guardar el peso junto a cada cosecha.
  final double sacoKg;

  static const _sentinel = Object();

  const FarmSettings({
    this.farmName = 'Mi Caferin',
    this.currency = 'COP',
    this.language = 'es',
    this.lastCropId,
    this.lastTerrenoId,
    this.lowPriceThresholdPerKg,
    this.cajaMenorMensual,
    this.presupuestoObraMensual,
    this.sacoKg = 70,
  });

  FarmSettings copyWith({
    String? farmName,
    String? currency,
    String? language,
    Object? lastCropId = _sentinel,
    Object? lastTerrenoId = _sentinel,
    Object? lowPriceThresholdPerKg = _sentinel,
    Object? cajaMenorMensual = _sentinel,
    Object? presupuestoObraMensual = _sentinel,
    double? sacoKg,
  }) {
    return FarmSettings(
      farmName: farmName ?? this.farmName,
      currency: currency ?? this.currency,
      language: language ?? this.language,
      lastCropId: lastCropId == _sentinel
          ? this.lastCropId
          : lastCropId as String?,
      // Mismo patrón que lastCropId: hace falta centinela para poder VACIARLO.
      // Elegir cultivo limpia el lote y viceversa, y esa limpieza tiene que
      // llegar a los ajustes o el desplegable arrancaría con lo del registro
      // anterior.
      lastTerrenoId: lastTerrenoId == _sentinel
          ? this.lastTerrenoId
          : lastTerrenoId as String?,
      lowPriceThresholdPerKg: lowPriceThresholdPerKg == _sentinel
          ? this.lowPriceThresholdPerKg
          : lowPriceThresholdPerKg as double?,
      cajaMenorMensual: cajaMenorMensual == _sentinel
          ? this.cajaMenorMensual
          : cajaMenorMensual as double?,
      // Igual que caja: hace falta sentinela para poder VACIARLO, que es la
      // forma de desactivar la obra y volver al comportamiento de siempre.
      // num → double: el parámetro es Object? para aceptar null, y un literal
      // entero (presupuestoObraMensual: 1000000) no debe reventar.
      presupuestoObraMensual: presupuestoObraMensual == _sentinel
          ? this.presupuestoObraMensual
          : (presupuestoObraMensual as num?)?.toDouble(),
      // Como nunca es null no necesita sentinela: `??` basta, igual que
      // `farmName` más arriba — solo se cambia si se pasa un valor.
      sacoKg: sacoKg ?? this.sacoKg,
    );
  }

  /// Aporte mensual de caja, con la obra ya plegada dentro.
  ///
  /// En la planilla de papel hay **un solo pote**: la plata que se saca cada
  /// mes para la finca cubre los jornales y los gastos chicos (luz, agua,
  /// arreglos). Antes la app lo partía en dos montos y dos barras, y eso
  /// obligaba a mirar dos números para una sola decisión.
  ///
  /// `cajaMenorMensual` y `presupuestoObraMensual` siguen existiendo en la
  /// BD: quien ya tenía los dos **no pierde presupuesto**, los dos se suman.
  /// Al guardar ajustes la pantalla pliega el total en `cajaMenorMensual` y
  /// deja `presupuestoObraMensual` en `null`, así que la suma es puntual y
  /// no se dobla cada vez que se lee.
  ///
  /// `null` si no hay nada configurado: sin aporte no hay barra.
  double? get cajaMensualEfectiva {
    final total = (cajaMenorMensual ?? 0) + (presupuestoObraMensual ?? 0);
    return total > 0 ? total : null;
  }

  Map<String, dynamic> toJson() => {
        'farm_name': farmName,
        'currency': currency,
        'language': language,
        if (lastCropId != null) 'last_crop_id': lastCropId,
        if (lastTerrenoId != null) 'last_terreno_id': lastTerrenoId,
        if (lowPriceThresholdPerKg != null)
          'low_price_threshold_per_kg': lowPriceThresholdPerKg,
        if (cajaMenorMensual != null)
          'caja_menor_mensual': cajaMenorMensual,
        // Solo si está configurado: un valor vacío quiere decir "obra sin
        // presupuesto", y eso es null, no 0.
        if (presupuestoObraMensual != null)
          'presupuesto_obra_mensual': presupuestoObraMensual,
        'saco_kg': sacoKg,
      };

  factory FarmSettings.fromJson(Map<String, dynamic> json) {
    return FarmSettings(
      farmName: (json['farm_name'] as String?) ?? 'Mi Caferin',
      currency: (json['currency'] as String?) ?? 'COP',
      language: (json['language'] as String?) ?? 'es',
      lastCropId: (json['last_crop_id'] as String?),
      // Respaldos y bajadas viejos no traen la clave → null → sin preselección
      // de lote, que es como se comportó siempre.
      lastTerrenoId: (json['last_terreno_id'] as String?),
      lowPriceThresholdPerKg:
          (json['low_price_threshold_per_kg'] as num?)?.toDouble(),
      cajaMenorMensual: (json['caja_menor_mensual'] as num?)?.toDouble(),
      // Respaldos y bajadas viejas no traen la clave → null → obra sin
      // presupuesto → la caja menor actúa como siempre.
      presupuestoObraMensual:
          (json['presupuesto_obra_mensual'] as num?)?.toDouble(),
      // Respaldos viejos no traen la clave → 70, el de la norma.
      sacoKg: (json['saco_kg'] as num?)?.toDouble() ?? 70,
    );
  }
}