create table public.users (
  id uuid primary key default gen_random_uuid(),
  display_name text not null check (char_length(trim(display_name)) between 1 and 50),
  created_at timestamptz not null default now()
);

create table public.availability (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  date date not null,
  start_time time not null,
  end_time time not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint valid_time_range check (start_time < end_time),
  constraint half_hour_start check (
    extract(minute from start_time) in (0, 30)
  ),
  constraint half_hour_end check (
    extract(minute from end_time) in (0, 30)
  ),
  constraint reasonable_hours check (
    start_time >= time '00:00'
    and end_time <= time '23:59'
  )
);

create index availability_date_idx
on public.availability(date);

create index availability_user_date_idx
on public.availability(user_id, date);

create or replace function public.update_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger availability_updated_at
before update on public.availability
for each row
execute function public.update_updated_at();

alter table public.users enable row level security;
alter table public.availability enable row level security;

create policy "public read users"
on public.users
for select
to anon, authenticated
using (true);

create policy "public insert users"
on public.users
for insert
to anon, authenticated
with check (true);

create policy "public delete users"
on public.users
for delete
to anon, authenticated
using (true);

create policy "public read availability"
on public.availability
for select
to anon, authenticated
using (true);

create policy "public insert availability"
on public.availability
for insert
to anon, authenticated
with check (true);

create policy "public update availability"
on public.availability
for update
to anon, authenticated
using (true)
with check (true);

create policy "public delete availability"
on public.availability
for delete
to anon, authenticated
using (true);

alter publication supabase_realtime
add table public.users;

alter publication supabase_realtime
add table public.availability;
