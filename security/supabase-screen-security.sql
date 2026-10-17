-- KWEIDER Street Display — secure data model (prototype branch)
-- No secrets are stored in this file.
-- Apply only to a dedicated Supabase project for the screen system.

begin;

-- -----------------------------------------------------------------------------
-- 1) ADMIN ALLOW-LIST
-- Only rows added here by a trusted operator (SQL editor / server-side tooling)
-- are allowed to edit drafts, upload assets, or publish.
-- -----------------------------------------------------------------------------

create table if not exists public.screen_admins (
    user_id uuid primary key references auth.users(id) on delete cascade,
    role text not null default 'admin' check (role in ('admin')),
    created_at timestamptz not null default now()
);

alter table public.screen_admins enable row level security;

revoke all on table public.screen_admins from anon;
revoke all on table public.screen_admins from authenticated;
grant select on table public.screen_admins to authenticated;

drop policy if exists "screen admins can read own membership" on public.screen_admins;
create policy "screen admins can read own membership"
on public.screen_admins
for select
to authenticated
using ((select auth.uid()) = user_id);

-- No client INSERT/UPDATE/DELETE policy is intentionally created for screen_admins.
-- Admin membership must be provisioned from trusted SQL/server-side tooling.

-- -----------------------------------------------------------------------------
-- 2) PRIVATE DRAFT CONTENT
-- The admin edits this table. Anonymous/display clients have zero access.
-- The complete ad payload is JSONB so the cinematic engine can evolve without
-- requiring a schema change for every presentational field.
-- -----------------------------------------------------------------------------

create table if not exists public.screen_ads_draft (
    id integer primary key check (id > 0),
    content jsonb not null default '{}'::jsonb,
    version bigint not null default 1 check (version > 0),
    updated_at timestamptz not null default now(),
    updated_by uuid references auth.users(id)
);

alter table public.screen_ads_draft enable row level security;

revoke all on table public.screen_ads_draft from anon;
revoke all on table public.screen_ads_draft from authenticated;
grant select, insert, update, delete on table public.screen_ads_draft to authenticated;

drop policy if exists "screen admins read drafts" on public.screen_ads_draft;
create policy "screen admins read drafts"
on public.screen_ads_draft
for select
to authenticated
using (
    exists (
        select 1
        from public.screen_admins a
        where a.user_id = (select auth.uid())
    )
);

drop policy if exists "screen admins insert drafts" on public.screen_ads_draft;
create policy "screen admins insert drafts"
on public.screen_ads_draft
for insert
to authenticated
with check (
    exists (
        select 1
        from public.screen_admins a
        where a.user_id = (select auth.uid())
    )
);

drop policy if exists "screen admins update drafts" on public.screen_ads_draft;
create policy "screen admins update drafts"
on public.screen_ads_draft
for update
to authenticated
using (
    exists (
        select 1
        from public.screen_admins a
        where a.user_id = (select auth.uid())
    )
)
with check (
    exists (
        select 1
        from public.screen_admins a
        where a.user_id = (select auth.uid())
    )
);

drop policy if exists "screen admins delete drafts" on public.screen_ads_draft;
create policy "screen admins delete drafts"
on public.screen_ads_draft
for delete
to authenticated
using (
    exists (
        select 1
        from public.screen_admins a
        where a.user_id = (select auth.uid())
    )
);

-- Automatically maintain draft version/audit fields.
create or replace function public.screen_draft_before_write()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
    if tg_op = 'UPDATE' then
        new.version := old.version + 1;
    end if;
    new.updated_at := now();
    new.updated_by := auth.uid();
    return new;
end;
$$;

revoke all on function public.screen_draft_before_write() from public;

drop trigger if exists screen_draft_before_write_trigger on public.screen_ads_draft;
create trigger screen_draft_before_write_trigger
before insert or update on public.screen_ads_draft
for each row execute function public.screen_draft_before_write();

