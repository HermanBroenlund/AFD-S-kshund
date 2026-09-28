# AFD Søkshund

Flutter-app for Android og iOS med Supabase-backend.

## Plattform
- Android: `no.afgruppen.afdsokshund`
- iOS bundle ID: `no.afgruppen.afdsokshund`
- Appnavn: **AFD Søkshund**

## Første oppsett
1. Installer Flutter stable.
2. Kjør `flutter pub get`.
3. Legg Supabase-verdiene inn som `--dart-define` eller GitHub Secrets:
   - `SUPABASE_URL`
   - `SUPABASE_PUBLISHABLE_KEY`
4. Kjør SQL-filen `supabase/migrations/001_initial_schema.sql` i AFD Søkshund-prosjektet.
5. Start lokalt:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://PROJECT.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
```

## GitHub Actions
- `Android` bygger release APK og legger den som artifact.
- `iOS compile check` verifiserer iOS-bygg uten signering.
- For TestFlight kan samme signing/distribution-oppsett som AFD Drone/AFD IMT kopieres inn når Apple bundle-ID/provisioning er opprettet.

## Funksjoner i førsteversjonen
- Oppdrag
- Planlegg søk
- Start planlagt eller nytt søk
- Hund og fører
- Firma/org.nr./kontaktperson
- Kart og polygon
- Kart/flyfoto
- MET-vær
- GPS-spor
- Pause/fortsett/avslutt
- Bilder av søksområdet som egen kategori
- Registrerte funn med egne bilder og posisjon
- Trening og treningsfunn
- Felles kalender
- Hunder
- Historikk
- Datamodell klargjort for ekstern hunde-GPS

## Viktig
`release` på Android bruker foreløpig debug-signering for å gjøre første CI-bygg enkelt. Før distribusjon må vi legge inn samme keystore/signering som de andre AFD-appene.
