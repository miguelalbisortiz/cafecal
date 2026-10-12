import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/crop.dart';
import '../models/terreno.dart';
import 'crop_loss_dialog.dart';

/// Editor de cultivo (crear y editar). Permite configurar fase/ciclo, unidad
/// preferida, área y plantas vivas. Al confirmar devuelve los valores editados.
class CropEditorDialog extends StatefulWidget {
  final Crop? crop;
  final List<String> existingNames;

  /// F3 · Suma sugerida de los gastos de siembra inicial del cultivo.
  ///
  /// Solo se usa si el campo de *Inversión total* viene vacío, y queda
  /// editable por si falta algo que no nació de un gasto de siembra
  /// (preparación de tierra, cercas, mano de obra).
  final double? suggestedEstablishmentCost;

  /// F4 · true cuando el número de plantas y el área **no los escribe** él:
  /// salen de las siembras, y cualquier cosa tecleada aquí se pierde en la
  /// próxima siembra. En ese caso los dos campos quedan en solo lectura.
  final bool sowingsLocked;

  /// E6-a · true cuando el cultivo **acaba de nacer** en la puerta de
  /// bienvenida y se abrió el editor para completarlo.
  ///
  /// El comportamiento es el de editar — el cultivo ya existe, hay que
  /// actualizarlo — pero el título no: decirle "Editar cultivo" a quien
  /// acaba de escribir el nombre sería mentirle sobre lo que está pasando.
  /// Con esto el título sigue lo que él tocó: **"Completar cultivo"**.
  ///
  /// El botón no lo necesita: ya dice "Guardar" en cuanto `crop` viene
  /// con id, que es lo que distingue crear de actualizar.
  final bool recienCreado;

  /// W1 · los terrenos que existen, para ofrecerlos en el desplegable.
  ///
  /// Vacío = no hay ninguno y el campo ni siquiera se enseña: la app sin
  /// terrenos es la misma de siempre, y no se le puede pedir a alguien que
  /// elija algo que todavía no existe.
  final List<Terreno> terrenos;

  /// Moneda de la cuenta para un cultivo **nuevo**.
  ///
  /// La moneda es única y no se puede cambiar, así que el editor no la
  /// pregunta: la toma de aquí. Quien edita un cultivo existente conserva
  /// la suya propia sin tocarla.
  final String defaultCurrency;

  const CropEditorDialog({
    super.key,
    this.crop,
    required this.existingNames,
    this.suggestedEstablishmentCost,
    this.sowingsLocked = false,
    this.recienCreado = false,
    this.terrenos = const [],
    this.defaultCurrency = 'COP',
  });

  @override
  State<CropEditorDialog> createState() => _CropEditorDialogState();
}

class _CropEditorDialogState extends State<CropEditorDialog> {
  final _nameController = TextEditingController();
  String _icon = '🌱';
  String _color = '#2E7D32';
  // Un cultivo nuevo nace en establecimiento (P3): sin cosecha que lo
  // demuestre, todavía no es producción. Al editar lo pisa initState con la
  // fase real del cultivo.
  CropPhase _phase = CropPhase.establecimiento;
  CropCycle _cycle = CropCycle.perenne;
  String? _defaultUnit;
  String _currency = 'COP';
  String? _terrenoId;
  DateTime? _plantedAt;

  /// E5 · "¿cuándo esperás la primera cosecha?".
  ///
  /// Su fecha, no una tabla de especies: él sabe cuánto tarda su cultivo, la
  /// app hace la cuenta del calendario. Opcional y borrable.
  DateTime? _firstHarvestAt;
  final _areaController = TextEditingController();
  final _plantsController = TextEditingController();
  final _establishmentController = TextEditingController();

  /// E4 · "kg/ha que quiero sacar de este lote".
  ///
  /// Su meta, escrita por él — no una tabla de referencia que la app le
  /// imponga. Vacío = sin meta.
  final _goalController = TextEditingController();
  String? _error;

  static const _unitOptions = ['kg', 'lb', 'arroba', 'saco', 'carga', 'racimo', 'cajon'];