-- -----------------------------------------------------------------------------
-- 3) PUBLIC/PUBLISHED CONTENT
-- The street display reads only this table. It never sees draft rows.
-- Anonymous users get SELECT only. There are no anonymous write grants/policies.
-- -----------------------------------------------------------------------------

create table if not exists public.screen_ads_public (
    id integer primary key check (id > 0),
    content jsonb not null,
    source_version bigint not null check (source_version > 0),
    published_at timestamptz not null default now(),
    published_by uuid references auth.users(id)
);

alter table public.screen_ads_public enable row level security;

revoke all on table public.screen_ads_public from anon;
revoke all on table public.screen_ads_public from authenticated;
grant select on table public.screen_ads_public to anon;
grant select, insert, update, delete on table public.screen_ads_public to authenticated;

drop policy if exists "display can read published ads" on public.screen_ads_public;
create policy "display can read published ads"
on public.screen_ads_public
for select
to anon
using (true);

drop policy if exists "authenticated can read published ads" on public.screen_ads_public;
create policy "authenticated can read published ads"
on public.screen_ads_public
for select
to authenticated
using (true);

drop policy if exists "screen admins insert published ads" on public.screen_ads_public;
create policy "screen admins insert published ads"
on public.screen_ads_public
for insert
to authenticated
with check (
    exists (
        select 1
        from public.screen_admins a
        where a.user_id = (select auth.uid())
    )
);

drop policy if exists "screen admins update published ads" on public.screen_ads_public;
create policy "screen admins update published ads"
on public.screen_ads_public
for update
to authenticated
using (
    exists (
        select 1
        from public.screen_admins a
        where a.user_id = (select auth.uid())
    )
)
with check (
    exists (
        select 1
        from public.screen_admins a
        where a.user_id = (select auth.uid())
    )
);

drop policy if exists "screen admins delete published ads" on public.screen_ads_public;
create policy "screen admins delete published ads"
on public.screen_ads_public
for delete
to authenticated
using (
    exists (
        select 1
        from public.screen_admins a
        where a.user_id = (select auth.uid())
    )
);

-- -----------------------------------------------------------------------------
-- 4) IMMUTABLE VERSION HISTORY
-- Records publication snapshots for rollback/audit.
-- Clients can insert through the publish function and read history, but there is
-- deliberately no UPDATE/DELETE client policy.
-- -----------------------------------------------------------------------------

create table if not exists public.screen_ad_versions (
    version_id bigint generated always as identity primary key,
    ad_id integer not null check (ad_id > 0),
    content jsonb not null,
    source_version bigint not null,
    action text not null default 'publish' check (action in ('publish')),
    created_at timestamptz not null default now(),
    created_by uuid references auth.users(id)
);

alter table public.screen_ad_versions enable row level security;

revoke all on table public.screen_ad_versions from anon;
revoke all on table public.screen_ad_versions from authenticated;
grant select, insert on table public.screen_ad_versions to authenticated;

drop policy if exists "screen admins read history" on public.screen_ad_versions;
create policy "screen admins read history"
on public.screen_ad_versions
for select
to authenticated
using (
    exists (
        select 1
        from public.screen_admins a
        where a.user_id = (select auth.uid())
    )
);

drop policy if exists "screen admins append history" on public.screen_ad_versions;
create policy "screen admins append history"
on public.screen_ad_versions
for insert
to authenticated
with check (
    created_by = (select auth.uid())
    and exists (
        select 1
        from public.screen_admins a
        where a.user_id = (select auth.uid())
    )
);

-- -----------------------------------------------------------------------------
-- 5) ATOMIC PUBLISH RPC
-- SECURITY INVOKER means this function does NOT bypass RLS.
-- It copies one private draft into the public table and writes a version snapshot.
-- -----------------------------------------------------------------------------

create or replace function public.publish_screen_ad(p_ad_id integer)
returns public.screen_ads_public
language plpgsql
security invoker
set search_path = ''
as $$
declare
    v_draft public.screen_ads_draft%rowtype;
    v_result public.screen_ads_public%rowtype;
