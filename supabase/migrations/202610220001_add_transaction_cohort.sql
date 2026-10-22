-- =============================================
-- Etapa B · kilos de un jornal atribuidos a un lote (cohorte de siembra).
--
--   transactions.cohort_sowing_id  lote al que se atribuyen los kilos
--                                  anotados en un jornal de «Cosechar».
--                                  null = sin lote (dato viejo o no elegido).
--
-- Solo tiene sentido junto a `harvested_kg` (Tanda 2): es una MEDIDA, no un
-- reparto de la venta. La venta sigue siendo del cultivo entero.
--
-- ORDEN IMPORTANTE: aplicar ANTES de desplegar la app que envia esta
-- columna. `buildTransactionPayload` la manda siempre; si no existe,
-- PostgREST responde PGRST204 y se cae el subido COMPLETO (el mismo caso que
-- `harvested_kg` 202610190001, `equiv_kg` 202610200001 y `task` 202610110002).
--
-- Aditiva, nullable, sin backfill. La FK apunta a una siembra (destino ya
-- subido: los `sowings` se empujan antes que las `transactions`).
--
-- Idempotente: se puede re-ejecutar sin efecto.
-- =============================================

alter table public.transactions
  add column if not exists cohort_sowing_id uuid
    references public.sowings(id) on delete set null;

create index if not exists idx_transactions_cohort
  on public.transactions (cohort_sowing_id);

comment on column public.transactions.cohort_sowing_id is
  'Lote (siembra) al que se atribuyen los kilos de un jornal de Cosechar. Null = sin lote. No reparte la venta.';