  @override
  void initState() {
    super.initState();
    final c = widget.crop;
    if (c != null) {
      _nameController.text = c.name;
      _icon = c.icon;
      _color = c.color;
      _phase = c.phase;
      _cycle = c.cycle;
      _defaultUnit = c.defaultUnit;
      _currency = c.currency ?? 'COP';
      _terrenoId = c.terrenoId;
      _plantedAt = c.plantedAt;
      _firstHarvestAt = c.primerCosechaEsperada;
      if (c.areaHa != null) _areaController.text = c.areaHa.toString();
      if (c.livePlants != null) _plantsController.text = c.livePlants.toString();
      if (c.establishmentCost != null) {
        _establishmentController.text = _importe(c.establishmentCost!);
      }
      // La meta llega con el mismo "sin .0" que la inversión.
      if (c.expectedYieldPerHa != null) {
        _goalController.text = _importe(c.expectedYieldPerHa!);
      }
    } else {
      // Moneda única de la cuenta: un cultivo nuevo no elige moneda, la
      // hereda. La de un cultivo ya existente se conserva tal cual, para
      // no reescribir lo que ya está guardado.
      _currency = widget.defaultCurrency;
    }
    // F3: si no había inversión anotada, se propone la suma de los gastos de
    // siembra inicial. Nunca pisa lo que el productor ya puso a mano.
    if (_establishmentController.text.isEmpty &&
        widget.suggestedEstablishmentCost != null) {
      _establishmentController.text =
          _importe(widget.suggestedEstablishmentCost!);
    }
  }

