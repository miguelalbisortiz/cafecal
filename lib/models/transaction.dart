import 'tasks.dart';

enum TransactionType {
  expense,
  income;

  static TransactionType parse(String value) =>
      value == 'income' ? TransactionType.income : TransactionType.expense;

  String get serialize => name;

  bool get isExpense => this == TransactionType.expense;
}

class Transaction {
  final String id;
  final String? cropId;

  /// El lote al que sirve el gasto, en vez de un cultivo concreto.
  ///
  /// Es la pieza de (b): un mismo jornal limpia café y plátano del mismo
  /// terreno, y esa plata no es "del café" ni "del plátano" — es del lote.
  /// La app solo la reparte al mostrar el costo de cada cultivo, y únicamente
  /// si todos los cultivos del lote tienen hectáreas anotadas; si falta alguna
  /// sale como línea aparte "sin repartir". Nunca se inventa la proporción.
  ///
  /// Mutuamente excluyente con [cropId]: o es de un cultivo, o sirve al lote.
  /// Nunca los dos — que las dos cosas a la vez sería contar el gasto dos veces.
  ///
  /// `null` = movimiento normal. Todos los datos viejos nacen así y siguen
  /// comportándose exactamente igual que antes.
  final String? terrenoId;
  final TransactionType type;
  final String category;
  final double amount;
  final String currency;
  final String description;
  final DateTime date;
  final DateTime createdAt;
  final bool pendingSync;
  final bool deleted;

  // ---- Capa productiva (Nivel 1) ----
  final double? quantity;
  final String? unit;
  final double? pricePerUnit;
  final String? client;
  final String? provider;

  // ---- Capa productiva (Nivel 2) ----
  final String? harvestId;
  final String? sowingId;

  // ---- La venta real (E1) ----
  /// Kilos que el comprador descontó antes de pagar: impureza, humedad,
  /// piedras. En café real no siempre se paga lo que se entregó, y sin este
  /// dato no se puede decir "coseché 480 kg, me descontaron 80, me pagaron
  /// por 400". Null = ningún descuento.
  final double? deductionQty;

  /// Motivo del descuento, en palabras del usuario ("impureza", "húmedo").
  /// Se guarda tal cual: no hay una lista cerrada de motivos.
  final String? deductionReason;

  /// ¿La plata ya entró? `false` = por cobrar.
  ///
  /// `true` por defecto a propósito: un movimiento de ingreso que no viene
  /// marcado es plata que ya estaba en la caja, y así quedan los datos
  /// antiguos — nadie hereda un "por cobrar" inventado.
  final bool paid;

  // ---- La obra del día (E3) ----

  /// Qué labor se hizo en este jornal.
  ///
  /// Es una tecla de [farmTasks] (`descolgar`, `abonar`…) o texto libre si
  /// eligió "Otra…". Se guarda la tecla y no el nombre mostrado a propósito:
  /// el nombre cambia con el idioma y la planilla tendría que agrupar por
  /// lo que hay en la BD.
  ///
  /// Null = sin labor declarada. Un gasto de mano de obra viejo (anterior a
  /// E3) nace así y sigue contando en la nómina: la planilla lo agrupa bajo
  /// "Sin labor" en vez de inventarle uno.
  final String? task;

  /// Kilos recolectados en este jornal (Tanda 2).
  ///
  /// **Es una medida de cosecha, no una forma de pago.** El jornal se sigue
  /// pagando `días × valor día`; este número solo alimenta la cosecha
  /// derivada cuando la labor es «Cosechar». `null` = no se midió, y entonces
  /// no se deriva nada (nunca un 0 inventado).
  final double? harvestedKg;

  /// Peso total de la venta, en kilos (tanda 4).
  ///
  /// Una venta en `racimo` o `cajon` no tiene factor fijo: el productor anota
  /// cuántos racimos entregó y cuánto pesaron juntos. Sin este número no hay
  /// kilos, y el precio por kilo, los totales y las exportaciones se callan —
  /// nunca 1 kg por unidad. `null` en todas las demás unidades y en los datos
  /// viejos.
  final double? equivalentKg;

