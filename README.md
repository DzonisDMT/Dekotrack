# DecoTrack

**DEKOBYGG AS equipment tracking** · Android-first · Expo / React Native / TypeScript

DecoTrack tracks individual tools, numbered tool bags, employees, construction projects, custody handovers, maintenance and audit history. It is deliberately not a full ERP.

## Architecture

- Android + responsive web: one Expo / React Native application.
- Cloud: Supabase Auth + PostgreSQL + Row Level Security.
- Hosting: Vercel for web export; Expo EAS for Android builds.
- Data access: typed repository functions in `src/lib/decotrack-api.ts`.
- Atomic custody handover: PostgreSQL RPC `complete_tool_transfer`.

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md), [docs/API.md](docs/API.md) and [docs/RELEASE_CHECKLIST.md](docs/RELEASE_CHECKLIST.md).

## Repository layout

```text
App.tsx                         Expo client (current UI prototype)
src/lib/supabase.ts             Supabase client configuration
src/lib/decotrack-api.ts        Typed cloud data access functions
supabase/migrations/            PostgreSQL schema, RLS and RPC migrations
docs/ARCHITECTURE.md            System architecture and scale path
docs/API.md                     API contract
docs/RELEASE_CHECKLIST.md       Go-live controls
index.html                      Legacy static browser preview
```

## Run the Android prototype

Requirements: Node.js LTS and npm.

```bash
npm install
npx expo start
```

Scan the Expo QR code with Expo Go, or run `npm run android`.

## Configure the cloud foundation

1. Create a Supabase project for development/staging.
2. In the Supabase SQL Editor, apply `supabase/migrations/0001_initial_schema.sql` (or use the Supabase CLI).
3. Copy the project URL and anon/publishable key into a local `.env` file:

```env
EXPO_PUBLIC_SUPABASE_URL=https://YOUR_PROJECT.supabase.co
EXPO_PUBLIC_SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```

4. Create the first organization, invite/sign up the owner account, then add the owner to `public.memberships` using the Supabase dashboard or a trusted admin script. Do not expose a service-role key in the app.
5. Test RLS with separate owner, foreman and employee accounts before entering real inventory.

## Important implementation status

The repository now contains the **cloud database foundation, tenant security policies, atomic transfer function, typed Supabase client/repository layer, and architecture/API/release documentation**.

The existing Expo screens are still a local prototype and have not yet been migrated to use the cloud repository end-to-end. Authentication UI, organization onboarding, employee-specific permissions, offline sync, end-to-end tests and production monitoring remain required before real company rollout. Do not treat the current UI or demo records as production inventory.

## Security principles

- Every business record is scoped to an organization.
- RLS is mandatory; client-side filtering is not security.
- The service-role key must never be bundled into Expo or browser code.
- Transfers must go through the database RPC so assignment and audit history commit together.
- Employee visibility and mutation permissions must be tightened and tested before rollout.

## Versioning

Semantic Versioning: patch for fixes, minor for backward-compatible features, major for stable production releases. Update `package.json` and `app.json` together for mobile releases and record changes in `CHANGELOG.md`.
