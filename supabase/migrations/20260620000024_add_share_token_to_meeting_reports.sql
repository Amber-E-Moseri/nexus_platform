-- Add share_token and meeting_id fields to meeting_attendance_reports
-- NOTE: Table is created in 20260716000000 which already includes these columns
-- on a fresh DB. Wrap in guard so fresh installs skip; production DBs apply patch.
do $$
begin
  if exists (
    select 1 from information_schema.tables
    where table_schema = 'public' and table_name = 'meeting_attendance_reports'
  ) then
    alter table public.meeting_attendance_reports
      add column if not exists share_token uuid unique default gen_random_uuid(),
      add column if not exists meeting_id uuid references public.meetings(id) on delete set null,
      add column if not exists subgroup_filter text;

    create index if not exists meeting_attendance_reports_share_token_idx
      on public.meeting_attendance_reports (share_token);

    create index if not exists meeting_attendance_reports_meeting_id_idx
      on public.meeting_attendance_reports (meeting_id);

    -- RLS policy for public access via share_token
    drop policy if exists "Public access to reports via share_token" on public.meeting_attendance_reports;
    execute $p$
      create policy "Public access to reports via share_token"
        on public.meeting_attendance_reports
        for select
        using (share_token is not null)
    $p$;
  end if;
end
$$;
