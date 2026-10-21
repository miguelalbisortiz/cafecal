-- =============================================
-- Tanda 4 · historial del aporte mensual de caja.
--
--   settings.cash_budget_history   {"2026-10": 1000000, "2026-11": 1200000}
--
-- Antes la app tenía un solo aporte (`caja_menor_mensual`) y lo aplicaba a
-- todos los meses: al cambiarlo hoy, el arrastre de la caja reescribía el
-- pasado y la tarjeta de un mes viejo mostraba un presupuesto que nunca rigió.
-- El historial guarda el monto de cada mes desde que se configura; los meses
-- anteriores no se reconstruyen (no hay dato para hacerlo sin inventar).
--
-- La fila sigue siendo una por usuario (`user_id` es PK) y la RLS ya la
-- cubre: no hay política nueva.
--
-- ⚠️ ORDEN IMPORTANTE: aplicar ANTES de desplegar la app que envía esta
-- columna, igual que `equivalent_kg` (202610200001). Si no existe, PostgREST
-- responde PGRST204 y se cae el guardado de ajustes COMPLETO.
--
-- Aditiva y con default '{}': los usuarios viejos quedan sin historial y la
-- app lo siembra con el aporte actual al abrir. Idempotente.
-- =============================================

alter table public.settings
  add column if not exists cash_budget_history jsonb not null default '{}'::jsonb;

comment on column public.settings.cash_budget_history is
  'Aporte de caja por mes, clave YYYY-MM. Vacío = sin historial; 0 = mes sin aporte explícito.';
