# AFD Søkshund

Flutter-app for Android og iOS. Appen er koblet til samme Supabase-prosjekt som AFD IMT og AFD Lager, men all operativ Søkshund-data ligger separat i egne `sokshund_*`-tabeller og private Storage-buckets.

## Tilgang

Innlogging bruker samme Supabase Auth/e-postkode som IMT/Lager. Tilgang til denne appen styres separat med `profiles.can_access_sokshund`. En bruker kan derfor ha tilgang til IMT, Lager og/eller Søkshund uavhengig av hverandre.

Administrator får et ikon for **Tilganger** øverst på startsiden. Der kan eksisterende brukere gis/fjernes Søkshund-tilgang, og nye brukere kan opprettes via den samme `invite-user` Edge Function-løsningen som de andre appene.

## Backend

Supabase URL og publishable key er konfigurert i `lib/core/app_config.dart`. Det ligger aldri service-role eller andre hemmelige nøkler i mobilappen.

Backend er allerede konfigurert i det delte prosjektet. Ikke kjør et gammelt generisk schema på prosjektet.

## Bygg

Android:

```bash
flutter pub get
flutter build apk --release
```

iOS compile check:

```bash
flutter pub get
flutter build ios --release --no-codesign
```

GitHub Actions ligger i `.github/workflows/`.


## GitHub Actions
Workflowene startes kun manuelt fra GitHub Actions via **Run workflow**. Commit/push starter ingen build automatisk.

## Oppdatering 0.2.0
- Treningssiden er nå kartbasert uten listefeltet under kartet.
- Treningsfunn viser type/kategori og nedgravningsdato direkte på kartet.
- Trykk på et funn åpner siden «Bruk funn».
- Gjennomførte treninger lagres i historikken.
- Treningsfunn kan slettes/redigeres og posisjon kan velges i kart eller fra mobilen.
- Historikk viser både oppdragsrapporter og gjennomførte treninger.
- Rapportvisning er strukturert i seksjoner, viser bilder og har eksport til PDF/Word.
- Rapportnavn følger RS-Firmanavn-YYYY-MM-DD.
