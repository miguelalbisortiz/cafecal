import 'dart:io';

import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/models/crop.dart';
import 'package:mi_cafetal/models/settings.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/services/pdf_export_service.dart';

Future<void> main() async {
  final now = DateTime.now();
  final tx = <Transaction>[];

  final sales = [3200000, 2750000, 2900000, 2400000, 3100000, 2650000];
  for (var i = 0; i < sales.length; i++) {
    tx.add(Transaction(
      id: 'seed_income_$i',
      type: TransactionType.income,
      category: 'Venta de café',
      cropId: 'cafe',
      amount: sales[i].toDouble(),
      description: 'Venta de café',
      date: DateTime(now.year, now.month - i, 1),
      createdAt: DateTime.now().toUtc(),
    ));
  }
  tx.add(Transaction(
    id: 'seed_income_p',
    type: TransactionType.income,
    category: 'Venta de plátano',
    cropId: 'platano',
    amount: 2500000,
    description: 'Venta de plátano',
    date: DateTime(now.year, now.month - 2, 1),
    createdAt: DateTime.now().toUtc(),
  ));

  final exp = <List<Object?>>[
    [DateTime(now.year, now.month - 1, 1), 'Fertilizantes', 'cafe', 450000],
    [DateTime(now.year, now.month - 2, 1), 'Mano de obra', 'cafe', 700000],
    [DateTime(now.year, now.month - 2, 1), 'Mano de obra', 'cafe', 620000],
    [DateTime(now.year, now.month - 3, 1), 'Herramientas', 'platano', 300000],
    [DateTime(now.year, now.month - 4, 1), 'Transporte', null, 180000],
    [DateTime(now.year, now.month - 5, 1), 'Insumos', 'cafe', 350000],
  ];
  for (var i = 0; i < exp.length; i++) {
    final e = exp[i];
    tx.add(Transaction(
      id: 'seed_expense_$i',
      type: TransactionType.expense,
      category: e[1] as String,
      cropId: e[2] as String?,
      amount: (e[3] as int).toDouble(),
      date: e[0] as DateTime,
      createdAt: DateTime.now().toUtc(),
    ));
  }

  final outDir = Directory('build/sample_pdfs')..createSync(recursive: true);
  final svc = PdfExportService();

  final yearBytes = await svc.buildReport(
    settings: const FarmSettings(farmName: 'Mi Cafetal'),
    transactions: tx,
    crops: defaultCrops,
    year: now.year,
    month: null,
    period: ReportPeriod.year,
    periodName: '${now.year}',
    l10n: stringsFor('es'),
  );
  File('${outDir.path}/reporte_anual.pdf').writeAsBytesSync(yearBytes);

  final monthBytes = await svc.buildReport(
    settings: const FarmSettings(farmName: 'Mi Cafetal'),
    transactions: tx,
    crops: defaultCrops,
    year: now.year,
    month: now.month,
    period: ReportPeriod.month,
    periodName: 'Septiembre ${now.year}',
    l10n: stringsFor('es'),
  );
  File('${outDir.path}/reporte_mensual.pdf').writeAsBytesSync(monthBytes);

  stdout.writeln('OK ${outDir.path}');
}
