import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Etapa B · contrato estático de la migración `add_transaction_cohort`.
///
/// No sustituye aplicarla en Supabase: impide que el archivo se pierda, que
/// deje de ser idempotente, que toque `harvests` o que meta un backfill que
/// reasigne kilos que nadie pesó.
void main() {
  const ruta = 'supabase/migrations/202610220001_add_transaction_cohort.sql';

  String sql() => File(ruta).readAsStringSync();

  test('el archivo existe y declara la columna en public.transactions', () {
    expect(File(ruta).existsSync(), isTrue, reason: ruta);
    final s = sql();
    expect(s, contains('public.transactions'));
    expect(s, contains('cohort_sowing_id'));
  });

  test('es idempotente: add column if not exists y create index if not exists',
      () {
    final s = sql().toLowerCase();
    expect(s, contains('add column if not exists cohort_sowing_id'));
    expect(s, contains('create index if not exists idx_transactions_cohort'));
  });

  test('la FK es a public.sowings(id) con on delete set null', () {
    final s = sql().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    expect(s, contains('references public.sowings(id) on delete set null'));
  });

  test('no hace backfill ni toca cosechas, ni borra nada, ni es not null', () {
    final s = sql().toLowerCase();
    expect(s, isNot(contains('update ')), reason: 'sin backfill');
    expect(s, isNot(contains('public.harvests')));
    expect(s, isNot(contains('drop ')));
    expect(s, isNot(contains('not null')));
    expect(s, isNot(contains('default ')));
  });
}
