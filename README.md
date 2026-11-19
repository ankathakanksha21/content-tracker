# Content Tracker

A public tracker for my content: what each video teaches, who it's for, its category and funnel stage, its sources, and how it performed.

Everyone can view it. Only the owner can log in to add, edit or delete content.

- **Site:** GitHub Pages (static files in this repo)
- **Database and login:** Supabase (free tier)

## Files

| File | What it is |
|---|---|
| `index.html` | The whole app |
| `config.js` | Supabase project URL and public (anon) key |
| `setup.sql` | One-time database setup: tables, permissions, live updates, the starting lists |
| `.github/workflows/keep-awake.yml` | Reads the database every 3 days so Supabase's free plan doesn't pause it for inactivity |

## Setup

### 1. Supabase

1. Create a free project at [supabase.com](https://supabase.com).
2. Open **SQL Editor** and click **New query**.
3. Paste `setup.sql`, replace `YOUR-ADMIN-EMAIL@example.com` with the owner's email, and click **Run**.
4. Go to **Authentication → Users → Add user → Create new user**. Enter the same email and a password, and tick **Auto confirm user**.
5. Go to **Authentication → Sign In / Providers** and turn off **Allow new users to sign up**.
6. Copy two values into `config.js`:
   - the **Project URL**, from **Project Settings → Data API**
   - the **Publishable key** (`sb_publishable_…`), from **Project Settings → API Keys**

### 2. GitHub Pages

Go to **Settings → Pages**. Under **Build and deployment**, choose **Deploy from a branch**, then select `main` and `/ (root)`.

## How access works

Row-level security in Postgres enforces who can do what:

- Anyone can read entries and lists.
- Only a logged-in user whose email is in `tracker_admins` can insert, update or delete.
- Nobody can read `tracker_admins` through the API.

The publishable key in `config.js` is meant to be public. Never put the secret key (or the legacy `service_role` key) in this repo.

To change the owner email, run:

```sql
delete from public.tracker_admins;
insert into public.tracker_admins values ('new@email.com');
```

## Changing the tracker later

- Edits from the app only write the columns the app knows about.
- New fields can go in a new column (`alter table public.entries add column ...`) or in the `extra` jsonb column.
- Existing data is never rewritten.
- To get a CSV, use **Copy as CSV** in the app, or export the `entries` table from Supabase's **Table Editor**.
