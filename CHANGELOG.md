# Changelog

Alle nennenswerten Änderungen an **AlcoholTracker** werden in dieser Datei dokumentiert.

Das Format basiert auf [Keep a Changelog](https://keepachangelog.com/de/1.0.0/),
und dieses Projekt hält sich an [Semantic Versioning](https://semver.org/lang/de/).

---

## [Unreleased]
### Hinzugefügt
- **Flutter-App (`flutter_app/`)** für Android & iOS mit identischem Funktionsumfang und gemeinsamem Supabase-Backend: Setup, Home, Party (Live-Ranking, Feed, Drink-Sheet, Runden, Undo, Quick-Repeat), Profil, Wrapped-Story, Guide, Promille-Radar, Party-PIN.
- **Animierter Startscreen:** Neon-Aurora, Logo-Pop mit Glanz-Schimmer, Buchstaben-Reveal des Titels und aufsteigende Bierblasen; lädt währenddessen das Profil und blendet dann zu Setup bzw. Home über. Respektiert „Animationen reduzieren“.
- Nativer Splash und App-Icons (Android Adaptive Icon, iOS) aus dem bestehenden Logo.
- Demo-Modus (`--dart-define=DEMO_MODE=true`) mit In-Memory-Backend für Entwicklung, Screenshots und Tests.
- Dart-Tests: Portierung der vitest-Suite (Alkohol-Rechner, Watson/BAC, Badges, Meilensteine, Symbol-Code) plus Wrapped-Auswertung, Party-State/Realtime und Widget-Flows.
- **CI für die Flutter-App** (GitHub Actions): Analyze/Test, Android-APK als Artefakt, iOS-Build auf macOS sowie signierter Upload zu TestFlight ohne eigenen Mac (Anleitung in `flutter_app/docs/TESTFLIGHT.md`).
- **Android-Release-Signatur:** fester Upload-Schlüssel (PKCS12, per openssl erzeugbar) für update-fähige APKs; signierte APK per Knopfdruck als GitHub-Release (Anleitung in `flutter_app/docs/ANDROID.md`).

### Geändert
- iOS-App ist iPhone-only (Portrait); `Info.plist` beantwortet die Exportverschlüsselung (`ITSAppUsesNonExemptEncryption = NO`).

### Geplant
- Push-Benachrichtigungen bei neuen Party-Runden
- Erweiterte Exportfunktionen für Party-Statistiken

---

## [2.2.0] - 2026-10-11
### Hinzugefügt
- **Promille-Radar (Watson-Formel 1980):** Wissenschaftliche Schätzung der Blutalkoholkonzentration (BAC) unter Berücksichtigung von biologischem Geschlecht, Alter, Größe und Gewicht zur Berechnung des realen Gesamtkörperwassers ($TBW$).
- **Zeitbasierte Kinetik & Ausnüchterungs-Prognose:** Simulation mit 30-minütiger Resorptionsphase pro Drink und kontinuierlichem Leberabbau ($0.12\text{ ‰/h}$). Beim Aufklappen der eigenen Karte wird die genaue Uhrzeit für 0,0 ‰ angezeigt.
- **Privacy by Design (100% Local Storage):** Biometrische Daten verlassen niemals das Smartphone und werden rein lokal im `localStorage` gespeichert.
- **2-Stufen-Discovery:** Dezent einklappbare Box im Onboarding (`Setup.jsx`) sowie unaufdringlicher `[ + Promille 🔒 ]`-Chip direkt auf der eigenen Leaderboard-Karte.
- **BodyMetricsSheet:** Schlankes Bottom-Sheet zur schnellen Angabe, Anpassung und rückstandslosen Löschung der Körperdaten.
- **Freiwilliges Teilen:** Opt-in Toggle, um den errechneten Promillewert (und nur diesen) mit Partyfreunden zu teilen.

---

## [2.1.1] - 2026-10-11
### Hinzugefügt
- **Fluid Club Aurora:** Volumefüllende, organische Neon-Lichtwellen (Cyan, Lime, Hot-Pink, Violett) über 100% der Bildschirmbreite und -höhe im oberen Header-Bereich.
- **Dynamische Safe-Area Clearance:** Universelle Formel `pt-[calc(env(safe-area-inset-top,0px)+2.375rem)]` für gestochen scharfen Text unterhalb des iOS 17/18 WebKit Progressive Blur.
- **In-App Versionsverwaltung:** Zentrale Versionsanzeige im Profil (`/me`) und Changelog-Modal.

### Geändert
- **Subtext beim Party-Erstellen:** Aussagekräftiger Hinweis *„Andere benötigen eine PIN, um beizutreten“* statt technischer Bezeichnungen.
- **Header-Transparenz:** Feine Justierung der Header-Deckkraft (`bg-bg/65`), damit die Aurora atmosphärisch strahlt, während scrollende Inhalte sauber weichgezeichnet werden.

### Behoben
- **iOS WebKit Progressive Blur:** Partytitel und Aktionsbuttons versinken auf Dynamic-Island-Geräten nicht mehr im systemseitigen Weichzeichnungsbereich.
- **Schwarze Lücke an der Oberkante:** Beseitigung der doppelten `safe-area-inset-top`-Verschiebung im `.app-container`.
- **Schließen des Party-Code-Screens:** `PartyCodeRevealModal` schließt nun nach der Erstellung zuverlässig und öffnet sich auf dem Partyscreen nur bei explizitem Klick.
- **Wrapped Story-Navigation:** Klicks auf *„Zurück zur Party“* und *„Wrapped teilen“* auf dem Abschluss-Slide werden nicht mehr von der unsichtbaren Tap-Overlay-Zone blockiert.

### Entfernt
- Störende horizontale Lichtleiste oberhalb des Partynamens zugunsten nahtloser, weicher Licht-Blobs.

---

## [2.1.0] - 2026-10-11
### Hinzugefügt
- **Wii-U-Style Party-PIN System:** Optionaler 4-stelliger Symbol-Code (♠️ Pik, ♥️ Herz, ♦️ Karo, ♣️ Kreuz) zum spielerischen Schutz privater Partys vor Fremden.
- **Zufalls-Code Toggle:** Ein-Klick-Aktivierung beim Party-Erstellen ohne manuelles Eintippen.
- **Code-Reveal-Modal:** Feierliches Pop-up nach der Erstellung mit 4 leuchtenden Spielkarten.
- **Interaktives Symbol-Keypad:** 4 Karten-Slots und 4 Neon-Tasten mit dualem Feedback (Android Vibration + Web Audio API Micro-Click auf iOS/Desktop), Fehler-Shake und Erfolgs-Konfetti.
- **Header-Code-Button:** `[ 🔒 Code ]`-Schnellzugriff direkt im Header und im Party-Menü zum Wiederanzeigen für Freunde im Raum.
- **Direktlink-Schutz:** Unbefugte Direktaufrufe über `/p/:id` sperren den Inhalt und fordern die PIN-Eingabe an.

---

## [2.0.2] - 2026-10-10
### Hinzugefügt
- **Dynamische Live-Titel & Badges:** Titel wandern in Echtzeit dynamisch an den Führenden der Kategorie:
  - 👑 **Bierkönig:** Meistes Biervolumen (ab 0.5L)
  - ⚡ **Shot-Maschine:** Meiste Kurze (ab 2 Shots)
  - 🤝 **Spendierhose:** Meiste Runden für Freunde ausgegeben
  - 🚀 **Frühstarter:** Erster Drink des Abends
- **Kollektive Gruppen-Meilensteine:** Gemeinsamer Fortschrittsbalken im Leaderboard (25g Warm-Up, 50g, 100g, 200g, 350g, 500g Club) mit synchronisiertem Konfetti-Regen bei Zielerreichung.
- **Verzeihendes Nachtragen:** Zeit-Schnellauswahl im Drink-Sheet (*„Jetzt ⚡“*, *„Vor 30 Min“*, *„Vor 1 Std“*) zur Wahrung präziser Zeitstempel bei vergessenen Drinks.

---

## [2.0.1] - 2026-10-10
### Hinzugefügt
- **Neues Logo & Branding:** Modernes Club-Icon für Favicon, Apple-Touch-Icon und Web App Manifest.
- **In-App Guide (`/guide`):** 5-Schritte-Erklärung zur Idee, Nutzung, Gast-Verwaltung und Meilensteinen direkt vom Homescreen erreichbar.

### Behoben
- Viewport-Stauchung und vertikales Überschneiden im Party-Erstellen-Sheet auf kleineren iPhones.
- Erste Safe-Area-Padding-Optimierungen für mobile PWA-Displays.

---

## [2.0.0] - 2026-10-10
### Hinzugefügt
- **AlcoholTracker 2.0 Club Edition:** Vollständiger Rewrite des Frontend- und Interaktionskonzepts mit modernem Cyberpunk-/Nightclub-Design (Neon-Lime `#C6FF3D`, Hot-Pink `#FF2E93`, Electric-Cyan `#00F0FF`, Deep-Black `#07070B`).
- **Realtime Party-Räume:** Automatische Synchronisation aller Getränke, Mitglieder und Events über Supabase Realtime Channels.
- **Live-Ranking & Live-Feed:** Umschaltbare Tabs für Rangliste nach Reinalkohol und chronologischen Event-Feed mit Emoji-Reaktionen.
- **Quick-Repeat Daumenzone:** Schwimmender 1-Klick-Button *„Nochmal [Drink]“* zum sekundenschnellen Eintragen von Folgedrinks.
- **Runden-Logik:** Gleichzeitiges Spendieren und Eintragen von Runden für mehrere Freunde.
- **Offline-Gäste:** Mitnahme von Freunden ohne Smartphone über die Gast-Funktion des Hosts.
- **Spotify-Wrapped Story Player:** Animierter Jahresrückblick-Style Story-Player bei Party-Ende mit Peak-Hour-Analyse, Top-Getränk, virtuellem Treppchen und persönlicher Statistik.
- **PWA-Vollunterstützung:** Offline-Caching, Service Worker und Standalone-Installation auf iOS & Android.

---

## [1.0.0] - 2026-08-31
### Hinzugefügt
- **Cloud-Backend-Migration:** Umstellung des lokalen Speicher-Systems auf Supabase PostgreSQL.
- **Identity & Profile:** Benutzer-Erstellung mit Name, Avatar-Emoji und Erkennungsfarbe.
- **Tavern Edition UI:** Warmes Tavernen-Design mit Single-View-Architektur.
- **Freundesverwaltung:** Hinzufügen, Entfernen und Bestätigungs-Modals für Freunde.

---

## [0.2.0] - 2026-06-25
### Hinzugefügt
- **Abend-Podium:** Virtuelles Siegerpodest für die Top-3-Trinker des Abends.
- **Mischgetränke:** Konfigurierbare Spirituosen- und Filler-Mischungen.
- **Neumorphes Design:** Frühes Schatten- und Relief-Design.
- **Reset-Funktion:** Zurücksetzen der Abendsitzung mit Bestätigungsmodal.

---

## [0.1.0] - 2026-06-24
### Hinzugefügt
- **Initialer Prototyp:** Lokales Tracking von Getränken im Browser.
- **Berechnungen:** Berechnung von Gramm Reinalkohol und Biervolumen (Liter).
- **Profil & Freunde:** Einfache Übersicht über eigene Getränke und Freunde.

[Unreleased]: https://github.com/94ASG/AlcoholTracker/compare/v2.2.0...HEAD
[2.2.0]: https://github.com/94ASG/AlcoholTracker/compare/v2.1.1...v2.2.0
[2.1.1]: https://github.com/94ASG/AlcoholTracker/compare/v2.1.0...v2.1.1
[2.1.0]: https://github.com/94ASG/AlcoholTracker/compare/v2.0.2...v2.1.0
[2.0.2]: https://github.com/94ASG/AlcoholTracker/compare/v2.0.1...v2.0.2
[2.0.1]: https://github.com/94ASG/AlcoholTracker/compare/v2.0.0...v2.0.1
[2.0.0]: https://github.com/94ASG/AlcoholTracker/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/94ASG/AlcoholTracker/compare/v0.2.0...v1.0.0
[0.2.0]: https://github.com/94ASG/AlcoholTracker/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/94ASG/AlcoholTracker/releases/tag/v0.1.0
