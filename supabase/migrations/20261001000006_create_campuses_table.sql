CREATE TABLE IF NOT EXISTS public.campuses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  institution TEXT NOT NULL,
  campus_name_alt TEXT,
  latitude NUMERIC NOT NULL,
  longitude NUMERIC NOT NULL,
  hub TEXT,
  group_name TEXT,
  spotify_playlist_id TEXT,
  status TEXT DEFAULT 'active',
  photo_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_campuses_group_name ON public.campuses(group_name);
CREATE INDEX IF NOT EXISTS idx_campuses_status ON public.campuses(status);
CREATE INDEX IF NOT EXISTS idx_campuses_location ON public.campuses(latitude, longitude);

ALTER TABLE public.campuses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "campuses_read_all"
  ON public.campuses FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "campuses_edit_admin_ors"
  ON public.campuses FOR UPDATE
  TO authenticated
  USING (EXISTS (
    SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('super_admin', 'ors')
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('super_admin', 'ors')
  ));

-- campus_edits: defined in 20260625000011 (guarded) — create here for fresh-DB installs
CREATE TABLE IF NOT EXISTS public.campus_edits (
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

CREATE INDEX IF NOT EXISTS idx_campus_edits_status ON public.campus_edits(status);
CREATE INDEX IF NOT EXISTS idx_campus_edits_campus_id ON public.campus_edits(campus_id);
CREATE INDEX IF NOT EXISTS idx_campus_edits_submitted_by ON public.campus_edits(submitted_by);

ALTER TABLE public.campus_edits ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'campus_edits' AND policyname = 'campus_edits_select_own_or_admin') THEN
    EXECUTE $p$ CREATE POLICY "campus_edits_select_own_or_admin" ON public.campus_edits FOR SELECT TO authenticated
      USING (auth.uid() = submitted_by OR (SELECT role FROM public.users WHERE id = auth.uid()) IN ('super_admin', 'ors')) $p$;
    EXECUTE $p$ CREATE POLICY "campus_edits_insert_authenticated" ON public.campus_edits FOR INSERT TO authenticated
      WITH CHECK (auth.uid() = submitted_by) $p$;
    EXECUTE $p$ CREATE POLICY "campus_edits_update_admin_only" ON public.campus_edits FOR UPDATE TO authenticated
      USING ((SELECT role FROM public.users WHERE id = auth.uid()) IN ('super_admin', 'ors')) $p$;
  END IF;
END
$$;
