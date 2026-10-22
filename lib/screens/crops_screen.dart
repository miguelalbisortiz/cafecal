import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/crop.dart';
import '../models/cohort_kilos.dart';
import '../models/sowing.dart';
import '../models/terreno.dart';
import '../services/terreno_area.dart';
import '../providers/transaction_provider.dart';
import '../utils/format.dart';
import '../widgets/crop_editor_dialog.dart';
import '../widgets/terreno_editor_dialog.dart';

/// Gestión de cultivos: crear/editar/eliminar con fase, ciclo, unidad
/// preferida, área y plantas vivas. También es la puerta de entrada al
/// editor de cultivo desde el flujo "Asignar cultivos".
class CropsScreen extends StatelessWidget {
  const CropsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tx = context.watch<TransactionProvider>();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.menuCrops),
        // W1 · la puerta de entrada a los terrenos. Va en la barra y no como
        // un bloque en pantalla para no añadir ruido a quien todavía no los
        // usa: la app sin terrenos sigue viéndose igual que siempre.
        actions: [
          IconButton(
            tooltip: l10n.terrenoNew,
            icon: const Icon(Icons.landscape_outlined),
            onPressed: () => _createTerreno(context, tx),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createCrop(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.cropNewOption),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: tx.crops.isEmpty && tx.terrenos.isEmpty
              ? Center(child: Text(l10n.cropsEmpty))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                  children: [
                    // La sección solo aparece cuando hay terrenos: mientras no
                    // cree ninguno, la pantalla es exactamente la de antes.
                    if (tx.terrenos.isNotEmpty) ...[
                      _terrenosSection(context, tx, l10n),
                      const SizedBox(height: 12),
                    ],
                    for (final c in tx.crops) _row(context, tx, c, l10n),
                  ],
                ),
        ),
      ),
    );
  }

  // ---- W1 · Terrenos ----

  Future<void> _createTerreno(
      BuildContext context, TransactionProvider tx) async {
    final form = await showDialog<TerrenoFormData>(
      context: context,
      builder: (_) => TerrenoEditorDialog(
        crops: tx.crops,
        existingNames: tx.terrenos.map((t) => t.name).toList(),
      ),
    );
    if (form == null || !context.mounted) return;
    await tx.addTerreno(
      form.name,
      areaHa: form.areaHa,
      lat: form.lat,
      lng: form.lng,
      locatedAt: form.locatedAt,
      cropIds: form.cropIds,
    );
  }

  Future<void> _editTerreno(
      BuildContext context, TransactionProvider tx, Terreno t) async {
    final form = await showDialog<TerrenoFormData>(
      context: context,
      builder: (_) => TerrenoEditorDialog(
        terreno: t,
        crops: tx.crops,
        initialCropIds: [
          for (final c in tx.crops)
            if (c.terrenoId == t.id) c.id,
        ],
        existingNames: tx.terrenos.map((x) => x.name).toList(),
      ),
    );
    if (form == null || !context.mounted) return;
    // `copyWith` usa centinela: `form.lat == null` significa **borrar** la
    // ubicación, y no "no me toques". Si la vacía en el diálogo, la quita.
    await tx.updateTerrenoWithCrops(
      t.copyWith(
        name: form.name,
        areaHa: form.areaHa,
        lat: form.lat,
        lng: form.lng,
        locatedAt: form.locatedAt,
      ),
      form.cropIds,
    );
  }

  /// Borra el terreno tras avisar. **No se borra ningún cultivo**: al
  /// confirmar, `deleteTerreno` deja los suyos con `terreno_id = null`, igual
  /// que la BD. El aviso dice exactamente eso, porque "eliminar" en una app
  /// de campo suena a arrancar café.
  Future<void> _deleteTerreno(BuildContext context, TransactionProvider tx,
      AppLocalizations l10n, Terreno t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.deleteTerrenoTitle),
        content: Text(l10n.deleteTerrenoBody(t.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await tx.deleteTerreno(t.id);
  }

  /// La lista de terrenos, en una tarjeta por encima de los cultivos.
  Widget _terrenosSection(BuildContext context, TransactionProvider tx,
      AppLocalizations l10n) {
    final shares = {
      for (final t in tx.terrenos) t.id: terrenoAreaShare(t, tx.crops),
    };
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.landscape_outlined,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.terrenosSection,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _createTerreno(context, tx),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(l10n.terrenoNew),
                ),
              ],
            ),
            for (final t in tx.terrenos) ...[
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.crop_square_outlined, size: 20),
                title: Text(t.name),
                // `null` → no se pinta nada. Un terreno sin área medida no
                // lleva "0,00 ha": lleva lo que sepa decirse (el recuento).
                subtitle: Text([
                  if (t.areaHa != null)
                    // Con cultivos medidos se compara; sin ellos, el área
                    // sola. Nunca un "0 de 8": eso diría que no hay nada.
                    shares[t.id]!.assigned > 0
                        ? l10n.terrenoAreaAssigned(
                            shares[t.id]!.assigned.toStringAsFixed(2),
                            t.areaHa!.toStringAsFixed(2),
                          )
                        : '${t.areaHa!.toStringAsFixed(2)} ha',
                  l10n.terrenoCropCount(
                      tx.crops.where((c) => c.terrenoId == t.id).length),
                ].join(' · ')),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: l10n.terrenoEdit,
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () => _editTerreno(context, tx, t),
                    ),
                    IconButton(
                      tooltip: l10n.terrenoDelete,
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: () => _deleteTerreno(context, tx, l10n, t),
                    ),
                  ],
                ),
              ),
              // Tanda 4 · el exceso se avisa en ámbar y no bloquea: dos
              // cultivos pueden compartir el lote y las áreas son una
              // estimación, no una escritura.
              if (shares[t.id]!.over || shares[t.id]!.withoutArea > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 40, bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (shares[t.id]!.over)
                        Text(
                          l10n.terrenoAreaOver(
                            shares[t.id]!.assigned.toStringAsFixed(2),
                            t.areaHa!.toStringAsFixed(2),
                          ),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color:
                                    Theme.of(context).colorScheme.tertiary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      if (shares[t.id]!.withoutArea > 0)
                        Text(
                          l10n.terrenoAreaWithoutArea(
                              shares[t.id]!.withoutArea),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _createCrop(BuildContext context) async {
    final tx = context.read<TransactionProvider>();
    final l10n = AppLocalizations.of(context)!;
    final wasEmpty = tx.crops.isEmpty;
    var keepAdding = true;
    while (keepAdding) {
      if (!context.mounted) return;
      final form = await showDialog<CropFormData>(
        context: context,
        builder: (_) => CropEditorDialog(
          existingNames: tx.crops.map((c) => c.name).toList(),
          // W1: vacío → el campo del terreno ni se enseña.
          terrenos: tx.terrenos,
          crops: tx.crops,
          // Moneda única: el cultivo nuevo la hereda de la cuenta; el
          // editor ya no la pregunta.
          defaultCurrency: tx.settings.currency,
        ),
      );
      if (form == null || !context.mounted) return;
      // Una sola escritura con todo el formulario (C5): antes era addCrop +
      // updateCrop, que guardaba y avisaba dos veces y disparaba el auto-sync
      // en dos pasadas.
      await tx.addCrop(
        form.name,
        icon: form.icon,
        color: form.color,
        currency: form.currency,
        phase: form.phase,
        cycle: form.cycle,
        defaultUnit: form.defaultUnit,
        areaHa: form.areaHa,
        livePlants: form.livePlants,
        establishmentCost: form.establishmentCost,
        plantedAt: form.plantedAt,
        expectedYieldPerHa: form.expectedYieldPerHa,
        // E5: al crear el campo ni siquiera se enseña, así que siempre null.
        primerCosechaEsperada: form.primerCosechaEsperada,
      );
      if (!wasEmpty || !context.mounted) return;
      // Primer cultivo: el onboarding invita a agregar varios existentes.
      keepAdding = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(l10n.onboardingCropAddedTitle),
              content: Text(l10n.onboardingAnotherPrompt),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(l10n.onboardingAnother),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n.onboardingDone),
                ),
              ],
            ),
          ) ??
          false;
    }
  }

  Future<void> _editCrop(BuildContext context, TransactionProvider tx,
      Crop crop) async {
    final form = await showDialog<CropFormData>(
      context: context,
      builder: (_) => CropEditorDialog(
        crop: crop,
        existingNames: tx.crops.map((c) => c.name).toList(),
        suggestedEstablishmentCost: tx.initialSowingCost(crop.id),
        sowingsLocked: _hasInitialSowing(tx, crop),
        terrenos: tx.terrenos,
        crops: tx.crops,
      ),
    );
    if (form == null || !context.mounted) return;
    await tx.updateCrop(crop.copyWith(
      name: form.name,
      phase: form.phase,
      cycle: form.cycle,
      defaultUnit: form.defaultUnit,
      areaHa: form.areaHa,
      livePlants: form.livePlants,
      establishmentCost: form.establishmentCost,
      // C1: antes la moneda se descartaba en silencio al editar (solo se
      // guardaba al crear).
      currency: form.currency,
      // C1: lo mismo con la fecha. Solo se enseña el campo cuando no hay
      // siembras; si las hay, se devuelve tal cual la que ya traía.
      plantedAt: form.plantedAt,
      // E4: aquí SÍ pasa el null del campo vacío, a propósito. El resto de
      // los campos usan `??` y conservan el valor anterior, pero la meta se
      // puede BORRAR — si el `??` la conservara, borrarla sería imposible.
      expectedYieldPerHa: form.expectedYieldPerHa,
      // E5: ídem — la fecha estimada se puede borrar.
      primerCosechaEsperada: form.primerCosechaEsperada,
      // W1: se puede sacar el cultivo de su terreno tan legítimo como
      // ponerlo, por eso el null va tal cual (centinela, no `??`).
      terrenoId: form.terrenoId,
    ));
  }

  /// C2: borrar un cultivo hace match con lo que hace `deleteCrop`
  /// (`transaction_provider.dart`) — borra siembras y cosechas y deja los
  /// gastos/ventas sin cultivo — así que lo avisamos antes de ejecutar.
  Future<void> _confirmDelete(BuildContext context, TransactionProvider tx,
      Crop crop, AppLocalizations l10n) async {
    final sowings = tx.sowings.where((s) => s.cropId == crop.id).length;
    final harvests = tx.harvests.where((h) => h.cropId == crop.id).length;
    final hasHistory = sowings > 0 || harvests > 0;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteCropTitle),
        content: Text(hasHistory
            ? l10n.deleteCropBody(sowings, harvests, crop.name)
            : l10n.deleteCropBodyEmpty(crop.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await tx.deleteCrop(crop.id);
  }

  /// F4 · true cuando el contador de plantas ya no lo escribe el usuario:
  /// sale de las siembras, así que lo tecleado en el editor se perdería en la
  /// próxima. Solo la siembra inicial fija el número (una resiembra lo mueve).
  static bool _hasInitialSowing(TransactionProvider tx, Crop crop) => tx.sowings
      .any((s) => s.cropId == crop.id && s.kind == SowingKind.siembra);

  /// Formato corto de hectáreas en lenguaje llano: `0,4 ha`, `2 ha`.
  /// La regla vive en `formatAreaHa` para que Reportes y los exports digan
  /// exactamente lo mismo.
  static String _ha(TransactionProvider tx, double v) =>
      formatAreaHa(v, tx.settings.numberLocale);

  Widget _row(
      BuildContext context, TransactionProvider tx, Crop crop, AppLocalizations l10n) {
    String phaseLabel(CropPhase p) => switch (p) {
          CropPhase.establecimiento => l10n.phaseEstablecimiento,
          CropPhase.produccion => l10n.phaseProduccion,
          CropPhase.renovacion => l10n.phaseRenovacion,
        };
    // F5 · edad junto a la fase. Si no hay datos (nada sembrado y sin fecha
    // en el editor) no se pinta nada: mejor callar que inventar un 0.
    final edad = edadDeCrop(crop, tx.sowings);

    // Etapa A · cohortes. Con **una** edad la tarjeta se ve exactamente igual
    // que siempre; con dos o más no hay «una» edad: se dice cuántas y se
    // despliegan, sin promedio.
    final cohortes = cropCohorts(crop.id, tx.sowings);
    final vivas = cohortes.where((c) => c.open).toList();
    final renovadas = cohortes.where((c) => !c.open).toList();
    final areaStatus = cohortAreaStatus(crop.areaHa, cohortes);

    String mesAnio(DateTime d) =>
        '${d.month.toString().padLeft(2, '0')}/${d.year}';

    // Etapa B · kilos medidos por lote. Salen de los jornales de «Cosechar»
    // (no se reparte la venta) y solo existen si alguien los pesó: sin kilos
    // el lote se ve como antes, nunca con un 0.
    final kilosPorLote = cohortKilos(
      cropId: crop.id,
      transactions: tx.transactions,
      storedHarvests: tx.storedHarvests,
      sowings: tx.sowings,
    );

    Widget cohorteLinea(Cohort c, {required bool abierta}) {
      final kg = abierta ? kilosPorLote[c.sowingId] : null;
      final kgPlanta = kg == null ? null : kgPerPlantCohort(kg, c.livePlants);
      final partes = <String>[
        l10n.sowingCohortOption(
            MaterialLocalizations.of(context).formatShortDate(c.date),
            c.livePlants),
        if (abierta && edadDeCohorte(crop, c) != null)
          l10n.cropAge(edadDeCohorte(crop, c)!),
        if (c.areaHa != null) '${_ha(tx, c.areaHa!)} ha',
        if (kg != null)
          l10n.cohortKgLabel(formatKg(kg, tx.settings.numberLocale)),
        if (kg != null && kgPlanta != null)
          l10n.cohortKgPerPlantLabel(
              formatKgPerPlant(kgPlanta, tx.settings.numberLocale)),
        if (abierta)
          l10n.cohortOpen
        else if (c.closedOn != null)
          l10n.cohortRenewedOn(mesAnio(c.closedOn!))
        else
          l10n.cohortRenewed,
      ];
      return Padding(
        padding: const EdgeInsets.only(top: 2),
        child:
            Text(partes.join(' · '), style: const TextStyle(fontSize: 11)),
      );
    }

    // E5 · "¿cuándo esperás la primera cosecha?". Su fecha, no una tabla de
    // especies. Si ya cosechó de verdad, manda lo que cosechó y esto calla.
    final estimada = primerCosechaEstimada(
      crop,
      yaCosecho: tx.harvests.any((h) => h.cropId == crop.id),
    );
    String estimadaTexto(FirstHarvestEstimate e) {
      final fecha = MaterialLocalizations.of(context).formatShortDate(e.date);
      return e.overdue
          ? l10n.firstHarvestOverdue(fecha)
          : l10n.firstHarvestSoon(fecha, e.monthsOut);
    }

    // L2.3 (patrón H10): la fase se ve con icono de forma distinta + texto,
    // nunca solo con color.
    IconData phaseIcon(CropPhase p) => switch (p) {
          CropPhase.establecimiento => Icons.spa_outlined,
          CropPhase.produccion => Icons.agriculture_outlined,
          CropPhase.renovacion => Icons.autorenew,
        };

    // L2.2: los nombres se pueden repetir (C4), así que el nombre ya no
    // distingue. Solo con empate se añade el subtítulo que separa cada fila;
    // con nombre único la lista queda como siempre.
    var sameName = 0;
    var ordinal = 0;
    for (final c in tx.crops) {
      if (c.name.toLowerCase() != crop.name.toLowerCase()) continue;
      sameName++;
      if (c.id == crop.id) ordinal = sameName;
    }
    final areaText =
        crop.areaHa == null ? null : '${_ha(tx, crop.areaHa!)} ha';
    final tag = sameName > 1 ? (areaText ?? l10n.cropLotTag(ordinal)) : null;

    final details = <String>[
      crop.cycle == CropCycle.anual ? l10n.cycleAnual : l10n.cyclePerenne,
      if (crop.defaultUnit != null) crop.defaultUnit!,
      if (areaText != null && areaText != tag) areaText,
      if (crop.livePlants != null) '${crop.livePlants}',
      // E5 · gris y en la línea de datos: es un dato, no una alerta. La
      // palabra "está" o "debería" es lo único que avisa.
      if (estimada != null) estimadaTexto(estimada),
    ];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(crop.icon),
        ),
        title: Text(
          crop.name,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tag != null)
              Text(
                tag,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFED6C02),
                ),
              ),
            Row(
              children: [
                Icon(
                  phaseIcon(crop.phase),
                  size: 14,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    phaseLabel(crop.phase),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                if (vivas.length < 2 && edad != null) ...[
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '· ${l10n.cropAge(edad)}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
            if (vivas.length >= 2)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(left: 12),
                dense: true,
                title: Text(
                  l10n.cohortsCount(vivas.length),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                children: [
                  for (final c in vivas) cohorteLinea(c, abierta: true),
                ],
              ),
            if (details.isNotEmpty)
              Text(
                details.join(' · '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            // D6 · el área no se inventa. Si falta la de algún lote se usa la
            // que él escribió y se dice; si los lotes ya suman más, se avisa.
            // Nunca bloquea.
            if (vivas.length >= 2 && areaStatus.incomplete)
              Text(
                l10n.cohortsAreaFallback,
                style:
                    const TextStyle(fontSize: 11, color: Color(0xFFED6C02)),
              ),
            if (vivas.length >= 2 && areaStatus.overManual)
              Text(
                l10n.cohortsAreaMismatch(
                  _ha(tx, areaStatus.measuredSum!),
                  _ha(tx, crop.areaHa!),
                ),
                style:
                    const TextStyle(fontSize: 11, color: Color(0xFFED6C02)),
              ),
            if (vivas.isEmpty && cohortes.isNotEmpty)
              Text(
                l10n.cohortsNoLivingPlants,
                style: const TextStyle(
                    fontSize: 12, fontStyle: FontStyle.italic),
              ),
            if (renovadas.isNotEmpty)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(left: 12),
                dense: true,
                title: Text(
                  l10n.cohortsHistoryTitle,
                  style: const TextStyle(fontSize: 12),
                ),
                children: [
                  for (final c in renovadas) cohorteLinea(c, abierta: false),
                ],
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: l10n.edit,
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () => _editCrop(context, tx, crop),
            ),
            IconButton(
              tooltip: l10n.delete,
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () => _confirmDelete(context, tx, crop, l10n),
            ),
          ],
        ),
      ),
    );
  }
}