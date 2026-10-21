import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/crop.dart';
import '../services/expense_split.dart';
import '../utils/format.dart';

/// T15 · reparto de un gasto entre varios cultivos.
///
/// El gasto no se guarda como un padre con hijos: se guardan N gastos
/// independientes, uno por cultivo, con el mismo día, categoría y descripción.
/// La suma de los pedazos es exactamente el total (el último absorbe el
/// redondeo). Cada gasto entra al costo por kilo de su cultivo.
class ExpenseSplitDialog extends StatefulWidget {
  const ExpenseSplitDialog({
    super.key,
    required this.total,
    required this.currency,
    required this.crops,
    this.initial = const [],
  });

  final double total;
  final String currency;
  final List<Crop> crops;

  /// Reparto ya elegido, para volver a abrirlo sin perder lo escrito.
  final List<ExpenseShare> initial;

  @override
  State<ExpenseSplitDialog> createState() => _ExpenseSplitDialogState();
}

class _ExpenseSplitDialogState extends State<ExpenseSplitDialog> {
  final Map<String, TextEditingController> _controllers = {};
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    for (final c in widget.crops) {
      final controller = TextEditingController();
      final current = widget.initial.where((s) => s.cropId == c.id).toList();
      if (current.isNotEmpty) {
        controller.text = _numText(current.first.percent);
        _selected.add(c.id);
      }
      _controllers[c.id] = controller;
    }

    // Sin reparto previo, se propone el de áreas **solo si todos** los cultivos
    // están medidos: con uno sin área, el atajo no puede repartir el 100 % y
    // proponerlo sería mentir.
    if (widget.initial.isEmpty) {
      final auto = areaShares(widget.crops);
      if (auto.isNotEmpty && auto.length == widget.crops.length) {
        _apply(auto);
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  static String _numText(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '');
  }

  void _apply(List<ExpenseShare> shares) {
    _selected.clear();
    for (final c in widget.crops) {
      final share = shares.where((s) => s.cropId == c.id).toList();
      _controllers[c.id]!.text =
          share.isEmpty ? '' : _numText(share.first.percent);
      if (share.isNotEmpty) _selected.add(c.id);
    }
  }

  double? _percentOf(String cropId) {
    final raw = _controllers[cropId]!.text.trim().replaceAll(',', '.');
    if (raw.isEmpty) return null;
    final v = double.tryParse(raw);
    if (v == null || v < 0) return null;
    return v;
  }

  List<String> _selectedIds() =>
      widget.crops.map((c) => c.id).where(_selected.contains).toList();

  double _sum() {
    var total = 0.0;
    for (final id in _selectedIds()) {
      total += _percentOf(id) ?? 0;
    }
    return total;
  }

  bool _valid() {
    final ids = _selectedIds();
    if (ids.length < 2) return false;
    for (final id in ids) {
      final p = _percentOf(id);
      // Un cultivo elegido con 0 (o vacío) crearía un gasto de 0: no es una
      // parte del reparto, es una fila que sobra.
      if (p == null || p <= 0) return false;
    }
    return (_sum() - 100).abs() <= 0.01;
  }

  void _useAreas(AppLocalizations l10n) {
    final shares = areaShares(widget.crops);
    if (shares.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.expenseSplitNoAreas)),
      );
      return;
    }
    setState(() => _apply(shares));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final selectedCrops =
        widget.crops.where((c) => _selected.contains(c.id)).toList();
    final amounts = _valid()
        ? splitAmounts(
            widget.total,
            selectedCrops.map((c) => _percentOf(c.id)!).toList(),
          )
        : null;
    final sum = _sum();
    final ids = _selectedIds();
    final valid = _valid();
    final hasZero = ids.any((id) => (_percentOf(id) ?? 0) <= 0);

    return AlertDialog(
      title: Text(l10n.expenseSplitTitle),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.expenseSplitBody),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final c in widget.crops) ...[
                      Row(
                        children: [
                          Checkbox(
                            value: _selected.contains(c.id),
                            onChanged: (v) => setState(() {
                              if (v == true) {
                                _selected.add(c.id);
                              } else {
                                _selected.remove(c.id);
                                _controllers[c.id]!.clear();
                              }
                            }),
                          ),
                          Expanded(
                            child: Text(
                              '${c.icon} ${c.name}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(
                            width: 96,
                            child: TextField(
                              controller: _controllers[c.id],
                              enabled: _selected.contains(c.id),
                              textAlign: TextAlign.end,
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true),
                              decoration: const InputDecoration(
                                suffixText: '%',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                      if (amounts != null && _selected.contains(c.id))
                        Padding(
                          padding: const EdgeInsets.only(left: 48, bottom: 4),
                          child: Text(
                            formatMoneyFor(
                              context,
                              amounts[selectedCrops.indexOf(c)],
                              currency: widget.currency,
                            ),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _useAreas(l10n),
                icon: const Icon(Icons.square_foot, size: 18),
                label: Text(l10n.expenseSplitUseAreas),
              ),
            ),
            Text(
              l10n.expenseSplitSum(_numText(sum)),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: valid ? scheme.onSurfaceVariant : scheme.tertiary,
              ),
            ),
            if (!valid) ...[
              const SizedBox(height: 4),
              Text(
                ids.length < 2
                    ? l10n.expenseSplitFew
                    : (hasZero
                        ? l10n.expenseSplitZero
                        : l10n.expenseSplitMustSum),
                style: TextStyle(fontSize: 12, color: scheme.tertiary),
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
        FilledButton(
          onPressed: valid
              ? () => Navigator.pop(
                    context,
                    [
                      for (final c in selectedCrops)
                        (cropId: c.id, percent: _percentOf(c.id)!),
                    ],
                  )
              : null,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
