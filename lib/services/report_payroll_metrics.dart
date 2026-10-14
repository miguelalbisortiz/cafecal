import '../models/categories.dart';
import '../models/tasks.dart';
import '../models/transaction.dart';
import 'pdf_export_service.dart' show ReportPeriod;
import 'week_utils.dart';

/// Fila de nómina: un trabajador (nombre snapshot en `provider`) con sus
/// días totales y el subtotal pagado en el período.
class PayrollRow {
  final String provider; // '' = gasto sin nombre de trabajador
  final double days;

  /// Montos pagados **por moneda** (clave = código ISO). Nunca se suman
  /// monedas distintas: con una sola moneda es el subtotal de siempre.
  final Map<String, double> byCurrency;

  PayrollRow({
    required this.provider,
    required this.days,
    Map<String, double>? byCurrency,
  }) : byCurrency = byCurrency ?? <String, double>{};

  /// Suma aritmética de [byCurrency]: válida con moneda única; con mezcla
  /// solo sirve para ordenar, no para mostrar.
  double get subtotal =>
      byCurrency.values.fold<double>(0, (a, b) => a + b);

  /// true → este trabajador cobró en más de una moneda.
  bool get isMixed => byCurrency.length > 1;
}

/// Resumen de nómina del período.
class PayrollSummary {
  final List<PayrollRow> rows;

  /// Cantidad de empleados: trabajadores distintos (nombres no vacíos en
  /// `provider`) con gasto de mano de obra en el período. No se anota a mano.
  final int distinctEmployees;

  PayrollSummary({
    required this.rows,
    required this.distinctEmployees,
  });

  /// Suma de los subtotales: cifra válida con moneda única; con moneda
  /// mixta hay que usar [totalByCurrency].
  double get total => rows.fold<double>(0, (a, r) => a + r.subtotal);

  /// Total del período **separado por moneda**.
  Map<String, double> get totalByCurrency {
    final out = <String, double>{};
    for (final r in rows) {
      r.byCurrency.forEach((code, v) => out[code] = (out[code] ?? 0) + v);
    }
    return out;
  }

  /// true → la nómina del período toca más de una moneda.
  bool get isMixed => totalByCurrency.length > 1;

  bool get isEmpty => rows.isEmpty;
}

/// Una línea de la **planilla** del mes (E3): una labor, en un cultivo, con
/// la gente que la hizo.
///
/// Es lo que antes no se podía responder: no solo cuánto se gastó en gente,
/// sino **en qué se la gastó**. Se agrupa por (labor, cultivo) — no por
/// persona — porque el plan del mes se lee así: "Descolgar café, 4 hombres
/// 2 días, $400.000".
class WorkSheetRow {
  /// Tecla de `farmTasks` o texto libre. Null = jornal viejo sin labor.
  final String? task;

  final String? cropId;

  /// Nombre ya resuelto para pintar (cultivo encontrado, o la leyenda de
  /// "sin cultivo" que pase el caller).
  final String cropName;

  /// Personas distintas que hicieron esta labor en este cultivo.
  final int workers;

  /// Día-persona totales: si 4 hombres trabajaron 2 días, son 8.
  final double days;

  /// Montos **por moneda**. Nunca se suman monedas distintas.
  final Map<String, double> byCurrency;

  WorkSheetRow({
    required this.task,
    required this.cropId,
    required this.cropName,
    required this.workers,
    required this.days,
    Map<String, double>? byCurrency,
  }) : byCurrency = byCurrency ?? <String, double>{};

  double get total => byCurrency.values.fold<double>(0, (a, b) => a + b);
  Set<String> get currencies => byCurrency.keys.toSet();
  bool get isMixed => currencies.length > 1;
}

