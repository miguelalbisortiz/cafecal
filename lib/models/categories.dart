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
  ExpenseCategory(key: 'fertilizante', name: 'Fertilizante', icon: '🧪', color: '#43A047'),
  ExpenseCategory(key: 'mano_obra', name: 'Mano de obra', icon: '👷', color: '#1E88E5'),
  ExpenseCategory(key: 'plagas', name: 'Control plagas', icon: '🐛', color: '#E53935'),
  ExpenseCategory(key: 'riego', name: 'Riego', icon: '💧', color: '#00ACC1'),
  ExpenseCategory(key: 'transporte', name: 'Transporte', icon: '🚛', color: '#FB8C00'),
  ExpenseCategory(key: 'equipo', name: 'Equipo', icon: '🔧', color: '#8E24AA'),
  ExpenseCategory(key: 'mantenimiento', name: 'Mantenimiento', icon: '🛠️', color: '#6D4C41'),
  ExpenseCategory(key: 'otro', name: 'Otro', icon: '📦', color: '#757575'),
];

const List<IncomeCategory> incomeCategories = [
  IncomeCategory(key: 'venta_cafe', name: 'Venta café', icon: '☕', color: '#6D4C41'),
  IncomeCategory(key: 'venta_platano', name: 'Venta plátano', icon: '🍌', color: '#F9A825'),
  IncomeCategory(key: 'venta_otro', name: 'Venta otros', icon: '💰', color: '#2E7D32'),
];

String expenseCategoryLabel(String key) {
  for (final c in expenseCategories) {
    if (c.key == key) return c.name;
  }
  return key;
}

String incomeCategoryLabel(String key) {
  for (final c in incomeCategories) {
    if (c.key == key) return c.name;
  }
  return key;
}