  /// Lote (siembra-cabeza) al que se atribuyen los kilos de un jornal.
  ///
  /// Solo tiene sentido en un jornal de «Cosechar» con kilos y cultivo: es una
  /// MEDIDA de lo que se pesó en ese lote, no un reparto de la venta. `null` =
  /// sin lote (dato viejo o no elegido) y esos kilos siguen contando para el
  /// cultivo, pero no se muestran por lote.
  final String? cohortSowingId;

  const Transaction({
    required this.id,
    this.cropId,
    this.terrenoId,
    required this.type,
    required this.category,
    required this.amount,
    this.currency = 'COP',
    this.description = '',
    required this.date,
    required this.createdAt,
    this.pendingSync = false,
    this.deleted = false,
    this.quantity,
    this.unit,
    this.pricePerUnit,
    this.client,
    this.provider,
    this.harvestId,
    this.sowingId,
    this.deductionQty,
    this.deductionReason,
    this.paid = true,
    this.task,
    this.harvestedKg,
    this.equivalentKg,
    this.cohortSowingId,
  });

  /// Lo que realmente se pagó: lo entregado menos lo descontado.
  ///
  /// Sin descuento devuelve [quantity] tal cual, así que los movimientos
  /// viejos y los nuevos sin descuento dan exactamente el mismo número.
  double? get netQuantity {
    final q = quantity;
    if (q == null) return null;
    final d = deductionQty;
    if (d == null || d <= 0) return q;
    final net = q - d;
    return net < 0 ? 0 : net;
  }

  /// ¿Tiene algún descuento registrado?
  bool get hasDeduction =>
      deductionQty != null && deductionQty! > 0 && !deleted;

  /// Marcador para distinguir "no tocar este campo" (`copyWith()`) de "borrarlo"
  /// (`copyWith(cropId: null)`). Sin él el null se interpretaba como "conserva el
  /// anterior", y así los tres ids de referencia (`crop_id`, `harvest_id`,
  /// `sowing_id`) no se podían desvincular: al borrar, el movimiento seguía
  /// apuntando a una fila que ya no existe y la BD rechazaba la subida.
  static const Object _keep = Object();

