-- W1-a · El terreno — la noción de espacio compartido.
--
-- Por qué una tabla y no un texto dentro del cultivo:
--   El terreno es la unidad con la que el productor piensa ("el lote de
--   arriba", "el potrero"): tiene nombre y, si él lo sabe, hectáreas. Y se
--   puede repetir — hay fincas con varios — algo que un campo de texto libre
--   resuelve mal: "Lote de arriba" y "lote arriba" serían dos terrenos
--   distintos para la app, y el reporte los separaría sin que nadie lo
--   hubiera pedido.
--
-- Aditiva y opcional, como todo lo de este frente:
--   * `terreno_id = null` en un cultivo = no está en ningún terreno y se
--     comporta exactamente como antes.
--   * Si el productor nunca crea un terreno, la app es la misma de siempre.
--   * Al borrar un terreno, sus cultivos quedan `null`: no se borra nada
--     con él. Nadie pierde lo suyo.
--
-- OJO con lo que este archivo NO hace: no reparte nada. Un gasto del
-- terreno se muestra aparte de cada cultivo; repartirlo proporcional a las
-- hectáreas sería inventar una cifra que nadie midió.

create table if not exists public.terrenos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  area_ha numeric,
  created_at timestamptz not null default now()
);

create index if not exists idx_terrenos_user
  on public.terrenos (user_id);

alter table public.terrenos enable row level security;

create policy "terrenos_select_own" on public.terrenos
  for select using (auth.uid() = user_id);

create policy "terrenos_insert_own" on public.terrenos
  for insert with check (auth.uid() = user_id);

create policy "terrenos_update_own" on public.terrenos
  for update using (auth.uid() = user_id);

create policy "terrenos_delete_own" on public.terrenos
  for delete using (auth.uid() = user_id);

-- =============================================
-- crops · a qué terreno pertenece (opcional)
-- =============================================
alter table public.crops
  add column if not exists terreno_id uuid
    references public.terrenos(id) on delete set null;

comment on column public.crops.terreno_id is
  'Terreno donde está plantado este cultivo. null = sin terreno asignado, '
  'se comporta igual que antes de existir la tabla.';

-- =============================================
-- transactions · gasto del terreno entero (RESERVADA)
-- =============================================
-- Va aquí y no en su propia migración para no pedirle dos corridas a
-- Supabase por un par de columnas.
--
-- Estado: RESERVADA. El día 2026-10-12 se decidió NO construir W1-b
-- (destino de tres vías Costos comunes / Terreno / Cultivo) por ahora,
-- así que hoy esta columna no la escribe ni la lee nadie. Se deja puesta
-- porque es aditiva, nullable y ya aplicada: si W1-b se retoma, no habrá
-- que pedirle otra corrida a Supabase. Mientras, está vacía en todas las
-- filas y no afecta a nada.
alter table public.transactions
  add column if not exists terreno_id uuid
    references public.terrenos(id) on delete set null;

comment on column public.transactions.terreno_id is
  'RESERVADA (W1-b no construida). Gasto de todo el terreno (cerca, camino, '
  'limpieza). Si algún día se usa: ambos nulos al mismo tiempo = costo común '
  'de la finca, como siempre, y nunca se reparte automáticamente entre los '
  'cultivos del terreno.';
