-- JIIL AL JADIID SCHOOLS: Supabase database schema
-- Run this once in Supabase Dashboard > SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  email text unique,
  phone text,
  role text not null default 'parent' check (role in ('admin','teacher','parent')),
  created_at timestamptz not null default now()
);

create table if not exists public.classes (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  teacher_id uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.students (
  id uuid primary key default gen_random_uuid(),
  admission_no text not null unique,
  full_name text not null,
  date_of_birth date,
  gender text check (gender in ('Male','Female')),
  class_id uuid references public.classes(id) on delete set null,
  guardian_name text not null,
  guardian_phone text not null,
  guardian_user_id uuid references public.profiles(id) on delete set null,
  previous_school text,
  status text not null default 'Active' check (status in ('Active','Pending','Inactive')),
  created_at timestamptz not null default now()
);

create table if not exists public.attendance (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id) on delete cascade,
  attendance_date date not null default current_date,
  status text not null check (status in ('Present','Absent','Late','Excused')),
  note text,
  marked_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  unique(student_id, attendance_date)
);

create table if not exists public.subjects (
  id uuid primary key default gen_random_uuid(),
  class_id uuid references public.classes(id) on delete cascade,
  name text not null,
  created_at timestamptz not null default now(),
  unique(class_id, name)
);

