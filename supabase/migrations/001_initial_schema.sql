create extension if not exists pgcrypto;

create table if not exists public.app_members (
  user_id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  role text not null default 'handler' check (role in ('admin','handler')),
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.dogs (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  birth_date date,
  chip_number text,
  photo_path text,
  tracker_provider text,
  tracker_device_id text,
  notes text,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.searches (
  id uuid primary key default gen_random_uuid(),
  search_name text unique,
  company_name text not null,
  organization_number text,
  contact_name text,
  contact_email text,
  contact_phone text,
  dog_id uuid references public.dogs(id),
  handler_id uuid not null references auth.users(id),
  planned_date date not null default current_date,
  search_area jsonb not null default '[]'::jsonb,
  notes text,
  summary text,
  status text not null check (status in ('planned','active','paused','completed','cancelled')),
  started_at timestamptz,
  completed_at timestamptz,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.weather_snapshots (
  id uuid primary key default gen_random_uuid(),
  search_id uuid not null references public.searches(id) on delete cascade,
  temperature_c numeric,
  wind_speed_ms numeric,
  wind_direction_deg numeric,
  humidity_percent numeric,
  air_pressure_hpa numeric,
  precipitation_mm numeric,
  fetched_at timestamptz not null
);

create table if not exists public.search_track_points (
  id bigint generated always as identity primary key,
  search_id uuid not null references public.searches(id) on delete cascade,
  source text not null default 'handler' check (source in ('handler','dog')),
  latitude double precision not null,
  longitude double precision not null,
  accuracy_m double precision,
  battery_percent numeric,
  recorded_at timestamptz not null default now()
);
create index if not exists search_track_points_search_time_idx on public.search_track_points(search_id, recorded_at);

create table if not exists public.search_pauses (
  id uuid primary key default gen_random_uuid(),
  search_id uuid not null references public.searches(id) on delete cascade,
  paused_at timestamptz not null,
  resumed_at timestamptz
);

create table if not exists public.search_photos (
  id uuid primary key default gen_random_uuid(),
  search_id uuid not null references public.searches(id) on delete cascade,
  photo_type text not null default 'search_area' check (photo_type = 'search_area'),
  storage_path text not null,
  latitude double precision,
  longitude double precision,
  taken_at timestamptz not null default now(),
  created_by uuid not null references auth.users(id)
);

create table if not exists public.findings (
  id uuid primary key default gen_random_uuid(),
  search_id uuid not null references public.searches(id) on delete cascade,
  description text not null,
  handling text not null check (handling in ('tatt_med_for_destruering','destruert_pa_plass')),
  latitude double precision not null,
  longitude double precision not null,
  found_at timestamptz not null default now(),
  created_by uuid not null references auth.users(id)
);

create table if not exists public.finding_photos (
  id uuid primary key default gen_random_uuid(),
  finding_id uuid not null references public.findings(id) on delete cascade,
  storage_path text not null,
  taken_at timestamptz not null default now(),
  created_by uuid not null references auth.users(id)
);

create table if not exists public.training_finds (
  id uuid primary key default gen_random_uuid(),
  material_type text,
  notes text,
  latitude double precision not null,
  longitude double precision not null,
  photo_path text,
  buried_at timestamptz not null default now(),
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now()
);

create table if not exists public.dog_events (
  id uuid primary key default gen_random_uuid(),
  dog_id uuid not null references public.dogs(id) on delete cascade,
  title text not null,
  notes text,
  event_date timestamptz not null,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now()
);

create table if not exists public.calendar_events (
  id uuid primary key default gen_random_uuid(),
  event_type text not null check (event_type in ('planned_search','training','training_find','dog_event','note')),
  title text not null,
  notes text,
  starts_at timestamptz not null,
  ends_at timestamptz,
  linked_table text,
  linked_id uuid,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now()
);

create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  search_id uuid not null references public.searches(id) on delete cascade,
  pdf_path text,
  docx_path text,
  generated_at timestamptz not null default now(),
  generated_by uuid not null references auth.users(id)
);

insert into storage.buckets (id,name,public) values ('search-media','search-media',false) on conflict (id) do nothing;
insert into storage.buckets (id,name,public) values ('training-media','training-media',false) on conflict (id) do nothing;
insert into storage.buckets (id,name,public) values ('reports','reports',false) on conflict (id) do nothing;

alter table public.app_members enable row level security;
alter table public.dogs enable row level security;
alter table public.searches enable row level security;
alter table public.weather_snapshots enable row level security;
alter table public.search_track_points enable row level security;
alter table public.search_pauses enable row level security;
alter table public.search_photos enable row level security;
alter table public.findings enable row level security;
alter table public.finding_photos enable row level security;
alter table public.training_finds enable row level security;
alter table public.dog_events enable row level security;
alter table public.calendar_events enable row level security;
alter table public.reports enable row level security;

create or replace function public.is_app_member()
returns boolean
language sql
stable
security invoker
set search_path = ''
as $$
  select exists(select 1 from public.app_members m where m.user_id = (select auth.uid()) and m.active = true);
$$;

revoke all on function public.is_app_member() from public;
grant execute on function public.is_app_member() to authenticated;

-- Team-app: all active AFD Søkshund members share operational data.
do $$
declare t text;
begin
  foreach t in array array['dogs','searches','weather_snapshots','search_track_points','search_pauses','search_photos','findings','finding_photos','training_finds','dog_events','calendar_events','reports']
  loop
    execute format('create policy %I on public.%I for select to authenticated using (public.is_app_member())', t||'_select_member', t);
    execute format('create policy %I on public.%I for insert to authenticated with check (public.is_app_member())', t||'_insert_member', t);
    execute format('create policy %I on public.%I for update to authenticated using (public.is_app_member()) with check (public.is_app_member())', t||'_update_member', t);
    execute format('create policy %I on public.%I for delete to authenticated using (public.is_app_member())', t||'_delete_member', t);
  end loop;
end $$;

create policy app_members_read_self on public.app_members for select to authenticated using (user_id = (select auth.uid()));

create policy search_media_select on storage.objects for select to authenticated using (bucket_id='search-media' and public.is_app_member());
create policy search_media_insert on storage.objects for insert to authenticated with check (bucket_id='search-media' and public.is_app_member());
create policy search_media_update on storage.objects for update to authenticated using (bucket_id='search-media' and public.is_app_member()) with check (bucket_id='search-media' and public.is_app_member());
create policy search_media_delete on storage.objects for delete to authenticated using (bucket_id='search-media' and public.is_app_member());

create policy training_media_select on storage.objects for select to authenticated using (bucket_id='training-media' and public.is_app_member());
create policy training_media_insert on storage.objects for insert to authenticated with check (bucket_id='training-media' and public.is_app_member());
create policy training_media_update on storage.objects for update to authenticated using (bucket_id='training-media' and public.is_app_member()) with check (bucket_id='training-media' and public.is_app_member());
create policy training_media_delete on storage.objects for delete to authenticated using (bucket_id='training-media' and public.is_app_member());

create policy reports_select on storage.objects for select to authenticated using (bucket_id='reports' and public.is_app_member());
create policy reports_insert on storage.objects for insert to authenticated with check (bucket_id='reports' and public.is_app_member());
create policy reports_update on storage.objects for update to authenticated using (bucket_id='reports' and public.is_app_member()) with check (bucket_id='reports' and public.is_app_member());
create policy reports_delete on storage.objects for delete to authenticated using (bucket_id='reports' and public.is_app_member());

grant usage on schema public to authenticated;
grant select,insert,update,delete on all tables in schema public to authenticated;
grant usage,select on all sequences in schema public to authenticated;
