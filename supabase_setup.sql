-- Run this in the Supabase SQL editor (Project > SQL Editor) once,
-- after creating the project. Sets up the `posts` table, row-level
-- security so users only see their own posts, and the storage bucket
-- used for uploaded images.

-- 1. Table
create table if not exists public.posts (
  id             uuid primary key default gen_random_uuid(),
  owner_uid      uuid not null references auth.users(id) on delete cascade,
  title          text not null,
  description    text not null default '',
  image_url      text,
  latitude       double precision,
  longitude      double precision,
  location_label text,
  created_at     timestamptz not null default now()
);

-- 2. Row Level Security — a user can only read/write their own posts.
alter table public.posts enable row level security;

create policy "Users can view their own posts"
  on public.posts for select
  using (auth.uid() = owner_uid);

create policy "Users can insert their own posts"
  on public.posts for insert
  with check (auth.uid() = owner_uid);

create policy "Users can update their own posts"
  on public.posts for update
  using (auth.uid() = owner_uid);

create policy "Users can delete their own posts"
  on public.posts for delete
  using (auth.uid() = owner_uid);

-- 3. Realtime — required for DatabaseService.watchMyPosts() to stream.
alter publication supabase_realtime add table public.posts;

-- 4. Storage bucket for post images (create via SQL or Dashboard >
-- Storage > New Bucket). Public-read so the app can use getPublicUrl()
-- directly; switch to private + createSignedUrl() if you need stricter
-- access control.
insert into storage.buckets (id, name, public)
values ('post-images', 'post-images', true)
on conflict (id) do nothing;

create policy "Users can upload to their own folder"
  on storage.objects for insert
  with check (
    bucket_id = 'post-images'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "Anyone can read post images"
  on storage.objects for select
  using (bucket_id = 'post-images');
