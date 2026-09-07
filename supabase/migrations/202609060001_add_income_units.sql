-- Mi Cafetal: capa productiva Nivel 1
-- Columnas aditivas en transactions (volumen/precio + cliente/proveedor).
-- Retrocompatible: usa add column if not exists; no borra ni altera nada existente.

alter table public.transactions
  add column if not exists quantity numeric,
  add column if not exists unit text,
  add column if not exists price_per_unit numeric,
  add column if not exists client text,
  add column if not exists provider text;
