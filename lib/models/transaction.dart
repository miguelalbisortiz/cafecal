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

  const Transaction({
    required this.id,
    this.cropId,
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
  }) {
    return Transaction(
      id: id ?? this.id,
      cropId: cropId == _keep ? this.cropId : cropId as String?,
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
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'crop_id': cropId,
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
      };

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      cropId: json['crop_id'] as String?,
      type: TransactionType.parse(json['type'] as String),
      category: json['category'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: (json['currency'] as String?) ?? 'COP',
      description: (json['description'] as String?) ?? '',
      date: DateTime.parse(json['date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      pendingSync: (json['pending_sync'] as bool?) ?? false,
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
    );
  }
}
