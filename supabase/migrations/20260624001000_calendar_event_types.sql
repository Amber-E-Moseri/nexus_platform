-- Create calendar_event_types table
create table if not exists public.calendar_event_types (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  color text not null default '#5B34C7',
  active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

-- Create index for quick lookups by active status and sort order
create index if not exists calendar_event_types_active_sort_order_idx
  on public.calendar_event_types(active, sort_order);

-- Enable row level security
alter table public.calendar_event_types enable row level security;

-- Allow authenticated users to read active event types
create policy "Read active event types"
  on public.calendar_event_types
  for select
  to authenticated
  using (active = true);

-- Allow users with calendar management permission to manage event types
-- NOTE: calendar_permissions is created in 20260625000000_calendar_system_foundation.sql.
-- Stub policy here; 20260625000000 drops and recreates it with the full implementation.
create policy "Manage event types"
  on public.calendar_event_types
  for all
  to authenticated
  using (auth.jwt() ->> 'user_role' = 'super_admin');
