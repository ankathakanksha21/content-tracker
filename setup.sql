-- =====================================================================
-- Content Tracker: database setup for Supabase
-- Run this once: Supabase dashboard → SQL Editor → New query → paste → Run.
-- Safe to run again: it won't delete or duplicate anything.
--
-- BEFORE RUNNING: replace YOUR-ADMIN-EMAIL@example.com (near the bottom)
-- with the email you'll log in with.
-- =====================================================================

-- 1. Tables ------------------------------------------------------------

create table if not exists public.entries (
  id            uuid primary key default gen_random_uuid(),
  title         text not null default '',
  value         text not null default '',
  audience      text not null default '',
  category      text not null default '',
  subcategory   text not null default '',
  funnel        text not null default '',
  source        text not null default '',
  source_title  text not null default '',
  links         text[] not null default '{}',
  status        text not null default 'Idea',
  posted_on     date,
  views         bigint,
  likes         bigint,
  comments      bigint,
  saves         bigint,
  shares        bigint,
  notes         text not null default '',
  extra         jsonb not null default '{}'::jsonb,   -- room for anything added later
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

-- Your dropdown lists (categories, subcategories, sources, audiences) live in one row.
create table if not exists public.tracker_config (
  id          text primary key,
  data        jsonb not null default '{}'::jsonb,
  updated_at  timestamptz not null default now()
);

-- Who may edit. Nobody can read this table through the website.
create table if not exists public.tracker_admins (
  email text primary key
);

-- 2. Keep updated_at current -------------------------------------------

create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

drop trigger if exists entries_touch on public.entries;
create trigger entries_touch before update on public.entries
  for each row execute function public.touch_updated_at();

drop trigger if exists tracker_config_touch on public.tracker_config;
create trigger tracker_config_touch before update on public.tracker_config
  for each row execute function public.touch_updated_at();

-- 3. "Is the logged-in person the owner?" ------------------------------

create or replace function public.is_admin()
returns boolean
language sql stable security definer
set search_path = public
as $$
  select exists (
    select 1 from public.tracker_admins a
    where lower(a.email) = lower(coalesce(auth.jwt() ->> 'email', ''))
  );
$$;
revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to anon, authenticated;

-- 4. Who can do what (row-level security) -------------------------------
-- Everyone (logged in or not) can read. Only the owner's email can add, edit or delete.

alter table public.entries        enable row level security;
alter table public.tracker_config enable row level security;
alter table public.tracker_admins enable row level security;

grant select on public.entries, public.tracker_config to anon, authenticated;
grant insert, update, delete on public.entries, public.tracker_config to authenticated;
revoke all on public.tracker_admins from anon, authenticated;

drop policy if exists "Anyone can read entries"   on public.entries;
drop policy if exists "Owner can add entries"     on public.entries;
drop policy if exists "Owner can edit entries"    on public.entries;
drop policy if exists "Owner can delete entries"  on public.entries;
create policy "Anyone can read entries"  on public.entries for select to anon, authenticated using (true);
create policy "Owner can add entries"    on public.entries for insert to authenticated with check (public.is_admin());
create policy "Owner can edit entries"   on public.entries for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "Owner can delete entries" on public.entries for delete to authenticated using (public.is_admin());

drop policy if exists "Anyone can read lists"   on public.tracker_config;
drop policy if exists "Owner can add lists"     on public.tracker_config;
drop policy if exists "Owner can edit lists"    on public.tracker_config;
drop policy if exists "Owner can delete lists"  on public.tracker_config;
create policy "Anyone can read lists"  on public.tracker_config for select to anon, authenticated using (true);
create policy "Owner can add lists"    on public.tracker_config for insert to authenticated with check (public.is_admin());
create policy "Owner can edit lists"   on public.tracker_config for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "Owner can delete lists" on public.tracker_config for delete to authenticated using (public.is_admin());

-- 5. Live updates for everyone who has the page open --------------------

do $$
begin
  begin
    alter publication supabase_realtime add table public.entries;
  exception when duplicate_object then null;
  end;
  begin
    alter publication supabase_realtime add table public.tracker_config;
  exception when duplicate_object then null;
  end;
end $$;

-- 6. Your lists (only added if not there yet) ----------------------------

insert into public.tracker_config (id, data)
values ('options', '{"categories": [{"name": "Educational in-depth", "subs": [{"name": "Fake case study (what I''d do for a brand or situation)", "funnel": "BOFU"}, {"name": "Challenge / gamified", "funnel": "BOFU"}, {"name": "Process / framework, step by step", "funnel": "BOFU"}, {"name": "Comparison (method, product, results, services)", "funnel": "BOFU"}, {"name": "Transformation (personal or client)", "funnel": "BOFU"}, {"name": "Tech stack, brandjacking, newsjacking, trendjacking", "funnel": "BOFU"}, {"name": "Case study (company, open source, startup, person, workflow)", "funnel": "BOFU"}, {"name": "Reaction video", "funnel": "BOFU"}]}, {"name": "Educational quick", "subs": [{"name": "Common mistakes / myth busting", "funnel": "TOFU"}, {"name": "Do''s and don''ts / right vs wrong", "funnel": "TOFU"}, {"name": "Quick tips or lessons", "funnel": "TOFU"}, {"name": "One-off tip or hack", "funnel": "TOFU"}, {"name": "Repeatable easy structure (lists)", "funnel": "TOFU"}, {"name": "Ranking / tier list", "funnel": "TOFU"}]}, {"name": "Storytelling", "subs": [{"name": "Experiences", "funnel": "MOFU"}, {"name": "Lifestyle", "funnel": "MOFU"}, {"name": "Product / service", "funnel": "MOFU"}, {"name": "Challenges (personal or business)", "funnel": "MOFU"}, {"name": "Lessons learnt", "funnel": "MOFU"}, {"name": "Wins / losses", "funnel": "MOFU"}, {"name": "Numbers / metrics (income reveal etc.)", "funnel": "MOFU"}]}, {"name": "Authority", "subs": [{"name": "Trade-offs, decision making, best practices", "funnel": "MOFU"}, {"name": "Progress / updates", "funnel": "MOFU"}, {"name": "Tech lessons learnt", "funnel": "MOFU"}, {"name": "Build journey of a product or service", "funnel": "MOFU"}, {"name": "Cost breakdown (product, service, business)", "funnel": "BOFU"}, {"name": "Candid lessons after some progress", "funnel": "TOFU"}, {"name": "Founder / insider interview", "funnel": "BOFU"}, {"name": "Beyond engineering: soft skills and 10x engineering", "funnel": "MOFU"}]}], "sources": ["Webinars", "Personal experience", "YouTube", "Medium", "X", "LinkedIn", "GitHub", "Podcasts", "Substack", "Instagram", "Learnings from big people", "Offline experiences", "Tech blogs"], "audiences": ["Software devs new to AI", "AI engineers", "Devs who vibe code", "College students learning AI"]}'::jsonb)
on conflict (id) do nothing;

-- 7. Your admin email ---------------------------------------------------
-- Replace with the email you'll log in with. To change it later, run:
--   delete from public.tracker_admins; insert into public.tracker_admins values ('new@email.com');

insert into public.tracker_admins (email)
values ('YOUR-ADMIN-EMAIL@example.com')
on conflict do nothing;
