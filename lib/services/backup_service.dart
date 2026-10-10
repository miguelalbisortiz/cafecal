import 'dart:convert';

import '../models/crop.dart';
import '../models/employee.dart';
import '../models/harvest.dart';
import '../models/settings.dart';
import '../models/sowing.dart';
import '../models/transaction.dart';

/// Marca de identidad del archivo de respaldo. Un JSON que no la trae (o trae
/// otro valor) **no** es un respaldo de la app y no se importa, ni siquiera a
/// medias: un archivo ajeno o corrupto nunca debe meter datos a medio gas.
const String kBackupFormat = 'cafecal-respaldo';

/// Versión del formato. Solo se acepta 1: una versión desconocida puede traer
/// campos que aquí se leerían mal.
const int kBackupVersion = 1;

/// Motivo por el que un archivo no pudo leerse como respaldo, para que la UI
/// avise con palabras claras (versión más nueva, archivo ajeno…) en lugar de
/// tirar un error crudo.
enum BackupErrorKind {
  malformado,
  formatoDesconocido,
  versionNoSoportada,
  incompleto,
}

/// [FormatException] con el motivo clasificado. Sigue siendo un
/// [FormatException], así que quien solo quiera capturar errores de formato
/// también la ve.
class BackupFormatException extends FormatException {
  final BackupErrorKind kind;

  BackupFormatException(super.message, this.kind);
}

/// Contadores por tipo de dato, para el envelope y para el resumen de
/// importación (agregados / omitidos).
class BackupCounts {
  final int cultivos;
  final int siembras;
  final int cosechas;
  final int empleados;
  final int movimientos;

  const BackupCounts({
    this.cultivos = 0,
    this.siembras = 0,
    this.cosechas = 0,
    this.empleados = 0,
    this.movimientos = 0,
  });

  static const BackupCounts cero = BackupCounts();

  int get total => cultivos + siembras + cosechas + empleados + movimientos;

  BackupCounts operator +(BackupCounts other) => BackupCounts(
        cultivos: cultivos + other.cultivos,
        siembras: siembras + other.siembras,
        cosechas: cosechas + other.cosechas,
        empleados: empleados + other.empleados,
        movimientos: movimientos + other.movimientos,
      );

  Map<String, int> toJson() => {
        'cultivos': cultivos,
        'siembras': siembras,
        'cosechas': cosechas,
        'empleados': empleados,
        'movimientos': movimientos,
      };

  @override
  bool operator ==(Object other) =>
      other is BackupCounts &&
      other.cultivos == cultivos &&
      other.siembras == siembras &&
      other.cosechas == cosechas &&
      other.empleados == empleados &&
      other.movimientos == movimientos;

  @override
  int get hashCode => Object.hash(
      cultivos, siembras, cosechas, empleados, movimientos);

  @override
  String toString() =>
      'BackupCounts($cultivos cultivos, $siembras siembras, '
      '$cosechas cosechas, $empleados empleados, '
      '$movimientos movimientos)';
}

/// Un respaldo leído y validado por completo. O llega entero o no llega.
class BackupPayload {
  /// Cuenta que exportó el archivo (vacío si se exportó sin sesión).
  final String cuenta;

  final DateTime? exportadoEn;

  final BackupCounts conteo;
  final List<Crop> crops;
  final List<Sowing> sowings;
  final List<Harvest> harvests;
  final List<Employee> employees;
  final List<Transaction> transactions;
  final FarmSettings settings;

  const BackupPayload({
    required this.cuenta,
    required this.exportadoEn,
    required this.conteo,
    required this.crops,
    required this.sowings,
    required this.harvests,
    required this.employees,
    required this.transactions,
    required this.settings,
  });
}

/// Resultado de una importación: qué entró, qué ya estaba y qué quedó sin
/// enlazar (para avisar, nunca para descartar datos del productor).
class BackupSummary {
  /// Registros nuevos añadidos (quedan con `pendingSync: true`).
  final BackupCounts agregados;

  /// Registros que ya existían con el mismo id: se conservan tal cual.
  final BackupCounts omitidos;

  /// Referencias (`cropId`/`sowingId`/`harvestId`) que no apuntan a nada ni
  /// local ni en el archivo. Se importan igual, sin enlazar.
  final int huerfanos;

  /// El archivo viene de otra cuenta (solo aviso; la fusión igual procede).
  final bool cuentaDistinta;

  /// Se aplicaron los ajustes del archivo.
  final bool ajustesImportados;

  const BackupSummary({
    required this.agregados,
    required this.omitidos,
    required this.huerfanos,
    required this.cuentaDistinta,
    required this.ajustesImportados,
  });
}

/// Serializa los datos del usuario como el JSON de respaldo.
///
/// Solo entran datos del productor (`settings`, cultivos, siembras, cosechas,
/// trabajadores y movimientos): la cola de sincronización (`deleted_crops_v1`,
/// `settings_dirty_v1`, `synced_at_v1`) **no** se exporta, porque no son datos
/// suyos sino estado interno de la app.
String encodeBackup({
  required List<Crop> crops,
  required List<Sowing> sowings,
  required List<Harvest> harvests,
  required List<Employee> employees,
  required List<Transaction> transactions,
  required FarmSettings settings,
  String? uid,
  DateTime? now,
}) {
  final ts = now ?? DateTime.now();
  final conteo = BackupCounts(
    cultivos: crops.length,
    siembras: sowings.length,
    cosechas: harvests.length,
    empleados: employees.length,
    movimientos: transactions.length,
  );

  final envelope = <String, dynamic>{
    'formato': kBackupFormat,
    'version': kBackupVersion,
    'exportadoEn': ts.toIso8601String(),
    'cuenta': uid ?? '',
    'conteo': conteo.toJson(),
    'cultivos': [for (final c in crops) c.toJson()],
    'siembras': [for (final s in sowings) s.toJson()],
    'cosechas': [for (final h in harvests) h.toJson()],
    'empleados': [for (final e in employees) e.toJson()],
    'movimientos': [for (final t in transactions) t.toJson()],
    'ajustes': settings.toJson(),
  };
  return const JsonEncoder.withIndent('  ').convert(envelope);
}