/// Consumo del **presupuesto de obra** de un mes calendario (E3).
///
/// Solo cuenta mano de obra: es la contraparte de [CashBoxMonthRow], que es
/// la caja. Existen aparte porque "gasté mucho en gente" y "gasté mucho en
/// misceláneos" son señales opuestas y no deben compartir barra.
class WorkMonthRow {
  final int year;
  final int month; // 1-12
  final double budget;

  /// Mano de obra del mes **por moneda**. Nunca se suman monedas distintas.
  final Map<String, double> laborByCurrency;

  const WorkMonthRow({
    required this.year,
    required this.month,
    required this.budget,
    required this.laborByCurrency,
  });

  /// Suma aritmética: solo comparable con [budget] si hay una sola moneda
  /// y es la del presupuesto.
  double get used => laborByCurrency.values.fold<double>(0, (a, b) => a + b);

  /// Positivo = lo que queda de presupuesto; negativo = obra agotada.
  double get balance => budget - used;

  Set<String> get currencies => laborByCurrency.keys.toSet();

  /// true → la mano de obra del mes mezcla monedas: no se compara con el
  /// presupuesto ni se imprime un porcentaje.
  bool get isMixed => currencies.length > 1;
}

/// Consumo de caja menor de un mes calendario dentro del período.
class CashBoxMonthRow {
  final int year;
  final int month; // 1-12
  final double budget;

  /// Jornales (mano de obra) **por moneda**.
  final Map<String, double> laborByCurrency;

  /// Extras de caja (`kCashBoxExtraCategories`) **por moneda**.
  final Map<String, double> extrasByCurrency;

  const CashBoxMonthRow({
    required this.year,
    required this.month,
    required this.budget,
    required this.laborByCurrency,
    required this.extrasByCurrency,
  });

  /// Jornales: suma aritmética (solo comparable con [budget] si hay una
  /// sola moneda y es la del presupuesto).
  double get labor =>
      laborByCurrency.values.fold<double>(0, (a, b) => a + b);

  /// Extras: misma regla que [labor].
  double get extras =>
      extrasByCurrency.values.fold<double>(0, (a, b) => a + b);

  double get total => labor + extras;

  /// Positivo = lo que queda; negativo = caja agotada. Solo es una cifra
  /// cierta si los gastos están en la misma moneda que el presupuesto.
  double get balance => budget - total;

  /// Monedas de los gastos de caja de ese mes.
  Set<String> get currencies =>
      {...laborByCurrency.keys, ...extrasByCurrency.keys};

  /// true → los gastos de caja del mes mezclan monedas: no se compara con
  /// el presupuesto ni se suma un total único.
  bool get isMixed => currencies.length > 1;

  /// Gastos del mes (jornales + extras) **por moneda**.
  Map<String, double> get totalByCurrency {
    final out = <String, double>{};
    laborByCurrency.forEach((c, v) => out[c] = (out[c] ?? 0) + v);
    extrasByCurrency.forEach((c, v) => out[c] = (out[c] ?? 0) + v);
    return out;
  }
}

/// Métricas de nómina y caja menor para los reportes (PDF, Excel y pantalla).
/// Lógica única compartida por los tres renderers.
class ReportPayrollMetrics {
  const ReportPayrollMetrics();

  /// Agrupa los gastos de mano de obra del período por trabajador (snapshot
  /// en `provider`). El total incluye todos los gastos; los empleados
  /// distintos solo cuentan nombres no vacíos.
  PayrollSummary payroll(Iterable<Transaction> periodTx) {
    final days = <String, double>{};
    final amounts = <String, Map<String, double>>{};
    final employees = <String>{};

    for (final t in periodTx) {
      if (t.deleted || !t.type.isExpense || t.category != 'mano_obra') {
        continue;
      }
      final key = (t.provider ?? '').trim();
      final byCurrency = amounts.putIfAbsent(key, () => <String, double>{});
      byCurrency[t.currency] = (byCurrency[t.currency] ?? 0) + t.amount;
      if (t.quantity != null) {
        days[key] = (days[key] ?? 0) + t.quantity!;
      }
      if (key.isNotEmpty) employees.add(key);
    }

    final rows = amounts.entries
        .map((e) => PayrollRow(
              provider: e.key,
              days: days[e.key] ?? 0,
              byCurrency: e.value,
            ))
        .toList()
      ..sort((a, b) => b.subtotal.compareTo(a.subtotal));

    return PayrollSummary(
      rows: rows,
      distinctEmployees: employees.length,
    );
  }