create table if not exists public.exams (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  term text,
  class_id uuid references public.classes(id) on delete cascade,
  exam_date date,
  published boolean not null default false,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.grades (
  id uuid primary key default gen_random_uuid(),
  exam_id uuid not null references public.exams(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  subject_id uuid references public.subjects(id) on delete set null,
  score numeric(6,2) not null check (score >= 0),
  max_score numeric(6,2) not null default 100 check (max_score > 0 and score <= max_score),
  teacher_note text,
  entered_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  unique(exam_id, student_id, subject_id)
);

create table if not exists public.fees (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id) on delete cascade,
  description text not null,
  amount numeric(12,2) not null check (amount >= 0),
  amount_paid numeric(12,2) not null default 0 check (amount_paid >= 0 and amount_paid <= amount),
  due_date date,
  status text generated always as (case when amount_paid >= amount then 'Paid' when amount_paid > 0 then 'Partial' else 'Unpaid' end) stored,
  created_at timestamptz not null default now()
);

create table if not exists public.announcements (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  body text not null,
  audience text not null default 'all' check (audience in ('all','parents','teachers')),
  published boolean not null default true,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

-- Automatically create a parent profile for every new sign-up.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, full_name, email, phone, role)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name',''), new.email, new.raw_user_meta_data->>'phone', 'parent')
  on conflict (id) do nothing;
  return new;
end;
$$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();

-- Security-definer helpers avoid recursive RLS lookups.
create or replace function public.my_role()
returns text language sql stable security definer set search_path = public as $$
  select role from public.profiles where id = auth.uid();
$$;
create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce(public.my_role() = 'admin', false);
$$;
create or replace function public.is_staff()
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce(public.my_role() in ('admin','teacher'), false);
$$;

create or replace function public.can_access_class(p_class_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select public.is_admin()
    or exists(select 1 from public.classes c where c.id=p_class_id and c.teacher_id=auth.uid())
    or exists(select 1 from public.students s where s.class_id=p_class_id and s.guardian_user_id=auth.uid());
$$;

create or replace function public.can_access_student(p_student_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select public.is_admin()
    or exists(
      select 1 from public.students s
      left join public.classes c on c.id=s.class_id
      where s.id=p_student_id
        and (s.guardian_user_id=auth.uid() or c.teacher_id=auth.uid())
    );
$$;

alter table public.profiles enable row level security;
alter table public.classes enable row level security;
alter table public.students enable row level security;
alter table public.attendance enable row level security;
alter table public.subjects enable row level security;
alter table public.exams enable row level security;
alter table public.grades enable row level security;
alter table public.fees enable row level security;
alter table public.announcements enable row level security;

-- Profiles
 drop policy if exists "profile read" on public.profiles;
create policy "profile read" on public.profiles for select to authenticated
using (id = auth.uid() or public.is_admin());
drop policy if exists "profile self update" on public.profiles;
create policy "profile self update" on public.profiles for update to authenticated
using (id = auth.uid() and role = public.my_role()) with check (id = auth.uid() and role = public.my_role());
drop policy if exists "admin profile update" on public.profiles;
create policy "admin profile update" on public.profiles for update to authenticated
using (public.is_admin()) with check (public.is_admin());

-- Classes and subjects: teachers see only their assigned classes; parents see linked children's classes.
drop policy if exists "classes read" on public.classes;
create policy "classes read" on public.classes for select to authenticated using (public.can_access_class(id));
drop policy if exists "classes admin manage" on public.classes;
create policy "classes admin manage" on public.classes for all to authenticated using (public.is_admin()) with check (public.is_admin());
drop policy if exists "subjects read" on public.subjects;
create policy "subjects read" on public.subjects for select to authenticated using (class_id is not null and public.can_access_class(class_id));
drop policy if exists "subjects admin manage" on public.subjects;
create policy "subjects admin manage" on public.subjects for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- Students: admins manage; teachers see students in their assigned classes; parents see linked children.
drop policy if exists "students read" on public.students;
create policy "students read" on public.students for select to authenticated using (public.can_access_student(id));
drop policy if exists "students admin insert" on public.students;
create policy "students admin insert" on public.students for insert to authenticated with check (public.is_admin());
drop policy if exists "students admin update" on public.students;
create policy "students admin update" on public.students for update to authenticated using (public.is_admin()) with check (public.is_admin());
drop policy if exists "students admin delete" on public.students;
create policy "students admin delete" on public.students for delete to authenticated using (public.is_admin());

-- Attendance: teachers can manage only their assigned classes; guardians can read linked children.
drop policy if exists "attendance read" on public.attendance;
create policy "attendance read" on public.attendance for select to authenticated using (public.can_access_student(student_id));
drop policy if exists "attendance staff insert" on public.attendance;
create policy "attendance staff insert" on public.attendance for insert to authenticated with check (
 public.is_admin() or (public.my_role()='teacher' and public.can_access_student(student_id) and marked_by=auth.uid())
);
drop policy if exists "attendance staff update" on public.attendance;
create policy "attendance staff update" on public.attendance for update to authenticated using (
 public.is_admin() or (public.my_role()='teacher' and public.can_access_student(student_id))
) with check (public.is_admin() or (public.my_role()='teacher' and public.can_access_student(student_id)));
drop policy if exists "attendance admin delete" on public.attendance;
create policy "attendance admin delete" on public.attendance for delete to authenticated using (public.is_admin());

-- Exams: teachers manage their own classes; parents can read published exams for linked children.
drop policy if exists "exams read" on public.exams;
create policy "exams read" on public.exams for select to authenticated using (
 public.is_admin()
 or (public.my_role()='teacher' and public.can_access_class(class_id))
 or (published and exists(select 1 from public.students s where s.class_id=exams.class_id and s.guardian_user_id=auth.uid()))
);
drop policy if exists "exams staff manage" on public.exams;
create policy "exams staff manage" on public.exams for all to authenticated using (
 public.is_admin() or (public.my_role()='teacher' and public.can_access_class(class_id))
) with check (
 public.is_admin() or (public.my_role()='teacher' and public.can_access_class(class_id) and created_by=auth.uid())
);

-- Grades: staff see/manage only assigned class marks; parents see marks only after publication.
drop policy if exists "grades read" on public.grades;
create policy "grades read" on public.grades for select to authenticated using (
 public.is_admin()
 or (public.my_role()='teacher' and public.can_access_student(student_id))
 or (exists(select 1 from public.exams e where e.id=exam_id and e.published)
     and exists(select 1 from public.students s where s.id=student_id and s.guardian_user_id=auth.uid()))
);
drop policy if exists "grades staff manage" on public.grades;
create policy "grades staff manage" on public.grades for all to authenticated using (
 public.is_admin() or (public.my_role()='teacher' and public.can_access_student(student_id))
) with check (
 public.is_admin() or (public.my_role()='teacher' and public.can_access_student(student_id) and entered_by=auth.uid())
);

-- Fees
 drop policy if exists "fees read" on public.fees;
create policy "fees read" on public.fees for select to authenticated using (
 public.is_admin() or exists(select 1 from public.students s where s.id=student_id and s.guardian_user_id=auth.uid())
);
drop policy if exists "fees admin manage" on public.fees;
create policy "fees admin manage" on public.fees for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- Announcements
 drop policy if exists "announcements read" on public.announcements;
create policy "announcements read" on public.announcements for select to authenticated using (
 public.is_admin() or (published and (audience='all' or (audience='parents' and public.my_role()='parent') or (audience='teachers' and public.my_role()='teacher')))
);
drop policy if exists "announcements admin manage" on public.announcements;
create policy "announcements admin manage" on public.announcements for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- Useful indexes
create index if not exists students_class_idx on public.students(class_id);
create index if not exists students_guardian_idx on public.students(guardian_user_id);
create index if not exists attendance_date_idx on public.attendance(attendance_date);
create index if not exists grades_student_idx on public.grades(student_id);
create index if not exists fees_student_idx on public.fees(student_id);

-- After signing up the first administrator in the app, run this once with that account's email:
-- update public.profiles p set role='admin' from auth.users u where p.id=u.id and u.email='YOUR_ADMIN_EMAIL';
