-- E5 · La vida del cultivo (W4) — "¿cuándo esperás la primera cosecha?".
--
-- Por qué es una fecha que pone él y no una tabla de especies:
--   El productor ya sabe, cuando planta, cuánto tarda su cultivo ("el café
--   a los 3 años", "el plátano a los 9 meses"): es conocimiento de su variedad,
--   de su suelo y de su región. Lo que no tiene a mano es la cuenta de
--   calendario. Esa cuenta la hace la app.
--
--   Una tabla (Cafe -> 36 meses, Platano -> 9) obligaría a adivinar de qué
--   especie es un cultivo por su nombre ("Cafe", "cafe", "Cafe 2") y le
--   impondria un numero que no aplica a su altitud, su lluvia ni su sombra,
--   con pinta de autoridad. Mismo problema que se descarto en E4.
--
-- Aditiva y opcional. `null` = no la estima -> la app no pinta nada.
-- Informativa: nunca dispara alertas ni cambia la fase por su cuenta
-- (la fase sigue decidiendo la primera cosecha registrada).
alter table public.crops
  add column if not exists primer_cosecha_esperada date;

comment on column public.crops.primer_cosecha_esperada is
  'Fecha aproximada en que el productor espera la primera cosecha de este lote. '
  'Es su dato, no una referencia de especie. null = no la estima. '
  'Informativa: nunca dispara alertas.';
