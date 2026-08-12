-- Add 'ors' role support
-- NOTE: users.role is a TEXT column, not a Postgres enum type.
-- No schema change needed — text columns accept any value including 'ors'.
-- The ALTER TYPE user_role from the original migration is a no-op here.
DO $$ BEGIN NULL; END $$;
