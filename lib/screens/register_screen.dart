import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/strings.dart';
import '../models/categories.dart';
import '../models/currencies.dart';
import '../models/harvest.dart';
import '../models/tasks.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../utils/format.dart';
import '../widgets/new_crop_dialog.dart';
import '../widgets/crop_setup_prompt.dart';
import '../widgets/employee_editor_dialog.dart';

class RegisterScreen extends StatefulWidget {
  final Transaction? editing;

  /// Tipo prefijado al abrir la pantalla (Gasto/Ingreso). Solo aplica cuando
  /// no se está editando un registro existente.
  final TransactionType? initialType;

  const RegisterScreen({super.key, this.editing, this.initialType});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const _newCropOption = '__new__';

  /// Encabezado "Lotes" dentro del desplegable de cultivo: no es un id real
  /// y no se puede elegir, pero necesita valor propio — con "Costos comunes"
  /// seleccionado el desplegable exige exactamente un ítem con valor null.
  static const _loteHeader = '__lote_header__';

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _clientController = TextEditingController();
  final _providerController = TextEditingController();

  static const _jornalOtherOption = '__other__';
  static const _jornalCreateOption = '__create__';

  final _jornalOtherNameController = TextEditingController();
  final _jornalDaysController = TextEditingController();
  final _jornalRateController = TextEditingController();

  /// Tanda 2 · kilos recolectados. Es una **medida**, no una forma de pago:
  /// el total sigue saliendo de días × valor día. Vacío = `null` = no medido.
  final _jornalHarvestedKgController = TextEditingController();

  /// E3 · la labor del jornal. Tecla de `farmTasks`, o [_jornalTaskOtherOption]
  /// si eligió "Otra…" (y entonces el texto vive en
  /// [_jornalTaskOtherController]).
  String? _jornalTaskValue;
  final _jornalTaskOtherController = TextEditingController();

  /// Valor del dropdown que significa "estoy escribiendo la mía".
  static const _jornalTaskOtherOption = '__task_otra__';
  String? _jornalWorkerValue;
  int _jornalDropKey = 0;

  // ---- E1 · la venta real ----
  final _deductionQtyController = TextEditingController();
  final _deductionReasonController = TextEditingController();

  /// ¿El comprador descontó antes de pagar? Impureza, humedad, piedras.
  bool _hasDeduction = false;

  /// ¿La plata ya entró? `false` = por cobrar.
  bool _paid = true;

  TransactionType _type = TransactionType.expense;
  String? _category;
  String? _cropId;

  /// El lote al que sirve el gasto, cuando sirve a varios cultivos del mismo
  /// terreno. Mutuamente excluyente con [_cropId]: o es de un cultivo, o es
  /// del lote — los dos a la vez sería contar el mismo peso dos veces.
  String? _terrenoId;
  String? _unit;
  String? _harvestId;
  String _currency = 'COP';
  DateTime _date = DateTime.now();

  /// Categorías que abren el bloque de datos de producción (ventas).
  /// [kIncomeCategorySale] es la clave nueva: su etiqueta toma el nombre
  /// del cultivo del movimiento. venta_cafe / venta_platano son legadas
  /// y solo sirven para seguir editando registros viejos.
  static const _saleCategories = {
    kIncomeCategorySale,
    'venta_cafe',
    'venta_platano',
    'venta_otro',
  };

  /// Claves de venta fijas que ya no se ofrecen al registrar (su equivalente
  /// es la venta por cultivo); se mantienen como ítem si el movimiento en
  /// edición ya las usa, para no romper el dropdown.
  static const _legacySaleCategories = {'venta_cafe', 'venta_platano'};

  /// Gasto de mano de obra: activa el bloque jornal (trabajador + días ×
  /// valor día) y bloquea el campo Monto (se calcula solo).
  bool get _isJornal =>
      _type == TransactionType.expense && _category == 'mano_obra';

  /// Tanda 2 · los kilos solo se piden cuando hay una cosecha que atribuir:
  /// la labor es «Cosechar» y hay un **cultivo**. Con un lote no hay a quién
  /// atribuirla (el lote no es un cultivo), y sin ninguno tampoco.
  bool get _showsHarvestedKg =>
      _isJornal &&
      _jornalTaskValue == kTaskCosechar &&
      _cropId != null &&
      _terrenoId == null;

  /// D12 · lo que se oculta no se guarda ni se restaura: al dejar de verse,
  /// el controlador se limpia para que no reaparezca un número viejo.
  void _clearHarvestedKgIfHidden() {
    if (!_showsHarvestedKg) _jornalHarvestedKgController.clear();
  }

