-- =============================================
-- C1 · fecha en que empezó el cultivo (opcional).
--
-- Columna aditiva en crops, retrocompatible: los cultivos viejos quedan en
-- null y la app no pide la fecha si ya hay siembras (manda la de la última
-- siembra/resiembra).
--
-- ⚠️ ORDEN IMPORTANTE: aplicar ANTES de desplegar la app que envía
-- `planted_at`. Si la columna no existe, Postgrest responde PGRST204 "Could
-- not find the 'planted_at' column of 'crops'" y se cae la subida COMPLETA —
-- exactamente lo que pasó con `currency` (ver
-- 202609250001_add_crops_currency_and_settings_cols.sql).
--
-- Todas las operaciones son idempotentes: se pueden re-ejecutar sin efecto.
-- =============================================

alter table public.crops
  add column if not exists planted_at date;
