# iOS → TestFlight (ohne Mac)

Gebaut, signiert und hochgeladen wird auf einem macOS-Runner von GitHub Actions
(`.github/workflows/flutter.yml`, Skript `scripts/ios_testflight.sh`). Lokal braucht es nur
einen Browser und `openssl` (unter Windows z. B. aus Git Bash).

**Bundle ID:** `com.alcoholtracker.alcoholTracker` (iOS) · iPhone-only, Portrait.

> Bundle IDs sind weltweit eindeutig. Ist sie beim Registrieren (Schritt 1) schon vergeben,
> eine andere wählen und `PRODUCT_BUNDLE_IDENTIFIER` in `ios/Runner.xcodeproj/project.pbxproj`
> anpassen.

## Einmalige Einrichtung

### 0. Apple Developer Program

Beitritt unter <https://developer.apple.com/programs/enroll/> (99 €/Jahr). Die Freischaltung
dauert meist 1–2 Tage. Als Einzelperson erscheint der eigene Name als Anbieter im App Store.

### 1. App-ID registrieren

[developer.apple.com → Identifiers](https://developer.apple.com/account/resources/identifiers/list)
→ **+** → *App IDs* → *App* → Bundle ID **Explicit**: `com.alcoholtracker.alcoholTracker`.
Keine Capabilities nötig.

### 2. Distribution-Zertifikat

```bash
cd flutter_app
scripts/ios_signing.sh csr
```

[Certificates](https://developer.apple.com/account/resources/certificates/list) → **+** →
*Apple Distribution* → `ios-signing/dist.csr` hochladen → `.cer` herunterladen.

```bash
scripts/ios_signing.sh p12 ~/Downloads/distribution.cer   # fragt nach einem Passwort
```

`ios-signing/` ist per `.gitignore` ausgeschlossen. Den Ordner sicher aufbewahren
(z. B. Passwortmanager) – er enthält den privaten Schlüssel.

### 3. Provisioning-Profil

[Profiles](https://developer.apple.com/account/resources/profiles/list) → **+** →
Distribution *App Store Connect* → App-ID aus Schritt 1 → Zertifikat aus Schritt 2 →
Name z. B. `AlcoholTracker App Store` → herunterladen.

```bash
scripts/ios_signing.sh profile ~/Downloads/AlcoholTracker_App_Store.mobileprovision
```

### 4. App in App Store Connect anlegen

[App Store Connect → Apps](https://appstoreconnect.apple.com/apps) → **+** → *Neue App* →
iOS, Name, Primärsprache Deutsch, Bundle ID aus Schritt 1, SKU beliebig (z. B. `alcoholtracker`).

### 5. API-Key für den Upload

App Store Connect → *Benutzer und Zugriff* → *Integrationen* → *App Store Connect API* →
*Team-Schlüssel* → **+** → Rolle **App Manager**. Die `.p8`-Datei lässt sich nur **einmal**
herunterladen. Key-ID und Issuer-ID stehen auf derselben Seite.

### 6. GitHub konfigurieren

Repo → *Settings* → *Secrets and variables* → *Actions*.

**Secrets**

| Name | Inhalt |
| --- | --- |
| `IOS_DIST_CERT_P12_BASE64` | Inhalt von `ios-signing/dist.p12.base64` |
| `IOS_DIST_CERT_PASSWORD` | Passwort aus Schritt 2 |
| `IOS_PROVISIONING_PROFILE_BASE64` | Inhalt von `ios-signing/profile.base64` |
| `ASC_KEY_ID` | Key-ID aus Schritt 5 |
| `ASC_ISSUER_ID` | Issuer-ID aus Schritt 5 |
| `ASC_KEY_P8` | kompletter Inhalt der `.p8`-Datei (inkl. `-----BEGIN PRIVATE KEY-----`) |

**Variables** (landen ohnehin in der App, daher keine Secrets)

| Name | Inhalt |
| --- | --- |
| `SUPABASE_URL` | wie `VITE_SUPABASE_URL` der Web-App |
| `SUPABASE_PUBLISHABLE_KEY` | wie der Publishable Key der Web-App (`sb_publishable_…`) |
| `WEB_BASE_URL` | optional, URL der Web-App für geteilte Party-Links |

## Build hochladen

Der Workflow muss auf dem Default-Branch (`main`) liegen, damit GitHub den manuellen Start anbietet.

*Actions* → **Flutter App** → *Run workflow* → Branch wählen → Häkchen
**„iOS-Build signieren und zu TestFlight hochladen"** → *Run*.

Die Build-Nummer ist die Run-Nummer des Workflows und steigt dadurch automatisch. Die Version
(`2.2.0`) kommt aus `pubspec.yaml`. Nach dem Upload verarbeitet Apple den Build (meist 5–30 min).

## Tester einladen

- **Intern** (Mitglieder des App-Store-Connect-Teams, bis 100): sofort, ohne Prüfung.
- **Extern** (z. B. Freunde per Link, bis 10 000): Gruppe anlegen, Testinformationen ausfüllen.
  Der erste Build einer Version geht durch die **Beta App Review** (meist < 1 Tag). Dort gelten im
  Kern die App-Store-Regeln, u. a. 1.4.3 (kein Anreiz zu übermäßigem Alkoholkonsum).

Tester installieren die App **TestFlight** und öffnen den Einladungslink.

## Wartung

- Zertifikat und Profil laufen nach **einem Jahr** ab → Schritte 2, 3 und 6 wiederholen.
- Exportverschlüsselung ist in `Info.plist` beantwortet (`ITSAppUsesNonExemptEncryption = NO`,
  die App nutzt nur HTTPS) – App Store Connect fragt dann nicht bei jedem Build nach.

## Fehlerbehebung

| Meldung | Ursache |
| --- | --- |
| `Secret … fehlt` | Secret in Schritt 6 nicht gesetzt |
| `Bundle-ID passt nicht zum Profil` | Profil wurde für eine andere App-ID erstellt |
| `MAC verification failed` / Import schlägt fehl | falsches `IOS_DIST_CERT_PASSWORD` |
| `No profile for team … matching …` | Profil passt nicht zum Zertifikat → Profil neu erstellen (Schritt 3) |
| Upload: `bundle version must be higher` | Build-Nummer schon vergeben → Workflow erneut starten |
