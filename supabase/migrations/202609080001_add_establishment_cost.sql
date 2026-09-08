-- Mi Cafetal: Nivel 3 — amortización del establecimiento
-- Columna aditiva en crops (retrocompatible).
-- El costo del establecimiento es opcional y lo registra el usuario:
-- es la inversión que hizo al sembrar (plantines, mano de obra, insumos).

alter table public.crops
  add column if not exists establishment_cost numeric;