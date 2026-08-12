-- Create role_permissions table
-- Note: user_role is TEXT in this codebase (not a Postgres enum); use text type.
create table if not exists public.role_permissions (
  id uuid primary key default gen_random_uuid(),
  role text not null,
  permission_key text not null,
  enabled boolean default true,
  description text,
  is_baseline boolean default true,
  category text,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now(),
  unique(role, permission_key)
);

-- Indexes
create index if not exists idx_role_permissions_role on public.role_permissions(role);
create index if not exists idx_role_permissions_permission_key on public.role_permissions(permission_key);
create index if not exists idx_role_permissions_category on public.role_permissions(category);

-- RLS
alter table public.role_permissions enable row level security;

drop policy if exists "Users can view permissions" on public.role_permissions;
create policy "Users can view permissions" on public.role_permissions
  for select using (auth.uid() is not null);

drop policy if exists "Super admin manages all" on public.role_permissions;
create policy "Super admin manages all" on public.role_permissions
  for all using (
    (select role from public.users where id = auth.uid()) = 'super_admin'
  );

-- Seed baseline permissions for SUPER_ADMIN role
insert into public.role_permissions (role, permission_key, enabled, is_baseline, description, category) values
  ('super_admin', 'campus:approve', true, true, 'Approve/reject campus edits', 'campus'),
  ('super_admin', 'campus:edit', true, true, 'Submit campus edits', 'campus'),
  ('super_admin', 'meetings:manage', true, true, 'Manage meetings', 'meetings'),
  ('super_admin', 'meetings:view', true, true, 'View all meetings', 'meetings'),
  ('super_admin', 'calendar:write', true, true, 'Edit calendar', 'calendar'),
  ('super_admin', 'calendar:view', true, true, 'View calendar', 'calendar'),
  ('super_admin', 'tasks:assign', true, true, 'Assign tasks', 'tasks'),
  ('super_admin', 'reports:view', true, true, 'View reports', 'admin'),
  ('super_admin', 'users:manage', true, true, 'Manage users', 'admin'),
  ('super_admin', 'automations:manage', true, true, 'Manage automations', 'admin'),
  ('super_admin', 'api:access', true, true, 'API access', 'admin')
on conflict (role, permission_key) do nothing;

-- Seed baseline permissions for DEPT_LEAD
insert into public.role_permissions (role, permission_key, enabled, is_baseline, description, category) values
  ('dept_lead', 'calendar:write', true, true, 'Edit calendar', 'calendar'),
  ('dept_lead', 'calendar:view', true, true, 'View calendar', 'calendar'),
  ('dept_lead', 'tasks:assign', true, true, 'Assign tasks', 'tasks'),
  ('dept_lead', 'reports:view', true, true, 'View reports', 'admin'),
  ('dept_lead', 'automations:manage', true, true, 'Manage automations', 'admin'),
  ('dept_lead', 'users:manage', false, false, 'Manage users (special)', 'admin')
on conflict (role, permission_key) do nothing;

-- Seed baseline permissions for PASTOR
insert into public.role_permissions (role, permission_key, enabled, is_baseline, description, category) values
  ('pastor', 'calendar:view', true, true, 'View calendar', 'calendar'),
  ('pastor', 'tasks:assign', true, true, 'Assign tasks', 'tasks'),
  ('pastor', 'tasks:create', true, true, 'Create tasks', 'tasks'),
  ('pastor', 'meetings:view', true, true, 'View meetings', 'meetings')
on conflict (role, permission_key) do nothing;

-- Seed baseline permissions for ORS
insert into public.role_permissions (role, permission_key, enabled, is_baseline, description, category) values
  ('ors', 'campus:approve', true, true, 'Approve/reject campus edits', 'campus'),
  ('ors', 'campus:edit', true, true, 'Submit campus edits', 'campus'),
  ('ors', 'meetings:manage', true, true, 'Manage meetings', 'meetings'),
  ('ors', 'meetings:view', true, true, 'View all meetings', 'meetings'),
  ('ors', 'calendar:view', true, true, 'View calendar', 'calendar'),
  ('ors', 'reports:view', true, true, 'View reports', 'admin'),
  ('ors', 'users:manage', false, false, 'Manage users (special)', 'admin')
on conflict (role, permission_key) do nothing;

-- Seed baseline permissions for REG_SEC
insert into public.role_permissions (role, permission_key, enabled, is_baseline, description, category) values
  ('reg_sec', 'calendar:view', true, true, 'View calendar', 'calendar'),
  ('reg_sec', 'reports:view', true, true, 'View reports', 'admin'),
  ('reg_sec', 'flock:integrate', true, true, 'Flock integration access', 'integrations')
on conflict (role, permission_key) do nothing;

-- Seed baseline permissions for MEMBER
insert into public.role_permissions (role, permission_key, enabled, is_baseline, description, category) values
  ('member', 'calendar:view', true, true, 'View own calendar', 'calendar'),
  ('member', 'tasks:view', true, true, 'View own tasks', 'tasks'),
  ('member', 'meetings:join', true, true, 'Join meetings', 'meetings')
on conflict (role, permission_key) do nothing;