begin
    if not exists (
        select 1
        from public.screen_admins a
        where a.user_id = auth.uid()
    ) then
        raise exception 'Not authorized to publish screen content'
            using errcode = '42501';
    end if;

    select *
    into v_draft
    from public.screen_ads_draft
    where id = p_ad_id;

    if not found then
        raise exception 'Draft ad % does not exist', p_ad_id
            using errcode = 'P0002';
    end if;

    insert into public.screen_ad_versions (
        ad_id,
        content,
        source_version,
        action,
        created_by
    ) values (
        v_draft.id,
        v_draft.content,
        v_draft.version,
        'publish',
        auth.uid()
    );

    insert into public.screen_ads_public (
        id,
        content,
        source_version,
        published_at,
        published_by
    ) values (
        v_draft.id,
        v_draft.content,
        v_draft.version,
        now(),
        auth.uid()
    )
    on conflict (id) do update
    set content = excluded.content,
        source_version = excluded.source_version,
        published_at = excluded.published_at,
        published_by = excluded.published_by
    returning * into v_result;

    return v_result;
end;
$$;

revoke all on function public.publish_screen_ad(integer) from public;
revoke all on function public.publish_screen_ad(integer) from anon;
grant execute on function public.publish_screen_ad(integer) to authenticated;

-- -----------------------------------------------------------------------------
-- 6) STORAGE
-- screen-drafts  = private images used while editing.
-- screen-public  = published images intended for the street display.
-- Public bucket status allows direct display downloads; write operations remain
-- protected by storage.objects RLS policies.
-- -----------------------------------------------------------------------------

insert into storage.buckets (id, name, public)
values
    ('screen-drafts', 'screen-drafts', false),
    ('screen-public', 'screen-public', true)
on conflict (id) do update
set public = excluded.public;

-- Admins may read/list both buckets.
drop policy if exists "screen admins read screen assets" on storage.objects;
create policy "screen admins read screen assets"
on storage.objects
for select
to authenticated
using (
    bucket_id in ('screen-drafts', 'screen-public')
    and exists (
        select 1
        from public.screen_admins a
        where a.user_id = (select auth.uid())
    )
);

-- Admins may upload to both buckets.
drop policy if exists "screen admins upload screen assets" on storage.objects;
create policy "screen admins upload screen assets"
on storage.objects
for insert
to authenticated
with check (
    bucket_id in ('screen-drafts', 'screen-public')
    and exists (
        select 1
        from public.screen_admins a
        where a.user_id = (select auth.uid())
    )
);

-- Upsert/replace requires SELECT + UPDATE as well as INSERT.
drop policy if exists "screen admins update screen assets" on storage.objects;
create policy "screen admins update screen assets"
on storage.objects
for update
to authenticated
using (
    bucket_id in ('screen-drafts', 'screen-public')
    and exists (
        select 1
        from public.screen_admins a
        where a.user_id = (select auth.uid())
    )
)
with check (
    bucket_id in ('screen-drafts', 'screen-public')
    and exists (
        select 1
        from public.screen_admins a
        where a.user_id = (select auth.uid())
    )
);

drop policy if exists "screen admins delete screen assets" on storage.objects;
create policy "screen admins delete screen assets"
on storage.objects
for delete
to authenticated
using (
    bucket_id in ('screen-drafts', 'screen-public')
    and exists (
        select 1
        from public.screen_admins a
        where a.user_id = (select auth.uid())
    )
);

commit;

-- -----------------------------------------------------------------------------
-- POST-SETUP (trusted operation, NOT part of public client code)
-- After the first admin has authenticated, add that user's auth UUID with:
--
-- insert into public.screen_admins (user_id)
-- values ('<AUTH_USER_UUID>');
--
-- Then run Supabase Security and Performance Advisors before connecting Publish.
-- -----------------------------------------------------------------------------
