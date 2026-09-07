// Herramienta local: verifica la escritura autenticada (end-to-end) contra
// Supabase con un usuario real. Hace el round-trip:
//   sign-in (password grant) → INSERT crop → SELECT crop → DELETE crop.
// Se ejecuta con:
//   flutter test tool/verify_auth_write_tool.dart \
//     --dart-define=SUPABASE_URL=https://ioyqlzhzlvkkebvenqnz.supabase.co \
//     --dart-define=SUPABASE_ANON_KEY=...
//
// Requiere un archivo `report_creds.env` (gitignored) en la raíz:
//   EMAIL=tu_correo
//   PASSWORD=tu_password
// No escribe ningún archivo: solo comprueba que un usuario autenticado puede
// insertar, leer y borrar (RLS).

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

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
    'Prefer': 'return=representation',
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
  test('round-trip de escritura autenticada (insert → select → delete)', () async {
    final creds = _readKeyValues(_credsFile);
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
    final userId = (signIn['user'] as Map<String, dynamic>)['id'] as String;
    stderr.writeln('[tool] sesión iniciada con ${creds['EMAIL']} (${userId.substring(0, 8)}…)');

    // INSERT autenticado (RLS exige user_id = auth.uid(); el id lo genera la BD).
    final probeName =
        'Verificación de escritura ${DateTime.now().millisecondsSinceEpoch}';
    final insert = await _request(url, key, 'POST', '/rest/v1/crops?select=*',
        token: token,
        body: {
          'name': probeName,
          'icon': '🔎',
          'color': '#2E7D32',
          'phase': 'produccion',
          'cycle': 'perenne',
          'user_id': userId,
        });
    final created = (jsonDecode(insert.body) as List).first as Map<String, dynamic>;
    final probeId = created['id'] as String;
    if (probeId.isEmpty) {
      throw Exception('INSERT no devolvió id generado: ${insert.body}');
    }
    stderr.writeln('[tool] INSERT OK: crop "$probeId"');

    // SELECT autenticado del registro recién creado.
    final sel = await _request(
        url, key, 'GET', '/rest/v1/crops?select=id,name&id=eq.$probeId',
        token: token);
    final rows = jsonDecode(sel.body) as List;
    if (rows.isEmpty || (rows.first as Map)['id'] != probeId) {
      throw Exception('SELECT no encontró el registro: ${sel.body}');
    }
    stderr.writeln('[tool] SELECT OK: encontró "$probeId"');

    // DELETE autenticado (limpia el registro de la verificación).
    await _request(url, key, 'DELETE', '/rest/v1/crops?id=eq.$probeId',
        token: token);
    final after = await _request(
        url, key, 'GET', '/rest/v1/crops?select=id&id=eq.$probeId',
        token: token);
    final remaining = jsonDecode(after.body) as List;
    if (remaining.isNotEmpty) {
      throw Exception('DELETE no eliminó el registro');
    }
    stderr.writeln('[tool] DELETE OK: registro de prueba eliminado');

    stderr.writeln('[tool] ✓ Escritura autenticada verificada end-to-end');
  }, timeout: const Timeout(Duration(minutes: 2)));
}