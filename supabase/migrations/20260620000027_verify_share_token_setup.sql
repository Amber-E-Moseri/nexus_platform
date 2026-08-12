-- Verify and fix share_token column setup
-- Guard: table created in 20260716000000 with share_token; on fresh DB this is a no-op
do $$
begin
  if exists (
    select 1 from information_schema.tables
    where table_schema = 'public' and table_name = 'meeting_attendance_reports'
  ) then
    -- 1. Ensure share_token column exists with auto-generation
    if not exists (
      select 1 from information_schema.columns
      where table_schema = 'public'
        and table_name = 'meeting_attendance_reports'
        and column_name = 'share_token'
    ) then
      alter table public.meeting_attendance_reports
        add column share_token uuid unique default gen_random_uuid();
    end if;

    -- 2. Backfill any null share_tokens
    update public.meeting_attendance_reports
    set share_token = gen_random_uuid()
    where share_token is null;

    -- 3. Make share_token NOT NULL after backfill
    alter table public.meeting_attendance_reports
      alter column share_token set not null;

    -- 4. Ensure index exists
    drop index if exists meeting_attendance_reports_share_token_idx;
    create index meeting_attendance_reports_share_token_idx
      on public.meeting_attendance_reports (share_token);

    -- 5. RLS policy for public access via share_token
    drop policy if exists "Public access via share_token" on public.meeting_attendance_reports;
    execute $p$
      create policy "Public access via share_token"
        on public.meeting_attendance_reports
        for select
        using (share_token is not null)
    $p$;
  end if;
end
$$;
