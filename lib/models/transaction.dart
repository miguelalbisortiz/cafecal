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
  });

  Transaction copyWith({
    String? id,
    String? cropId,
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
    String? harvestId,
    String? sowingId,
  }) {
    return Transaction(
      id: id ?? this.id,
      cropId: cropId ?? this.cropId,
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
      harvestId: harvestId ?? this.harvestId,
      sowingId: sowingId ?? this.sowingId,
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
    );
  }
}
