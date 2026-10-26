-- §6 y §7 de la auditoría (2026-10-25).
--
-- §6 · Faltaban índices en las columnas que el sync usa para borrar y filtrar:
--   - crops.user_id no tenía ninguno (es la columna de RLS: cada pull hacía
--     scan completo).
--   - Las FK crop_id/harvest_id/sowing_id se recorrían enteras en cada
--     `on delete set null` y en cada borrado por cultivo.
--
-- §7 · `crop_id` y `terreno_id` son excluyentes (un gasto en los dos contaría
-- el mismo peso en el ROI del cultivo y del terreno), pero solo estaba escrito
-- en un comentario. El formulario lo respeta; el respaldo y un bug futuro no.

create index if not exists idx_crops_user on public.crops (user_id);
create index if not exists idx_crops_terreno on public.crops (terreno_id);
create index if not exists idx_sowings_crop on public.sowings (crop_id);
create index if not exists idx_harvests_crop on public.harvests (crop_id);
create index if not exists idx_transactions_crop on public.transactions (crop_id);
create index if not exists idx_transactions_harvest on public.transactions (harvest_id);
create index if not exists idx_transactions_sowing on public.transactions (sowing_id);

alter table public.transactions
  drop constraint if exists transactions_crop_xor_terreno;

alter table public.transactions
  add constraint transactions_crop_xor_terreno
  check (crop_id is null or terreno_id is null);
