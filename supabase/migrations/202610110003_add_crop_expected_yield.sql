-- E4 · El rendimiento (W2) — "kg/ha que quiero" de este lote.
--
-- Por qué es un campo del cultivo y no una tabla de especies:
--   La app tiene que servir a cualquier agricultor de cualquier región.
--   Una tabla precargada de Cenicafé obligaría a adivinar de qué especie es
--   un cultivo (¿"Café"? ¿"café"? ¿"Cafe 2"?) por su nombre, y sobre todo
--   le pondría al productor una referencia que no le aplica a su altitud,
--   su lluvia ni su sombra. El número que sí es cierto para todos es el que
--   pone él mismo: es su meta, no una norma ajena.
--
-- Aditiva y opcional. `null` = no tiene meta → la app no pinta nada.
alter table public.crops
  add column if not exists expected_yield_kg_ha numeric;

comment on column public.crops.expected_yield_kg_ha is
  'Rendimiento meta en kg/ha que el productor quiere lograr de este lote. '
  'null = sin meta. Informativa: nunca dispara alertas.';
