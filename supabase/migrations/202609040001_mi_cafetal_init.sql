-- Mi Cafetal: esquema inicial
-- Tablas: crops, transactions, settings
-- RLS: cada usuario solo ve sus filas.

-- =============================================
-- crops
-- =============================================
create table if not exists public.crops (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  icon text not null default '🌱',
  color text not null default '#2E7D32',
  created_at timestamptz not null default now()
);

alter table public.crops enable row level security;

create policy "crops_select_own" on public.crops
  for select using (auth.uid() = user_id);

create policy "crops_insert_own" on public.crops
  for insert with check (auth.uid() = user_id);

create policy "crops_update_own" on public.crops
  for update using (auth.uid() = user_id);

create policy "crops_delete_own" on public.crops
  for delete using (auth.uid() = user_id);

-- =============================================
-- transactions
-- =============================================
create table if not exists public.transactions (
  id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  crop_id uuid null references public.crops(id) on delete set null,
  type text not null check (type in ('expense', 'income')),
  category text not null,
  amount numeric not null check (amount >= 0),
  currency text not null default 'COP',
  description text not null default '',
  txn_date date not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_transactions_user_date
  on public.transactions (user_id, txn_date desc);

create index if not exists idx_transactions_user_category
  on public.transactions (user_id, category);

alter table public.transactions enable row level security;

create policy "transactions_select_own" on public.transactions
  for select using (auth.uid() = user_id);

create policy "transactions_insert_own" on public.transactions
  for insert with check (auth.uid() = user_id);

create policy "transactions_update_own" on public.transactions
  for update using (auth.uid() = user_id);

create policy "transactions_delete_own" on public.transactions
  for delete using (auth.uid() = user_id);

-- =============================================
-- settings
-- =============================================
create table if not exists public.settings (
  user_id uuid primary key references auth.users(id) on delete cascade,
  farm_name text not null default 'Mi Cafetal',
  currency text not null default 'COP',
  locale text not null default 'es_CO',
  updated_at timestamptz not null default now()
);

alter table public.settings enable row level security;

create policy "settings_select_own" on public.settings
  for select using (auth.uid() = user_id);

create policy "settings_insert_own" on public.settings
  for insert with check (auth.uid() = user_id);

create policy "settings_update_own" on public.settings
  for update using (auth.uid() = user_id);

-- =============================================
-- perfil + defaults al registrarse
-- =============================================
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.settings (user_id, farm_name)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name', 'Mi Cafetal'))
  on conflict (user_id) do nothing;

  insert into public.crops (user_id, name, icon, color)
  values
    (new.id, 'Café', '☕', '#6D4C41'),
    (new.id, 'Plátano', '🍌', '#F9A825')
  on conflict do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();