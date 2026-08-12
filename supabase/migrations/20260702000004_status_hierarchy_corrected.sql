-- Migration: Two-tier status hierarchy with CORRECTED canonical IDs
-- Run this AFTER 20260702000003_status_hierarchy_reset.sql
-- FIXED for fresh-DB installs: uses legacy_key/category matching instead of hardcoded production UUIDs

BEGIN;

-- 1. Ensure schema columns exist
DO $$
BEGIN
  BEGIN
    ALTER TABLE public.task_status_definitions
    ADD COLUMN org_status_id UUID REFERENCES public.task_status_definitions(id) ON DELETE RESTRICT;
  EXCEPTION WHEN duplicate_column THEN NULL;
  END;
  BEGIN
    ALTER TABLE public.task_status_definitions
    ADD COLUMN is_org_status BOOLEAN NOT NULL DEFAULT false;
  EXCEPTION WHEN duplicate_column THEN NULL;
  END;
END $$;

-- 2. Mark the org-wide statuses (department_id IS NULL) as canonical
UPDATE public.task_status_definitions
SET is_org_status = true
WHERE department_id IS NULL;

-- 3a. Map dept-specific statuses to their org parents by exact legacy_key match
UPDATE public.task_status_definitions dept_status
SET org_status_id = (
  SELECT org.id
  FROM public.task_status_definitions org
  WHERE org.is_org_status = true
    AND org.legacy_key = dept_status.legacy_key
  LIMIT 1
)
WHERE is_org_status = false
  AND department_id IS NOT NULL
  AND legacy_key IS NOT NULL;

-- 3b. For remaining unmapped dept statuses (no legacy_key or no exact match),
--     map by name heuristics + category fallback
UPDATE public.task_status_definitions dept_status
SET org_status_id = (
  SELECT org.id
  FROM public.task_status_definitions org
  WHERE org.is_org_status = true
    AND org.legacy_key = (
      CASE
        WHEN dept_status.category = 'open'       THEN 'backlog'
        WHEN dept_status.category = 'completed'  THEN 'done'
        WHEN dept_status.category = 'cancelled'  THEN 'cancelled'
        WHEN dept_status.category = 'in_progress'
          AND dept_status.name ILIKE '%review%'  THEN 'review'
        WHEN dept_status.category = 'in_progress'
          AND dept_status.name ILIKE '%blocked%' THEN 'blocked'
        WHEN dept_status.category = 'in_progress' THEN 'in_progress'
        ELSE NULL
      END
    )
  LIMIT 1
)
WHERE is_org_status = false
  AND department_id IS NOT NULL
  AND org_status_id IS NULL;

-- 4. Verify all non-org statuses now have a mapping
DO $$
DECLARE
  unmapped_count INT;
BEGIN
  SELECT COUNT(*) INTO unmapped_count FROM public.task_status_definitions
  WHERE is_org_status = false AND org_status_id IS NULL;

  IF unmapped_count > 0 THEN
    RAISE EXCEPTION 'Unmapped statuses found: %. Please review the mapping logic.', unmapped_count;
  END IF;
END $$;

-- 5. Drop existing constraints if present
ALTER TABLE public.task_status_definitions DROP CONSTRAINT IF EXISTS org_status_required_for_custom;
ALTER TABLE public.task_status_definitions DROP CONSTRAINT IF EXISTS task_status_definitions_hierarchy_check;

-- 6. Add CHECK constraint to enforce hierarchy
ALTER TABLE public.task_status_definitions
ADD CONSTRAINT org_status_required_for_custom
  CHECK (
    (is_org_status = true AND org_status_id IS NULL)
    OR
    (is_org_status = false AND org_status_id IS NOT NULL)
  );

-- 7. Final verification - display summary
DO $$
DECLARE
  org_count INT;
  dept_count INT;
  orphaned_count INT;
BEGIN
  SELECT COUNT(*) INTO org_count FROM public.task_status_definitions WHERE is_org_status = true;
  SELECT COUNT(*) INTO dept_count FROM public.task_status_definitions WHERE is_org_status = false AND org_status_id IS NOT NULL;
  SELECT COUNT(*) INTO orphaned_count FROM public.task_status_definitions WHERE is_org_status = false AND org_status_id IS NULL;

  RAISE NOTICE 'Migration Summary:';
  RAISE NOTICE '  Org statuses: %', org_count;
  RAISE NOTICE '  Dept statuses (with parent): %', dept_count;
  RAISE NOTICE '  Orphaned statuses: %', orphaned_count;

  IF orphaned_count > 0 THEN
    RAISE EXCEPTION 'Orphaned statuses detected! Migration failed.';
  END IF;
END $$;

COMMIT;
