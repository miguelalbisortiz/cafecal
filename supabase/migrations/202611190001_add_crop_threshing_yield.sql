-- =============================================
-- Fase 3 · rendimiento de trilla por cultivo.
--
--   threshing_yield   kg de cereza que hacen 1 kg de pergamino
--                     (5 = de 5 kg de cereza sale 1 kg vendible)
--                     null = no se calcula el rendimiento
--
-- Va en `crops` y no en cada cosecha porque el productor lo conoce por
-- cultivo, no por lote; promediar lotes sin decirlo sería inventar.
--
-- ⚠️ ORDEN IMPORTANTE: aplicar ANTES de desplegar la app que envía esta
-- columna. `buildCropPayload` manda las columnas a mano, así que si no
-- existe Postgrest responde PGRST204 y se cae el subido COMPLETO — el mismo
-- caso que `currency`, `saco_kg` y `product_state`.
--
-- Idempotente: se puede re-ejecutar sin efecto.
-- =============================================

alter table public.crops
  add column if not exists threshing_yield numeric;
