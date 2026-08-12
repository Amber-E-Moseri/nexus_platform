# Demo Authentication Setup

Before running `supabase db reset`, you must create demo users in the Supabase auth schema. These auth records must exist so the `public.users` table can reference them.

## Step 1: Create Demo Users in Supabase

1. Open [Supabase Dashboard](https://app.supabase.com/) → select project `vohkcvivxnkkuwvwtqzm`
2. Navigate to **SQL Editor**
3. Run this SQL to create auth users:

```sql
-- Create demo auth users
-- Note: Supabase auth.users requires encrypted passwords via bcrypt
-- The password 'Demo123!@#' is hashed here

INSERT INTO auth.users (
  id, email, encrypted_password, email_confirmed_at, 
  raw_user_meta_data, created_at, updated_at, aud, role
) VALUES
  (
    '11111111-1111-1111-1111-111111111111',
    'maya@virtualllaunch.app',
    crypt('Demo123!@#', gen_salt('bf')),
    NOW(),
    '{"name": "Maya", "role": "super_admin"}',
    NOW(),
    NOW(),
    'authenticated',
    'authenticated'
  ),
  (
    '22222222-2222-2222-2222-222222222222',
    'alex@virtualllaunch.app',
    crypt('Demo123!@#', gen_salt('bf')),
    NOW(),
    '{"name": "Alex Chen", "role": "dept_lead"}',
    NOW(),
    NOW(),
    'authenticated',
    'authenticated'
  ),
  (
    '33333333-3333-3333-3333-333333333333',
    'jordan@virtualllaunch.app',
    crypt('Demo123!@#', gen_salt('bf')),
    NOW(),
    '{"name": "Jordan Smith", "role": "member"}',
    NOW(),
    NOW(),
    'authenticated',
    'authenticated'
  ),
  (
    '44444444-4444-4444-4444-444444444444',
    'casey@virtualllaunch.app',
    crypt('Demo123!@#', gen_salt('bf')),
    NOW(),
    '{"name": "Casey Lee", "role": "member"}',
    NOW(),
    NOW(),
    'authenticated',
    'authenticated'
  ),
  (
    '55555555-5555-5555-5555-555555555555',
    'sam@virtualllaunch.app',
    crypt('Demo123!@#', gen_salt('bf')),
    NOW(),
    '{"name": "Sam Rodriguez", "role": "member"}',
    NOW(),
    NOW(),
    'authenticated',
    'authenticated'
  ),
  (
    '66666666-6666-6666-6666-666666666666',
    'aria@virtualllaunch.app',
    crypt('Demo123!@#', gen_salt('bf')),
    NOW(),
    '{"name": "Aria Patel", "role": "dept_lead"}',
    NOW(),
    NOW(),
    'authenticated',
    'authenticated'
  ),
  (
    '77777777-7777-7777-7777-777777777777',
    'morgan@virtualllaunch.app',
    crypt('Demo123!@#', gen_salt('bf')),
    NOW(),
    '{"name": "Morgan Davis", "role": "member"}',
    NOW(),
    NOW(),
    'authenticated',
    'authenticated'
  ),
  (
    '88888888-8888-8888-8888-888888888888',
    'blake@virtualllaunch.app',
    crypt('Demo123!@#', gen_salt('bf')),
    NOW(),
    '{"name": "Blake Taylor", "role": "member"}',
    NOW(),
    NOW(),
    'authenticated',
    'authenticated'
  ),
  (
    '99999999-9999-9999-9999-999999999999',
    'quinn@virtualllaunch.app',
    crypt('Demo123!@#', gen_salt('bf')),
    NOW(),
    '{"name": "Quinn Adams", "role": "dept_lead"}',
    NOW(),
    NOW(),
    'authenticated',
    'authenticated'
  ),
  (
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    'reese@virtualllaunch.app',
    crypt('Demo123!@#', gen_salt('bf')),
    NOW(),
    '{"name": "Reese Mitchell", "role": "member"}',
    NOW(),
    NOW(),
    'authenticated',
    'authenticated'
  ),
  (
    'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
    'tori@virtualllaunch.app',
    crypt('Demo123!@#', gen_salt('bf')),
    NOW(),
    '{"name": "Tori Williamson", "role": "dept_lead"}',
    NOW(),
    NOW(),
    'authenticated',
    'authenticated'
  ),
  (
    'cccccccc-cccc-cccc-cccc-cccccccccccc',
    'vance@virtualllaunch.app',
    crypt('Demo123!@#', gen_salt('bf')),
    NOW(),
    '{"name": "Vance Thompson", "role": "member"}',
    NOW(),
    NOW(),
    'authenticated',
    'authenticated'
  ),
  (
    'dddddddd-dddd-dddd-dddd-dddddddddddd',
    'yuki@virtualllaunch.app',
    crypt('Demo123!@#', gen_salt('bf')),
    NOW(),
    '{"name": "Yuki Tanaka", "role": "dept_lead"}',
    NOW(),
    NOW(),
    'authenticated',
    'authenticated'
  ),
  (
    'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee',
    'zara@virtualllaunch.app',
    crypt('Demo123!@#', gen_salt('bf')),
    NOW(),
    '{"name": "Zara Hassan", "role": "member"}',
    NOW(),
    NOW(),
    'authenticated',
    'authenticated'
  )
ON CONFLICT (id) DO NOTHING;

-- Verify creation
SELECT id, email FROM auth.users WHERE email LIKE '%virtualllaunch.app%';
```

## Step 2: Create Identities (Required by Supabase Auth)

Each auth.users record needs at least one identity entry. Run this SQL:

```sql
-- Create identities for each demo user
INSERT INTO auth.identities (
  id, user_id, identity_data, provider, provider_id, 
  last_sign_in_at, created_at, updated_at
)
SELECT
  gen_random_uuid(), id,
  jsonb_build_object('sub', id::text, 'email', email),
  'email', email,
  NULL, NOW(), NOW()
FROM auth.users
WHERE email LIKE '%virtualllaunch.app%'
ON CONFLICT DO NOTHING;

-- Verify
SELECT user_id, provider, provider_id FROM auth.identities 
WHERE provider_id LIKE '%virtualllaunch.app%';
```

## Step 3: Run Database Reset

Now that auth users exist, run the seed:

```bash
cd ~/Downloads/nexus_demo/nexus-public-demo
supabase db reset
```

This will:
1. Run all migrations (including the fixed 643-chain)
2. Load `supabase/seed.sql` to populate demo data
3. Create all 14 demo users in `public.users` table

## Step 4: Test Login Locally

```bash
npm run dev
```

Visit `http://localhost:5173` and try these credentials:

| Email | Password | Role |
|---|---|---|
| `maya@virtualllaunch.app` | `Demo123!@#` | Super Admin |
| `alex@virtualllaunch.app` | `Demo123!@#` | Dept Lead (Social) |
| `aria@virtualllaunch.app` | `Demo123!@#` | Dept Lead (Brand) |
| `jordan@virtualllaunch.app` | `Demo123!@#` | Member (Social) |
| `morgan@virtualllaunch.app` | `Demo123!@#` | Member (Design) |

All 14 users share the same password: `Demo123!@#`

## Troubleshooting

**"User not found" after login**
- Verify auth.users were created: run `SELECT COUNT(*) FROM auth.users WHERE email LIKE '%virtualllaunch.app%';` — should show 14
- Verify identities exist: run `SELECT COUNT(*) FROM auth.identities WHERE provider_id LIKE '%virtualllaunch.app%';` — should show 14

**"relation public.users does not exist"**
- Migrations didn't run. Run `supabase db reset` to apply them.

**Seed data not loaded**
- Check `supabase db reset` output for SQL errors
- Verify UUIDs in seed.sql match the auth users created above

**Tasks/meetings don't appear**
- Department IDs may differ in your schema. seed.sql queries departments by name (Admin, Media, ORS, Pastors, PFCC) — verify these exist in your fresh DB via `SELECT name FROM public.departments;`
