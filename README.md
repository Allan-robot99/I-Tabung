# I-Tabung
Our apk file can be accessed from this gdrive link:
https://drive.google.com/drive/folders/1XZ1pWtb686qC_p9MvZwg5DjAd4uqi4oC?usp=sharing
## Problem Statement
Many families want children to build saving habits, but most savings tools are built for adults and treat saving as a simple balance tracker. They do not guide parent-child collaboration, do not translate goals into realistic recurring contributions, and do not help families pause before impulse spending or stay on track with recurring reminders.

I-Tabung is designed to solve that gap by turning saving into a guided family goal journey. It helps parents and children create shared savings goals, review goal plans with AI support, track milestone progress, reflect before spending, and set recurring reminders that connect the savings habit to real-world routines.

## Project Description
I-Tabung is a Flutter mobile app backed by Supabase.

The app currently includes:
- Goal Planner Agent
  - generates target amount, recurring target, contribution ratio, timeline, milestones, and summary
- Tabung dashboard
  - shows target, progress, role-based contribution share, recurring contribution progress, and milestone journey
- Spending Habit Coach
  - reviews a planned spend before confirmation and gives AI alternatives
- Goal Summary
  - selected-tabung-based recurring progress and reminder status
- Recurring Goal Reminder Agent
  - prepares recurring reminder plans and connects to Google Calendar

Main stack:
- Flutter
- Riverpod
- Supabase Auth, Postgres, Edge Functions
- Gemini API
- Google Calendar OAuth + Calendar API

## Architecture Overview

Frontend:
- Flutter app in `lib/`
- Feature-based MVVM structure

Backend:
- SQL schema:
  - [`i_tabung_application_supabase_schema.sql`](</c:/Users/User/I-Tabung/i_tabung/i_tabung_application_supabase_schema.sql>)
- Supabase migrations:
  - `supabase/migrations/`
- Supabase Edge Functions:
  - `goal-planner-agent`
  - `spending-habit-coach-agent`
  - `recurring-goal-reminder-agent`
  - `google-calendar-auth-start`
  - `google-calendar-auth-callback`

Local config templates:
- [`.env.example`](</c:/Users/User/I-Tabung/i_tabung/.env.example>)
- [`supabase/.env.example`](</c:/Users/User/I-Tabung/i_tabung/supabase/.env.example>)

## Setup From Zero

### 1. Prerequisites
Install these first:

- Flutter SDK
- Dart SDK
- Git
- Node.js 20 or newer
- A Supabase account
- A Google Cloud project

Recommended tools:
- Android Studio or VS Code
- Android emulator or physical Android device

Check local tools:

```powershell
flutter --version
node --version
git --version
```

### 2. Clone the Project

```powershell
git clone <your-repo-url>
cd C:\Users\User\I-Tabung\i_tabung
```

### 3. Install Flutter Dependencies

```powershell
flutter pub get
```

### 4. Create a Supabase Project
In Supabase Dashboard:

1. Create a new project
2. Wait until the database is ready
3. Copy these values from `Project Settings -> API`
   - Project URL
   - anon key
   - service role key

You will use:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `APP_SUPABASE_URL`
- `APP_SUPABASE_SERVICE_ROLE_KEY`

### 5. Link the Local Project to Supabase

```powershell
npx supabase@latest login
npx supabase@latest link --project-ref <YOUR_PROJECT_REF>
```

### 6. Apply Database Schema and Migrations

#### Option A: Fresh database
If this is a completely new Supabase project, run the canonical schema first in Supabase SQL Editor:

- [`i_tabung_application_supabase_schema.sql`](</c:/Users/User/I-Tabung/i_tabung/i_tabung_application_supabase_schema.sql>)

#### Option B: Existing project already using migrations
Push the migrations:

```powershell
npx supabase@latest db push
```

