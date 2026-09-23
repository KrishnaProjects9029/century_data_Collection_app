-- ============================================================
-- KRISHNA CENTURY DATA APP — SUPABASE POSTGRESQL SCHEMA
-- Run this script in: Supabase Dashboard -> SQL Editor -> New Query -> Run
-- ============================================================

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- ============================================================
-- 1. PROFILES TABLE (Stores user info and role)
-- ============================================================
create table if not exists public.profiles (
    id uuid references auth.users(id) on delete cascade primary key,
    name text not null,
    email text not null,
    role text not null check (role in ('ADMIN', 'DATA_ENTRY')) default 'DATA_ENTRY',
    is_active boolean not null default true,
    created_at timestamptz not null default timezone('utc'::text, now())
);

-- Enable RLS on profiles
alter table public.profiles enable row level security;

-- ============================================================
-- 2. HELPER FUNCTIONS FOR ROW LEVEL SECURITY (RLS)
-- ============================================================
create or replace function public.is_admin()
returns boolean security definer
set search_path = public
language plpgsql as $$
begin
  return exists (
    select 1 from public.profiles
    where id = auth.uid()
      and role = 'ADMIN'
      and is_active = true
  );
end;
$$;

create or replace function public.is_active_user()
returns boolean security definer
set search_path = public
language plpgsql as $$
begin
  return exists (
    select 1 from public.profiles
    where id = auth.uid()
      and is_active = true
  );
end;
$$;

-- Profiles Policies
create policy "Users can read own profile"
    on public.profiles for select
    to authenticated
    using (auth.uid() = id or public.is_admin());

create policy "Admins can insert profiles"
    on public.profiles for insert
    to authenticated
    with check (public.is_admin() or auth.uid() = id);

create policy "Admins can update profiles"
    on public.profiles for update
    to authenticated
    using (public.is_admin() or auth.uid() = id);

-- ============================================================
-- 3. STUDENTS TABLE (Stores student registration records)
-- ============================================================
create table if not exists public.students (
    id uuid primary key default gen_random_uuid(),
    serial_number bigserial unique not null,
    first_name text not null,
    middle_name text default '',
    surname text not null,
    school_name text not null,
    sibling_class text default '',
    parents text not null,
    mother_contact text default '',
    father_contact text default '',
    full_address text not null,
    area text not null,
    other_area text default '',
    landmark text not null,
    other_landmark text default '',
    photo_url text default '',
    maker_user_id uuid not null references auth.users(id) on delete restrict,
    maker_name text not null,
    submitted_at timestamptz not null default timezone('utc'::text, now()),
    updated_at timestamptz,
    updated_by text default '',
    is_deleted boolean not null default false
);

-- Enable RLS on students
alter table public.students enable row level security;

-- Indexes for lightning-fast search and filter queries
create index if not exists idx_students_serial on public.students(serial_number desc);
create index if not exists idx_students_maker on public.students(maker_user_id);
create index if not exists idx_students_submitted_at on public.students(submitted_at desc);
create index if not exists idx_students_area on public.students(area);
create index if not exists idx_students_landmark on public.students(landmark);
create index if not exists idx_students_parents on public.students(parents);
create index if not exists idx_students_is_deleted on public.students(is_deleted);
create index if not exists idx_students_search on public.students(first_name, surname, school_name);

-- Students Policies
create policy "Admins can view all non-deleted students"
    on public.students for select
    to authenticated
    using (public.is_admin());

create policy "Data entry users can view only their own records"
    on public.students for select
    to authenticated
    using (
        auth.uid() = maker_user_id
        and is_deleted = false
        and public.is_active_user()
    );

create policy "Active users can insert student records"
    on public.students for insert
    to authenticated
    with check (
        auth.uid() = maker_user_id
        and public.is_active_user()
    );

create policy "Admins can update student records"
    on public.students for update
    to authenticated
    using (public.is_admin());

create policy "Admins can delete student records"
    on public.students for delete
    to authenticated
    using (public.is_admin());

-- ============================================================
-- 4. STORAGE BUCKET: student_photos
-- ============================================================
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
    'student_photos',
    'student_photos',
    true,
    5242880, -- 5 MB
    array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set
    public = true,
    file_size_limit = 5242880;

-- Storage RLS: Public read, authenticated upload
create policy "Public read student photos"
    on storage.objects for select
    to public
    using (bucket_id = 'student_photos');

create policy "Authenticated users can upload student photos"
    on storage.objects for insert
    to authenticated
    with check (bucket_id = 'student_photos');

create policy "Admins and owners can delete student photos"
    on storage.objects for delete
    to authenticated
    using (bucket_id = 'student_photos');

-- ============================================================
-- 5. AUTOMATIC PROFILE TRIGGER ON AUTH SIGNUP
-- ============================================================
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, name, email, role, is_active)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)),
    new.email,
    coalesce(new.raw_user_meta_data->>'role', 'DATA_ENTRY'),
    true
  )
  on conflict (id) do nothing;
  return new;
end;
$$ language plpgsql security definer;

-- Trigger execution
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ============================================================
-- 6. ENABLE REALTIME ON STUDENTS AND PROFILES
-- ============================================================
alter publication supabase_realtime add table public.students;
alter publication supabase_realtime add table public.profiles;

-- ============================================================
-- 7. BOOTSTRAP INSTRUCTIONS FOR FIRST ADMIN
-- After creating your admin user in Authentication -> Users, run:
-- update public.profiles set role = 'ADMIN' where email = 'your-admin-email@example.com';
-- ============================================================