/// Lee y valida un respaldo. O devuelve el [BackupPayload] completo o lanza
/// [BackupFormatException] (subclase de [FormatException]) con un mensaje en
/// español: nunca se devuelve un respaldo a medias.
BackupPayload decodeBackup(String raw) {
  dynamic decoded;
  try {
    decoded = jsonDecode(raw);
  } catch (_) {
    throw BackupFormatException(
      'El archivo no se puede leer: no es un respaldo válido.',
      BackupErrorKind.malformado,
    );
  }
  if (decoded is! Map) {
    throw BackupFormatException(
      'El archivo no se puede leer: no es un respaldo válido.',
      BackupErrorKind.malformado,
    );
  }
  final map = decoded.cast<String, dynamic>();

  if (map['formato'] != kBackupFormat) {
    throw BackupFormatException(
      'Ese archivo no es un respaldo de la app.',
      BackupErrorKind.formatoDesconocido,
    );
  }
  final version = map['version'];
  if (version is! int || version != kBackupVersion) {
    throw BackupFormatException(
      'Este respaldo es de otra versión de la app y no se puede restaurar aquí.',
      BackupErrorKind.versionNoSoportada,
    );
  }

  final crops = _parseList(map, 'cultivos', Crop.fromJson);
  final sowings = _parseList(map, 'siembras', Sowing.fromJson);
  final harvests = _parseList(map, 'cosechas', Harvest.fromJson);
  final employees = _parseList(map, 'empleados', Employee.fromJson);
  final transactions = _parseList(map, 'movimientos', Transaction.fromJson);

  final ajustesRaw = map['ajustes'];
  if (ajustesRaw is! Map) {
    throw BackupFormatException(
      'El archivo está incompleto: falta la información de "ajustes".',
      BackupErrorKind.incompleto,
    );
  }
  FarmSettings settings;
  try {
    settings = FarmSettings.fromJson(ajustesRaw.cast<String, dynamic>());
  } catch (_) {
    throw BackupFormatException(
      'El archivo está dañado: los ajustes no se pueden leer.',
      BackupErrorKind.malformado,
    );
  }

  final cuentaRaw = map['cuenta'];
  final exportadoRaw = map['exportadoEn'];

  return BackupPayload(
    cuenta: cuentaRaw is String ? cuentaRaw : '',
    exportadoEn: exportadoRaw is String ? DateTime.tryParse(exportadoRaw) : null,
    // El conteo se recalcula de las listas reales: si el archivo miente en el
    // envelope, la UI muestra lo que de verdad hay dentro.
    conteo: BackupCounts(
      cultivos: crops.length,
      siembras: sowings.length,
      cosechas: harvests.length,
      empleados: employees.length,
      movimientos: transactions.length,
    ),
    crops: crops,
    sowings: sowings,
    harvests: harvests,
    employees: employees,
    transactions: transactions,
    settings: settings,
  );
}

/// Fusiona los ajustes del respaldo sobre los locales **sin borrar nada**.
///
/// Un valor con contenido del archivo manda (nombre de finca distinto, otra
/// moneda…); un valor por defecto o nulo no pisa lo que el productor ya
/// configuró en este dispositivo. Así restaurar solo suma.
FarmSettings mergeBackupSettings(FarmSettings local, FarmSettings backup) {
  const defaults = FarmSettings();
  return FarmSettings(
    farmName: backup.farmName == defaults.farmName
        ? local.farmName
        : backup.farmName,
    currency:
        backup.currency == defaults.currency ? local.currency : backup.currency,
    locale: backup.locale == defaults.locale ? local.locale : backup.locale,
    language:
        backup.language == defaults.language ? local.language : backup.language,
    lastCropId: backup.lastCropId ?? local.lastCropId,
    lowPriceThresholdPerKg:
        backup.lowPriceThresholdPerKg ?? local.lowPriceThresholdPerKg,
    cajaMenorMensual: backup.cajaMenorMensual ?? local.cajaMenorMensual,
    // Misma regla de arriba: un respaldo viejo (sin la clave, así que con el
    // 70 de la norma) **no** puede pisarle el 60 que ya configuró aquí.
    sacoKg: backup.sacoKg == defaults.sacoKg ? local.sacoKg : backup.sacoKg,
  );
}

List<T> _parseList<T>(
  Map<String, dynamic> map,
  String key,
  T Function(Map<String, dynamic>) fromJson,
) {
  final raw = map[key];
  if (raw is! List) {
    throw BackupFormatException(
      'El archivo está incompleto: falta la información de "$key".',
      BackupErrorKind.incompleto,
    );
  }
  final out = <T>[];
  for (final item in raw) {
    if (item is! Map) {
      throw BackupFormatException(
        'El archivo está dañado: los datos de "$key" no se pueden leer.',
        BackupErrorKind.malformado,
      );
    }
    try {
      out.add(fromJson(item.cast<String, dynamic>()));
    } catch (_) {
      throw BackupFormatException(
        'El archivo está dañado: los datos de "$key" no se pueden leer.',
        BackupErrorKind.malformado,
      );
    }
  }
  return out;
}