  /// Ayuda que se muestra justo al elegir la categoría.
  ///
  /// Va en el momento exacto de la elección y no en un glosario que nadie
  /// abre. Cubre las categorías que se confunden entre sí, sobre todo las
  /// que apuntan al mismo hecho con dos nombres distintos: "Cosecha y
  /// recolección" y "Mano de obra" (una labor se llama "cosechar", así que
  /// es fácil pagarle a quien recoge en la categoría equivocada y perder el
  /// dato del trabajador), "Siembra" y "Semillas e insumos" (elegir mal
  /// saca la inversión del costo/kg), y "Riego" y "Agua" (mueven la misma
  /// factura entre producción y fijos).
  String? _categoryHint(AppLocalizations l10n) {
    if (!_type.isExpense) return null;
    return switch (_category) {
      kExpenseCategorySowing => l10n.sowingCategoryHint,
      kExpenseCategoryHarvest => l10n.harvestCategoryHint,
      'mano_obra' => l10n.laborCategoryHint,
      'semillas_insumos' => l10n.seedsCategoryHint,
      'riego' => l10n.irrigationCategoryHint,
      'agua' => l10n.waterCategoryHint,
      _ => null,
    };
  }

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      _amountController.text = (e.amount % 1 == 0)
          ? e.amount.toInt().toString()
          : e.amount.toString();
      _descriptionController.text = e.description;
      _type = e.type;
      _category = e.category;
      _cropId = e.cropId;
      _terrenoId = e.terrenoId;
      _date = e.date;
      _unit = e.unit;
      _currency = e.currency;
      _harvestId = e.harvestId;
      if (e.quantity != null) {
        _quantityController.text = (e.quantity! % 1 == 0)
            ? e.quantity!.toInt().toString()
            : e.quantity!.toString();
      }
      if (e.client != null) _clientController.text = e.client!;
      if (e.provider != null) _providerController.text = e.provider!;
      // E1 · la venta real: descuento y estado de pago.
      _hasDeduction = e.deductionQty != null && e.deductionQty! > 0;
      _paid = e.paid;
      if (e.deductionQty != null) {
        _deductionQtyController.text = (e.deductionQty! % 1 == 0)
            ? e.deductionQty!.toInt().toString()
            : e.deductionQty!.toString();
      }
      if (e.deductionReason != null) {
        _deductionReasonController.text = e.deductionReason!;
      }
      // Jornal: restaurar trabajador, días y valor día desde el snapshot.
      if (e.type == TransactionType.expense && e.category == 'mano_obra') {
        if (e.quantity != null) {
          _jornalDaysController.text = (e.quantity! % 1 == 0)
              ? e.quantity!.toInt().toString()
              : e.quantity!.toString();
          // Los días viven en el bloque jornal, no en el campo de ventas.
          _quantityController.clear();
        }
        final rate = e.pricePerUnit ??
            ((e.quantity != null && e.quantity! > 0)
                ? e.amount / e.quantity!
                : null);
        if (rate != null) {
          _jornalRateController.text =
              (rate % 1 == 0) ? rate.toInt().toString() : rate.toString();
        }
        final name = e.provider?.trim();
        if (name != null && name.isNotEmpty) {
          final tx = context.read<TransactionProvider>();
          final match = tx.employees
              .where((emp) => emp.name.toLowerCase() == name.toLowerCase())
              .toList();
          if (match.isNotEmpty) {
            _jornalWorkerValue = match.first.id;
          } else {
            // El trabajador ya no está en la lista: conservar el nombre
            // snapshot como "Otro nombre…" (sin romper el registro).
            _jornalWorkerValue = _jornalOtherOption;
            _jornalOtherNameController.text = name;
          }
        }
        // E3 · la labor guardada. Si está en la lista se marca su tecla; si
        // no (texto libre de "Otra…", o una tecla que ya no existe), se marca
        // "Otra…" y se recarga el texto — así editar no la pierde.
        final savedTask = e.task;
        if (savedTask != null && savedTask.isNotEmpty) {
          if (taskByKey(savedTask) != null) {
            _jornalTaskValue = savedTask;
          } else {
            _jornalTaskValue = _jornalTaskOtherOption;
            _jornalTaskOtherController.text = savedTask;
          }
        }
        // Tanda 2 · se restaura solo si el campo va a verse: lo oculto no
        // guarda un valor escondido que pueda reaparecer (D12).
        if (_showsHarvestedKg && e.harvestedKg != null) {
          final kg = e.harvestedKg!;
          _jornalHarvestedKgController.text =
              (kg % 1 == 0) ? kg.toInt().toString() : kg.toString();
        }
      }
    } else {
      final provider = context.read<TransactionProvider>();
      _currency = provider.settings.currency;
      if (widget.initialType != null) {
        _type = widget.initialType!;
      }

      // Preselecciona lo último usado para agilizar los gastos recurrentes.
      //
      // El lote va primero: es mutuamente excluyente con el cultivo, y si el
      // registro anterior fue un gasto compartido, lo que hay que volver a
      // elegir es el lote y no uno de sus cultivos.
      //
      // Solo en gastos. Un ingreso no tiene lote —es de un cultivo o de la
      // finca entera—, y preseleccionarlo aquí metería un terrenoId en una
      // venta.
      if (_type.isExpense) {
        final lastTerreno = provider.settings.lastTerrenoId;
        if (lastTerreno != null &&
            provider.terrenos.any((t) => t.id == lastTerreno)) {
          _terrenoId = lastTerreno;
        }
      }
      // El cultivo solo si no quedó un lote puesto: los dos no conviven.
      if (_terrenoId == null) {
        final last = provider.settings.lastCropId;
        if (last != null && provider.crops.any((c) => c.id == last)) {
          _cropId = last;
        }
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _clientController.dispose();
    _providerController.dispose();
    _jornalOtherNameController.dispose();
    _jornalDaysController.dispose();
    _jornalRateController.dispose();
    _jornalHarvestedKgController.dispose();
    _jornalTaskOtherController.dispose();
    _deductionQtyController.dispose();
    _deductionReasonController.dispose();
    super.dispose();
  }

  /// E1 · lo que de verdad se pagó: lo entregado menos lo descontado.
  ///
  /// Sin descuento devuelve la cantidad tal cual, así que el precio por
  /// unidad que ya se mostraba antes de E1 sigue siendo idéntico — nadie ve
  /// un número cambiado por este cambio.
  double? _netSaleQuantity() {
    final q = double.tryParse(
        _quantityController.text.trim().replaceAll(',', '.'));
    if (q == null) return null;
    if (!_hasDeduction) return q;
    final d = double.tryParse(
        _deductionQtyController.text.trim().replaceAll(',', '.'));
    if (d == null || d <= 0) return q;
    final net = q - d;
    return net < 0 ? 0 : net;
  }

  Future<void> _createCrop() async {
    final tx = context.read<TransactionProvider>();
    final res = await showDialog<NewCropResult>(
      context: context,
      builder: (_) => NewCropDialog(crops: tx.crops),
    );
    if (!mounted) return;
    if (res == null) {
      // Cancelado: repinta para que el desplegable no se quede en la opción
      // de "crear nuevo".
      setState(() {});
      return;
    }
    // L2.2: si el diálogo devolvió un id se usa directo; sin id, es un
    // cultivo nuevo con ese nombre.
    if (res.existingId != null) {
      // Un cultivo elegido desplaza al lote: son mutuamente excluyentes.
      setState(() {
        _cropId = res.existingId;
        _terrenoId = null;
      });
      return;
    }
    final crop = await tx.addCrop(res.name, currency: _currency);
    if (!mounted) return;
    setState(() {
      _cropId = crop.id;
      _terrenoId = null;
    });
    // L2.5b: aviso opcional y descartable para completar los datos.
    await CropSetupPrompt.show(context, tx, crop);
  }

  /// Reconstruye el campo Monto con días × valor por día cuando el bloque
  /// jornal está completo. No toca el monto si faltan datos.
  void _recalcJornalAmount() {
    final days = double.tryParse(
        _jornalDaysController.text.trim().replaceAll(',', '.'));
    final rate = double.tryParse(
        _jornalRateController.text.trim().replaceAll(',', '.'));
    if (days == null || days <= 0 || rate == null || rate <= 0) return;
    final total = days * rate;
    final text = total % 1 == 0 ? total.toInt().toString() : total.toString();
    if (_amountController.text != text) {
      _amountController.text = text;
    }
  }

  /// Abre el diálogo "Crear trabajador" desde el dropdown del bloque jornal.
  Future<void> _createJornalWorker() async {
    final tx = context.read<TransactionProvider>();
    final form = await showDialog<EmployeeFormData>(
      context: context,
      builder: (_) => EmployeeEditorDialog(
        existingNames: tx.employees.map((e) => e.name).toList(),
      ),
    );
    if (!mounted) return;
    if (form == null) {
      // Reinicia el dropdown para no quedarse en "Crear trabajador…".
      setState(() => _jornalDropKey++);
      return;
    }
    final employee = await tx.addEmployee(form.name, dayRate: form.dayRate);
    if (!mounted) return;
    setState(() {
      _jornalWorkerValue = employee.id;
      _jornalDropKey++;
      // Misma regla que en el desplegable: el jornal pertenece a la moneda
      // de la cuenta, así que no se rellena si este registro vive en otra.
      if (employee.dayRate != null && _currency == tx.settings.currency) {
        final r = employee.dayRate!;
        _jornalRateController.text =
            (r % 1 == 0) ? r.toInt().toString() : r.toString();
      }
      _recalcJornalAmount();
    });
  }

  Future<void> _pickDate() async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      helpText: l10n.datePickerHelp,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final tx = context.read<TransactionProvider>();
    final l10n = AppLocalizations.of(context)!;
    final isSale = _type == TransactionType.income &&
        _saleCategories.contains(_category);
    double amount;
    double? quantity;
    String? unit;
    double? pricePerUnit;
    String? client;
    String? provider;
    // E3 · la labor solo existe en un jornal: un gasto que no es mano de
    // obra no tiene nada que anotar, y si el movimiento se edita para dejar
    // de ser jornal, la labor se limpia (no queda colgando).
    String? task;
    // Tanda 2 · kilos recolectados. Solo existen si el campo se veía al
    // guardar: lo oculto no viaja (null), nunca un 0 inventado.
    double? harvestedKg;
    if (_isJornal) {
      // Bloque jornal: total = días × valor día (Monto es solo lectura).
      final days = double.parse(
          _jornalDaysController.text.trim().replaceAll(',', '.'));
      final rate = double.parse(
          _jornalRateController.text.trim().replaceAll(',', '.'));
      amount = days * rate;
      quantity = days;
      unit = 'día';
      pricePerUnit = rate;
      final v = _jornalWorkerValue;
      if (v == _jornalOtherOption) {
        provider = _jornalOtherNameController.text.trim();
      } else if (v != null) {
        final match = tx.employees.where((e) => e.id == v).toList();
        provider = match.isEmpty ? null : match.first.name;
      } else {
        provider = null;
      }
      client = null;
      // "Otra…" guarda lo que escribió, tal cual: es la forma de anotar una
      // labor que no está en la lista sin romper la agrupación de la de
      // siempre. Vacío = sin labor declarada.
      if (_jornalTaskValue == _jornalTaskOtherOption) {
        final free = _jornalTaskOtherController.text.trim();
        task = free.isEmpty ? null : free;
      } else {
        task = _jornalTaskValue;
      }
      if (_showsHarvestedKg) {
        final kgText =
            _jornalHarvestedKgController.text.trim().replaceAll(',', '.');
        harvestedKg = kgText.isEmpty ? null : double.tryParse(kgText);
      }
    } else {
      amount = double.parse(_amountController.text.replaceAll(',', '.'));
      final qtyText = _quantityController.text.trim().replaceAll(',', '.');
      // La cantidad y la unidad son UNA sola cosa: los kilos de la venta.
      // `unit` ya se guardaba solo si era venta; `quantity` no.
      //
      // No es un detalle: el campo de cantidad se oculta al cambiar de
      // categoría, pero el texto se queda en el controlador. El agricultor
      // escribe 50 en una Venta, se da cuenta de que era una SUBVENCIÓN y
      // la cambia, y esa subvención se guardaba con quantity=50 y unit=null.
      // Aguas abajo, report_harvest_metrics suma `quantity * unitToKg(unit)`
      // a «kg vendidos» sin comprobar que sea venta, y `unitToKg(null)` es
      // 1. Un millón de subvención inflando cincuenta kilos vendidos.
      quantity =
          (isSale && qtyText.isNotEmpty) ? double.tryParse(qtyText) : null;
      unit = (isSale && quantity != null) ? (_unit ?? 'kg') : null;
      client = isSale ? _clientController.text.trim() : null;
      provider = _type == TransactionType.expense
          ? _providerController.text.trim()
          : null;
    }
    final harvestId = _type == TransactionType.expense ? _harvestId : null;

    // E1 · la venta real. El descuento y el estado de pago solo aplican a
    // ventas: en un gasto no hay nada que descontar, y la plata ya salió, así
    // que "por cobrar" no significaría nada. Si el interruptor está apagado o
    // la cantidad viene vacía, queda null — y null, en esta app, es oculto.
    final isSaleTxn =
        _type == TransactionType.income && _saleCategories.contains(_category);
    double? deductionQty;
    String? deductionReason;
    if (isSaleTxn && _hasDeduction) {
      deductionQty = double.tryParse(
          _deductionQtyController.text.trim().replaceAll(',', '.'));
      if (deductionQty != null && deductionQty <= 0) deductionQty = null;
      final reason = _deductionReasonController.text.trim();
      deductionReason = reason.isEmpty ? null : reason;
    }
    final paid = isSaleTxn ? _paid : true;

    final editing = widget.editing;
    if (editing != null) {
      // Construimos el objeto directamente (no copyWith) para que los campos
      // nullable de producción se puedan LIMPIAR con null al cambiar de tipo
      // o categoría (p.ej. una venta convertida en gasto).
      await tx.updateTransaction(Transaction(
        id: editing.id,
        cropId: _cropId,
        // (b) · el lote viaja con el gasto. Con null el movimiento queda
        // exactamente como estaba.
        terrenoId: _terrenoId,
        type: _type,
        category: _category ?? 'otro',
        amount: amount,
        currency: _currency,
        description: _descriptionController.text.trim(),
        date: _date,
        createdAt: editing.createdAt,
        deleted: editing.deleted,
        pendingSync: true,
        quantity: quantity,
        unit: unit,
        pricePerUnit: pricePerUnit,
        client: client,
        provider: provider,
        harvestId: harvestId,
        sowingId: editing.sowingId,
        deductionQty: deductionQty,
        deductionReason: deductionReason,
        paid: paid,
        task: task,
        harvestedKg: harvestedKg,
      ));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.recordUpdated),
          duration: const Duration(seconds: 1),
        ),
      );
      Navigator.pop(context);
      return;
    }

    await tx.addTransaction(
      type: _type,
      category: _category ?? 'otro',
      cropId: _cropId,
      terrenoId: _terrenoId,
      amount: amount,
      currency: _currency,
      description: _descriptionController.text.trim(),
      date: _date,
      quantity: quantity,
      unit: unit,
      pricePerUnit: pricePerUnit,
      client: client,
      provider: provider,
      harvestId: harvestId,
      deductionQty: deductionQty,
      deductionReason: deductionReason,
      paid: paid,
      task: task,
      harvestedKg: harvestedKg,
    );

    // Recuerda lo elegido para preseleccionarlo la próxima vez.
    //
    // Se guardan LOS DOS y se limpian LOS DOS juntos, porque son mutuamente
    // excluyentes. Si el gasto fue de un lote, `_cropId` viene en `null` y con
    // él se borraba el recordatorio del cultivo sin que el lote ocupara su
    // sitio: el siguiente gasto compartido arrancaba en "Costos comunes" y
    // dejaba de repartirse por hectáreas.
    await tx.updateSettings(tx.settings
        .copyWith(lastCropId: _cropId, lastTerrenoId: _terrenoId));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.recordSaved),
        duration: const Duration(seconds: 1),
      ),
    );
    _descriptionController.clear();
    _amountController.clear();
    _quantityController.clear();
    _clientController.clear();
    _providerController.clear();
    _jornalOtherNameController.clear();
    _jornalDaysController.clear();
    _jornalRateController.clear();
    _jornalHarvestedKgController.clear();
    _jornalTaskValue = null;
    _jornalTaskOtherController.clear();
    _deductionQtyController.clear();
    _deductionReasonController.clear();
    setState(() {
      _unit = (isSale && quantity != null) ? _unit : null;
      _jornalWorkerValue = null;
      // Una venta guardada no arrastra el descuento ni el estado de pago de
      // la anterior: cada registro empieza limpio.
      _hasDeduction = false;
      _paid = true;
    });
  }

  Future<void> _confirmDelete() async {
    final editing = widget.editing;
    if (editing == null) return;
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.deleteDialogTitle),
        content: Text(l10n.deleteDialogBody),
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
    if (!mounted || ok != true) return;
    final tx = context.read<TransactionProvider>();
    await tx.deleteTransaction(editing.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.recordDeleted),
        duration: const Duration(seconds: 1),
      ),
    );
    Navigator.pop(context);
  }

  String _effectiveUnit(TransactionProvider tx) {
    // Si el usuario no eligió unidad y el cultivo tiene una preferida, la usa.
    // Una transacción guardada conserva su unidad almacenada.
    if (_unit != null) return _unit!;
    if (_cropId != null) {
      final matches = tx.crops.where((c) => c.id == _cropId).toList();
      if (matches.isNotEmpty && matches.first.defaultUnit != null) {
        return matches.first.defaultUnit!;
      }
    }
    return 'kg';
  }

  /// Cosechas del cultivo activo ordenadas de más reciente a más antigua,
  /// usadas para vincular el gasto con una cosecha.
  List<Harvest> _linkedHarvests(TransactionProvider tx) {
    if (_cropId == null) return const [];
    final list = tx.harvestsFor(_cropId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final tx = context.watch<TransactionProvider>();
    final l10n = AppLocalizations.of(context)!;
    final categoryHint = _categoryHint(l10n);
    final crops = tx.crops;
    final isExpense = _type.isExpense;
    final categories = isExpense
        ? expenseCategories
            .map((c) => (key: c.key, icon: c.icon, name: l10n.expenseCategory(c.key)))
            .toList()
        : incomeCategories
            // Las claves legadas (Venta café/…) solo se ofrecen si el
            // movimiento ya las usa; lo nuevo es la venta por cultivo.
            .where(
                (c) => c.key == _category || !_legacySaleCategories.contains(c.key))
            .map((c) {
              final isSale = c.key == kIncomeCategorySale;
              final crop = isSale ? cropOf(crops, _cropId) : null;
              return (
                key: c.key,
                icon: isSale ? (crop?.icon ?? c.icon) : c.icon,
                name: isSale
                    ? l10n.incomeSaleLabel(crop?.name)
                    : l10n.incomeCategory(c.key),
              );
            })
            .toList();

    final form = Form(
      key: _formKey,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            widget.editing != null ? l10n.registerEditTitle : l10n.tabRegister,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          // Tipo: gasto o ingreso
          SegmentedButton<TransactionType>(
            segments: [
              ButtonSegment(
                value: TransactionType.expense,
                label: Text(l10n.expenseTypeLabel),
                icon: const Icon(Icons.remove_circle_outline),
              ),
              ButtonSegment(
                value: TransactionType.income,
                label: Text(l10n.incomeTypeLabel),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() {
              _type = s.first;
              _category = null;
              // El lote es cosa de gastos: un ingreso no se reparte por
              // hectáreas, es de un cultivo o de la finca entera. Si estaba
              // elegido y pasa a ingreso, se quita.
              if (s.first == TransactionType.income) _terrenoId = null;
              _clearHarvestedKgIfHidden();
            }),
          ),
          const SizedBox(height: 16),

          // Cultivo o, si el gasto sirve a todo el lote, el lote. Van en el
          // MISMO desplegable y son mutuamente excluyentes: un gasto es de un
          // cultivo o del lote, nunca de los dos — lo dos a la vez sería
          // contar el mismo peso dos veces en el ROI de la finca.
          DropdownButtonFormField<String>(
            // El desplegable exige UN valor elegido; con lote puesto muestra
            // el lote y el cultivo se queda vacío.
            value: isExpense ? (_terrenoId ?? _cropId) : _cropId,
            decoration: InputDecoration(
              labelText: l10n.cropFieldLabel,
              prefixIcon: const Icon(Icons.grass_outlined),
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem<String>(
                value: null,
                // E2 · "Sin especificar" no le decía nada a nadie. Al ser el
                // único grupo que NO es de un cultivo, se llama por lo que es.
                // En ingresos, "lo que es" no es un costo: una venta sin
                // cultivo no es «Costos comunes», y el aviso de abajo (que
                // habla de cerca, camino y luz) tampoco le corresponde.
                child: Text(isExpense ? l10n.commonCosts : l10n.noCropLabel),
              ),
              DropdownMenuItem<String>(
                value: _newCropOption,
                child: Text(l10n.cropNewOption),
              ),
              ...crops.map((c) => DropdownMenuItem<String>(
                    value: c.id,
                    child: Text('${c.icon} ${c.name}'),
                  )),
              // Los lotes solo aparecen en gastos. Un encabezado no puede
              // quedar con valor null (con "Costos comunes" elegido el
              // desplegable exigiría exactamente un ítem con ese valor), así
              // que lleva un valor propio imposible y además no es elegible.
              if (isExpense && tx.terrenos.isNotEmpty) ...[
                DropdownMenuItem<String>(
                  enabled: false,
                  value: _loteHeader,
                  child: Text(
                    l10n.terrenoGroupLabel,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
                ...tx.terrenos.map((t) => DropdownMenuItem<String>(
                      value: t.id,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.landscape_outlined, size: 18),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(t.name,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    )),
              ],
            ],
            onChanged: (v) {
              if (v == _newCropOption) {
                _createCrop();
              } else {
                // Moneda única: elegir cultivo ya no toca la moneda. Antes la
                // cambiaba sola según el cultivo, y el registro podía salir
                // en otra moneda que la que se había escrito, sin avisar.
                final esLote = tx.terrenos.any((t) => t.id == v);
                setState(() {
                  if (esLote) {
                    _terrenoId = v;
                    _cropId = null;
                  } else {
                    _cropId = v;
                    _terrenoId = null;
                  }
                  _unit = null;
                  _harvestId = null;
                  _clearHarvestedKgIfHidden();
                });
              }
            },
          ),
          const SizedBox(height: 4),
          // E2 · el aviso cambia con la elección: si el movimiento no es de
          // ningún cultivo, lo que hay que explicar es lo que eso implica.
          // Si sí lo es, se mantiene el de siempre.
          Text(
            // En ingresos el ítem nulo no son costos comunes, así que el
            // aviso tampoco puede serlo.
            _terrenoId != null
                ? l10n.terrenoGroupHint
                : (_cropId == null
                    ? (isExpense ? l10n.commonCostsHint : l10n.noCropHint)
                    : l10n.cropGroupHint),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),

          // Categoría
          DropdownButtonFormField<String>(
            value: _category,
            decoration: InputDecoration(
              labelText: l10n.categoryFieldLabel,
              prefixIcon: const Icon(Icons.category_outlined),
              border: const OutlineInputBorder(),
            ),
            items: categories
                .map((c) => DropdownMenuItem<String>(
                      value: c.key,
                      child: Text('${c.icon} ${c.name}'),
                    ))
                .toList(),
            onChanged: (v) => setState(() {
              _category = v;
              _clearHarvestedKgIfHidden();
            }),
          ),

          // Ayuda al elegir categoría. H4 · el camino corto ya existía y
          // nadie lo veía: anotar colinos como gasto de "Siembra" cuenta
          // como inversión. El mismo sitio ahora explica también cuándo va
          // el pago a quien cosecha (Mano de obra) y cuándo el gasto de la
          // cosecha en sí (Cosecha y recolección), que se confunden porque
          // una labor se llama "cosechar".
          if (categoryHint != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 18,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      categoryHint,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSecondaryContainer,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Datos de producción (solo ventas)
          if (_type == TransactionType.income &&
              _saleCategories.contains(_category)) ...[
            _ProdSectionHeader(label: l10n.prodSectionTitle),
            const SizedBox(height: 12),

            // Cantidad vendida
            TextFormField(
              controller: _quantityController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l10n.quantityFieldLabel,
                prefixIcon: const Icon(Icons.scale_outlined),
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),

            // Unidad
            DropdownButtonFormField<String>(
              value: _effectiveUnit(tx),
              decoration: InputDecoration(
                labelText: l10n.unitFieldLabel,
                prefixIcon: const Icon(Icons.category_outlined),
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: 'kg', child: Text(l10n.unitKg)),
                DropdownMenuItem(value: 'lb', child: Text(l10n.unitLb)),
                DropdownMenuItem(value: 'arroba', child: Text(l10n.unitArroba)),
                DropdownMenuItem(value: 'saco', child: Text(l10n.unitSaco)),
                DropdownMenuItem(value: 'carga', child: Text(l10n.unitCarga)),
                DropdownMenuItem(value: 'racimo', child: Text(l10n.unitRacimo)),
                DropdownMenuItem(value: 'cajon', child: Text(l10n.unitCajon)),
              ],
              onChanged: (v) => setState(() => _unit = v),
            ),
            const SizedBox(height: 12),

            // Cliente / comprador
            TextFormField(
              controller: _clientController,
              decoration: InputDecoration(
                labelText: l10n.clientFieldLabel,
                prefixIcon: const Icon(Icons.person_outline),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Precio por unidad (auto). Se calcula sobre lo que de verdad se
            // pagó, no sobre lo que se entregó: si hubo descuento, el precio
            // que importa es el de la unidad que entró a la caja.
            _PricePerUnitInfo(
              amount: double.tryParse(
                  _amountController.text.trim().replaceAll(',', '.')),
              quantity: _netSaleQuantity(),
              unit: _unit,
              currency: _currency,
              locale: tx.settings.numberLocale,
              l10n: l10n,
            ),
            const SizedBox(height: 12),

            // E1 · ¿el comprador descontó antes de pagar?
            SwitchListTile(
              value: _hasDeduction,
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.deductionSwitchLabel),
              subtitle: Text(l10n.deductionHint),
              onChanged: (v) => setState(() => _hasDeduction = v),
            ),
            if (_hasDeduction) ...[
              TextFormField(
                controller: _deductionQtyController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l10n.deductionQtyLabel,
                  prefixIcon: const Icon(Icons.trending_down),
                  border: const OutlineInputBorder(),
                  // La unidad es la de la venta, que es la de la cosecha: no
                  // se descuentan kilos de una venta hecha en racimos.
                  suffixText: _unit,
                ),
                validator: (v) {
                  if (!_hasDeduction) return null;
                  final n =
                      double.tryParse((v ?? '').trim().replaceAll(',', '.'));
                  if (n == null || n <= 0) return l10n.deductionQtyInvalid;
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _deductionReasonController,
                decoration: InputDecoration(
                  labelText: l10n.deductionReasonLabel,
                  prefixIcon: const Icon(Icons.notes_outlined),
                  border: const OutlineInputBorder(),
                  hintText: l10n.deductionReasonHint,
                ),
              ),
              const SizedBox(height: 12),
              _DeductionSummary(
                quantity: double.tryParse(_quantityController.text
                    .trim()
                    .replaceAll(',', '.')),
                deduction: double.tryParse(
                    _deductionQtyController.text.trim().replaceAll(',', '.')),
                reason: _deductionReasonController.text.trim(),
                unit: _unit,
                l10n: l10n,
              ),
            ],
            const SizedBox(height: 16),

            // E1 · estado de pago. Dos estados a propósito: "parcial" se
            // resuelve registrando lo que ya entró como otro ingreso.
            _ProdSectionHeader(label: l10n.paidStatusTitle),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: true, label: Text(l10n.paidStatusPaid)),
                ButtonSegment(
                    value: false, label: Text(l10n.paidStatusPending)),
              ],
              selected: {_paid},
              onSelectionChanged: (s) => setState(() => _paid = s.first),
            ),
            const SizedBox(height: 16),
          ],

          // Proveedor / Jornal (solo gastos)
          if (_type == TransactionType.expense) ...[
            _ProdSectionHeader(
                label:
                    _isJornal ? l10n.jornalSectionTitle : l10n.providerFieldLabel),
            const SizedBox(height: 12),

            if (_isJornal) ...[
              // Trabajador (dropdown de la lista + Otro nombre… + Crear…)
              DropdownButtonFormField<String>(
                key: ValueKey('jornal-$_jornalWorkerValue-$_jornalDropKey'),
                value: _jornalWorkerValue,
                decoration: InputDecoration(
                  labelText: l10n.jornalWorkerLabel,
                  prefixIcon: const Icon(Icons.person_outline),
                  border: const OutlineInputBorder(),
                  hintText:
                      tx.employees.isEmpty ? l10n.jornalWorkerHint : null,
                ),
                items: [
                  ...tx.employees.map((e) => DropdownMenuItem<String>(
                        value: e.id,
                        child: Text(e.name),
                      )),
                  DropdownMenuItem<String>(
                    value: _jornalOtherOption,
                    child: Text(l10n.jornalOtherNameOption),
                  ),
                  DropdownMenuItem<String>(
                    value: _jornalCreateOption,
                    child: Text(l10n.jornalCreateOption),
                  ),
                ],
                validator: (v) {
                  if (v == null) return l10n.jornalWorkerRequired;
                  if (v == _jornalOtherOption &&
                      _jornalOtherNameController.text.trim().isEmpty) {
                    return l10n.workerNameRequired;
                  }
                  return null;
                },
                onChanged: (v) {
                  if (v == _jornalCreateOption) {
                    _createJornalWorker();
                    return;
                  }
                  setState(() {
                    _jornalWorkerValue = v;
                    if (v != null &&
                        v != _jornalOtherOption &&
                        v != _jornalCreateOption) {
                      final match = tx.employees
                          .where((e) => e.id == v)
                          .toList();
                      // El jornal de un trabajador se guarda y se pinta
                      // SIEMPRE en la moneda de la cuenta: así se registran
                      // y así se muestran en Trabajadores. Aquí solo se
                      // autocompleta si este registro vive en esa misma
                      // moneda. Si es un registro viejo en otra —se edita
                      // conservando su moneda— meter el número sería
                      // presentar pesos como dólares.
                      if (match.isNotEmpty &&
                          match.first.dayRate != null &&
                          _currency == tx.settings.currency) {
                        final r = match.first.dayRate!;
                        _jornalRateController.text =
                            (r % 1 == 0) ? r.toInt().toString() : r.toString();
                      }
                    }
                    _recalcJornalAmount();
                  });
                },
              ),
              if (_jornalWorkerValue == _jornalOtherOption) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _jornalOtherNameController,
                  decoration: InputDecoration(
                    labelText: l10n.workerNameLabel,
                    prefixIcon: const Icon(Icons.person_outline),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
              const SizedBox(height: 12),

              // E3 · qué se hizo. Lista cerrada para que la planilla pueda
              // agrupar: "Descolgar" y "descolgar" tienen que ser el mismo
              // renglón. "Otra…" abre un campo de texto para lo demás.
              DropdownButtonFormField<String>(
                value: _jornalTaskValue,
                decoration: InputDecoration(
                  labelText: l10n.taskFieldLabel,
                  prefixIcon: const Icon(Icons.checklist_outlined),
                  border: const OutlineInputBorder(),
                  hintText: l10n.taskFieldHint,
                ),
                items: [
                  for (final t in farmTasks)
                    DropdownMenuItem<String>(
                      value: t.key,
                      child: Text('${t.icon} ${t.name}'),
                    ),
                  DropdownMenuItem<String>(
                    value: _jornalTaskOtherOption,
                    child: Text(l10n.taskOtherOption),
                  ),
                ],
                onChanged: (v) => setState(() {
                  _jornalTaskValue = v;
                  if (v != _jornalTaskOtherOption) {
                    _jornalTaskOtherController.clear();
                  }
                  _clearHarvestedKgIfHidden();
                }),
              ),
              if (_jornalTaskValue == _jornalTaskOtherOption) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _jornalTaskOtherController,
                  decoration: InputDecoration(
                    labelText: l10n.taskOtherLabel,
                    prefixIcon: const Icon(Icons.edit_outlined),
                    border: const OutlineInputBorder(),
                    hintText: l10n.taskOtherHint,
                  ),
                ),
              ],
              const SizedBox(height: 12),

              // Tanda 2 · kilos recolectados. Opcional: vacío = no medido.
              // Solo con «Cosechar» y cultivo; si falta el cultivo se dice
              // por qué no está, en vez de esconderlo sin explicación.
              if (_showsHarvestedKg) ...[
                TextFormField(
                  controller: _jornalHarvestedKgController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: l10n.jornalHarvestedKgLabel,
                    helperText: l10n.jornalHarvestedKgHelp,
                    prefixIcon: const Icon(Icons.scale_outlined),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final txt = (v ?? '').trim();
                    if (txt.isEmpty) return null; // opcional
                    final n = double.tryParse(txt.replaceAll(',', '.'));
                    if (n == null || n <= 0) {
                      return l10n.jornalHarvestedKgInvalid;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
              ] else if (_jornalTaskValue == kTaskCosechar) ...[
                Text(
                  l10n.jornalHarvestedKgNoCrop,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
              ],

              // Días trabajados
              TextFormField(
                controller: _jornalDaysController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.jornalDaysLabel,
                  prefixIcon: const Icon(Icons.today_outlined),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  final n = int.tryParse((v ?? '').trim());
                  if (n == null || n <= 0) return l10n.jornalDaysRequired;
                  return null;
                },
                onChanged: (_) => setState(_recalcJornalAmount),
              ),
              const SizedBox(height: 12),

              // Valor por día (autocompletado desde la ficha)
              TextFormField(
                controller: _jornalRateController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l10n.workerDayRateShort,
                  prefixIcon: const Icon(Icons.payments_outlined),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  final n = double.tryParse(
                      (v ?? '').trim().replaceAll(',', '.'));
                  if (n == null || n <= 0) return l10n.jornalRateRequired;
                  return null;
                },
                onChanged: (_) => setState(_recalcJornalAmount),
              ),
              const SizedBox(height: 8),

              // Total = días × valor día (reflejado en el campo Monto)
              _JornalTotalInfo(
                days: double.tryParse(_jornalDaysController.text
                    .trim()
                    .replaceAll(',', '.')),
                rate: double.tryParse(_jornalRateController.text
                    .trim()
                    .replaceAll(',', '.')),
                currency: _currency,
                locale: tx.settings.numberLocale,
                l10n: l10n,
              ),
              const SizedBox(height: 12),
            ] else ...[
              TextFormField(
                controller: _providerController,
                decoration: InputDecoration(
                  labelText: l10n.providerFieldLabel,
                  prefixIcon: const Icon(Icons.storefront_outlined),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Vincular a cosecha (solo gastos): las cosechas recientes del
            // cultivo elegido, para asociar el pago de recogida.
            if (_cropId != null && _linkedHarvests(tx).isNotEmpty) ...[
              DropdownButtonFormField<String?>(
                value: _harvestId,
                decoration: InputDecoration(
                  labelText: l10n.expenseLinkHarvestLabel,
                  prefixIcon: const Icon(Icons.link),
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(l10n.expenseLinkHarvestNone),
                  ),
                  ..._linkedHarvests(tx).map((h) => DropdownMenuItem<String?>(
                        value: h.id,
                        child: Text(
                          '${h.date.day.toString().padLeft(2, '0')}/'
                          '${h.date.month.toString().padLeft(2, '0')}/'
                          '${h.date.year} · '
                          '${h.amount.toStringAsFixed(h.amount % 1 == 0 ? 0 : 2)}',
                        ),
                      )),
                ],
                onChanged: (v) => setState(() => _harvestId = v),
              ),
            ],
            const SizedBox(height: 16),
          ],

          // Monto (solo lectura cuando el bloque jornal lo calcula)
          TextFormField(
            controller: _amountController,
            readOnly: _isJornal,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.amountFieldLabel,
              prefixIcon: const Icon(Icons.attach_money),
              border: const OutlineInputBorder(),
              suffixIcon: _isJornal
                  ? Tooltip(
                      message: l10n.jornalTotalHint,
                      child: const Icon(Icons.lock_outline, size: 20),
                    )
                  : null,
            ),
            validator: (v) {
              if (_isJornal) {
                // El total lo defienden los validadores de días y valor día.
                final days = int.tryParse(_jornalDaysController.text.trim());
                final rate = double.tryParse(_jornalRateController.text
                    .trim()
                    .replaceAll(',', '.'));
                if (days == null || days <= 0) return l10n.jornalDaysRequired;
                if (rate == null || rate <= 0) {
                  return l10n.jornalRateRequired;
                }
                return null;
              }
              final n = double.tryParse((v ?? '').replaceAll(',', '.'));
              if (n == null || n <= 0) return l10n.amountInvalid;
              return null;
            },
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),

          // Moneda única de la cuenta: no hay nada que elegir. El símbolo
          // del monto ya la dice, y aquí solo se aclara cuál es — para que
          // quien edita un registro viejo en otra moneda sepa que se
          // conserva la suya y no la de la cuenta.
          Text(
            l10n.currencyRegisterHint(
                '${currencyInfo(_currency).name} (${currencyInfo(_currency).code})'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),

          // Fecha
          InkWell(
            onTap: _pickDate,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: l10n.dateFieldLabel,
                prefixIcon: const Icon(Icons.calendar_today_outlined),
                border: const OutlineInputBorder(),
              ),
              child: Text(
                MaterialLocalizations.of(context).formatShortDate(_date),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Descripción
          TextFormField(
            controller: _descriptionController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: l10n.descriptionFieldLabel,
              alignLabelWithHint: true,
              prefixIcon: const Icon(Icons.notes),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),

          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check),
            label: Text(widget.editing != null ? l10n.saveChanges : l10n.saveRecord),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _type.isExpense ? l10n.expenseFootnote : l10n.incomeFootnote,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          ],
        ),
        ),
        ),
    );
    if (widget.editing != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.registerEditTitle),
          actions: [
            IconButton(
              tooltip: l10n.delete,
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmDelete,
            ),
          ],
        ),
        body: form,
      );
    }
    return form;
  }
}