  /// Una fila por mes del período con el presupuesto de caja configurado.
  /// Los meses sin gastos también aparecen (control anual mes a mes); el
  /// saldo NO se acumula entre meses: cada fila se reinicia con su presupuesto.
  /// Devuelve vacío si no hay presupuesto (caja desactivada).
  ///
  /// [includeLabor] · E3. `true` (por defecto) cuenta jornales + extras, que
  /// es lo que la caja hacía siempre. `false` deja afuera la mano de obra:
  /// eso solo pasa cuando hay un **presupuesto de obra** configurado, porque
  /// entonces la gente tiene su propia barra y contarla dos veces inventaría
  /// un gasto.
  List<CashBoxMonthRow> cashBoxByMonth({
    required Iterable<Transaction> periodTx,
    required double? budget,
    required ReportPeriod period,
    required int year,
    int? month,
    DateTime? now,
    bool includeLabor = true,
  }) {
    final b = budget;
    if (b == null || b <= 0) return const [];
    final ref = now ?? DateTime.now();

    final labor = <String, Map<String, double>>{};
    final extras = <String, Map<String, double>>{};
    for (final t in periodTx) {
      if (t.deleted || !t.type.isExpense || !discountsCashBox(t.category)) {
        continue;
      }
      final isLabor = t.category == 'mano_obra';
      if (isLabor && !includeLabor) continue;
      final key = '${t.date.year}-${t.date.month}';
      final byCurrency = (isLabor ? labor : extras)
          .putIfAbsent(key, () => <String, double>{});
      byCurrency[t.currency] = (byCurrency[t.currency] ?? 0) + t.amount;
    }

    final keys = <String>{...labor.keys, ...extras.keys};
    _seedMonths(keys, period: period, year: year, month: month, ref: ref);

    final out = <CashBoxMonthRow>[];
    for (final key in _sortedMonthKeys(keys)) {
      final parts = key.split('-');
      out.add(CashBoxMonthRow(
        year: int.parse(parts[0]),
        month: int.parse(parts[1]),
        budget: b,
        laborByCurrency: Map.of(labor[key] ?? const {}),
        extrasByCurrency: Map.of(extras[key] ?? const {}),
      ));
    }
    return out;
  }

