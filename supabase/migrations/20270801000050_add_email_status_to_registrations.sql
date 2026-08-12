-- Add email_status tracking to registrations
-- Guard: registrations table is pre-existing on production (not in migration history)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_name = 'registrations'
  ) THEN RETURN; END IF;

  ALTER TABLE registrations ADD COLUMN IF NOT EXISTS email_status TEXT
    DEFAULT 'not_registered'
    CHECK (email_status IN ('not_registered', 'confirming', 'confirmed'));

  CREATE INDEX IF NOT EXISTS idx_registrations_email_status ON registrations(email_status);
END
$$;