class _ProdSectionHeader extends StatelessWidget {
  final String label;
  const _ProdSectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.factory_outlined,
            size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _JornalTotalInfo extends StatelessWidget {
  final double? days;
  final double? rate;
  final String currency;
  final String locale;
  final AppLocalizations l10n;

  const _JornalTotalInfo({
    required this.days,
    required this.rate,
    required this.currency,
    required this.locale,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final d = days;
    final r = rate;
    if (d == null || d <= 0 || r == null || r <= 0) {
      return Text(
        l10n.jornalTotalHint,
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    final total = d * r;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.calculate_outlined, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                      text: '${l10n.jornalTotalLabel}: ',
                      style: Theme.of(context).textTheme.bodyMedium),
                  TextSpan(
                    text: formatAmount(total,
                        currency: currency, locale: locale),
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// E1 · recuento visible del descuento: entregado, descontado y pagado.
///
/// Existe como widget aparte porque es la única parte del formulario que
/// **no** es un campo que se llena, sino una cuenta que se lee. Regla de oro
/// aplicada: si falta la cantidad o el descuento, no se muestra nada — nunca
/// un "0" inventado.
class _DeductionSummary extends StatelessWidget {
  final double? quantity;
  final double? deduction;
  final String reason;
  final String? unit;
  final AppLocalizations l10n;

  const _DeductionSummary({
    required this.quantity,
    required this.deduction,
    required this.reason,
    required this.unit,
    required this.l10n,
  });

  static String _fmt(double v) =>
      (v % 1 == 0) ? v.toInt().toString() : v.toString();

  @override
  Widget build(BuildContext context) {
    final q = quantity;
    final d = deduction;
    if (q == null || q <= 0 || d == null || d <= 0) {
      return const SizedBox.shrink();
    }
    final net = (q - d).clamp(0.0, double.infinity).toDouble();
    final suffix = (unit == null || unit!.isEmpty) ? '' : ' ${unit!}';
    final over = d > q;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: over
            ? Theme.of(context).colorScheme.errorContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row(l10n.deductionRegisteredLabel, '${_fmt(q)}$suffix'),
          _row(l10n.deductionRegisteredLabel, '${_fmt(q)}$suffix'),
          _row(l10n.deductionDeductedLabel, '-${_fmt(d)}$suffix'),
          if (reason.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 4),
              child: Text(
                reason,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          const Divider(height: 12),
          _row(
            l10n.deductionPaidLabel,
            '${_fmt(net)}$suffix',
            bold: true,
          ),
          if (over)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l10n.deductionOverQuantity,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _PricePerUnitInfo extends StatelessWidget {
  final double? amount;
  final double? quantity;
  final String? unit;
  final String currency;
  final String locale;
  final AppLocalizations l10n;

  const _PricePerUnitInfo({
    required this.amount,
    required this.quantity,
    required this.unit,
    required this.currency,
    required this.locale,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final a = amount;
    final q = quantity;
    final u = unit;
    if (a == null || q == null || q <= 0 || u == null) {
      return Text(
        l10n.pricePerUnitHint,
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    final perUnit = a / q;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.calculate_outlined, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                      text: '${l10n.pricePerUnitLabel} $u: ',
                      style: Theme.of(context).textTheme.bodyMedium),
                  TextSpan(
                    text: formatAmount(perUnit,
                        currency: currency, locale: locale, decimals: 2),
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