Current migrations in this project include:
- `20260522_goal_planner_idempotency.sql`
- `20260523_auth_onboarding_rpc.sql`
- `202605231200_auth_onboarding_rpc_fix_ambiguous.sql`
- `202605231230_fix_invite_code_generator.sql`
- `202605231300_fix_onboarding_family_id_ambiguous.sql`
- `202605231530_goal_planner_v3_contract.sql`
- `202605231900_spending_habit_coach_payment_context.sql`
- `202605231930_refresh_tabung_amount_with_spending.sql`
- `202605232000_spending_habit_place_reason.sql`
- `202605232130_recurring_reminder_agent.sql`
- `202605232230_private_google_oauth_rpc.sql`
- `202605240030_backfill_recurring_start_date.sql`

If you are starting from zero, the safest route is:
1. run the full schema once
2. then run `db push` only for newer incremental changes if needed

### 7. Configure Local Flutter Runtime Values
This app does not keep real Supabase credentials in tracked source anymore.

Run Flutter with `--dart-define`.

PowerShell:

```powershell
flutter run `
  --dart-define=SUPABASE_URL=https://your-project-ref.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=your-supabase-anon-key
```

PowerShell single-line version:

```powershell
flutter run --dart-define="SUPABASE_URL=https://your-project-ref.supabase.co" --dart-define="SUPABASE_ANON_KEY=your-supabase-anon-key"
```

`cmd` version:

```cmd
flutter run ^
  --dart-define=SUPABASE_URL=https://your-project-ref.supabase.co ^
  --dart-define=SUPABASE_ANON_KEY=your-supabase-anon-key
```

Reference template:
- [`.env.example`](</c:/Users/User/I-Tabung/i_tabung/.env.example>)

### 8. Configure Supabase Edge Function Secrets
In Supabase Dashboard:

`Edge Functions -> Secrets`

Add these secrets:

- `APP_SUPABASE_URL`
- `APP_SUPABASE_SERVICE_ROLE_KEY`
- `GEMINI_API_KEY`
- `GEMINI_MODEL`
- `GOOGLE_CLIENT_ID`
- `GOOGLE_CLIENT_SECRET`
- `GOOGLE_OAUTH_REDIRECT_URI`

Recommended values:

- `APP_SUPABASE_URL`
  - `https://your-project-ref.supabase.co`
- `APP_SUPABASE_SERVICE_ROLE_KEY`
  - your Supabase `service_role` key
- `GEMINI_MODEL`
  - `gemini-1.5-flash`
- `GOOGLE_OAUTH_REDIRECT_URI`
  - `https://your-project-ref.functions.supabase.co/google-calendar-auth-callback`

Reference template:
- [`supabase/.env.example`](</c:/Users/User/I-Tabung/i_tabung/supabase/.env.example>)

You can also set secrets with CLI:

```powershell
npx supabase@latest secrets set APP_SUPABASE_URL=https://your-project-ref.supabase.co
npx supabase@latest secrets set APP_SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
npx supabase@latest secrets set GEMINI_API_KEY=your-gemini-api-key
npx supabase@latest secrets set GEMINI_MODEL=gemini-1.5-flash
npx supabase@latest secrets set GOOGLE_CLIENT_ID=your-google-web-client-id
npx supabase@latest secrets set GOOGLE_CLIENT_SECRET=your-google-web-client-secret
npx supabase@latest secrets set GOOGLE_OAUTH_REDIRECT_URI=https://your-project-ref.functions.supabase.co/google-calendar-auth-callback
```

### 9. Set Up Google Cloud for Calendar Access
This is required for the recurring reminder flow.

#### 9.1 Enable Google Calendar API
In Google Cloud Console:

1. Open your project
2. Go to `APIs & Services -> Library`
3. Search `Google Calendar API`
4. Click `Enable`

#### 9.2 Configure OAuth Consent Screen
In Google Cloud Console:

1. Go to `APIs & Services -> OAuth consent screen`
2. Set app name, support email, developer contact email
3. Set audience as needed
4. Add test users while developing

#### 9.3 Add Data Access Scope
Add this scope:

```text
https://www.googleapis.com/auth/calendar.events
```

#### 9.4 Create OAuth Client
Create:
- `OAuth Client ID`
- Type: `Web application`

Add this authorized redirect URI:

```text
https://your-project-ref.functions.supabase.co/google-calendar-auth-callback
```

Then copy:
- `GOOGLE_CLIENT_ID`
- `GOOGLE_CLIENT_SECRET`