  /// Importe para el campo, sin el ".0" que sueltan los doubles.
  static String _importe(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  /// C1 · el campo es opcional, así que cancelar o borrar dejan `null`.
  ///
  /// **La fecha de plantación ya no decide la fase** (H2): es un dato de la
  /// planta, no del rendimiento. Anotarla no cambia nada que la app no
  /// sepa con certeza.
  Future<void> _pickPlantedAt() async {
    final hoy = DateTime.now();
    final elegida = await showDatePicker(
      context: context,
      initialDate: _plantedAt ?? hoy,
      firstDate: DateTime(1950, 1, 1),
      lastDate: hoy,
    );
    if (!mounted || elegida == null) return;
    setState(() {
      _plantedAt = DateTime(elegida.year, elegida.month, elegida.day);
    });
  }

  void _clearPlantedAt() {
    setState(() => _plantedAt = null);
  }

  /// E5 · a diferencia de `planted_at`, esta fecha **puede ser del futuro**:
  /// es lo que espera que pase, no lo que ya pasó.
  ///
  /// H2 · **esta** es la fecha que decide la fase al crear: lo que él estimó
  /// manda sobre cualquier umbral de años.
  Future<void> _pickFirstHarvest() async {
    final hoy = DateTime.now();
    final elegida = await showDatePicker(
      context: context,
      initialDate: _firstHarvestAt ?? DateTime(hoy.year + 1, hoy.month),
      firstDate: DateTime(1950, 1, 1),
      lastDate: DateTime(hoy.year + 30, 12, 31),
    );
    if (!mounted || elegida == null) return;
    setState(() {
      _firstHarvestAt = DateTime(elegida.year, elegida.month, elegida.day);
      _deducePhaseIfCreating();
    });
  }

  void _clearFirstHarvest() {
    setState(() {
      _firstHarvestAt = null;
      _deducePhaseIfCreating();
    });
  }

  /// H2 · la fecha de primera cosecha que él estimó decide la fase.
  ///
  /// No hay umbral de años: plátano rinde a los 9-12, mango a los 3-5 y
  /// cualquier número fijo sería el del café puesto en boca de todos.
  ///
  /// Al **editar** un cultivo que ya vivió no se re-deduces: su fase sale de
  /// su historial y de la primera cosecha registrada
  /// (`_promotePhaseOnHarvest`), y pisarla aquí sería un regreso.
  ///
  /// La excepción es la **puerta de bienvenida** (E6): ahí el cultivo acaba
  /// de nacer en este mismo tramo y completarlo sigue siendo crearlo, con el
  /// historial todavía vacío.
  ///
  /// E6: la cuenta vive en [deducePhaseOnCreate], compartida con la puerta,
  /// para que la regla no quede escrita en dos sitios.
  void _deducePhaseIfCreating() {
    if (widget.crop != null && !widget.recienCreado) return;
    _phase = deducePhaseOnCreate(
        cycle: _cycle, primerCosechaEsperada: _firstHarvestAt);
  }

  /// F4 · Puerta de salida del bloqueo: el productor anota cuántas plantas
  /// quedan y la app escribe la resiembra que corresponda (0 plantas nuevas
  /// si hay mortandad). Al volver se refresca el contador en solo lectura.
  Future<void> _registerLoss() async {
    final crop = widget.crop;
    final actuales = crop?.livePlants;
    if (crop == null || actuales == null) return;

    final nuevo = await showDialog<int>(
      context: context,
      builder: (_) => CropLossDialog(crop: crop, currentPlants: actuales),
    );
    if (nuevo == null || !mounted) return;
    setState(() => _plantsController.text = nuevo.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _areaController.dispose();
    _plantsController.dispose();
    _establishmentController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    final n = _nameController.text.trim();
    if (n.isEmpty) {
      setState(() => _error = l10n.cropNameRequired);
      return;
    }
    final current = widget.crop?.name.toLowerCase();
    final dup = widget.existingNames.any((e) =>
        e.toLowerCase() == n.toLowerCase() && e.toLowerCase() != current);
    if (dup) {
      // C3: decía "el nombre es obligatorio", que era un mensaje para otra
      // cosa y dejaba al usuario reescribiendo el mismo nombre.
      setState(() => _error = l10n.cropNameTaken);
      return;
    }
    final areaText = _areaController.text.trim().replaceAll(',', '.');
    final area = areaText.isEmpty ? null : double.tryParse(areaText);
    final plantsText = _plantsController.text.trim();
    final plants = plantsText.isEmpty ? null : int.tryParse(plantsText);
    final estText = _establishmentController.text.trim().replaceAll(',', '.');
    final establishmentCost =
        estText.isEmpty ? null : double.tryParse(estText);
    // Opcional y borrable: vacío o escrito mal → null → sin meta, y la app
    // no pinta nada (regla de oro: null → oculto, nunca 0).
    final goalText = _goalController.text.trim().replaceAll(',', '.');
    final expectedYieldPerHa =
        goalText.isEmpty ? null : double.tryParse(goalText);
    Navigator.pop(context, CropFormData(
      name: n,
      icon: _icon,
      color: _color,
      phase: _phase,
      cycle: _cycle,
      defaultUnit: _defaultUnit,
      areaHa: area,
      livePlants: plants,
      establishmentCost: establishmentCost,
      currency: _currency,
      plantedAt: _plantedAt,
      expectedYieldPerHa: expectedYieldPerHa,
      primerCosechaEsperada: _firstHarvestAt,
      terrenoId: _terrenoId,
    ));
  }

  /// H3 · la fase que se guarda es **la que él eligió**, sin pisarla.
  ///
  /// Antes había aquí un invariante que forzaba `produccion` en los anuales,
  /// justificado porque el selector de fase estaba **oculto** para ellos: sin
  /// regla, un anual quedaba atascado y no había forma de corregirlo. Esa
  /// razón se cae con H1 —el vocabulario ya no es de cafetal— así que el
  /// selector está a la vista también para el anual y manda lo que él diga.
  ///
  /// Lo que sí se mantiene es el **valor por defecto**: al elegir Anual, la
  /// fase arranca en `produccion`, que es lo habitual (se siembra y se cosecha
  /// en el año). Es una sugerencia, no un candado.

  String _unitLabel(String key, AppLocalizations l10n) => switch (key) {
        'kg' => l10n.unitKg,
        'arroba' => l10n.unitArroba,
        'saco' => l10n.unitSaco,
        'racimo' => l10n.unitRacimo,
        'cajon' => l10n.unitCajon,
        _ => key,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final editing = widget.crop != null;
    return AlertDialog(
      title: Text(switch ((editing, widget.recienCreado)) {
        // Recién creado desde la puerta: no lo está editando, lo está
        // completando. El título debe seguir lo que él acaba de tocar.
        (true, true) => l10n.welcomeCompleteTitle,
        (true, false) => l10n.editCropTitle,
        (false, _) => l10n.newCropDialogTitle,
      }),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              onChanged: (_) {
                // El error no debe quedarse pegado mientras el usuario
                // escribe un nombre nuevo.
                if (_error != null) setState(() => _error = null);
              },
              decoration: InputDecoration(
                labelText: l10n.cropNameLabel,
                errorText: _error,
                prefixIcon: const Icon(Icons.grass_outlined),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<CropCycle>(
              value: _cycle,
              decoration: InputDecoration(
                labelText: l10n.cycleLabel,
                helperText: l10n.helpCycleShort,
                suffixIcon: Tooltip(
                  message: l10n.helpCycle,
                  child: const Icon(Icons.info_outline, size: 20),
                ),
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(
                  value: CropCycle.perenne,
                  child: Text(l10n.cyclePerenne),
                ),
                DropdownMenuItem(
                  value: CropCycle.anual,
                  child: Text(l10n.cycleAnual),
                ),
              ],
              onChanged: (v) => setState(() {
                _cycle = v ?? CropCycle.perenne;
                if (_cycle == CropCycle.anual) {
                  // H3 · solo el valor por defecto: el selector de fase está
                  // a la vista también para el anual, así que lo puede
                  // cambiar si esto no es lo que ocurre en su finca.
                  _phase = CropPhase.produccion;
                }
              }),
            ),
            if (_cycle == CropCycle.perenne) ...[
              // C1 · opcional. Si el cultivo ya tiene siembras ni siquiera
              // se enseña: ahí manda la fecha de la última, la que él anotó
              // en el campo, y preguntarle otra cosa sería contradecirla.
              if (!widget.sowingsLocked) ...[
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickPlantedAt,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.plantedAtLabel,
                      helperText: l10n.helpPlantedAtShort,
                      prefixIcon: const Icon(Icons.calendar_today_outlined),
                      suffixIcon: _plantedAt == null
                          ? null
                          : IconButton(
                              tooltip: l10n.plantedAtClear,
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: _clearPlantedAt,
                            ),
                      border: const OutlineInputBorder(),
                    ),
                    child: Text(
                      _plantedAt == null
                          ? l10n.plantedAtEmpty
                          : MaterialLocalizations.of(context)
                              .formatShortDate(_plantedAt!),
                      style: _plantedAt == null
                          ? TextStyle(color: Theme.of(context).hintColor)
                          : null,
                    ),
                  ),
                ),
              ],
            ],
            // H3 · a la vista también para el anual. El selector estaba
            // escondido porque "un anual no tiene fases de cafetal", que era
            // H1 hablando; con el vocabulario ya no de cafetal se cae esa
            // razón, y esconderlo le quitaba la posibilidad de corregirlo.
            const SizedBox(height: 12),
            DropdownButtonFormField<CropPhase>(
              value: _phase,
              decoration: InputDecoration(
                labelText: l10n.phaseLabel,
                helperText: l10n.phaseHelpShort,
                suffixIcon: Tooltip(
                  message: l10n.phaseHelp,
                  child: const Icon(Icons.info_outline, size: 20),
                ),
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(
                  value: CropPhase.establecimiento,
                  child: Text(l10n.phaseEstablecimiento),
                ),
                DropdownMenuItem(
                  value: CropPhase.produccion,
                  child: Text(l10n.phaseProduccion),
                ),
                DropdownMenuItem(
                  value: CropPhase.renovacion,
                  child: Text(l10n.phaseRenovacion),
                ),
              ],
              onChanged: (v) => setState(() => _phase = v ?? CropPhase.produccion),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _defaultUnit,
              decoration: InputDecoration(
                labelText: l10n.defaultUnitLabel,
                helperText: l10n.helpUnitShort,
                suffixIcon: Tooltip(
                  message: l10n.helpUnit,
                  child: const Icon(Icons.info_outline, size: 20),
                ),
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text(l10n.defaultUnitNone),
                ),
                ..._unitOptions.map((u) => DropdownMenuItem<String>(
                      value: u,
                      child: Text(_unitLabel(u, l10n)),
                    )),
              ],
              onChanged: (v) => setState(() => _defaultUnit = v),
            ),
            // W1 · ¿en qué tierra está? Solo se enseña si ya existe al menos
            // un terreno: no se le puede pedir que elija algo que todavía no
            // ha creado. El '' es un centinela y no un id: los ids son uuid.
            if (widget.terrenos.isNotEmpty) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _terrenoId ?? '',
                decoration: InputDecoration(
                  labelText: l10n.cropTerrenoLabel,
                  helperText: l10n.helpCropTerreno,
                  prefixIcon: const Icon(Icons.landscape_outlined),
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem<String>(
                    value: '',
                    child: Text(l10n.cropTerrenoNone),
                  ),
                  for (final t in widget.terrenos)
                    DropdownMenuItem<String>(
                      value: t.id,
                      child: Text(t.name),
                    ),
                ],
                onChanged: (v) => setState(
                    () => _terrenoId = (v == null || v.isEmpty) ? null : v),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _areaController,
              // F4: el área la fija la siembra inicial; escribirla aquí no
              // tendría efecto, así que se muestra y no se toca.
              enabled: !widget.sowingsLocked,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l10n.areaHaLabel,
                helperText:
                    widget.sowingsLocked ? l10n.cropLockedHint : l10n.helpAreaShort,
                prefixIcon: const Icon(Icons.square_foot_outlined),
                suffixIcon: Tooltip(
                  message: l10n.helpArea,
                  child: const Icon(Icons.info_outline, size: 20),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _plantsController,
              // F4: las plantas vivas se recalculan con cada siembra.
              enabled: !widget.sowingsLocked,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.livePlantsLabel,
                helperText:
                    widget.sowingsLocked ? l10n.cropLockedHint : l10n.helpPlantsShort,
                prefixIcon: const Icon(Icons.park_outlined),
                suffixIcon: Tooltip(
                  message: l10n.helpPlants,
                  child: const Icon(Icons.info_outline, size: 20),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            // F4: el contador ya no lo escribe él, pero no se queda sin
            // salida — aquí anota cuántas plantas quedan.
            if (widget.sowingsLocked && widget.crop?.livePlants != null) ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _registerLoss,
                  icon: const Icon(Icons.trending_down, size: 18),
                  label: Text(l10n.cropLossRegister),
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _establishmentController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l10n.establishmentCostLabel,
                helperText: l10n.helpEstablishmentShort,
                prefixIcon: const Icon(Icons.savings_outlined),
                suffixIcon: Tooltip(
                  message: l10n.helpEstablishment,
                  child: const Icon(Icons.info_outline, size: 20),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            // E4 · su meta, solo al editar. Al crear todavía no hay nada que
            // apuntar, y la regla manda: si se puede pedir después, no se
            // pide ahora. Es opcional y se puede borrar.
            if (editing) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _goalController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l10n.expectedYieldLabel,
                  helperText: l10n.helpExpectedYieldShort,
                  prefixIcon: const Icon(Icons.flag_outlined),
                  suffixIcon: Tooltip(
                    message: l10n.helpExpectedYield,
                    child: const Icon(Icons.info_outline, size: 20),
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
            // E5 · su fecha, solo al editar. Igual que la meta: al crear no
            // hay nada que apuntar todavía, y la regla manda — si se puede
            // pedir después, no se pide ahora.
            if (editing) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickFirstHarvest,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.firstHarvestLabel,
                    helperText: l10n.helpFirstHarvestShort,
                    prefixIcon: const Icon(Icons.event_outlined),
                    suffixIcon: _firstHarvestAt == null
                        ? null
                        : IconButton(
                            tooltip: l10n.plantedAtClear,
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: _clearFirstHarvest,
                          ),
                    border: const OutlineInputBorder(),
                  ),
                  child: Text(
                    _firstHarvestAt == null
                        ? l10n.firstHarvestEmpty
                        : MaterialLocalizations.of(context)
                            .formatShortDate(_firstHarvestAt!),
                    style: _firstHarvestAt == null
                        ? TextStyle(color: Theme.of(context).hintColor)
                        : null,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        // El cultivo ya existe — editándolo o completándolo desde la
        // puerta — y el botón guarda. Decirle "Agregar" le estaría
        // prometiendo un cultivo nuevo.
        FilledButton(
          onPressed: _submit,
          child: Text(editing ? l10n.save : l10n.add),
        ),
      ],
    );
  }
}

class CropFormData {
  final String name;
  final String icon;
  final String color;
  final CropPhase phase;
  final CropCycle cycle;
  final String? defaultUnit;
  final double? areaHa;
  final int? livePlants;
  final double? establishmentCost;
  final String currency;

  /// C1 · `null` = el productor no la quiso poner (o el cultivo ya tenía
  /// siembras y el campo ni siquiera se le enseñó).
  final DateTime? plantedAt;

  /// E4 · `null` = no puso meta (o el cultivo es nuevo y ni siquiera se le
  /// enseñó el campo).
  final double? expectedYieldPerHa;

  /// E5 · `null` = no quiso estimarla (o el cultivo es nuevo y ni siquiera
  /// se le enseñó el campo).
  final DateTime? primerCosechaEsperada;

  /// W1 · `null` = sin terreno (o no se le enseñó el campo porque no hay
  /// ninguno creado todavía).
  final String? terrenoId;

  const CropFormData({
    required this.name,
    required this.icon,
    required this.color,
    required this.phase,
    required this.cycle,
    this.defaultUnit,
    this.areaHa,
    this.livePlants,
    this.establishmentCost,
    this.currency = 'COP',
    this.plantedAt,
    this.expectedYieldPerHa,
    this.primerCosechaEsperada,
    this.terrenoId,
  });
}
