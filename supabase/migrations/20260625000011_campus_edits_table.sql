-- Campus edits table: tracks pending/approved/rejected changes to campus data
-- Two-phase workflow: users submit → ORS reviews and approves
--
-- NOTE: public.campuses is created in 20261001000006_create_campuses_table.sql.
-- On a fresh DB this migration is a no-op; campus_edits is created in 20261001000006.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'campuses'
  ) THEN
    RETURN;
  END IF;

  -- Table may already exist (created by 20261001000006 on fresh DBs)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'campus_edits'
  ) THEN
    CREATE TABLE public.campus_edits (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      campus_id uuid NOT NULL REFERENCES public.campuses(id) ON DELETE CASCADE,
      field_name text NOT NULL,
      old_value text,
      new_value text NOT NULL,
      submitted_by uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
      submitted_at timestamptz DEFAULT now(),
      status text NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'approved', 'rejected')),
      reviewed_by uuid REFERENCES auth.users(id),
      reviewed_at timestamptz,
      notes text,
      created_at timestamptz DEFAULT now()
    );

    CREATE INDEX idx_campus_edits_status ON public.campus_edits(status);
    CREATE INDEX idx_campus_edits_campus_id ON public.campus_edits(campus_id);
    CREATE INDEX idx_campus_edits_submitted_by ON public.campus_edits(submitted_by);

    ALTER TABLE public.campus_edits ENABLE ROW LEVEL SECURITY;

    EXECUTE $p$ CREATE POLICY "campus_edits_select_own_or_admin" ON public.campus_edits FOR SELECT TO authenticated
      USING (auth.uid() = submitted_by OR (SELECT role FROM public.users WHERE id = auth.uid()) IN ('super_admin', 'ors')) $p$;
    EXECUTE $p$ CREATE POLICY "campus_edits_insert_authenticated" ON public.campus_edits FOR INSERT TO authenticated
      WITH CHECK (auth.uid() = submitted_by) $p$;
    EXECUTE $p$ CREATE POLICY "campus_edits_update_admin_only" ON public.campus_edits FOR UPDATE TO authenticated
      USING ((SELECT role FROM public.users WHERE id = auth.uid()) IN ('super_admin', 'ors')) $p$;
  END IF;
END
$$;
