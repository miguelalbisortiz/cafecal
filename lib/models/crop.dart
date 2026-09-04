class Crop {
  final String id;
  final String name;
  final String icon;
  final String color;
  final bool pendingSync;

  const Crop({
    required this.id,
    required this.name,
    this.icon = '🌱',
    this.color = '#2E7D32',
    this.pendingSync = false,
  });

  Crop copyWith({
    String? id,
    String? name,
    String? icon,
    String? color,
    bool? pendingSync,
  }) {
    return Crop(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      pendingSync: pendingSync ?? this.pendingSync,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'color': color,
        'pending_sync': pendingSync,
      };

  factory Crop.fromJson(Map<String, dynamic> json) {
    return Crop(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: (json['icon'] as String?) ?? '🌱',
      color: (json['color'] as String?) ?? '#2E7D32',
      pendingSync: (json['pending_sync'] as bool?) ?? false,
    );
  }
}

const List<Crop> defaultCrops = [
  Crop(id: 'cafe', name: 'Café', icon: '☕', color: '#6D4C41'),
  Crop(id: 'platano', name: 'Plátano', icon: '🍌', color: '#F9A825'),
  Crop(id: 'otro', name: 'Otro', icon: '🌱', color: '#2E7D32'),
];