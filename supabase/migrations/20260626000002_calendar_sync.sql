-- Add calendar_event_id to meetings table for Phase 2b (Calendar Sync)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='meetings' AND column_name='calendar_event_id'
  ) THEN
    ALTER TABLE meetings ADD COLUMN calendar_event_id TEXT UNIQUE;
    CREATE INDEX idx_meetings_calendar_event_id ON meetings(calendar_event_id) WHERE calendar_event_id IS NOT NULL;
  END IF;
END
$$;

-- Add task_id to meeting_action_items table for Phase 2c (Action Items Bridge)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='meeting_action_items' AND column_name='task_id'
  ) THEN
    ALTER TABLE meeting_action_items ADD COLUMN task_id TEXT UNIQUE;
    CREATE INDEX idx_action_items_task_id ON meeting_action_items(task_id) WHERE task_id IS NOT NULL;
  END IF;
END
$$;

-- ============================================================================
-- RLS Policy: Allow users to link action items to tasks
-- Guard: org_members table is not created by any migration (pre-existing on production)
-- ============================================================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables WHERE table_name = 'org_members'
  ) THEN RETURN; END IF;

  DROP POLICY IF EXISTS "ORS can link action items to tasks" ON meeting_action_items;
  EXECUTE $p$
    CREATE POLICY "ORS can link action items to tasks"
      ON meeting_action_items FOR UPDATE
      USING (EXISTS (SELECT 1 FROM org_members WHERE org_members.user_id = auth.uid() AND org_members.role = 'organizational_rep_secretary'))
      WITH CHECK (EXISTS (SELECT 1 FROM org_members WHERE org_members.user_id = auth.uid() AND org_members.role = 'organizational_rep_secretary'))
  $p$;
END
$$;
