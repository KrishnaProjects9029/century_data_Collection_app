# Krishna Century Data App — Supabase Setup Guide

This guide walks you through setting up **Supabase** for the Krishna Century Student Registration & Management Android Application.

---

## Step 1: Create a Free Supabase Project (2 minutes)

1. Go to [https://supabase.com](https://supabase.com) and click **"Start your project"** (Sign in with GitHub or email).
2. Click **"New Project"**.
3. Choose an Organization and enter:
   - **Name**: `krishna-century`
   - **Database Password**: Create a strong password (and save it).
   - **Region**: Choose **South Asia (Mumbai)** — `ap-south-1` for lowest latency in India.
4. Click **"Create new project"**.
   *(It takes about 1-2 minutes for Supabase to provision your database)*.

---

## Step 2: Run the One-Click Database Schema (1 minute)

1. In your Supabase Dashboard, click the **SQL Editor** icon in the left menu (looks like `>_` or SQL terminal).
2. Click **"New query"**.
3. Open the file [`supabase_schema.sql`](file:///c:/Users/admin/Downloads/Krishna%20Century%20data%20app/supabase_schema.sql) in this project, copy all its contents, and paste them into the SQL Editor.
4. Click **"Run"** (green button at bottom-right).

**What this automatically sets up for you**:
- ✅ `profiles` table (for user authentication and role management: `ADMIN` / `DATA_ENTRY`).
- ✅ `students` table (stores registration records with auto-incrementing `serial_number BIGSERIAL`).
- ✅ Row-Level Security (RLS) policies protecting records.
- ✅ `student_photos` storage bucket with 5 MB file size limit and public read.
- ✅ Automatic profile trigger when any user signs up.

---

## Step 3: Get Your Project URL & Anon Key (30 seconds)

1. In Supabase Dashboard, go to **Project Settings** (gear icon at the bottom of the left sidebar).
2. Click **API** under Configuration.
3. You will see two values:
   - **Project URL** (e.g. `https://xyzabc123.supabase.co`)
   - **Project API Keys** -> `anon` / `public` (a long string starting with `eyJhbGciOi...`)
4. Open [`lib/core/config/supabase_config.dart`](file:///c:/Users/admin/Downloads/Krishna%20Century%20data%20app/lib/core/config/supabase_config.dart) in this project and paste your values:

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'https://YOUR_ACTUAL_PROJECT_ID.supabase.co';
  static const String supabaseAnonKey = 'YOUR_ACTUAL_ANON_PUBLIC_KEY';

  static const String studentPhotosBucket = 'student_photos';
}
```

---

## Step 4: Bootstrap the First Administrator User (1 minute)

Because the app restricts user management to authorized admins only, create your first Admin account once:

1. In Supabase Dashboard, click **Authentication** -> **Users** in the left sidebar.
2. Click **"Add user"** -> **"Create user"**:
   - **Email**: `admin@krishnacentury.com` (or your email)
   - **Password**: Choose a secure password
   - Toggle **"Auto Confirm User"** to ON.
   - Click **"Create user"**.
3. Go back to **SQL Editor** -> **New Query**, and run:
   ```sql
   update public.profiles
   set role = 'ADMIN', name = 'Your Admin Name'
   where email = 'admin@krishnacentury.com';
   ```
4. Click **Run**.
5. Your Admin account is now ready!

---

## Step 5: Install Dependencies & Run the App

Open terminal inside this project directory (`c:\Users\admin\Downloads\Krishna Century data app`):

1. **Install Flutter packages**:
   ```bash
   flutter pub get
   ```

2. **Run the App** (on a connected phone or Android emulator):
   ```bash
   flutter run
   ```

3. **Or Build the Release Android APK**:
   ```bash
   flutter build apk --release
   ```
   The APK will be generated at:
   `build/app/outputs/flutter-apk/app-release.apk`
   You can install this APK on any Android phone.

---

## Testing the Complete Workflow

1. Open the app → Tap the **Admin Login** tab.
2. Enter your admin email and password.
3. You will enter the **Admin Dashboard**:
   - View student submissions entered by **all operators** in real-time.
   - Filter records by specific Data Entry Operator or view All.
   - Tap **"Export All Data to Excel"** to generate the `.xlsx` file with all 17 columns in exact order.
   - Go to **Manage Users** to create Data Entry accounts for your staff.
   - Tap **Add Student** to fill all 14 fields, attach photos, and test duplicate detection.

---

## Excel Column Sequence (Exact 17 Columns Guaranteed)

| Col # | Column Header | Description |
|:---:|:---|:---|
| 1 | **Sr. No.** | Auto-generated serial number (`BIGSERIAL`) |
| 2 | **Student First Name** | First Name |
| 3 | **Middle Name** | Middle Name |
| 4 | **Surname** | Surname |
| 5 | **School Name** | School Name |
| 6 | **Bro/Sis In Class (STD & DIV)** | Sibling Class Info |
| 7 | **Parents** | Both / Mother (Single) / Father (Single) |
| 8 | **Mother Contact No.** | 10-Digit Mobile |
| 9 | **Father Contact No.** | 10-Digit Mobile |
| 10 | **Address In Full** | Complete Address |
| 11 | **Area** | Dropdown Area |
| 12 | **Other Area** | Custom Area (if Area = Other) |
| 13 | **Landmark** | Dropdown Landmark |
| 14 | **Other Landmark** | Custom Landmark (if Landmark = Other) |
| 15 | **Student Photo** | Supabase Storage Photo URL |
| 16 | **Maker** | Name of user who submitted the record |
| 17 | **Date & Time** | IST Format (`DD-MM-YYYY HH:mm:ss`) |
