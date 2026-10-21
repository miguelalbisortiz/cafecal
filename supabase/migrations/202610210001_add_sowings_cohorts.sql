-- Mi Cafetal · Etapa A · cohortes dentro de un cultivo.
-- Aditiva y retrocompatible. No toca harvests ni transactions.
-- Sin backfill: las columnas entran en null y la app normaliza al abrir.

alter table public.sowings
  add column if not exists replaces_plants integer
    check (replaces_plants is null or replaces_plants >= 0),
  add column if not exists replaces_area_ha numeric
    check (replaces_area_ha is null or replaces_area_ha >= 0),
  add column if not exists cohort_sowing_id uuid
    references public.sowings(id) on delete set null;

create index if not exists idx_sowings_cohort
  on public.sowings (cohort_sowing_id);
