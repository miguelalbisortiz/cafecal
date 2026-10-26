-- Una resiembra puede anotar SOLO mortandad: 0 plantas nuevas y `lost_plants`
-- mayor que cero. La app ya lo permite (y lo pide), pero la base lo rechazaba
-- con `23514`: la fila quedaba en `pendingSync` para siempre y la mortandad
-- nunca llegaba a la nube.
--
-- El cliente sigue exigiendo que una siembra inicial plante algo (`plants > 0`
-- en el validador); la base solo tiene que no romper el caso de la resiembra.
alter table public.sowings
  drop constraint if exists sowings_plants_check;

alter table public.sowings
  add constraint sowings_plants_check check (plants >= 0);
