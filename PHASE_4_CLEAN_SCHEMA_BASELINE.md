# Phase 4: Clean Schema Baseline — Portfolio-Grade Database

**Status**: Planning (starts after Phase 3)

**Goal**: Replace 248 messy production migrations with a clean, generated schema that showcases architecture and RLS design without operational history.

## The Problem

Current state: 248 migrations in `supabase/migrations/`

These contain:
- Specific fixes for named individuals ("fix Pastor X's meeting visibility")
- Operational history ("backfill attendance for event Y")
- Real people's names and UUIDs
- Organization-specific logic
- Incremental schema adjustments that obscure the actual design

**Recruiters should see**: "Here's how this person designs databases and RLS."
**Recruiters should not see**: "Here's the story of production incidents and fixes."

## Solution: Generated Schema Baseline

Replace with 3-4 canonical schema files generated from the current live schema:

```
supabase/schema/
  001_core_tables.sql      # All table definitions (no data)
  002_rls_policies.sql     # All RLS policies
  003_functions_types.sql  # Custom types, functions, stored procs
  004_demo_seed.sql        # Demo data (already exists as seed.sql)
```

### Structure of 001_core_tables.sql

```sql
-- ============================================================================
-- NEXUS CORE SCHEMA
-- ============================================================================
-- Clean baseline generated from production schema.
-- This file contains all table definitions required for the Nexus platform.
-- Organization-specific tables and columns are omitted.

-- Users & Authentication
CREATE TABLE IF NOT EXISTS public.users (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name text NOT NULL,
  email text NOT NULL UNIQUE,
  role text NOT NULL DEFAULT 'member' CHECK (role IN (...)),
  department_id uuid REFERENCES public.departments(id),
  status text NOT NULL DEFAULT 'active',
  -- ... other columns
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Organization Structure
CREATE TABLE IF NOT EXISTS public.departments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.sprints (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text,
  status text NOT NULL DEFAULT 'planning' CHECK (status IN (...)),
  start_date date,
  end_date date,
  created_by uuid REFERENCES public.users(id),
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Task Management (Core PM)
CREATE TABLE IF NOT EXISTS public.folders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  department_id uuid NOT NULL REFERENCES public.departments(id) ON DELETE CASCADE,
  created_by uuid REFERENCES public.users(id),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.lists (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  folder_id uuid NOT NULL REFERENCES public.folders(id) ON DELETE CASCADE,
  created_by uuid REFERENCES public.users(id),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.tasks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text,
  list_id uuid REFERENCES public.lists(id) ON DELETE SET NULL,
  sprint_id uuid REFERENCES public.sprints(id) ON DELETE SET NULL,
  status_id uuid REFERENCES public.task_status_definitions(id),
  priority text NOT NULL DEFAULT 'medium' CHECK (priority IN (...)),
  assignee_id uuid REFERENCES public.users(id),
  due_date date,
  is_personal boolean NOT NULL DEFAULT false,
  created_by uuid REFERENCES public.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.task_comments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id uuid NOT NULL REFERENCES public.tasks(id) ON DELETE CASCADE,
  author_id uuid REFERENCES public.users(id),
  body text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Meetings
CREATE TABLE IF NOT EXISTS public.meetings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  date timestamptz NOT NULL,
  meeting_type text NOT NULL DEFAULT 'general',
  department_id uuid REFERENCES public.departments(id),
  created_by uuid REFERENCES public.users(id),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.meeting_attendance (
  meeting_id uuid NOT NULL REFERENCES public.meetings(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'present' CHECK (status IN (...)),
  PRIMARY KEY (meeting_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.meeting_minutes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  meeting_id uuid NOT NULL UNIQUE REFERENCES public.meetings(id) ON DELETE CASCADE,
  created_by uuid NOT NULL REFERENCES public.users(id),
  summary text,
  status text NOT NULL DEFAULT 'draft' CHECK (status IN (...)),
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Email Campaigns (Comms)
CREATE TABLE IF NOT EXISTS public.communication_campaigns (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  subject text NOT NULL,
  body text NOT NULL,
  status text NOT NULL DEFAULT 'draft',
  created_by uuid REFERENCES public.users(id),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.campaign_recipients (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id uuid NOT NULL REFERENCES public.communication_campaigns(id) ON DELETE CASCADE,
  email text NOT NULL,
  status text NOT NULL DEFAULT 'pending',
  sent_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Calendar Integration
CREATE TABLE IF NOT EXISTS public.calendar_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text,
  event_date timestamptz NOT NULL,
  event_type text NOT NULL DEFAULT 'event',
  department_id uuid REFERENCES public.departments(id),
  created_by uuid REFERENCES public.users(id),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.calendar_rsvps (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id uuid NOT NULL REFERENCES public.calendar_events(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN (...)),
  created_at timestamptz NOT NULL DEFAULT now()
);

-- ... (more tables as needed)

-- Indexes for common queries
CREATE INDEX IF NOT EXISTS idx_tasks_list_id ON public.tasks(list_id);
CREATE INDEX IF NOT EXISTS idx_tasks_sprint_id ON public.tasks(sprint_id);
CREATE INDEX IF NOT EXISTS idx_tasks_assignee_id ON public.tasks(assignee_id);
CREATE INDEX IF NOT EXISTS idx_meetings_department_id ON public.meetings(department_id);
CREATE INDEX IF NOT EXISTS idx_calendar_events_department_id ON public.calendar_events(department_id);
```

### Structure of 002_rls_policies.sql

