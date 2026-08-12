-- Add bySubgroup JSON column to store per-subgroup breakdown data
-- Guard: table created in 20260716000000 which includes by_subgroup; no-op on fresh DB
do $$
begin
  if exists (
    select 1 from information_schema.tables
    where table_schema = 'public' and table_name = 'meeting_attendance_reports'
  ) then
    alter table public.meeting_attendance_reports
      add column if not exists by_subgroup jsonb default null;

    create index if not exists meeting_attendance_reports_by_subgroup_idx
      on public.meeting_attendance_reports using gin (by_subgroup);
  end if;
end
$$;
