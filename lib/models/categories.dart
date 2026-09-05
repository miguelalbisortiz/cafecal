class ExpenseCategory {
  final String key;
  final String name;
  final String icon;
  final String color;

  const ExpenseCategory({
    required this.key,
    required this.name,
    required this.icon,
    required this.color,
  });
}

class IncomeCategory {
  final String key;
  final String name;
  final String icon;
  final String color;

  const IncomeCategory({
    required this.key,
    required this.name,
    required this.icon,
    required this.color,
  });
}

const List<ExpenseCategory> expenseCategories = [
  ExpenseCategory(key: 'siembra', name: 'Siembra', icon: '🌱', color: '#2E7D32'),
  ExpenseCategory(key: 'semillas_insumos', name: 'Semillas e insumos', icon: '🌾', color: '#7CB342'),
  ExpenseCategory(key: 'fertilizante', name: 'Fertilizante', icon: '🧪', color: '#43A047'),
  ExpenseCategory(key: 'mano_obra', name: 'Mano de obra', icon: '👷', color: '#1E88E5'),
  ExpenseCategory(key: 'cosecha', name: 'Cosecha y recolección', icon: '🧺', color: '#F57F17'),
  ExpenseCategory(key: 'plagas', name: 'Control plagas', icon: '🐛', color: '#E53935'),
  ExpenseCategory(key: 'riego', name: 'Riego', icon: '💧', color: '#00ACC1'),
  ExpenseCategory(key: 'empaque', name: 'Empacado y comercialización', icon: '🛍️', color: '#5E35B1'),
  ExpenseCategory(key: 'transporte', name: 'Transporte', icon: '🚛', color: '#FB8C00'),
  ExpenseCategory(key: 'equipo', name: 'Equipo', icon: '🔧', color: '#8E24AA'),
  ExpenseCategory(key: 'mantenimiento', name: 'Mantenimiento', icon: '🛠️', color: '#6D4C41'),
  ExpenseCategory(key: 'arriendo', name: 'Arriendo de tierras', icon: '🏞️', color: '#78909C'),
  ExpenseCategory(key: 'impuestos', name: 'Impuestos y tasas', icon: '🧾', color: '#546E7A'),
  ExpenseCategory(key: 'otro', name: 'Otro', icon: '📦', color: '#757575'),
];

const List<IncomeCategory> incomeCategories = [
  IncomeCategory(key: 'venta_cafe', name: 'Venta café', icon: '☕', color: '#6D4C41'),
  IncomeCategory(key: 'venta_platano', name: 'Venta plátano', icon: '🍌', color: '#F9A825'),
  IncomeCategory(key: 'subvenciones', name: 'Subvenciones y apoyos', icon: '🤝', color: '#00897B'),
  IncomeCategory(key: 'venta_otro', name: 'Venta otros', icon: '💰', color: '#2E7D32'),
];