```sql
-- ============================================================================
-- ROW LEVEL SECURITY POLICIES
-- ============================================================================
-- All tables have RLS enabled. Policies enforce multi-tenant isolation
-- based on department membership and role.

-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meetings ENABLE ROW LEVEL SECURITY;
-- ... etc

-- Helper functions used by policies
CREATE OR REPLACE FUNCTION public.current_user_role()
  RETURNS text
  LANGUAGE sql
  STABLE
AS $$
  SELECT 
    COALESCE(
      auth.jwt() ->> 'user_role',
      (SELECT role FROM public.users WHERE id = auth.uid())
    )
$$;

CREATE OR REPLACE FUNCTION public.current_user_department()
  RETURNS uuid
  LANGUAGE sql
  STABLE
AS $$
  SELECT 
    COALESCE(
      (auth.jwt() ->> 'user_department_id')::uuid,
      (SELECT department_id FROM public.users WHERE id = auth.uid())
    )
$$;

-- Task RLS: Users see their department's tasks and personal tasks
CREATE POLICY "tasks_select_own_department" ON public.tasks
  FOR SELECT USING (
    department_id = public.current_user_department()
    OR created_by = auth.uid()
    OR is_personal = true AND created_by = auth.uid()
  );

CREATE POLICY "tasks_insert" ON public.tasks
  FOR INSERT WITH CHECK (created_by = auth.uid());

-- ... (more policies)

-- Meeting RLS: Users see their department's meetings
CREATE POLICY "meetings_select" ON public.meetings
  FOR SELECT USING (
    department_id = public.current_user_department()
    OR department_id IS NULL  -- Org-wide meetings
  );

-- ... (more policies)
```

### Structure of 003_functions_types.sql

```sql
-- ============================================================================
-- CUSTOM TYPES & STORED PROCEDURES
-- ============================================================================

-- Custom types
CREATE TYPE public.task_priority AS ENUM ('urgent', 'high', 'medium', 'low');
CREATE TYPE public.attendance_status AS ENUM ('present', 'absent', 'excused');
CREATE TYPE public.campaign_status AS ENUM ('draft', 'scheduled', 'sent', 'archived');

-- Stored procedures for complex operations
CREATE OR REPLACE FUNCTION public.assign_task(
  p_task_id uuid,
  p_assignee_id uuid
)
  RETURNS void
  LANGUAGE plpgsql
  SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.tasks
  SET assignee_id = p_assignee_id, updated_at = now()
  WHERE id = p_task_id
    AND (auth.uid() = created_by OR public.current_user_role() = 'admin');
END;
$$;

-- ... (more stored procedures)
```

## Migration Strategy

### Step 1: Generate Clean Schema Files

From current live database:

```bash
# Export current schema WITHOUT data
pg_dump \
  --schema-only \
  --no-owner \
  --no-privileges \
  --no-extensions \
  $SUPABASE_DB_URL > supabase/schema/001_core_tables.sql

# Extract RLS policies
pg_dump \
  --schema-only \
  --no-owner \
  $SUPABASE_DB_URL | \
  grep -A 50 "CREATE POLICY" > supabase/schema/002_rls_policies.sql

# Extract functions/types
pg_dump \
  --schema-only \
  --no-owner \
  $SUPABASE_DB_URL | \
  grep -E "CREATE (TYPE|FUNCTION|PROCEDURE)" > supabase/schema/003_functions_types.sql
```

### Step 2: Clean Generated Files

Edit each schema file to:
- Remove any hardcoded UUIDs or organization-specific references
- Remove any comments containing people's names or operational details
- Add clear section headers and documentation
- Ensure idempotency (`CREATE OR REPLACE`, `IF NOT EXISTS`)

### Step 3: Update Documentation

Create `docs/DATABASE_DESIGN.md`:

```markdown
# Database Design

## Architecture Overview
[Explain the schema structure and design decisions]

## Row-Level Security
[Explain how RLS enforces multi-tenancy and data isolation]

## Key Tables
[Describe each major table and its relationships]

## Indexing Strategy
[Explain indexes and query optimization patterns]
```

### Step 4: Remove Old Migrations

Once schema files are tested and verified:

```bash
# Archive old migrations (keep for reference if needed)
git rm supabase/migrations/202606*.sql
git rm supabase/migrations/202607*.sql
# ... etc

# Commit the clean schema
git add supabase/schema/
git commit -m "chore(schema): replace 248 production migrations with clean baseline"
```

### Step 5: Update Database Initialization

Update `supabase/config.toml` or equivalent to:
1. Load schema files instead of migrations
2. Run demo seed data
3. Initialize RLS policies

## What Recruiters See

**Before**: "248 migrations dating back 18 months with operational history"
**After**: "Clean schema showcase demonstrating:
- Multi-tenant architecture via RLS
- Thoughtful indexing strategy
- Separation of concerns (tables, policies, functions)
- Role-based access control implementation"

## What's NOT Visible

- ✅ Removed: Specific operational fixes and incidents
- ✅ Removed: Personal names and details
- ✅ Removed: Real people's email addresses
- ✅ Removed: Organization-specific business rules embedded in schema
- ✅ Kept: Database architecture and RLS patterns

## Success Criteria

After Phase 4:
- ✅ `supabase/migrations/` contains only 004+ (if any new migrations needed)
- ✅ Schema baseline in `supabase/schema/001-003.sql`
- ✅ Demo seed in `supabase/seed.sql`
- ✅ `supabase db reset` works with new schema
- ✅ All data integration tests pass
- ✅ No hardcoded UUIDs, names, or operational details in schema files
- ✅ Database design documented in `docs/DATABASE_DESIGN.md`
