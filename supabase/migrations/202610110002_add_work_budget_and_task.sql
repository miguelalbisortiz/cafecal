-- =============================================
-- E3 · La obra del día.
--
-- Dos piezas que faltaban para que "mano de obra" fuera un tema aparte y no
-- un renglón más de la caja:
--
--   settings.presupuesto_obra_mensual   cuánto se pensaba gastar en gente
--                                       este mes. null = no configurado, y
--                                       ahí la caja menor se comporta EXACTA
--                                       igual que siempre (sigue contando
--                                       jornales + extras). Es opt-in: nadie
--                                       hereda un cambio de comportamiento.
--
--   transactions.task                   qué labor se hizo ("Descolgar",
--                                       "Abonar"…). Sin esto la planilla no
--                                       puede agrupar: texto libre daría
--                                       "Descolgar café", "descolgar" y
--                                       "Descolgar el café" como tres
--                                       renglones distintos.
--
-- ⚠️ ORDEN IMPORTANTE: aplicar ANTES de desplegar la app que envía estas
-- columnas. `buildSettingsPayload` y `buildTransactionPayload` mandan las
-- columnas a mano, así que si no existen Postgrest responde PGRST204 y se
-- cae el subido COMPLETO — el mismo caso que `currency` (202609250001),
-- `saco_kg` (202610100002) y las deducciones de E1 (202610110001).
--
-- Idempotente: se puede re-ejecutar sin efecto.
-- =============================================

alter table public.settings
  add column if not exists presupuesto_obra_mensual numeric;

alter table public.transactions
  add column if not exists task text;
