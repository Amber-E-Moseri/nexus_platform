-- Reconcile broadcast_campaigns with communication_segments
-- Adds optional segment_id FK to broadcast_campaigns and documents the
-- canonical recipient pill shape on both tables.
--
-- NOTE: communication_segments is created in 20260721000001.
--       broadcast_campaigns is created in 20260901000000_native_communications_system.sql.
--       On a fresh DB neither table exists yet; wrap in existence guards.

do $$
begin
  -- Document the canonical pill shape on communication_segments.filters
  if exists (
    select 1 from information_schema.tables
    where table_schema = 'public' and table_name = 'communication_segments'
  ) then
    comment on column public.communication_segments.filters is
      'Array of recipient pill objects: [{"type":"department","deptId":"..."}, {"type":"role","role":"pastor"}, {"type":"individual","email":"...","name":"..."}]';
  end if;

  -- Add optional segment_id to broadcast_campaigns and document columns
  if exists (
    select 1 from information_schema.tables
    where table_schema = 'public' and table_name = 'broadcast_campaigns'
  ) then
    if not exists (
      select 1 from information_schema.columns
      where table_schema = 'public'
        and table_name = 'broadcast_campaigns'
        and column_name = 'segment_id'
    ) then
      alter table public.broadcast_campaigns
        add column segment_id uuid references public.communication_segments(id) on delete set null;
    end if;

    comment on column public.broadcast_campaigns.recipient_filters is
      'Inline recipient pills — same shape as communication_segments.filters. Ignored at send time if segment_id is set.';

    comment on column public.broadcast_campaigns.segment_id is
      'Optional FK to communication_segments. When set, filters are resolved at send time and recipient_filters is ignored.';
  end if;
end
$$;
