-- =============================================
-- A2 · peso real del saco de café (kg).
--
-- El estándar del café colombiano es 70 kg, pero en la finca el costal puede
-- pesar 60. El número vive en `settings` (una sola finca, una sola
-- preferencia) y de ahí lo leen reportes, PDF, Excel y alertas.
--
-- ⚠️ ORDEN IMPORTANTE: aplicar ANDES de desplegar la app que envía
-- `saco_kg`. `buildSettingsPayload` manda las columnas a mano, así que si la
-- columna no existe Postgrest responde PGRST204 y se cae el subido COMPLETO
-- de ajustes — el mismo caso que `currency`
-- (202609250001_add_crops_currency_and_settings_cols.sql).
--
-- El `default 70` rellena las filas existentes: nadie lo tenía configurado,
-- así que todos pasan a tener el de la norma y nadie ve un número raro.
-- Idempotente: se puede re-ejecutar sin efecto.
-- =============================================

alter table public.settings
  add column if not exists saco_kg numeric not null default 70;
