-- Allow the Programs team to manage calendar category visibility.
-- The original policy (20260930000000) only permits super_admin to read/write
-- calendar_category_visibility. The Category Visibility config UI is also used by
-- the Programs team (any member of the Programs department), so they need access.
--
-- Guard: calendar_category_visibility is created in 20260930000004 (one migration later).
-- The is_programs_team() helper is safe to create here; the policy is deferred.

CREATE OR REPLACE FUNCTION public.is_programs_team()
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.users u
    JOIN public.departments d ON d.id = u.department_id
    WHERE u.id = auth.uid()
      AND lower(d.name) = 'programs'
  );
$$;

COMMENT ON FUNCTION public.is_programs_team() IS
  'True when the current user belongs to the Programs department. Used by category visibility RLS.';

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'calendar_category_visibility'
  ) THEN RETURN; END IF;

  DROP POLICY IF EXISTS "visibility_programs_team_all" ON public.calendar_category_visibility;
  EXECUTE $p$
    CREATE POLICY "visibility_programs_team_all"
      ON public.calendar_category_visibility
      USING (public.is_programs_team())
      WITH CHECK (public.is_programs_team())
  $p$;
END
$$;
