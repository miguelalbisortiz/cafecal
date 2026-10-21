import '../models/crop.dart';

/// Una parte del gasto repartido: qué cultivo y qué porcentaje.
typedef ExpenseShare = ({String cropId, double percent});

/// Convierte porcentajes en montos que **suman exactamente** [total].
///
/// Los primeros se redondean a 2 decimales y el último absorbe el remanente:
/// tres partes iguales de 100.000 son 33.333,33 + 33.333,33 + 33.333,34, no
/// 99.999,99. Si los porcentajes no suman 100, devuelve `null`: no se inventa
/// un reparto que no cuadra.
List<double>? splitAmounts(double total, List<double> percents) {
  if (percents.length < 2 || total <= 0) return null;
  final sum = percents.fold<double>(0, (a, b) => a + b);
  if ((sum - 100).abs() > 0.01) return null;

  final amounts = <double>[];
  var assigned = 0.0;
  for (var i = 0; i < percents.length - 1; i++) {
    final part =
        double.parse((total * percents[i] / 100).toStringAsFixed(2));
    amounts.add(part);
    assigned += part;
  }
  amounts.add(double.parse((total - assigned).toStringAsFixed(2)));
  return amounts;
}

/// Porcentaje de cada cultivo según su área, para el atajo «usar áreas».
///
/// Solo entran los cultivos con área > 0: sin área no hay con qué repartir, y
/// darle un porcentaje inventado torcería todos los demás. Hacen falta al menos
/// dos cultivos medidos. El último absorbe el remanente para que sumen 100.
List<ExpenseShare> areaShares(Iterable<Crop> crops) {
  final measured = crops.where((c) => (c.areaHa ?? 0) > 0).toList();
  if (measured.length < 2) return const [];

  final totalArea = measured.fold<double>(0, (a, c) => a + c.areaHa!);
  final shares = <ExpenseShare>[];
  var assigned = 0.0;
  for (var i = 0; i < measured.length - 1; i++) {
    final pct = double.parse(
        (measured[i].areaHa! / totalArea * 100).toStringAsFixed(2));
    shares.add((cropId: measured[i].id, percent: pct));
    assigned += pct;
  }
  shares.add((
    cropId: measured.last.id,
    percent: double.parse((100 - assigned).toStringAsFixed(2)),
  ));
  return shares;
}
