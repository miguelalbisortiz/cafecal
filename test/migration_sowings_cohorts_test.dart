import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Etapa A · contrato estático de la migración `add_sowings_cohorts`.
///
/// No sustituye aplicarla en Supabase: solo impide que el archivo se pierda,
/// que deje de ser idempotente, que toque `harvests`/`transactions` o que meta
/// un `not null`/backfill que rompería los datos viejos.
void main() {
  const ruta = 'supabase/migrations/202610210001_add_sowings_cohorts.sql';

  String sql() => File(ruta).readAsStringSync();

  test('el archivo existe y declara las tres columnas', () {
    expect(File(ruta).existsSync(), isTrue, reason: ruta);
    final s = sql();
    expect(s, contains('replaces_plants'));
    expect(s, contains('replaces_area_ha'));
    expect(s, contains('cohort_sowing_id'));
    expect(s, contains('public.sowings'));
  });

  test('es idempotente: todo con if not exists', () {
    final s = sql().toLowerCase();
    expect(s, contains('add column if not exists replaces_plants'));
    expect(s, contains('add column if not exists replaces_area_ha'));
    expect(s, contains('add column if not exists cohort_sowing_id'));
    expect(s, contains('create index if not exists idx_sowings_cohort'));
  });

  test('la FK es auto-referente y no arrastra la otra siembra', () {
    final s = sql().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    expect(s, contains('references public.sowings(id) on delete set null'));
  });

  test('no hace backfill ni toca cosechas ni movimientos', () {
    final s = sql().toLowerCase();
    expect(s, isNot(contains('update ')), reason: 'sin backfill');
    expect(s, isNot(contains('public.harvests')));
    expect(s, isNot(contains('public.transactions')));
    expect(s, isNot(contains('drop ')));
  });

  test('las columnas nuevas son nullables y no aceptan negativos', () {
    final s = sql().toLowerCase();
    expect(s, isNot(contains('not null')));
    expect(s, contains('replaces_plants is null or replaces_plants >= 0'));
    expect(s, contains('replaces_area_ha is null or replaces_area_ha >= 0'));
  });
}
