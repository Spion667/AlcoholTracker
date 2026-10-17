# AlcoholTracker – Flutter App 🍺⚡

Native Android- und iOS-App zur React-/PWA-Version im Repo-Root. Gleiche Funktionen, **gleiches Supabase-Backend**
(Schema, Realtime, `end_party`-RPC aus [`../supabase`](../supabase) bleiben unverändert).

- Animierter **Startscreen** (Neon-Aurora, Logo-Pop mit Glanz, Titel-Reveal, aufsteigende Bierblasen)
- Setup, Home, Party (Live-Ranking, Live-Feed, Drink-Sheet, Runden, Undo, Quick-Repeat), Profil, Wrapped-Story, Guide
- Promille-Radar (Watson-Formel), Party-PIN mit Symbol-Keypad, Badges, Gruppen-Meilensteine, Konfetti, Haptik

## Voraussetzungen

- Flutter ≥ 3.47 (Dart ≥ 3.13) – <https://docs.flutter.dev/get-started/install>
- Ein Supabase-Projekt mit den Migrationen aus [`../supabase/migrations`](../supabase/migrations) (siehe [`../SETUP.md`](../SETUP.md))
- Android: Android Studio / SDK · iOS: Mac mit Xcode

## Konfiguration

Die Schlüssel werden beim Build per `--dart-define` übergeben (Gegenstück zu `VITE_*` der Web-App).
Verwende den **Publishable Key** (`sb_publishable_…`), niemals den Secret Key.

```bash
cd flutter_app
cp dart_defines.example.json dart_defines.json   # Werte eintragen (wird nicht eingecheckt)
flutter pub get
flutter run --dart-define-from-file=dart_defines.json
```

| Variable | Pflicht | Zweck |
|---|---|---|
| `SUPABASE_URL` | ja | `https://<projekt>.supabase.co` |
| `SUPABASE_PUBLISHABLE_KEY` | ja | `sb_publishable_…` |
| `WEB_BASE_URL` | nein | URL der gehosteten Web-App; wird beim Teilen als klickbarer Link `…/p/<id>` angehängt |
| `DEMO_MODE` | nein | `true` = In-Memory-Backend mit Beispieldaten, kein Netzwerk nötig |

Ohne Schlüssel zeigt die App eine Hinweisseite statt zu crashen.

### Demo-Modus (ohne Backend)

```bash
flutter run --dart-define=DEMO_MODE=true            # Gerät/Emulator
flutter run -d chrome --dart-define=DEMO_MODE=true  # Browser
```

Beispiel-Partys (inkl. code-geschützter Party mit Code ♠ ♥ ♣ ♦ und einer beendeten Party für das Wrapped) werden
im Speicher simuliert, inklusive Realtime-Events. Nützlich für Screenshots und UI-Entwicklung.

## Tests & Qualität

```bash
flutter analyze
flutter test
```

Die Tests portieren die vitest-Suite der Web-App (Alkohol-Rechner, Promille/Watson, Badges, Meilensteine, Symbol-Code)
und ergänzen Wrapped-Auswertung, `PartyController` (Ranking, Runden, Undo, Realtime, Host-Rechte) sowie
Widget-Flows (Splash → Setup → Home).

## Builds

```bash
# Android
flutter build apk --release   --dart-define-from-file=dart_defines.json
flutter build appbundle       --dart-define-from-file=dart_defines.json   # Play Store

# iOS (nur auf dem Mac)
flutter build ipa             --dart-define-from-file=dart_defines.json
```

Vor der Veröffentlichung:

1. **Bundle-/Application-ID festlegen.** Aktuell `com.alcoholtracker.alcohol_tracker`
   (`android/app/build.gradle.kts`, `ios/Runner.xcodeproj`). Nach dem Store-Release nicht mehr änderbar.
2. **Android-Signing** einrichten (<https://docs.flutter.dev/deployment/android#sign-the-app>) – Release-Builds sind
   sonst nur debug-signiert.
3. **iOS-Team/Signing** in Xcode setzen.

App-Icon und nativer Splash werden aus `assets/images` erzeugt:

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

## Architektur

```
lib/
├── main.dart            Start: Supabase.initialize bzw. DemoApi
├── app.dart             Provider, go_router (Splash → Setup/Home), Theme
├── config/              Env (dart-define), Version & Changelog
├── models/              Profile, Party, Drink, BodyProfile
├── services/            Api (Interface) · SupabaseApi · DemoApi · Haptics
├── state/               ProfileController, PartyController (Realtime), BodyProfileController, StartupController
├── utils/               drinks, bac (Watson), symbols, wrapped_stats – reine Logik, 1:1 aus der Web-App
├── screens/             Splash, Setup, Home, Party, Me, Wrapped, Guide
└── widgets/             Aurora, Konfetti, Sheets, Leaderboard, Feed, SuitIcon …
```

State: `provider` (ChangeNotifier) · Routing: `go_router` · Backend: `supabase_flutter` · Lokal: `shared_preferences`.
Schriften (Bebas Neue, Inter, Space Mono; OFL) liegen unter `assets/fonts` – die App läuft offline-fähig ohne Font-Download.

## Unterschiede zur Web-App

| Thema | Web (PWA) | Flutter |
|---|---|---|
| Installation | `InstallGate` (Zum Homescreen) | entfällt – echte App; stattdessen animierter Startscreen |
| Push-Benachrichtigungen | Web Push (Service Worker) | **noch nicht umgesetzt** – braucht Firebase/APNs-Projekt |
| Teilen | `navigator.share` + URL | System-Share-Sheet; Link nur wenn `WEB_BASE_URL` gesetzt |
| Deep Links (`/p/<id>`) | Browser-URL | **noch nicht umgesetzt** (App-Links/Universal Links nötig) |
| Klick-Sound Keypad | Web Audio | System-Klick + Haptik |
| Symbole ♠♥♦♣ | Unicode-Text | Vektor-Icons (Emoji-Fonts färben sie sonst rot/schwarz) |
| Quick-Repeat „Nochmal …“ | Bierfaktor pauschal 1 | Bierfaktor aus dem Original-Drink abgeleitet (Radler/0,33 L zählen korrekt) |
| Promillewerte | Space Mono | Inter (das ‰ in Space Mono ist klein kaum von % zu unterscheiden) |