  Transaction copyWith({
    String? id,
    Object? cropId = _keep,
    Object? terrenoId = _keep,
    TransactionType? type,
    String? category,
    double? amount,
    String? currency,
    String? description,
    DateTime? date,
    DateTime? createdAt,
    bool? pendingSync,
    bool? deleted,
    double? quantity,
    String? unit,
    double? pricePerUnit,
    String? client,
    String? provider,
    Object? harvestId = _keep,
    Object? sowingId = _keep,
    Object? deductionQty = _keep,
    Object? deductionReason = _keep,
    bool? paid,
    Object? task = _keep,
    Object? harvestedKg = _keep,
    Object? equivalentKg = _keep,
    Object? cohortSowingId = _keep,
  }) {
    return Transaction(
      id: id ?? this.id,
      cropId: cropId == _keep ? this.cropId : cropId as String?,
      // Misma sentinela que `cropId`: poder cambiar un gasto de "del café" a
      // "del lote" y de vuelta sin dejar el dato atascado.
      terrenoId: terrenoId == _keep ? this.terrenoId : terrenoId as String?,
      type: type ?? this.type,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      description: description ?? this.description,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      pendingSync: pendingSync ?? this.pendingSync,
      deleted: deleted ?? this.deleted,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      client: client ?? this.client,
      provider: provider ?? this.provider,
      harvestId: harvestId == _keep ? this.harvestId : harvestId as String?,
      sowingId: sowingId == _keep ? this.sowingId : sowingId as String?,
      deductionQty: deductionQty == _keep
          ? this.deductionQty
          // num → double: el parámetro es Object? para poder limpiar con
          // null, y un literal entero (deductionQty: 80) no debe reventar.
          : (deductionQty as num?)?.toDouble(),
      deductionReason: deductionReason == _keep
          ? this.deductionReason
          : deductionReason as String?,
      paid: paid ?? this.paid,
      // Sentinela igual que los tres ids: sin ella no habría forma de
      // QUITARLE la labor a un jornal, que es lo que pasa al cambiarlo de
      // categoría a algo que no es mano de obra.
      task: task == _keep ? this.task : task as String?,
      // Misma sentinela: al dejar de ser «Cosechar» hay que poder limpiar
      // los kilos, no conservarlos escondidos (D12).
      harvestedKg: harvestedKg == _keep
          ? this.harvestedKg
          : (harvestedKg as num?)?.toDouble(),
      // Sentinela: al cambiar la unidad de la venta hay que poder borrar el
      // peso, no dejarlo escondido en un racimo que ya no existe.
      equivalentKg: equivalentKg == _keep
          ? this.equivalentKg
          : (equivalentKg as num?)?.toDouble(),
      // Sentinela: al cambiar de labor o de cultivo hay que poder limpiar el
      // lote sin dejar la atribución escondida.
      cohortSowingId: cohortSowingId == _keep
          ? this.cohortSowingId
          : cohortSowingId as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'crop_id': cropId,
        'terreno_id': terrenoId,
        'type': type.serialize,
        'category': category,
        'amount': amount,
        'currency': currency,
        'description': description,
        'date': date.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'pending_sync': pendingSync,
        'deleted': deleted,
        'quantity': quantity,
        'unit': unit,
        'price_per_unit': pricePerUnit,
        'client': client,
        'provider': provider,
        'harvest_id': harvestId,
        'sowing_id': sowingId,
        'deduction_qty': deductionQty,
        'deduction_reason': deductionReason,
        'paid': paid,
        'task': task,
        'harvested_kg': harvestedKg,
        'equivalent_kg': equivalentKg,
        'cohort_sowing_id': cohortSowingId,
      };

  factory Transaction.fromJson(Map<String, dynamic> json) {
    final type = TransactionType.parse(json['type'] as String);
    final category = json['category'] as String;
    final cropId = json['crop_id'] as String?;
    final terrenoId = json['terreno_id'] as String?;
    final task = json['task'] as String?;
    final harvestedKg = (json['harvested_kg'] as num?)?.toDouble();
    final cohortRaw = json['cohort_sowing_id'] as String?;

    // Etapa B · el lote solo tiene sentido en un jornal de «Cosechar» con
    // kilos, dentro de un cultivo y sin lote de terreno. Un registro que llegue
    // al revés se limpia y se marca sucio para que la corrección suba.
    //
    // Un puntero a una siembra que no está NO se limpia aquí: `fromJson` no
    // conoce las siembras y el pull puede llegar en desorden; la regla de
    // lectura (`cohortKilos`) lo trata como «sin lote».
    final puedeLlevarLote = cohortRaw != null &&
        type == TransactionType.expense &&
        category == 'mano_obra' &&
        task == kTaskCosechar &&
        harvestedKg != null &&
        harvestedKg > 0 &&
        cropId != null &&
        terrenoId == null;
    final sucioLote = cohortRaw != null && !puedeLlevarLote;

    return Transaction(
      id: json['id'] as String,
      cropId: cropId,
      // Clave ausente en respaldos viejos → null → se comporta como siempre.
      terrenoId: terrenoId,
      type: type,
      category: category,
      amount: (json['amount'] as num).toDouble(),
      currency: (json['currency'] as String?) ?? 'COP',
      description: (json['description'] as String?) ?? '',
      date: DateTime.parse(json['date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      pendingSync: ((json['pending_sync'] as bool?) ?? false) || sucioLote,
      deleted: (json['deleted'] as bool?) ?? false,
      quantity: (json['quantity'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
      pricePerUnit: (json['price_per_unit'] as num?)?.toDouble(),
      client: json['client'] as String?,
      provider: json['provider'] as String?,
      harvestId: json['harvest_id'] as String?,
      sowingId: json['sowing_id'] as String?,
      deductionQty: (json['deduction_qty'] as num?)?.toDouble(),
      deductionReason: json['deduction_reason'] as String?,
      // true por defecto: un dato viejo sin marca es plata que entró.
      paid: (json['paid'] as bool?) ?? true,
      // Respaldos anteriores a E3 no traen la clave → null → sin labor.
      task: task,
      // Tanda 2 · clave ausente en respaldos viejos → null → sin cosecha.
      harvestedKg: harvestedKg,
      // Tanda 4 · clave ausente en respaldos viejos → null → sin peso.
      equivalentKg: (json['equivalent_kg'] as num?)?.toDouble(),
      // Etapa B · ausente en respaldos viejos → null → sin lote.
      cohortSowingId: puedeLlevarLote ? cohortRaw : null,
    );
  }
}
