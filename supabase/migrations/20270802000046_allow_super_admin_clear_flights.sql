-- Allow super_admin to update flight data in registrations table
-- Guard: registrations table is pre-existing on production (not in migration history)
do $$
begin
  if not exists (
    select 1 from information_schema.tables where table_name = 'registrations'
  ) then
    return;
  end if;

  if not exists (select 1 from pg_policies where policyname = 'super_admin_update_flights' and tablename = 'registrations') then
    execute $p$
      create policy "super_admin_update_flights" on registrations
        for update to authenticated
        using (current_user_role() = 'super_admin'::text)
        with check (current_user_role() = 'super_admin'::text)
    $p$;
  end if;
end $$;
