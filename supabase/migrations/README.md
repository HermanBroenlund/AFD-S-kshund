# AFD Søkshund – delt Supabase-backend

AFD Søkshund bruker samme Supabase-prosjekt som AFD IMT og AFD Lager.
Backend-migrasjonen ble lagt inn direkte 2026-09-28 og skal **ikke** kjøres på nytt fra dette repoet.

Data er isolert med egne `sokshund_*`-tabeller og egne private Storage-buckets:

- `sokshund-search-media`
- `sokshund-training-media`
- `sokshund-reports`

Tilgang styres separat via `profiles.can_access_sokshund` og RLS-funksjonen
`private.can_access_sokshund()`. IMT- og Lager-tilganger påvirkes ikke.
