-- ============================================================
--  NACBA Webinar Docket — managing access from the app
--  Safe to re-run.
--
--  Adding someone was an INSERT typed into the SQL editor, which is a
--  poor way to hand out access. This adds what the Team screen needs.
--
--  `role` stays about ACCESS, not job title — that distinction is why
--  'President' failed the check constraint earlier. Titles now have
--  their own column, so someone can be President and still hold
--  whichever access level is appropriate.
-- ============================================================

alter table allowed_emails add column if not exists title       text not null default '';
alter table allowed_emails add column if not exists invited_by  text not null default '';

comment on column allowed_emails.role  is
  'Access level, not job title: admin can manage the team, everyone else can edit content.';
comment on column allowed_emails.title is
  'Organisational title for display — President, EMC Chair, Coordinator, and so on.';

-- Record who granted access, the same way task completions are stamped.
create or replace function public.stamp_invite()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.invited_by = '' then
    new.invited_by := coalesce(nullif(auth.jwt() ->> 'email', ''), '');
  end if;
  new.email := lower(trim(new.email));
  return new;
end $$;

drop trigger if exists trg_stamp_invite on allowed_emails;
create trigger trg_stamp_invite before insert on allowed_emails
  for each row execute function public.stamp_invite();

-- Never let the last admin be removed — an allowlist with no admin
-- cannot be edited by anyone, from anywhere in the app.
create or replace function public.guard_last_admin()
returns trigger language plpgsql security definer set search_path = public as $$
declare admins int;
begin
  select count(*) into admins from allowed_emails where role = 'admin';
  if tg_op = 'DELETE' and old.role = 'admin' and admins <= 1 then
    raise exception 'That is the only administrator. Promote someone else first.';
  end if;
  if tg_op = 'UPDATE' and old.role = 'admin' and new.role <> 'admin' and admins <= 1 then
    raise exception 'That is the only administrator. Promote someone else first.';
  end if;
  return coalesce(new, old);
end $$;

drop trigger if exists trg_guard_last_admin on allowed_emails;
create trigger trg_guard_last_admin before update or delete on allowed_emails
  for each row execute function public.guard_last_admin();
