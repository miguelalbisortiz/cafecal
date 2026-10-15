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

  /// Registrar la venta de la cosecha: es el paso que cierra el ciclo. La
  /// cosecha de la que sale esta venta **nace de la propia venta** (es
  /// derivada), así que no hay un "registrar cosecha" aparte — D2/D5.
  sale,
}

/// Resultado de la guía: qué paso mostrar y a qué cultivo refiere (si aplica).
class NextStep {
  final NextStepType type;

  /// Cultivo al que apunta el paso (siembra), si existe.
  final String? cropId;

  const NextStep({required this.type, this.cropId});
}

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
/// 3. Sin gastos → registrar el primer gasto (aplica a finca ya establecida:
///    un cultivo en `produccion` no exige siembra).
/// 4. Con gastos pero sin ingresos → registrar la venta de la cosecha.
///
/// **D3 · El corte es `tiene gasto && tiene ingreso`, no el primer
/// movimiento.** La guía se borraba apenas aparecía *cualquier* registro, y
/// así nunca llegaba a invitar a vender — que es el paso que cierra el ciclo
/// y del que nace la cosecha. Ahora aguanta hasta que el ciclo está cerrado.
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

  // D3 · El único corte es el ciclo completo: gasto **e** ingreso. Mientras
  // falte uno —sin gastos, o gastos sin venta— la tarjeta sigue ahí para no
  // dejar al usuario sin invitación. Las borradas no cuentan.
  final tieneGasto = transactions.any((t) => !t.deleted && t.type.isExpense);
  final tieneIngreso =
      transactions.any((t) => !t.deleted && !t.type.isExpense);
  if (tieneGasto && tieneIngreso) return null;

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

  // Sin gastos → invita a registrar el primer gasto.
  if (!tieneGasto) return const NextStep(type: NextStepType.expenses);

  // Ya gastó pero todavía no vendió: el ciclo sigue abierto. Invita a la
  // venta —el paso que antes la guía nunca alcanzaba a sugerir porque se
  // borraba con el primer registro (D3).
  return const NextStep(type: NextStepType.sale);
}