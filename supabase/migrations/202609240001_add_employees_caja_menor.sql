-- Mi Cafetal: capa de nómina — empleados, caja menor y campos de cosecha
-- Retrocompatible: usa add column if not exists / create table if not exists.

-- =============================================
-- employees (lista fija de trabajadores)
-- =============================================
create table if not exists public.employees (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  day_rate numeric,
  created_at timestamptz not null default now()
);

create index if not exists idx_employees_user
  on public.employees (user_id);

alter table public.employees enable row level security;

create policy "employees_select_own" on public.employees
  for select using (auth.uid() = user_id);

create policy "employees_insert_own" on public.employees
  for insert with check (auth.uid() = user_id);

create policy "employees_update_own" on public.employees
  for update using (auth.uid() = user_id);

create policy "employees_delete_own" on public.employees
  for delete using (auth.uid() = user_id);

-- =============================================
-- settings: caja menor mensual (null = desactivado)
-- =============================================
alter table public.settings
  add column if not exists caja_menor_mensual numeric;

-- =============================================
-- harvests: personal en la cosecha + kilos de racimos
-- =============================================
alter table public.harvests
  add column if not exists workers integer,
  add column if not exists equivalent_kg numeric;
