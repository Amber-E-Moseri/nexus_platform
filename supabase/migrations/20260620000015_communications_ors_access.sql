-- Grant ORS and permissioned people access to communications
-- ORS members can manage segments and campaigns
-- Department leads can manage in their own department
-- Others have view-only access
--
-- NOTE: On a fresh DB the communication tables are created in 20260721000001.
-- This migration was a policy patch on a production DB where those tables already
-- existed. Wrap everything in an existence guard so fresh installs are unaffected;
-- 20260721000001 creates the tables with equivalent (updated) policies.

do $$
begin
  if exists (
    select 1 from information_schema.tables
    where table_schema = 'public' and table_name = 'communication_segments'
  ) then

    -- Segments policies
    drop policy if exists "comm_segments_insert" on public.communication_segments;
    drop policy if exists "comm_segments_update" on public.communication_segments;
    drop policy if exists "comm_segments_delete" on public.communication_segments;

    execute $p$
      create policy "comm_segments_insert" on public.communication_segments for insert to authenticated
        with check (
          (auth.jwt() ->> 'role') = 'super_admin'
          or (
            select d.name = 'ORS Projects' or d.name = 'ORS'
            from public.departments d
            where d.id = public.current_user_department()
          )
          or (auth.jwt() ->> 'role') = 'dept_lead'
        )
    $p$;

    execute $p$
      create policy "comm_segments_update" on public.communication_segments for update to authenticated
        using (
          (auth.jwt() ->> 'role') = 'super_admin'
          or (
            select d.name = 'ORS Projects' or d.name = 'ORS'
            from public.departments d
            where d.id = public.current_user_department()
          )
          or (auth.jwt() ->> 'role') = 'dept_lead'
        )
    $p$;

    execute $p$
      create policy "comm_segments_delete" on public.communication_segments for delete to authenticated
        using ((auth.jwt() ->> 'role') = 'super_admin')
    $p$;

  end if;

  if exists (
    select 1 from information_schema.tables
    where table_schema = 'public' and table_name = 'communication_campaigns'
  ) then

    -- Campaigns policies
    drop policy if exists "comm_campaigns_insert" on public.communication_campaigns;
    drop policy if exists "comm_campaigns_update" on public.communication_campaigns;
    drop policy if exists "comm_campaigns_delete" on public.communication_campaigns;

    execute $p$
      create policy "comm_campaigns_insert" on public.communication_campaigns for insert to authenticated
        with check (
          (auth.jwt() ->> 'role') = 'super_admin'
          or (
            select d.name = 'ORS Projects' or d.name = 'ORS'
            from public.departments d
            where d.id = public.current_user_department()
          )
          or (auth.jwt() ->> 'role') = 'dept_lead'
        )
    $p$;

    execute $p$
      create policy "comm_campaigns_update" on public.communication_campaigns for update to authenticated
        using (
          (auth.jwt() ->> 'role') = 'super_admin'
          or (
            select d.name = 'ORS Projects' or d.name = 'ORS'
            from public.departments d
            where d.id = public.current_user_department()
          )
          or (auth.jwt() ->> 'role') = 'dept_lead'
        )
    $p$;

    execute $p$
      create policy "comm_campaigns_delete" on public.communication_campaigns for delete to authenticated
        using ((auth.jwt() ->> 'role') = 'super_admin')
    $p$;

  end if;

  if exists (
    select 1 from information_schema.tables
    where table_schema = 'public' and table_name = 'communication_sends'
  ) then

    -- Sends policies
    drop policy if exists "comm_sends_insert" on public.communication_sends;
    drop policy if exists "comm_sends_update" on public.communication_sends;
    drop policy if exists "comm_sends_delete" on public.communication_sends;

    execute $p$
      create policy "comm_sends_insert" on public.communication_sends for insert to authenticated
        with check (
          (auth.jwt() ->> 'role') = 'super_admin'
          or (
            select d.name = 'ORS Projects' or d.name = 'ORS'
            from public.departments d
            where d.id = public.current_user_department()
          )
          or (auth.jwt() ->> 'role') = 'dept_lead'
        )
    $p$;

    execute $p$
      create policy "comm_sends_update" on public.communication_sends for update to authenticated
        using (
          (auth.jwt() ->> 'role') = 'super_admin'
          or (
            select d.name = 'ORS Projects' or d.name = 'ORS'
            from public.departments d
            where d.id = public.current_user_department()
          )
          or (auth.jwt() ->> 'role') = 'dept_lead'
        )
    $p$;

    execute $p$
      create policy "comm_sends_delete" on public.communication_sends for delete to authenticated
        using ((auth.jwt() ->> 'role') = 'super_admin')
    $p$;

  end if;
end
$$;
