import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/transaction_provider.dart';
import '../services/pdf_export_service.dart';
import '../utils/format.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  static const _months = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  late int _year;
  late int _month;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
  }

  @override
  Widget build(BuildContext context) {
    final tx = context.watch<TransactionProvider>();
    final records = tx.where(year: _year, month: _month);
    final expenses = records
        .where((t) => t.type.isExpense)
        .fold<double>(0, (a, t) => a + t.amount);
    final incomes = records
        .where((t) => !t.type.isExpense)
        .fold<double>(0, (a, t) => a + t.amount);
    final balance = incomes - expenses;
    final movement = expenses + incomes;

    return Scaffold(
      appBar: AppBar(title: const Text('Reporte')),
      body: RefreshIndicator(
        onRefresh: () async {},
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _month,
                    decoration: const InputDecoration(
                      labelText: 'Mes',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (var i = 0; i < 12; i++)
                        DropdownMenuItem(value: i, child: Text(_months[i])),
                    ],
                    onChanged: (v) =>
                        setState(() => _month = v ?? _month),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _year,
                    decoration: const InputDecoration(
                      labelText: 'Año',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (var y = _year - 2; y <= _year; y++)
                        DropdownMenuItem(value: y, child: Text('$y')),
                    ],
                    onChanged: (v) => setState(() => _year = v ?? _year),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              '${_months[_month]} de $_year',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _SummaryCard(
                label: 'Gastos', value: expenses, color: Colors.red),
            const SizedBox(height: 8),
            _SummaryCard(
                label: 'Ingresos', value: incomes, color: Colors.green),
            const SizedBox(height: 8),
            _SummaryCard(
                label: 'Balance',
                value: balance,
                color: balance >= 0 ? Colors.green.shade700 : Colors.red.shade700),
            const SizedBox(height: 8),
            _SummaryCard(
              label: 'Gasto/movimiento',
              value: movement <= 0
                  ? 0
                  : (expenses / movement) * 100,
              color: Colors.brown,
              suffix: '%',
            ),

            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Desglose por cultivo (año $_year)',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ..._cropRows(tx, _year).map((row) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(row.name,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600)),
                                    Text(
                                      'G ${formatAmount(row.expenses,
                                          currency: tx.settings.currency,
                                          locale: tx.settings.locale)} · '
                                      'I ${formatAmount(row.incomes,
                                          currency: tx.settings.currency,
                                          locale: tx.settings.locale)}',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                row.roiLabel,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: row.roi < -0.30
                                      ? Colors.red
                                      : Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        )),
                    if (_cropRows(tx, _year).isEmpty)
                      const Text('Sin datos de cultivos en el año.'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _exporting ? null : () => _export(tx),
              icon: _exporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf),
              label: Text(_exporting ? 'Generando…' : 'Exportar PDF y compartir'),
            ),
          ],
        ),
      ),
    );
  }

  List<_CropRow> _cropRows(TransactionProvider tx, int year) {
    final nameById = {for (final c in tx.crops) c.id: c.name};
    final totals = <String?, _CropRow>{
      null: _CropRow(name: 'Sin especificar'),
    };
    for (final c in tx.crops) {
      totals.putIfAbsent(c.id, () => _CropRow(name: c.name));
    }
    for (final t in tx.transactions) {
      if (t.deleted || t.date.year != year) continue;
      final row = totals.putIfAbsent(t.cropId, () => _CropRow(
          name: t.cropId == null ? 'Sin especificar' : (nameById[t.cropId] ?? t.cropId!)));
      if (t.type.isExpense) {
        row.expenses += t.amount;
      } else {
        row.incomes += t.amount;
      }
    }
    return totals.values
        .where((r) => r.expenses > 0 || r.incomes > 0)
        .toList()
      ..sort((a, b) => (b.expenses + b.incomes)
          .compareTo(a.expenses + a.incomes));
  }

  Future<void> _export(TransactionProvider tx) async {
    setState(() => _exporting = true);
    try {
      final svc = PdfExportService();
      final bytes = await svc.buildReport(
        settings: tx.settings,
        transactions: tx.transactions,
        crops: tx.crops,
        year: _year,
        month: _month,
        monthName: _months[_month],
      );

final fileName =
          'reporte_$_year-${(_month + 1).toString().padLeft(2, '0')}.pdf';
      final result = await SharePlus.instance.share(ShareParams(
        files: [
          XFile.fromData(Uint8List.fromList(bytes),
              mimeType: 'application/pdf', name: fileName),
        ],
        subject: 'Mi Cafetal — Reporte $_year',
      ));
      if (!mounted) return;
      if (result.status != ShareResultStatus.dismissed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reporte generado.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo exportar: $e')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final String? suffix;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final tx = context.read<TransactionProvider>();
    final text = suffix == null
        ? formatAmount(value,
            currency: tx.settings.currency,
            locale: tx.settings.locale)
        : '${value.toStringAsFixed(0)}$suffix';
    return Card(
      child: ListTile(
        leading: Icon(Icons.circle, color: color, size: 14),
        title: Text(label, style: const TextStyle(fontSize: 13)),
        trailing: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: value < 0 ? Colors.red : null,
          ),
        ),
      ),
    );
  }
}

class _CropRow {
  final String name;
  double expenses = 0;
  double incomes = 0;

  _CropRow({required this.name});

  double get roi => expenses <= 0 ? 0 : (incomes - expenses) / expenses;
  String get roiLabel =>
      expenses <= 0 ? '—' : 'ROI ${(roi * 100).toStringAsFixed(0)}%';
}