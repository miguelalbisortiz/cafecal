-- (b) · El gasto que sirve a varios cultivos va al lote.
--
-- Por qué en `transactions` y no repartido a mano al anotar:
--   El productor anota "jornal de limpieza, $80.000" y no piensa en
--   porcentajes. A cuántos cultivos sirve ese jornal no lo sabe él, lo sabe la
--   app al mostrar, mirando qué hay en ese terreno. Obligarlo a repartir a
--   mano sería obligarlo a inventar una cifra.
--
-- Por qué un solo campo y no dos:
--   `crop_id` y `terreno_id` son mutuamente excluyentes. Un gasto o es de un
--   cultivo (solo a ese le sirve) o sirve a todo el lote. Los dos a la vez
--   sería contar el mismo peso dos veces en el ROI de la finca.
--
-- Aditiva y opcional, como todo lo de este frente:
--   * `terreno_id = null` en un movimiento = el comportamiento de siempre.
--   * Los datos viejos quedan todos en null y no cambian de significado.
--   * Al borrar un terreno, sus gastos quedan `null`: el dinero ya se gastó y
--     sigue contando en los comunes, solo deja de apuntar al lote. Nadie
--     pierde lo suyo.
--
-- OJO con lo que NO hace este archivo: no reparte nada. El reparto por
-- hectáreas lo calcula la app al mostrar, y solo cuando TODOS los cultivos
-- del lote tienen hectáreas anotadas. Si falta alguna, el gasto sale como
-- línea aparte "sin repartir" — repartir igual dejaría a los demás en 0 ha,
-- que es una cifra que nadie midió.
--
-- Las políticas de RLS no cambian: siguen atadas a `user_id`, y una fila con
-- `terreno_id` nulo se comporta exactamente que antes.

alter table public.transactions
  add column if not exists terreno_id uuid
  references public.terrenos(id) on delete set null;

create index if not exists idx_transactions_terreno_id
  on public.transactions (user_id, terreno_id)
  where terreno_id is not null;
