-- Communication Campaign Attachments: Storage & Metadata

-- 1. Add attachments column to communication_campaigns
-- Guard: table is created in 20260721000001; on fresh DB this is a no-op
do $$
begin
  if exists (
    select 1 from information_schema.tables
    where table_schema = 'public' and table_name = 'communication_campaigns'
  ) then
    if not exists (
      select 1 from information_schema.columns
      where table_schema = 'public'
        and table_name = 'communication_campaigns'
        and column_name = 'attachments'
    ) then
      alter table public.communication_campaigns
        add column attachments jsonb not null default '[]'::jsonb;
    end if;

    comment on column public.communication_campaigns.attachments is
      'Array of attachment objects: {filename: string, storage_path: string, size: integer, mime_type: string, public_url: string}';
  end if;
end
$$;

-- 2. Create communication-attachments storage bucket
insert into storage.buckets (id, name, public)
  values ('communication-attachments', 'communication-attachments', true)
  on conflict (id) do nothing;

-- 3. RLS Policies for communication-attachments bucket
drop policy if exists "authenticated_users_can_upload_campaign_attachments" on storage.objects;
create policy "authenticated_users_can_upload_campaign_attachments"
  on storage.objects
  for insert
  to authenticated
  with check (bucket_id = 'communication-attachments');

drop policy if exists "authenticated_users_can_delete_campaign_attachments" on storage.objects;
create policy "authenticated_users_can_delete_campaign_attachments"
  on storage.objects
  for delete
  to authenticated
  using (bucket_id = 'communication-attachments');

drop policy if exists "public_can_read_campaign_attachments" on storage.objects;
create policy "public_can_read_campaign_attachments"
  on storage.objects
  for select
  to public
  using (bucket_id = 'communication-attachments');
