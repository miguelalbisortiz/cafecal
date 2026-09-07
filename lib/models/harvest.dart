class Harvest {
  final String id;
  final String? cropId;
  final DateTime date;
  final double amount;
  final String unit;
  final HarvestDestination destination;
  final bool pendingSync;

  const Harvest({
    required this.id,
    this.cropId,
    required this.date,
    required this.amount,
    this.unit = 'kg',
    this.destination = HarvestDestination.vendido,
    this.pendingSync = false,
  });

  Harvest copyWith({
    String? id,
    String? cropId,
    DateTime? date,
    double? amount,
    String? unit,
    HarvestDestination? destination,
    bool? pendingSync,
  }) {
    return Harvest(
      id: id ?? this.id,
      cropId: cropId ?? this.cropId,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      destination: destination ?? this.destination,
      pendingSync: pendingSync ?? this.pendingSync,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'crop_id': cropId,
        'date': date.toIso8601String(),
        'amount': amount,
        'unit': unit,
        'destination': destination.name,
        'pending_sync': pendingSync,
      };

  factory Harvest.fromJson(Map<String, dynamic> json) {
    return Harvest(
      id: json['id'] as String,
      cropId: json['crop_id'] as String?,
      date: DateTime.parse(json['date'] as String),
      amount: (json['amount'] as num).toDouble(),
      unit: (json['unit'] as String?) ?? 'kg',
      destination: HarvestDestination.values.firstWhere(
        (d) => d.name == json['destination'],
        orElse: () => HarvestDestination.vendido,
      ),
      pendingSync: (json['pending_sync'] as bool?) ?? false,
    );
  }
}

enum HarvestDestination {
  vendido,
  almacenado,
  perdida;
}
