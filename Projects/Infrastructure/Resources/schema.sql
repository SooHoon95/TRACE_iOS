-- TRACE — Supabase schema + RLS (Phase 2). Run once in the Supabase SQL editor.
-- Photos live in Supabase Storage bucket "moment-photos" (public read) for the PoC.

-- ── Tables ──────────────────────────────────────────────────────────────────
create table if not exists profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  nickname    text not null default '여행자',
  created_at  timestamptz not null default now()
);

create table if not exists places (
  id              uuid primary key default gen_random_uuid(),
  ref_type        text not null check (ref_type in ('poi','coordinate')),
  ref_provider_id text,
  ref_name        text,
  latitude        double precision not null,
  longitude       double precision not null,
  display_name    text not null,
  created_at      timestamptz not null default now()
);

create table if not exists moments (
  id          uuid primary key default gen_random_uuid(),
  place_id    uuid not null references places(id) on delete cascade,
  author_id   uuid not null references auth.users(id) on delete cascade,
  photo_ref   text not null,
  caption     text,
  companion   text,
  vibe        text,
  latitude    double precision not null,
  longitude   double precision not null,
  visibility  text not null default 'publicExhibit'
              check (visibility in ('publicExhibit','privateOnly')),
  created_at  timestamptz not null default now()
);

create index if not exists moments_place_created  on moments(place_id, created_at desc);
create index if not exists moments_author_created on moments(author_id, created_at desc);

-- ── resolveOrCreate as an atomic RPC (snap to nearest within radius, else insert) ──
create or replace function resolve_or_create_place(
  p_lat double precision, p_lng double precision, p_radius_m double precision, p_name text
) returns setof places language plpgsql as $$
declare nearest places; dist double precision;
begin
  select * into nearest from places
  order by 6371000 * 2 * asin(sqrt(
    power(sin(radians(latitude - p_lat) / 2), 2) +
    cos(radians(p_lat)) * cos(radians(latitude)) *
    power(sin(radians(longitude - p_lng) / 2), 2))) asc
  limit 1;

  if nearest.id is not null then
    dist := 6371000 * 2 * asin(sqrt(
      power(sin(radians(nearest.latitude - p_lat) / 2), 2) +
      cos(radians(p_lat)) * cos(radians(nearest.latitude)) *
      power(sin(radians(nearest.longitude - p_lng) / 2), 2)));
    if dist <= p_radius_m then
      return next nearest; return;
    end if;
  end if;

  return query
    insert into places (ref_type, ref_provider_id, ref_name, latitude, longitude, display_name)
    values (case when p_name is null then 'coordinate' else 'poi' end,
            case when p_name is null then null else 'mock' end,
            p_name, p_lat, p_lng, coalesce(p_name, '이름 없는 자리'))
    returning *;
end; $$;

-- ── Row Level Security ──────────────────────────────────────────────────────
alter table profiles enable row level security;
alter table places   enable row level security;
alter table moments  enable row level security;

create policy "profiles readable"      on profiles for select using (true);
create policy "profile upsert by self" on profiles for insert with check (id = auth.uid());
create policy "profile update by self" on profiles for update using (id = auth.uid());

create policy "places readable"        on places for select using (true);
create policy "places insert authed"   on places for insert with check (auth.uid() is not null);

-- public moments visible to everyone; private only to their author
create policy "moments select"         on moments for select
  using (visibility = 'publicExhibit' or author_id = auth.uid());
create policy "moments insert owner"   on moments for insert with check (author_id = auth.uid());
create policy "moments modify owner"   on moments for update using (author_id = auth.uid());
create policy "moments delete owner"   on moments for delete using (author_id = auth.uid());
