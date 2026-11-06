# DecoTrack API contract

The MVP uses Supabase's authenticated PostgREST API for ordinary CRUD and one PostgreSQL RPC for atomic handovers. All requests require a valid Supabase access token; RLS enforces organization membership.

| Operation | Method / endpoint | Purpose |
|---|---|---|
| Sign in | `POST /auth/v1/token?grant_type=password` | Email/password session |
| Sign out | `POST /auth/v1/logout` | End session |
| List tools | `GET /rest/v1/tools?organization_id=eq.{org}&select=*` | Search/filter inventory |
| Create tool | `POST /rest/v1/tools` | Register equipment |
| Update tool | `PATCH /rest/v1/tools?id=eq.{id}` | Update metadata/status |
| List employees | `GET /rest/v1/employees?organization_id=eq.{org}` | Active staff |
| List projects | `GET /rest/v1/projects?organization_id=eq.{org}` | Active sites |
| List bags | `GET /rest/v1/tool_bags?organization_id=eq.{org}` | Numbered bags |
| Bag contents | `GET /rest/v1/bag_items?bag_id=eq.{id}` | Tools assigned to a bag |
| Transfer history | `GET /rest/v1/transfers?organization_id=eq.{org}&order=transferred_at.desc` | Custody history |
| Complete handover | `POST /rest/v1/rpc/complete_tool_transfer` | Atomic assignment + audit |
| Maintenance | `POST /rest/v1/maintenance_records` | Report damage/service |

## Handover RPC payload
```json
{
  "p_organization_id": "organization-uuid",
  "p_tool_ids": ["tool-uuid"],
  "p_to_employee_id": "employee-uuid",
  "p_to_project_id": "project-uuid",
  "p_notes": "Handover confirmed on site"
}
```
The recipient employee or project may be null, but not both. The function returns the transfer UUID. Invalid organization/tool combinations fail and roll back the entire transaction.

## Error contract
Supabase returns standard PostgREST errors. The client must show a human-readable message but must not expose SQL details to ordinary employees. Use idempotency keys for future offline queued writes; do not retry a transfer blindly after a network timeout—refresh transfer history first.
