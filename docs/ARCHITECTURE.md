# DecoTrack — startup MVP architecture

## Product boundary
DecoTrack is an equipment custody and visibility system for DEKOBYGG AS. It is not an ERP, payroll, procurement or accounting product.

## Architecture
- **Client:** Expo + React Native + TypeScript. One codebase for Android and responsive web; mobile-first workflows for scanning and handover.
- **Hosting:** Vercel for the web export; Expo EAS Build for signed Android packages and Play Store releases.
- **Backend:** Supabase Auth, managed PostgreSQL, Row Level Security (RLS), Storage. Use Supabase Edge Functions only for operations that need trusted secrets or external integrations.
- **Data access:** typed client-side repository functions in `src/lib/decotrack-api.ts`; RLS is the security boundary. Never ship a service-role key to a client.
- **QR:** QR payload is an opaque, random `qr_code_value`, not employee or project personal data.
- **Audit:** immutable transfer records and audit log entries. The handover RPC updates custody and writes history in one database transaction.

## Tenancy and roles
Every business record belongs to an organization. `memberships` links authenticated users to organizations and grants one role:
- owner: organization setup and all permissions
- manager: people, projects, tools, reports and settings
- foreman: day-to-day tools, projects and handovers
- employee: read assigned equipment and participate in handovers (tighten employee policies before launch)

RLS filters every tenant-owned table by membership. Never trust a client-provided organization ID without checking membership on the server.

## Core flows
1. Manager invites or creates a user, adds employee profile and grants membership.
2. Manager registers a tool with a unique asset tag; system generates QR identifier.
3. Foreman scans QR, checks current custody, and starts a handover.
4. `complete_tool_transfer` validates organization and tool ownership, locks tool rows, updates current assignment and writes transfer + audit records atomically.
5. Search and dashboard query the same shared database, so changes are visible across devices.

## Scale path
Start with one Supabase project and one organization. Keep organization IDs on all business rows from day one. Add indexes on organization + common filters. Later add storage photos, push notifications, offline write queue, analytics read models and background jobs without replacing the schema.

## Environments
- Local: Supabase CLI + Expo development server.
- Staging: separate Supabase project and Vercel preview environment.
- Production: production Supabase project, Vercel production deployment and EAS signed Android build.

## Required production controls
Enable MFA for managers, configure backups/PITR, monitor database/auth errors, rate-limit invite flows, use least-privilege roles, test RLS as each role, and retain audit records. Do not onboard live company inventory until the security checklist in `docs/RELEASE_CHECKLIST.md` passes.
