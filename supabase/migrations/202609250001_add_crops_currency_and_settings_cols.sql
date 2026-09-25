-- =============================================
-- Columnas que el modelo Dart ya usaba pero nunca se crearon en la BD.
--
-- Detectado el 2026-09-25 al diagnosticar por qué ninguna cuenta subía
-- datos: el push de `crops` enviaba `currency` y Postgrest respondía
-- PGRST204 "Could not find the 'currency' column of 'crops'", abortando
-- el sync completo. Mismo caso para las 3 columnas de `settings`.
--
-- Todas son aditivas e idempotentes: se pueden re-ejecutar sin efecto.
-- =============================================

-- Cultivo con moneda propia (feature "moneda por cultivo", commit 0141006).
alter table public.crops
  add column if not exists currency text;

-- Preferencias de settings que el modelo FarmSettings ya persiste en local.
-- `last_crop_id` va como text a propósito: los datos legados guardan ids
-- fijos ('cafe') que no son uuid, y una FK ahí rompería el push otra vez.
alter table public.settings
  add column if not exists language text;

alter table public.settings
  add column if not exists last_crop_id text;

alter table public.settings
  add column if not exists low_price_threshold_per_kg numeric;
