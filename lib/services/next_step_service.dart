import '../models/crop.dart';
import '../models/harvest.dart';
import '../models/sowing.dart';
import '../models/transaction.dart';

/// Tipo del "próximo paso" que la tarjeta debe guiar.
enum NextStepType {
  /// Crear el primer cultivo.
  crop,

  /// Registrar la siembra de un cultivo joven (establecimiento/renovación).
  sowing,

  /// Registrar los primeros gastos del año.
  expenses,

  /// Registrar la primera cosecha.
  harvest,

  /// Registrar la venta de la cosecha.
  sale,
}

/// Resultado de la guía: qué paso mostrar y a qué cultivo refiere (si aplica).
class NextStep {
  final NextStepType type;

  /// Cultivo al que apunta el paso (siembra), si existe.
  final String? cropId;

  const NextStep({required this.type, this.cropId});
}

const Set<String> _saleCategories = {'venta_cafe', 'venta_platano', 'venta_otro'};

/// True mientras la finca esté vacía (0 cultivos y 0 siembras): el usuario aún
/// no eligió su primer paso. Cualquier cultivo o siembra la desbloquea.
bool needsOnboarding(List<Crop> crops, List<Sowing> sowings) =>
    crops.isEmpty && sowings.isEmpty;

/// Deriva EL siguiente paso que el usuario debe completar, según el estado
/// actual de sus datos. Reglas en orden de prioridad:
///
/// 1. Sin cultivos → crear el primero.
/// 2. Cultivo en `establecimiento` / `renovacion` sin siembra propia → sembrar
///    (el plantío joven aún no produce; la guía lo lleva a la siembra).
/// 3. Sin gastos del año → registrar gastos (aplica a finca ya establecida:
///    un cultivo en `produccion` no exige siembra).
/// 4. Con gastos pero sin cosechas → registrar cosecha.
/// 5. Con cosecha pero sin ventas → registrar venta de la cosecha.
///
/// Cero estado guardado: se recalcula en cada llamada y aparece/desaparece solo.
/// 1. Sin cultivos, o solo los por defecto sin configurar y sin ningún dato
///    registrado → revisar/crear el primer cultivo (así la tarjeta arranca por
///    el cultivo, como explica la guía, y no salta a los gastos).
NextStep? nextStepFor({
  required List<Crop> crops,
  required List<Sowing> sowings,
  required List<Harvest> harvests,
  required List<Transaction> transactions,
  required int year,
}) {
  final hasAnyData = sowings.isNotEmpty ||
      harvests.isNotEmpty ||
      transactions.any((t) => !t.deleted);
  if (crops.isEmpty && !hasAnyData) {
    return const NextStep(type: NextStepType.crop);
  }

  bool needsSowing(Crop c) =>
      c.phase != CropPhase.produccion &&
      !sowings.any((s) => s.cropId == c.id && s.kind == SowingKind.siembra);
  final youngCrop = crops.where(needsSowing).firstOrNull;
  if (youngCrop != null) {
    return NextStep(type: NextStepType.sowing, cropId: youngCrop.id);
  }

  final hasExpenses = transactions.any(
    (t) => !t.deleted && t.type.isExpense && t.date.year == year,
  );
  if (!hasExpenses) {
    return const NextStep(type: NextStepType.expenses);
  }

  if (harvests.isEmpty) {
    return const NextStep(type: NextStepType.harvest);
  }

  final hasSales = transactions.any(
    (t) =>
        !t.deleted &&
        !t.type.isExpense &&
        _saleCategories.contains(t.category) &&
        t.date.year == year,
  );
  if (!hasSales) {
    return const NextStep(type: NextStepType.sale);
  }

  return null;
}