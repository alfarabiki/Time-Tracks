# Radjak RBAC + Sync — Design Spec

Date: 2026-06-13
Branch: `radjak-app`
Backend: **Supabase** (Postgres + Auth + Storage + RLS)
Roles: **admin · manajer · staf**
Offline: **offline-capture + auto-sync**
Status: Approved (direction); awaiting Supabase project credentials to implement.

## Why / context
RBAC turns Radjak from offline-only into an **online app with offline cache**, so Managers get real visibility ("akuntabilitas") into their team's field visits. Login required; each role sees a different home. Builds on the v2 app ([[two-app-architecture]]). Supabase chosen for managed Postgres + Auth + Row-Level-Security (fast, free tier, official Flutter plugin).

## Auth
- Supabase Auth: **email + password**. Biometric (`local_auth`) used only to unlock a remembered session locally.
- Login screen (already designed/previewed) wired to `supabase_flutter`. Session persisted; on cold start → if session valid, skip login.
- App config: `SUPABASE_URL` + `SUPABASE_ANON_KEY` via `--dart-define` (not hardcoded secrets; anon key is client-safe).

## Data model (Supabase Postgres)
- `profiles` (id uuid = auth.users.id, full_name, **role** enum `admin|manajer|staf`, branch, created_at). Auto-created on signup via trigger.
- `visits` (id, staff_id→profiles, tracking_number, facility, visit_type, address, latitude, longitude, accuracy, taken_at, photo_url, image_hash, created_at).
- Photos → Supabase **Storage** bucket `visit-photos`, path `<uid>/<tracking>.jpg`.

## RLS (the RBAC core)
- **staf**: insert/select/update only own `visits` (staff_id = auth.uid()); read own profile.
- **manajer**: select `visits` of staff in the **same branch**; read same-branch profiles.
- **admin**: full access to profiles + visits.
- IMPORTANT (Supabase gotcha): role checks inside policies must use a `SECURITY DEFINER` helper `public.my_role()` / `my_branch()` to avoid infinite RLS recursion when a `profiles` policy queries `profiles`. Schema uses that pattern.

## Roles & UX (role-based routing after login)
- **Staf**: own Dashboard → Mulai Kunjungan → camera (offline ok) → save local → sync. History = own visits.
- **Manajer**: Team Dashboard — list/filter all team visits (by staf/tanggal/faskes), counts, map/timeline later. (Approval workflow = R3.)
- **Admin**: User management (create staff, assign role/branch) + everything managers see.

## Offline-capture + auto-sync
- Capture flow stays local-first (current SQLite + photo file). A **sync queue** uploads unsynced visits when online: photo → Storage, row → `visits`. Mark `synced` flag locally.
- Local `photo_history` gains a `synced INTEGER DEFAULT 0` column (DB v3 migration). Sync service runs on app start + on connectivity regained (`connectivity_plus`).
- Manager/Admin views read from Supabase (online); cache last result for offline viewing.

## Packages to add
`supabase_flutter`, `connectivity_plus`, `local_auth` (biometric). (Remove nothing.)

## Phasing
- **R1 — Auth + roles + gate** (this phase): supabase_flutter init; login screen real auth; `profiles` + role; cold-start session gate; role-based routing (staf → current app; manajer/admin → placeholder team screen). NO sync yet (visits still local). Ship-able.
- **R2 — Sync + Manager team view**: DB v3 `synced` column; sync service (photo→Storage, row→visits); Manager Team Dashboard reading Supabase with filters.
- **R3 — Admin user mgmt + approvals + (web portal later)**.

## Play Store note
Play forbids our self-update-APK mechanism. A Play build must disable auto-update + drop `REQUEST_INSTALL_PACKAGES`. Decide distribution (Play vs sideload) separately; not part of RBAC.

## Prerequisite (user action)
Create a Supabase project; provide **Project URL** + **anon public key**. SQL schema in `supabase/schema.sql` to run in the SQL editor.

## Testing
- Unit: role-routing decision (role→home), sync-queue selection (which records unsynced), tracking-format (existing).
- RLS: manual verify in Supabase (staf cannot read others; manajer reads branch; admin all).
- Widget: login form validation; role-based home renders correct screen.
