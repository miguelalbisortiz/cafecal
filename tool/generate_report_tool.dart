// Herramienta local: genera los PDF de reporte (septiembre 2026 y anual 2026)
// con los datos reales de Supabase, usando el mismo motor del sistema
// (PdfExportService). Se ejecuta con:
//   flutter test tool/generate_report_tool.dart
//
// Requiere un archivo `report_creds.env` (gitignored) en la raíz con:
//   EMAIL=tu_correo
//   PASSWORD=tu_password
// El archivo se borra después de generar (ver final del main).

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/models/crop.dart';
import 'package:mi_cafetal/models/settings.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/services/pdf_export_service.dart';

const _reportsDir = 'reportes';
const _credsFile = 'report_creds.env';

Map<String, String> _readKeyValues(String path) {
  if (!File(path).existsSync()) return const {};
  final out = <String, String>{};
  for (final line in File(path).readAsStringSync().split('\n')) {
    final t = line.trim();
    if (t.isEmpty || t.startsWith('#')) continue;
    final i = t.indexOf('=');
    if (i > 0) out[t.substring(0, i).trim()] = t.substring(i + 1).trim();
  }
  return out;
}

Map<String, String> _readCreds() => _readKeyValues(_credsFile);

Future<http.Response> _request(
  String url,
  String apikey,
  String method,
  String path, {
  String? token,
  Object? body,
}) async {
  final uri = Uri.parse('$url$path');
  final headers = {
    'apikey': apikey,
    'Authorization': 'Bearer ${token ?? apikey}',
    'Content-Type': 'application/json; charset=UTF-8',
  };
  final req = http.Request(method, uri)..headers.addAll(headers);
  if (body != null) req.body = jsonEncode(body);
  final streamed = await req.send();
  final res = await http.Response.fromStream(streamed);
  if (res.statusCode >= 300) {
    throw Exception('$method $path -> HTTP ${res.statusCode}: ${res.body}');
  }
  return res;
}

void main() {
  test('genera PDF septiembre + anual con datos reales', () async {
    // Red real primero: inicializar el binding de test bloquea los HttpClient.
    final creds = _readCreds();
    final env = _readKeyValues('.env');
    const urlDef = String.fromEnvironment('SUPABASE_URL');
    const keyDef = String.fromEnvironment('SUPABASE_ANON_KEY');
    final url = urlDef.isNotEmpty ? urlDef : (env['SUPABASE_URL'] ?? '');
    final key = keyDef.isNotEmpty ? keyDef : (env['SUPABASE_ANON_KEY'] ?? '');
    if (url.isEmpty ||
        key.isEmpty ||
        !creds.containsKey('EMAIL') ||
        !creds.containsKey('PASSWORD')) {
      throw Exception(
          'Faltan credenciales. Revisa $_credsFile y que el comando incluya '
          '--dart-define=SUPABASE_URL y SUPABASE_ANON_KEY.');
    }

    final signIn = jsonDecode((await _request(
      url,
      key,
      'POST',
      '/auth/v1/token?grant_type=password',
      body: {'email': creds['EMAIL'], 'password': creds['PASSWORD']},
    ))
            .body)
        as Map<String, dynamic>;
    final token = signIn['access_token'] as String;
    final user = (signIn['user'] as Map<String, dynamic>)['id'] as String;

    final txJson = jsonDecode(
            (await _request(url, key, 'GET', '/rest/v1/transactions?select=*',
                    token: token))
                .body)
        as List;
    final cropsJson = jsonDecode(
            (await _request(url, key, 'GET', '/rest/v1/crops?select=*',
                    token: token))
                .body)
        as List;
    final settingsJson = jsonDecode(
            (await _request(url, key, 'GET', '/rest/v1/settings?select=*',
                    token: token))
                .body)
        as List;

    final transactions = txJson
        .map((e) {
          final r = e as Map<String, dynamic>;
          return Transaction.fromJson({
            'id': r['id'],
            'crop_id': r['crop_id'],
            'type': r['type'],
            'category': r['category'],
            'amount': (r['amount'] as num).toDouble(),
            'currency': r['currency'] ?? 'COP',
            'description': r['description'] ?? '',
            'date': r['txn_date'],
            'created_at': r['created_at'],
            'pending_sync': false,
            'deleted': false,
          });
        })
        .toList();
    final crops = cropsJson
        .map((e) => Crop.fromJson((e as Map<String, dynamic>)))
        .toList();
    final row = settingsJson.isEmpty
        ? null
        : (settingsJson.first as Map<String, dynamic>);
    final settings = FarmSettings(
      farmName: (row?['farm_name'] as String?) ?? 'Mi Cafetal',
      currency: (row?['currency'] as String?) ?? 'COP',
      locale: (row?['locale'] as String?) ?? 'es_CO',
    );

    final l10n = stringsFor('es');
    // Las fuentes Roboto viven en assets: necesita el binding de Flutter.
    TestWidgetsFlutterBinding.ensureInitialized();
    final svc = PdfExportService();
    Directory(_reportsDir).createSync(recursive: true);

    final n = transactions.length;
    final sales2026 = transactions
        .where((t) =>
            !t.deleted &&
            t.date.year == 2026 &&
            t.type == TransactionType.income)
        .fold<double>(0, (a, t) => a + t.amount);
    stderr.writeln(
        '[tool] usuario ${user.substring(0, 8)}… · $n transacciones · '
        '${crops.length} cultivos · finca "${settings.farmName}" · '
        '${settings.currency} · ventas 2026 \$${sales2026.toStringAsFixed(0)}');

    // PDF mensual (septiembre 2026): incluye el anexo anual automático.
    final sept = await svc.buildReport(
      settings: settings,
      transactions: transactions,
      crops: crops,
      year: 2026,
      month: 9,
      period: ReportPeriod.month,
      periodName: l10n.reportPeriodMonth(l10n.monthFull[8], 2026),
      l10n: l10n,
    );
    File('$_reportsDir/2026-septiembre.pdf')
        .writeAsBytesSync(sept, flush: true);

    // PDF anual: todo 2026.
    final annual = await svc.buildReport(
      settings: settings,
      transactions: transactions,
      crops: crops,
      year: 2026,
      period: ReportPeriod.year,
      periodName: l10n.yearLabel(2026),
      l10n: l10n,
    );
    File('$_reportsDir/2026-anual.pdf').writeAsBytesSync(annual, flush: true);

    stderr.writeln('[tool] OK: PDFs en "$_reportsDir/"');
  }, timeout: const Timeout(Duration(minutes: 3)));
}