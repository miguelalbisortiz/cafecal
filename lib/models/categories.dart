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

/// Clave de la categoría de gasto "Siembra".
///
/// Tiene **dos** vías de entrada, y las dos son válidas:
///  1. El flujo de siembra: al registrar una siembra con costo, la pantalla
///     crea un gasto vinculado bajo esta categoría.
///  2. El editor de gastos: **se elige a mano**. Es el camino corto para
///     anotar colinos, semillones o plantas compradas sin abrir una siembra.
///
/// La vía 2 no es un hueco: el gasto igual cuenta como inversión del
/// cultivo y entra en su costo/kg
/// (`report_harvest_metrics.dart`, `transaction_provider.dart`). Sin ella,
/// registrar 30 colinos de plátano obligaría a fingir una "siembra" solo
/// por anotar la plata.
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
///
/// **Decisión 2026-10-11 (H7): `otro` sigue descontando, a propósito.**
/// En la planilla de papel, "caja" es plata chica para todo lo que no es un
/// insumo: la mano de obra y **cualquier gasto adicional que no cabe en una
/// categoría fija**. Si `otro` no descontara, esa plata quedaría por fuera
/// del presupuesto mensual y dejaría de vigilarse. El riesgo de que una
/// compra grande mal clasificada dispare la barra es preferible a perderla
/// de vista.
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
  // H5 · inversión inicial del terreno: lo que se gasta ANTES de que el
  // cultivo arranque (cerca, tapia, desmonte, preparación de camellones).
  ExpenseCategory(key: 'cercas_preparacion', name: 'Cercas y preparación', icon: '🚧', color: '#5D4037'),
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
  // H5 · lo que se pide prestado y lo que cuesta mantenerse asegurado:
  // el interés no es insumo, es el precio de haber tenido plata antes.
  ExpenseCategory(key: 'credito_intereses', name: 'Crédito e intereses', icon: '💸', color: '#8D6E63'),
  ExpenseCategory(key: 'seguros', name: 'Seguros', icon: '🛡️', color: '#00838F'),
  ExpenseCategory(key: 'otro', name: 'Otro', icon: '📦', color: '#757575'),
];

/// Bloques en que se agrupan los gastos en el estado de resultados (P5).
///
/// La idea es responder "¿cuánto me costó producir?" sin sumar a mano las
/// categorías. `otros` recoge la clave `otro` y cualquier clave legada no
/// reconocida, para que ningún gasto se pierda de vista.
enum ExpenseGroup { produccion, venta, fijos, otros }

const Set<String> _productionKeys = {
  'siembra',
  'cercas_preparacion',
  'semillas_insumos',
  'fertilizante',
  'mano_obra',
  'cosecha',
  'plagas',
  'riego',
};

const Set<String> _sellingKeys = {
  'empaque',
  'transporte',
};

const Set<String> _fixedKeys = {
  'arriendo',
  'energia',
  'agua',
  'equipo',
  'mantenimiento',
  'impuestos',
  'credito_intereses',
  'seguros',
};

/// Grupo de una categoría de gasto. Ver [expenseGroupOf].
ExpenseGroup expenseGroupOf(String key) {
  if (_productionKeys.contains(key)) return ExpenseGroup.produccion;
  if (_sellingKeys.contains(key)) return ExpenseGroup.venta;
  if (_fixedKeys.contains(key)) return ExpenseGroup.fijos;
  return ExpenseGroup.otros;
}

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