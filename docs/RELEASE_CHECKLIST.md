# Production release checklist

- [ ] Create separate staging and production Supabase projects.
- [ ] Apply migrations and confirm all RLS policies are enabled.
- [ ] Create the first organization and owner membership using a trusted admin process.
- [ ] Test owner, manager, foreman and employee access with separate test accounts.
- [ ] Verify a user from organization A cannot read or mutate organization B data.
- [ ] Verify transfer RPC rejects foreign tools and writes transfer + audit atomically.
- [ ] Configure Auth redirect URLs, email templates and MFA for managers.
- [ ] Add EXPO_PUBLIC_SUPABASE_URL and EXPO_PUBLIC_SUPABASE_ANON_KEY to Vercel/EAS.
- [ ] Never add SUPABASE_SERVICE_ROLE_KEY to an Expo public environment variable.
- [ ] Configure backups, monitoring, error reporting and data retention.
- [ ] Test QR scan on supported Android devices and camera permission denial.
- [ ] Test poor-network behaviour; disable unsafe offline transfer writes until a queue is implemented.
- [ ] Confirm original DEKOBYGG AS logo assets and app icon are approved.
- [ ] Run accessibility, responsive layout and end-to-end tests.
- [ ] Import and reconcile real equipment inventory before employee rollout.
