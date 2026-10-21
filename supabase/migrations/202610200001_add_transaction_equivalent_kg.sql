-- =============================================
-- Tanda 4 · el peso de una venta en racimo o cajón.
--
--   transactions.equivalent_kg   kilos totales que pesó la venta cuando la
--                                unidad no tiene factor fijo (racimo, cajón).
--                                null = no se anotó.
--
-- Antes, `unitToKg('racimo')` devolvía 1: doce racimos contaban como 12 kg y
-- el precio por kilo, kg/ha y las exportaciones salían de una cifra inventada.
-- Ahora la venta guarda el peso real y quien no lo tenga no entra a los
-- totales (se lista como «sin peso» para completarlo).
--
-- ⚠️ ORDEN IMPORTANTE: aplicar ANTES de desplegar la app que envía esta
-- columna. `buildTransactionPayload` la manda a mano, así que si no existe
-- PostgREST responde PGRST204 y se cae el subido COMPLETO — el mismo caso que
-- `currency` (202609250001), `task` (202610110002), `terreno_id`
-- (202610160002) y `harvested_kg` (202610190001).
--
-- Aditiva y nullable: las ventas viejas quedan en null y se comportan como
-- antes. Sin backfill: no hay forma de saber cuánto pesaron esos racimos.
--
-- Idempotente: se puede re-ejecutar sin efecto.
-- =============================================

alter table public.transactions
  add column if not exists equivalent_kg numeric;

comment on column public.transactions.equivalent_kg is
  'Kilos totales de una venta en racimo o cajón. Null = sin peso anotado (no entra a los totales).';