  /// Sobrante de caja acumulado hasta el mes **anterior** a [year]/[month].
  ///
  /// Regla: cada mes aporta [budget] y resta lo que se gastó en caja ese mes.
  /// Lo que no se gasta **no desaparece**: se arrastra al mes siguiente. No
  /// hay reinicio en enero — un fondo de caja no se borra por calendario, se
  /// gasta.
  ///
  /// El arrastre arranca en el primer mes con registros, así "desde que llevo
  /// anotando" es exactamente lo que cuenta.
  ///
  /// Devuelve `null` cuando no se puede calcular sin mentir: si algún mes del
  /// tramo gastó caja en otra moneda que la del presupuesto, restarlo sería
  /// sumar monedas distintas. `null` es "no lo sé", **no** 0.
  double? cashCarryUpTo({
    required Iterable<Transaction> allTx,
    required double budget,
    required String budgetCurrency,
    required int year,
    required int month,
  }) {
    if (budget <= 0 || budgetCurrency.isEmpty) return null;

    // Gastos de caja por mes, separados por moneda: así un mes mezclado se
    // detecta en vez de sumarse en silencio.
    final byMonth = <String, Map<String, double>>{};
    final months = <String>{};
    for (final t in allTx) {
      if (t.deleted) continue;
      final key = '${t.date.year}-${t.date.month}';
      months.add(key);
      if (!t.type.isExpense || !discountsCashBox(t.category)) continue;
      final byCurrency = byMonth.putIfAbsent(key, () => <String, double>{});
      byCurrency[t.currency] = (byCurrency[t.currency] ?? 0) + t.amount;
    }
    if (months.isEmpty) return 0;

    // El mes de arranque es el primer mes con registros: antes de eso no
    // había finca que llevar. Desde ahí **todos** los meses cuentan, aunque
    // no se haya anotado nada — un mes sin gasto es un mes en que el aporte
    // sigue entero.
    final start = _sortedMonthKeys(months).map((k) {
      final p = k.split('-');
      return int.parse(p[0]) * 12 + int.parse(p[1]);
    }).first;
    final target = year * 12 + month;
    if (start >= target) return 0;

    var carry = 0.0;
    for (var ym = start; ym < target; ym++) {
      final key = '${(ym - 1) ~/ 12}-${(ym - 1) % 12 + 1}';
      final spent = byMonth[key] ?? const <String, double>{};
      if (spent.keys.any((c) => c != budgetCurrency)) return null;
      carry += budget - (spent[budgetCurrency] ?? 0);
    }
    return carry;
  }

  /// E3 · lo mismo que [cashBoxByMonth], pero solo para la **obra**.
  ///
  /// Existe porque la obra tiene su propio presupuesto y su propia barra: si
  /// la gente se contara también dentro de la caja, el mismo jornal
  /// aparecería gastado dos veces.
  List<WorkMonthRow> workBudgetByMonth({
    required Iterable<Transaction> periodTx,
    required double? budget,
    required ReportPeriod period,
    required int year,
    int? month,
    DateTime? now,
  }) {
    final b = budget;
    if (b == null || b <= 0) return const [];
    final ref = now ?? DateTime.now();

    final labor = <String, Map<String, double>>{};
    for (final t in periodTx) {
      if (t.deleted || !t.type.isExpense || t.category != 'mano_obra') {
        continue;
      }
      final key = '${t.date.year}-${t.date.month}';
      final byCurrency = labor.putIfAbsent(key, () => <String, double>{});
      byCurrency[t.currency] = (byCurrency[t.currency] ?? 0) + t.amount;
    }

    final keys = <String>{...labor.keys};
    _seedMonths(keys, period: period, year: year, month: month, ref: ref);

    return _sortedMonthKeys(keys).map((key) {
      final parts = key.split('-');
      return WorkMonthRow(
        year: int.parse(parts[0]),
        month: int.parse(parts[1]),
        budget: b,
        laborByCurrency: Map.of(labor[key] ?? const {}),
      );
    }).toList();
  }

