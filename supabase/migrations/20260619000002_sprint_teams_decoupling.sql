-- ============================================================================
-- Sprint Teams Decoupling Migration
-- Decouple sprint teams from spaces with optional sprint assignment
-- ============================================================================

-- Step 1: Alter sprint_teams table to support independent teams
-- Make sprint_id nullable (allows teams without sprints)
ALTER TABLE sprint_teams
ALTER COLUMN sprint_id DROP NOT NULL;

-- Add source_space_id to track teams created from spaces
-- NOTE: "spaces" = public.departments (see 20260618000000_spaces.sql — "Departments ARE spaces")
ALTER TABLE sprint_teams
ADD COLUMN source_space_id uuid REFERENCES public.departments(id) ON DELETE SET NULL;

-- Add is_archived for soft deletes (prefer over hard delete)
ALTER TABLE sprint_teams
ADD COLUMN is_archived boolean DEFAULT false;

-- Add created_by for audit trail
ALTER TABLE sprint_teams
ADD COLUMN created_by uuid REFERENCES users(id);

-- Create indexes for new columns
CREATE INDEX idx_sprint_teams_source_space ON sprint_teams(source_space_id);
CREATE INDEX idx_sprint_teams_is_archived ON sprint_teams(is_archived);
CREATE INDEX idx_sprint_teams_created_by ON sprint_teams(created_by);

-- ============================================================================
-- Step 2: sprint_team_members — SUPERSEDED by 20260620000000_sprint_system_hardening.sql
-- That migration defines the correct schema (sprint_id, sprint_team_id, user_id).
-- Skipped here to avoid schema conflict on fresh-DB installs.
-- ============================================================================

-- ============================================================================
-- Step 4: Update RLS on sprint_teams table
-- ============================================================================

-- Read Policy: Users can read teams (existing organizations)
CREATE POLICY "Users can read all teams" ON sprint_teams
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.id = auth.uid()
      AND u.status = 'active'
    )
  );

-- Create Policy: Users can create independent teams
CREATE POLICY "Users can create teams" ON sprint_teams
  FOR INSERT
  WITH CHECK (
    auth.uid() = created_by
  );

-- Update Policy: Creators can update their teams
CREATE POLICY "Creators can update their teams" ON sprint_teams
  FOR UPDATE
  USING (
    created_by = auth.uid()
  );

-- Delete Policy: Creators can archive their teams
CREATE POLICY "Creators can archive teams" ON sprint_teams
  FOR DELETE
  USING (
    created_by = auth.uid()
  );
