# AFD Søkshund – v0.1 kildepakke

Første kodebase for AFD Søkshund. Designet følger AFD-appfamilien: gul/svart profil, store knapper, Supabase Auth med kode på e-post, Flutter for Android/iOS.

## Implementert i denne pakken

- Fem hovedknapper: Oppdrag, Trening, Kalender, Hunder, Historikk.
- Oppdrag > Start søk > Bruk planlagt søk / Nytt søk.
- Planlegg søk med firma, org.nr., kontaktperson, e-post, telefon, hund, automatisk innlogget fører, dato, kartområde og notat.
- Kart med vanlig kart/flyfoto og linje rundt definert område.
- MET Norway vær-snapshot ved oppstart.
- Aktivt søk med pause/fortsett, fører-GPS-spor, søksområdebilde, funnregistrering og avslutning.
- Søksområdebilder og funnbilder lagres separat.
- Funn: mobilposisjon, beskrivelse, bilder og håndteringsstatus.
- Trening: treningsfunn på kart med dato, posisjon, bilde, type/kategori, redigering og sletting.
- Kalender: felles kalender for hendelser og dagsnotater.
- Hunder: hunderegister, tracker-ID og hundehendelser til kalender.
- Historikkgrunnlag for full rapport.
- Supabase-schema med RLS og private Storage-buckets.
- Datamodell klar for hunde-GPS (`search_track_points.source = dog`).

## Ikke ferdig i v0.1

- Leverandørspesifikk hunde-GPS/4G-integrasjon. Datamodellen er klar, men hardware/API må velges først.
- Ferdig layoutet PDF- og DOCX-rapportgenerator. Tabellen `reports` og rapportgrunnlaget er på plass; dette er neste kodeblokk.
- Bakgrunnssporing når mobilen er låst/minimert. V1 logger mens aktiv-søk-skjermen kjører.
- Direkte åpning fra kalenderhendelse til alle tilknyttede objekttyper er ikke koblet ferdig ennå.

## Opprette Flutter-skallet

Denne arbeidsøkten har ikke Flutter SDK installert, så Android/iOS-skallet kan ikke autogenereres eller kompileres her. På utviklingsmaskinen:

```bash
flutter create --org no.afgruppen.afd --platforms=android,ios .
flutter pub get
```

Behold `lib/`, `assets/`, `supabase/`, `pubspec.yaml` og `analysis_options.yaml` fra denne pakken når Flutter-skallet opprettes.

## Supabase

Opprett et separat prosjekt når du ønsker det, kjør SQL-en i:

`supabase/migrations/001_initial_schema.sql`

Legg deretter inn første godkjente bruker i `app_members`:

```sql
insert into public.app_members (user_id, full_name, role)
values ('AUTH-USER-UUID', 'Navn', 'admin');
```

Appen bruker `shouldCreateUser: false`, slik at tilfeldige e-postadresser ikke automatisk oppretter nye brukere.

Start lokalt med:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://PROJECT.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_xxx
```

## E-postkode

Supabase Email OTP-template må bruke `{{ .Token }}`. Dette er samme OTP-prinsipp som i de andre AFD-appene.

## Kart

- Vanlig kart: OpenStreetMap.
- Flyfoto: Esri World Imagery.
- Før produksjonsbruk bør tile-provider/bruksvilkår og ønsket kartleverandør låses endelig.

## Vær

`WeatherService` bruker MET Norway Locationforecast og lagrer værdata som snapshot når et søk starter.
