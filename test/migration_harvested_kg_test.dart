import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Tanda 2 · contrato estático de la migración `harvested_kg`.
///
/// No sustituye aplicarla en Supabase: solo impide que el archivo se pierda,
/// que deje de ser idempotente o que alguien le meta un backfill o un
/// `not null` que rompería los jornales viejos.
void main() {
  const ruta =
      'supabase/migrations/202610190001_add_transaction_harvested_kg.sql';

  String sql() => File(ruta).readAsStringSync();

  test('el archivo existe y declara la columna harvested_kg', () {
    expect(File(ruta).existsSync(), isTrue, reason: ruta);
    expect(sql(), contains('harvested_kg'));
    expect(sql(), contains('public.transactions'));
  });

  test('es idempotente: usa if not exists', () {
    expect(sql().toLowerCase(),
        contains('add column if not exists harvested_kg'));
  });

  test('no hace backfill ni toca otras columnas', () {
    final contenido = sql().toLowerCase();
    expect(contenido, isNot(contains('update ')),
        reason: 'los jornales viejos quedan en null, no se inventan kilos');
    expect(contenido, isNot(contains('alter column')));
    expect(contenido, isNot(contains('not null')));
  });
}
