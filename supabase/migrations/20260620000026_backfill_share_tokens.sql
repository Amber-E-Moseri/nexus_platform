-- Backfill share_token for existing meeting_attendance_reports
-- Guard: table created in 20260716000000; on fresh DB the column is pre-populated
do $$
begin
  if exists (
    select 1 from information_schema.tables
    where table_schema = 'public' and table_name = 'meeting_attendance_reports'
  ) then
    update public.meeting_attendance_reports
    set share_token = gen_random_uuid()
    where share_token is null;
  end if;
end
$$;
