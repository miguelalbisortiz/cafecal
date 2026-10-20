-- =============================================
-- Tanda 2 · kilos recolectados en el jornal de «Cosechar».
--
--   transactions.harvested_kg   kilos medidos en un jornal de labor
--                               «Cosechar». null = no se midió.
--
-- Es una MEDIDA, no una forma de pago: el jornal se sigue pagando
-- días × valor día. Solo alimenta la cosecha derivada, que la usa como
-- fuente independiente de la venta (prioridad manual > jornal > venta).
--
-- ⚠️ ORDEN IMPORTANTE: aplicar ANTES de desplegar la app que envía esta
-- columna. `buildTransactionPayload` la manda a mano, así que si no existe
-- PostgREST responde PGRST204 y se cae el subido COMPLETO — el mismo caso
-- que `currency` (202609250001), `task` (202610110002) y `terreno_id`
-- (202610160002).
--
-- Aditiva y nullable: los jornales viejos quedan en null y se comportan
-- exactamente como antes. Sin backfill y sin índice: no hay consulta que
-- filtre por ella.
--
-- Idempotente: se puede re-ejecutar sin efecto.
-- =============================================

alter table public.transactions
  add column if not exists harvested_kg numeric;

comment on column public.transactions.harvested_kg is
  'Kilos recolectados anotados en un jornal de labor Cosechar. Null = no medido. No afecta el pago (días × valor día).';
