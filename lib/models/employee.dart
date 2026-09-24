class Employee {
  final String id;
  final String name;

  /// Valor por día (opcional): autocompleta el bloque jornal al registrar
  /// un gasto de mano de obra. null = se define en cada jornal.
  final double? dayRate;
  final bool pendingSync;

  const Employee({
    required this.id,
    required this.name,
    this.dayRate,
    this.pendingSync = false,
  });

  Employee copyWith({
    String? id,
    String? name,
    Object? dayRate = _sentinel,
    bool? pendingSync,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      dayRate: dayRate == _sentinel ? this.dayRate : dayRate as double?,
      pendingSync: pendingSync ?? this.pendingSync,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (dayRate != null) 'day_rate': dayRate,
        'pending_sync': pendingSync,
      };

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as String,
      name: json['name'] as String,
      dayRate: (json['day_rate'] as num?)?.toDouble(),
      pendingSync: (json['pending_sync'] as bool?) ?? false,
    );
  }
}

const _sentinel = Object();
