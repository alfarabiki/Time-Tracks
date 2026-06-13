-- Radjak Marketing — Supabase schema + RLS (RBAC: admin / manajer / staf)
-- Run in Supabase SQL editor (Project → SQL). Safe to re-run (idempotent-ish).

-- 1) Role enum
do $$ begin
  create type user_role as enum ('admin','manajer','staf');
exception when duplicate_object then null; end $$;

-- 2) profiles (1 row per auth user)
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  role user_role not null default 'staf',
  branch text not null default 'Salemba',
  created_at timestamptz not null default now()
);
alter table public.profiles enable row level security;

-- 3) visits
create table if not exists public.visits (
  id uuid primary key default gen_random_uuid(),
  staff_id uuid not null references public.profiles(id) on delete cascade,
  tracking_number text not null,
  facility text not null default '',
  visit_type text not null default '',
  address text default '',
  latitude double precision,
  longitude double precision,
  accuracy double precision,
  taken_at timestamptz not null,
  photo_url text,
  image_hash text,
  created_at timestamptz not null default now()
);
alter table public.visits enable row level security;
create index if not exists visits_staff_taken on public.visits(staff_id, taken_at desc);

-- 4) SECURITY DEFINER helpers (avoid RLS recursion on profiles)
create or replace function public.my_role() returns user_role
  language sql security definer stable set search_path = public as $$
  select role from public.profiles where id = auth.uid();
$$;
create or replace function public.my_branch() returns text
  language sql security definer stable set search_path = public as $$
  select branch from public.profiles where id = auth.uid();
$$;

-- 5) RLS — profiles
drop policy if exists profiles_self_read on public.profiles;
create policy profiles_self_read on public.profiles
  for select using (id = auth.uid());
drop policy if exists profiles_self_update on public.profiles;
create policy profiles_self_update on public.profiles
  for update using (id = auth.uid());
drop policy if exists profiles_admin_all on public.profiles;
create policy profiles_admin_all on public.profiles
  for all using (public.my_role() = 'admin') with check (public.my_role() = 'admin');
drop policy if exists profiles_manager_branch_read on public.profiles;
create policy profiles_manager_branch_read on public.profiles
  for select using (public.my_role() = 'manajer' and branch = public.my_branch());

-- 6) RLS — visits
drop policy if exists visits_staff_own on public.visits;
create policy visits_staff_own on public.visits
  for all using (staff_id = auth.uid()) with check (staff_id = auth.uid());
drop policy if exists visits_manager_branch_read on public.visits;
create policy visits_manager_branch_read on public.visits
  for select using (
    public.my_role() = 'manajer'
    and exists (select 1 from public.profiles s where s.id = visits.staff_id and s.branch = public.my_branch())
  );
drop policy if exists visits_admin_all on public.visits;
create policy visits_admin_all on public.visits
  for all using (public.my_role() = 'admin') with check (public.my_role() = 'admin');

-- 7) Auto-create profile on signup
create or replace function public.handle_new_user() returns trigger
  language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name',''))
  on conflict (id) do nothing;
  return new;
end; $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users for each row execute function public.handle_new_user();

-- 8) Storage bucket for visit photos (private)
insert into storage.buckets (id, name, public)
  values ('visit-photos','visit-photos', false)
  on conflict (id) do nothing;
-- staff write/read own folder (<uid>/...)
drop policy if exists visit_photos_staff_write on storage.objects;
create policy visit_photos_staff_write on storage.objects
  for insert with check (bucket_id = 'visit-photos' and (storage.foldername(name))[1] = auth.uid()::text);
drop policy if exists visit_photos_staff_read on storage.objects;
create policy visit_photos_staff_read on storage.objects
  for select using (bucket_id = 'visit-photos' and (storage.foldername(name))[1] = auth.uid()::text);
-- NOTE: manager/admin cross-user photo read policies added in R2 (use my_role()).

-- 9) After creating your first user via the app, promote yourself to admin:
--    update public.profiles set role='admin' where id = '<your-auth-uid>';
