# Plattformtillatelser

## Android
Legg inn i `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.CAMERA" />
```

For kontinuerlig GPS i bakgrunnen må egen bakgrunnsløsning vurderes senere. V1 logger mens aktiv-søk-skjermen kjører.

## iOS
Legg inn i `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>AFD Søkshund bruker kamera til bilder av søksområde og registrerte funn.</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>AFD Søkshund bruker posisjon til søksspor, søksområde og registrering av funn.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>AFD Søkshund kan bruke bildebiblioteket til dokumentasjon.</string>
```