#### 9.5 Testing vs public use
- During development, keep OAuth in `Testing` and add your Gmail as a test user
- For public production use, you may need to publish and complete Google verification

### 10. Deploy Edge Functions
This project uses multiple Edge Functions.

Deploy them one by one:

```powershell
npx supabase@latest functions deploy goal-planner-agent
npx supabase@latest functions deploy spending-habit-coach-agent
npx supabase@latest functions deploy recurring-goal-reminder-agent
npx supabase@latest functions deploy google-calendar-auth-start
npx supabase@latest functions deploy google-calendar-auth-callback
```

Important:
- `supabase/config.toml` already marks these as public callback/start functions:
  - `google-calendar-auth-start`
  - `google-calendar-auth-callback`

### 11. Rebuild and Run the App

PowerShell:

```powershell
flutter run `
  --dart-define=SUPABASE_URL=https://your-project-ref.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=your-supabase-anon-key
```

If you changed Android manifest, deep links, or Google callback handling, do a full rebuild:

```powershell
flutter clean
flutter pub get
flutter run `
  --dart-define=SUPABASE_URL=https://your-project-ref.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=your-supabase-anon-key
```

Build APK in PowerShell:

```powershell
flutter build apk `
  --dart-define=SUPABASE_URL=https://your-project-ref.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=your-supabase-anon-key
```

Important:
- In PowerShell, use the backtick `` ` `` for multi-line commands
- In `cmd`, use `^`
- Do not put `APP_SUPABASE_SERVICE_ROLE_KEY` into the Flutter app build

## Verification Checklist

### 1. Static checks

```powershell
flutter analyze
flutter test
```

### 2. Goal Planner
Verify:
- parent can create tabung
- child is blocked from direct creation
- planner opens from setup page
- review page creates the tabung and redirects to tabung dashboard

### 3. Spending Habit Coach
Verify:
- choose tabung
- spend form opens
- location permission is required
- AI review returns suggestions
- confirm payment updates balances

### 4. Goal Summary
Verify:
- user must choose a tabung first
- selected tabung drives Goal Summary content

### 5. Recurring Reminder
Verify:
- Google Calendar can connect
- preview reminder works
- reminder event can be created
- reminder status appears in Goal Summary

## Useful Supabase Checks

### AI logs

```sql
select id, agent_type, user_id, family_id, tabung_id, created_at
from public.ai_logs
order by created_at desc
limit 20;
```

### Calendar connection

```sql
select user_id, provider, is_connected, google_calendar_id, connected_at
from public.calendar_connections
order by connected_at desc
limit 20;
```

### Calendar events

```sql
select tabung_id, event_type, title, sync_status, google_event_id, created_at
from public.calendar_events
order by created_at desc
limit 20;
```

### Tabung recurring start date

```sql
select id, tabung_name, recurring_amount, recurring_period, recurring_start_date, created_at
from public.tabung_goals
order by created_at desc
limit 20;
```

## Common Issues

### `supabase` command not found
Use:

```powershell
npx supabase@latest <command>
```

### Google OAuth says access blocked
Usually caused by:
- app still in `Testing`
- your Gmail is not added to `Test users`
- wrong redirect URI

### `UNAUTHORIZED_NO_AUTH_HEADER` on callback
Make sure:
- `supabase/config.toml` is present
- callback/start functions are redeployed

### `OAuth state not found`
Usually caused by:
- missing migrations
- callback deployed before latest OAuth state storage fixes

### `Invalid schema: private`
Fixed in current code by using public RPC wrappers.
Make sure the latest migrations are applied and the latest functions are deployed.

### Reminder preview says recurring start date is missing
Apply the latest migration:
- `202605240030_backfill_recurring_start_date.sql`

### Secret safety
Do not commit:
- service role keys
- Google client secret
- Gemini key
- real `.env` files

## Project Notes
- Markdown files are currently gitignored for new Git adds in this workspace.
- Existing credentials should still be rotated if they were ever committed or pushed previously.
- The current app behavior treats tabung creation as a parent-only action at the UI level.


## Developer
1. Allan Tan
2. Denzel QUAH 
