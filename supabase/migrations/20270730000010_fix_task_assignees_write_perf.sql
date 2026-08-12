-- Fix: task_assignees_write policy uses a raw tasks subquery which causes
-- a slow evaluation chain: task_comments → tasks → task_assignees → tasks again.
-- Replace with task_meta() SECURITY DEFINER function (same fix as 20270724000114).

-- Stub: has_any_space_role is defined in 20270802000000_fix_assignee_sync_and_permissions.sql.
-- Created here so the policy below can reference it.
-- 20270802000000 replaces this with the real implementation via CREATE OR REPLACE.
create or replace function public.has_any_space_role(p_user_id uuid, p_role text)
returns boolean
language sql
stable
as $$
  select false
$$;

drop policy if exists "task_assignees_write" on public.task_assignees;

create policy "task_assignees_write" on public.task_assignees
  for all
  using (
    (
      select
        tm.created_by = auth.uid()
        or public.current_user_role() in ('super_admin', 'regional_secretary')
        or public.has_space_role(auth.uid(), tm.department_id, 'dept_lead')
        or public.has_any_space_role(auth.uid(), 'ors')
        or public.has_any_space_role(auth.uid(), 'programs')
      from public.task_meta(task_assignees.task_id) tm
    )
  );
