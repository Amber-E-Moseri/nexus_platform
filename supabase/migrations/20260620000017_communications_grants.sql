-- Update communications policies to use user grants system
-- Allows ORS, dept_leads, and users with grants
--
-- NOTE: On a fresh DB the communication tables are created in 20260721000001.
-- This migration was a policy patch on a production DB where those tables already
-- existed. Wrap in existence guards; 20260721000001 creates the tables.

do $$
begin
  if exists (
    select 1 from information_schema.tables
    where table_schema = 'public' and table_name = 'communication_segments'
  ) then

    drop policy if exists "comm_segments_insert" on public.communication_segments;
    drop policy if exists "comm_segments_update" on public.communication_segments;

    execute $p$
      create policy "comm_segments_insert" on public.communication_segments for insert to authenticated
        with check (
          (auth.jwt() ->> 'role') = 'super_admin'
          or (select d.name = 'ORS Projects' or d.name = 'ORS'
              from public.departments d where d.id = public.current_user_department())
          or (auth.jwt() ->> 'role') = 'dept_lead'
          or public.user_has_grant(auth.uid(), 'communications_manager')
        )
    $p$;

    execute $p$
      create policy "comm_segments_update" on public.communication_segments for update to authenticated
        using (
          (auth.jwt() ->> 'role') = 'super_admin'
          or (select d.name = 'ORS Projects' or d.name = 'ORS'
              from public.departments d where d.id = public.current_user_department())
          or (auth.jwt() ->> 'role') = 'dept_lead'
          or public.user_has_grant(auth.uid(), 'communications_manager')
        )
    $p$;

  end if;

  if exists (
    select 1 from information_schema.tables
    where table_schema = 'public' and table_name = 'communication_campaigns'
  ) then

    drop policy if exists "comm_campaigns_insert" on public.communication_campaigns;
    drop policy if exists "comm_campaigns_update" on public.communication_campaigns;

    execute $p$
      create policy "comm_campaigns_insert" on public.communication_campaigns for insert to authenticated
        with check (
          (auth.jwt() ->> 'role') = 'super_admin'
          or (select d.name = 'ORS Projects' or d.name = 'ORS'
              from public.departments d where d.id = public.current_user_department())
          or (auth.jwt() ->> 'role') = 'dept_lead'
          or public.user_has_grant(auth.uid(), 'communications_manager')
        )
    $p$;

    execute $p$
      create policy "comm_campaigns_update" on public.communication_campaigns for update to authenticated
        using (
          (auth.jwt() ->> 'role') = 'super_admin'
          or (select d.name = 'ORS Projects' or d.name = 'ORS'
              from public.departments d where d.id = public.current_user_department())
          or (auth.jwt() ->> 'role') = 'dept_lead'
          or public.user_has_grant(auth.uid(), 'communications_manager')
        )
    $p$;

  end if;

  if exists (
    select 1 from information_schema.tables
    where table_schema = 'public' and table_name = 'communication_sends'
  ) then

    drop policy if exists "comm_sends_insert" on public.communication_sends;
    drop policy if exists "comm_sends_update" on public.communication_sends;

    execute $p$
      create policy "comm_sends_insert" on public.communication_sends for insert to authenticated
        with check (
          (auth.jwt() ->> 'role') = 'super_admin'
          or (select d.name = 'ORS Projects' or d.name = 'ORS'
              from public.departments d where d.id = public.current_user_department())
          or (auth.jwt() ->> 'role') = 'dept_lead'
          or public.user_has_grant(auth.uid(), 'communications_manager')
        )
    $p$;

    execute $p$
      create policy "comm_sends_update" on public.communication_sends for update to authenticated
        using (
          (auth.jwt() ->> 'role') = 'super_admin'
          or (select d.name = 'ORS Projects' or d.name = 'ORS'
              from public.departments d where d.id = public.current_user_department())
          or (auth.jwt() ->> 'role') = 'dept_lead'
          or public.user_has_grant(auth.uid(), 'communications_manager')
        )
    $p$;

  end if;
end
$$;
