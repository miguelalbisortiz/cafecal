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

/// Clave de la categoría de gasto generada por el flujo de siembra: al
/// registrar una siembra con costo, la pantalla crea un gasto vinculado
/// bajo esta categoría (única vía de entrada: no se elige manualmente en el
/// editor de gastos porque el costo nace de la propia siembra).
const String kExpenseCategorySowing = 'siembra';

/// Clave de la categoría de gasto de recolección. Es la contraparte de
/// [kExpenseCategorySowing] para el flujo de cosecha: se registra de forma
/// manual y puede vincularse a una cosecha concreta desde el editor de gastos.
const String kExpenseCategoryHarvest = 'cosecha';

/// Categorías de gasto que descuentan de la caja menor además de los
/// jornales (mano de obra). Son los "gastos extras o misceláneos" de la
/// planilla: energía, agua, imprevistos y arreglos. Insumos, abonos y
/// fertilizantes NO están aquí (son inversión de producción).
/// Ajustable: agregar una categoría a este set la hace descontar de caja.
const Set<String> kCashBoxExtraCategories = {
  'energia',
  'agua',
  'otro',
  'mantenimiento',
};

/// ¿Este gasto descuenta de la caja menor? Jornales + extras.
bool discountsCashBox(String category) =>
    category == 'mano_obra' || kCashBoxExtraCategories.contains(category);

/// Clave de la categoría de ingreso "venta de cosecha". La etiqueta se
/// completa con el nombre del cultivo elegido en el movimiento
/// ("Venta plátano", "Venta café"…); sin cultivo se muestra "Venta".
/// Antes cada cultivo tenía su propia clave fija (venta_cafe, …): esas
/// claves legadas siguen mostrándose igual en los datos viejos.
const String kIncomeCategorySale = 'venta';

/// ¿La categoría de ingreso es una venta (cualquier época)?
/// Cubre la clave nueva [kIncomeCategorySale] y las legadas venta_*.
bool isSaleCategory(String category) =>
    category == kIncomeCategorySale || category.startsWith('venta_');

const List<ExpenseCategory> expenseCategories = [
  ExpenseCategory(key: kExpenseCategorySowing, name: 'Siembra', icon: '🌱', color: '#2E7D32'),
  ExpenseCategory(key: 'semillas_insumos', name: 'Semillas e insumos', icon: '🌾', color: '#7CB342'),
  ExpenseCategory(key: 'fertilizante', name: 'Fertilizante', icon: '🧪', color: '#43A047'),
  ExpenseCategory(key: 'mano_obra', name: 'Mano de obra', icon: '👷', color: '#1E88E5'),
  ExpenseCategory(key: kExpenseCategoryHarvest, name: 'Cosecha y recolección', icon: '🧺', color: '#F57F17'),
  ExpenseCategory(key: 'plagas', name: 'Control plagas', icon: '🐛', color: '#E53935'),
  ExpenseCategory(key: 'riego', name: 'Riego', icon: '💧', color: '#00ACC1'),
  ExpenseCategory(key: 'energia', name: 'Energía', icon: '⚡', color: '#FBC02D'),
  ExpenseCategory(key: 'agua', name: 'Agua', icon: '🚿', color: '#039BE5'),
  ExpenseCategory(key: 'empaque', name: 'Empacado y comercialización', icon: '🛍️', color: '#5E35B1'),
  ExpenseCategory(key: 'transporte', name: 'Transporte', icon: '🚛', color: '#FB8C00'),
  ExpenseCategory(key: 'equipo', name: 'Equipo', icon: '🔧', color: '#8E24AA'),
  ExpenseCategory(key: 'mantenimiento', name: 'Mantenimiento', icon: '🛠️', color: '#6D4C41'),
  ExpenseCategory(key: 'arriendo', name: 'Arriendo de tierras', icon: '🏞️', color: '#78909C'),
  ExpenseCategory(key: 'impuestos', name: 'Impuestos y tasas', icon: '🧾', color: '#546E7A'),
  ExpenseCategory(key: 'otro', name: 'Otro', icon: '📦', color: '#757575'),
];

const List<IncomeCategory> incomeCategories = [
  IncomeCategory(key: kIncomeCategorySale, name: 'Venta', icon: '💰', color: '#2E7D32'),
  IncomeCategory(key: 'subvenciones', name: 'Subvenciones y apoyos', icon: '🤝', color: '#00897B'),
  IncomeCategory(key: 'venta_otro', name: 'Venta otros', icon: '💰', color: '#2E7D32'),
  // Legadas: cada cultivo tenía su clave fija. Ya no se ofrecen al
  // registrar (la venta nueva toma el nombre del cultivo del movimiento),
  // pero se conservan para icono/color y etiqueta de los datos viejos.
  IncomeCategory(key: 'venta_cafe', name: 'Venta café', icon: '☕', color: '#6D4C41'),
  IncomeCategory(key: 'venta_platano', name: 'Venta plátano', icon: '🍌', color: '#F9A825'),
];