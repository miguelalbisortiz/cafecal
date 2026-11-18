-- =============================================
-- Fase 1 · estado del café vendido.
--
--   transactions.product_state   'cereza' | 'pergamino' | 'verde' | 'tueste'.
--                                null = no se anotó (plátano, otros cultivos
--                                y todos los movimientos anteriores).
--
-- El mismo grano vale distinto según en qué punto de la cadena se venda, y
-- hasta ahora una venta de cereza y una de tueste se veían iguales: dos filas
-- «Venta Café» con precios incomparables. La columna guarda ese punto para
-- poder comparar precio por kilo por estado.
--
-- ⚠️ ORDEN IMPORTANTE: aplicar ANTES de desplegar la app que envía esta
-- columna. `buildTransactionPayload` la manda a mano, así que si no existe
-- PostgREST responde PGRST204 y se cae el subido COMPLETO — el mismo caso que
-- `currency` (202609250001), `task` (202610110002), `terreno_id`
-- (202610160002), `harvested_kg` (202610190001) y `equivalent_kg`
-- (202610200001).
--
-- Aditiva y nullable: las ventas viejas quedan en null y se comportan como
-- antes. Sin backfill: no hay forma de saber en qué estado se vendieron.
--
-- Idempotente: se puede re-ejecutar sin efecto.
-- =============================================

alter table public.transactions
  add column if not exists product_state text;

comment on column public.transactions.product_state is
  'Estado del café vendido: cereza, pergamino, verde o tueste. Null = sin anotar (no es un estado «otro»).';