  /// E3 · la planilla del período: agrupa la mano de obra por (labor, cultivo).
  ///
  /// Cada línea responde "¿en qué se gastó la gente?" — que era la pregunta
  /// que no se podía hacer con la nómina por trabajador.
  ///
  /// Los jornales **sin labor** no se descartan: salen agrupados aparte con
  /// [unlabeledTaskName]. Si se los tirara, la planilla mentiría sobre cuánto
  /// se gastó (el total dejaría de cuadrar con el presupuesto de obra).
  List<WorkSheetRow> workSheetRows({
    required Iterable<Transaction> periodTx,
    required Map<String, String> cropNames,
    String unlabeledTaskName = '',
  }) {
    final workersByGroup = <String, Set<String>>{};
    final daysByGroup = <String, double>{};
    final amountsByGroup = <String, Map<String, double>>{};
    final metaByGroup = <String, (String?, String)>{}; // (cropId, cropName)

    for (final t in periodTx) {
      if (t.deleted || !t.type.isExpense || t.category != 'mano_obra') {
        continue;
      }
      // Sin cantidad no hay días que sumar: igual que en la nómina, cuenta
      // con 0 días y su monto igual entra, para que el total no se pierda.
      final cropName = t.cropId == null ? '' : (cropNames[t.cropId] ?? '');
      final group = '${t.task ?? '\u0000'}|${t.cropId ?? '\u0000'}';
      metaByGroup[group] = (t.cropId, cropName);

      final days = t.quantity;
      daysByGroup[group] = (daysByGroup[group] ?? 0) + (days ?? 0);

      final provider = t.provider?.trim();
      if (provider != null && provider.isNotEmpty) {
        workersByGroup
            .putIfAbsent(group, () => <String>{})
            .add(provider.toLowerCase());
      }

      final byCurrency =
          amountsByGroup.putIfAbsent(group, () => <String, double>{});
      byCurrency[t.currency] = (byCurrency[t.currency] ?? 0) + t.amount;
    }

    final out = amountsByGroup.keys.map((group) {
      final meta = metaByGroup[group]!;
      return WorkSheetRow(
        task: group.split('|').first == '\u0000'
            ? null
            : group.split('|').first,
        cropId: meta.$1,
        cropName: meta.$2,
        workers: workersByGroup[group]?.length ?? 0,
        days: daysByGroup[group] ?? 0,
        byCurrency: Map.of(amountsByGroup[group] ?? const {}),
      );
    }).toList();

    // Lo de la lista sale en el orden en que se trabaja; lo sin labor y lo
    // de texto libre al final, que es donde le toca.
    final order = <String, int>{
      for (var i = 0; i < farmTasks.length; i++) farmTasks[i].key: i,
    };
    int rank(String? task) {
      if (task == null) return 1000;
      if (isFreeTask(task)) return 999;
      return order[task] ?? 999;
    }

    out.sort((a, b) {
      final ra = rank(a.task);
      final rb = rank(b.task);
      if (ra != rb) return ra - rb;
      final cmp = b.total.compareTo(a.total);
      return cmp != 0 ? cmp : a.cropName.compareTo(b.cropName);
    });

    // La leyenda de "sin labor" se aplica ya resuelta: el campo es final a
    // propósito (una fila de planilla no cambia después de nacer).
    if (unlabeledTaskName.isEmpty) return out;
    return [
      for (final r in out)
        if (r.task == null)
          WorkSheetRow(
            task: unlabeledTaskName,
            cropId: r.cropId,
            cropName: r.cropName,
            workers: r.workers,
            days: r.days,
            byCurrency: Map.of(r.byCurrency),
          )
        else
          r,
    ];
  }

  /// Meses del período a sembrar, para que aparezcan aunque no tengan
  /// gastos (control mes a mes del año entero).
  static void _seedMonths(
    Set<String> keys, {
    required ReportPeriod period,
    required int year,
    required int? month,
    required DateTime ref,
  }) {
    void seed(int y, int m) => keys.add('$y-$m');

    switch (period) {
      case ReportPeriod.week:
        final range = weekRange(year, month ?? 1);
        seed(range.start.year, range.start.month);
        seed(range.end.year, range.end.month);
      case ReportPeriod.month:
        seed(year, month ?? ref.month);
      case ReportPeriod.year:
        for (var m = 1; m <= 12; m++) {
          seed(year, m);
        }
      case ReportPeriod.yearToDate:
        final last = year < ref.year ? 12 : ref.month;
        for (var m = 1; m <= last; m++) {
          seed(year, m);
        }
    }
  }

  /// Orden numérico (año, mes); el orden lexicográfico pondría "10" antes
  /// que "2".
  static List<String> _sortedMonthKeys(Iterable<String> keys) =>
      keys.toList()
        ..sort((a, b) {
          final pa = a.split('-');
          final pb = b.split('-');
          final cmp = int.parse(pa[0]).compareTo(int.parse(pb[0]));
          return cmp != 0 ? cmp : int.parse(pa[1]).compareTo(int.parse(pb[1]));
        });
}
