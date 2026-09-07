-- Mi Cafetal: capa productiva Nivel 2
-- Columnas aditivas en crops/transactions + tablas sowings/harvests + RLS.
-- Retrocompatible: usa add column if not exists / create table if not exists.

-- =============================================
-- crops: fase de vida, ciclo y estado del cultivo
-- =============================================
alter table public.crops
  add column if not exists phase text not null default 'produccion'
    check (phase in ('establecimiento','produccion','renovacion')),
  add column if not exists cycle text not null default 'perenne'
    check (cycle in ('perenne','anual')),
  add column if not exists default_unit text,
  add column if not exists area_ha numeric,
  add column if not exists live_plants integer;

-- =============================================
-- sowings
-- =============================================
create table if not exists public.sowings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  crop_id uuid null references public.crops(id) on delete set null,
  kind text not null default 'siembra'
    check (kind in ('siembra','resiembra')),
  plants integer not null check (plants > 0),
  area_ha numeric,
  lost_plants integer,
  reason text,
  sowing_date date not null,
  created_at timestamptz not null default now()
);

create index if not exists idx_sowings_user_date
  on public.sowings (user_id, sowing_date desc);

alter table public.sowings enable row level security;

create policy "sowings_select_own" on public.sowings
  for select using (auth.uid() = user_id);

create policy "sowings_insert_own" on public.sowings
  for insert with check (auth.uid() = user_id);

create policy "sowings_update_own" on public.sowings
  for update using (auth.uid() = user_id);

create policy "sowings_delete_own" on public.sowings
  for delete using (auth.uid() = user_id);

-- =============================================
-- harvests
-- =============================================
create table if not exists public.harvests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  crop_id uuid null references public.crops(id) on delete set null,
  amount numeric not null check (amount > 0),
  unit text not null default 'kg',
  destination text not null default 'vendido'
    check (destination in ('vendido','almacenado','perdida')),
  harvest_date date not null,
  created_at timestamptz not null default now()
);

create index if not exists idx_harvests_user_date
  on public.harvests (user_id, harvest_date desc);

alter table public.harvests enable row level security;

create policy "harvests_select_own" on public.harvests
  for select using (auth.uid() = user_id);

create policy "harvests_insert_own" on public.harvests
  for insert with check (auth.uid() = user_id);

create policy "harvests_update_own" on public.harvests
  for update using (auth.uid() = user_id);

create policy "harvests_delete_own" on public.harvests
  for delete using (auth.uid() = user_id);

-- =============================================
-- transactions: vínculo con cosechas / siembras
-- (después de crear sowings/harvests: las FK
-- requieren que la tabla referenciada exista)
-- =============================================
alter table public.transactions
  add column if not exists harvest_id uuid references public.harvests(id) on delete set null,
  add column if not exists sowing_id uuid references public.sowings(id) on delete set null;
