-- Ubicación del lote (GPS) en terrenos.
--
-- Por qué va en terrenos y no en crops:
--   Lo que se geolocaliza es el **pedazo de tierra**, no cada cultivo que
--   hay dentro. Un lote con café y plátano es un punto; poner un GPS en el
--   cultivo daría dos coordenadas idénticas para el mismo suelo.
--
-- Por qué nullable y por qué los tres juntos:
--   `lat`, `lng` y `located_at` son todos `null` en cualquier terreno que
--   nunca se haya ubicado — que es la mayoría, y debe seguir siendo la
--   mayoría. Un `null` en la app se oculta; un `0` obligaría a dibujar un
--   punto en el ecuador y el meridiano de Greenwich, que es inventar datos.
--   La app solo los escribe cuando el productor aprieta "Tomar mi
--   ubicación" o los teclea a mano.
--
-- Sobre `located_at`:
--   No es la hora del satélite: es el día en que **él** registró el punto.
--   Sirve para poder decirle "esto se midió el 16 de octubre" y que no
--   crea que la coordenada es su posición de ahora. La app jamás la
--   re-mide sola: mover la tierra en silencio sería inventar datos.
--
-- Precisión:
--   `numeric` sin escala guarda los 6 decimales que pide la EUDR
--   (0.11 m) sin redondearlos a la basura.
--
-- Aditiva y opcional, como todo lo de este frente: una tabla ya poblada
-- queda intacta; las filas viejas llegan con los tres en `null` y la app
-- no pinta nada por ellos.

alter table public.terrenos
  add column if not exists lat numeric,
  add column if not exists lng numeric,
  add column if not exists located_at timestamptz;

comment on column public.terrenos.lat is
  'Latitud del lote en grados decimales (-90 a 90). null = sin ubicar; '
  'la app oculta el dato y nunca lo rellena con 0.';

comment on column public.terrenos.lng is
  'Longitud del lote en grados decimales (-180 a 180). Debe ir siempre '
  'junto a `lat`: una sola coordenada no dice dónde está nada.';

comment on column public.terrenos.located_at is
  'Día en que el productor registró el punto (no la hora del satélite). '
  'null = nunca se ubicó, o se borró la ubicación.';
