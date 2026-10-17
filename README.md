# AlcoholTracker 🍺⚡

[![Version](https://img.shields.io/badge/version-2.2.0-cyan.svg)](CHANGELOG.md)
[![Changelog](https://img.shields.io/badge/changelog-Keep%20a%20Changelog-brightgreen.svg)](CHANGELOG.md)

Eine moderne, party-basierte Progressive Web App (PWA) im **Neon Night Design**, um gemeinsam mit Freunden den Alkoholkonsum am Abend live zu tracken – inklusive Live-Ranking, Reaktions-Feed und automatischem **Spotify-Wrapped-Rückblick** am nächsten Morgen.

---

## Highlights

- 📱 **Echtes PWA-Feeling:** Wird als Vollbild-App auf dem Home-Bildschirm installiert (Schutz vor versehentlichem Schließen & Push-Benachrichtigungen).
- ⚡ **1-Tap Drink Logging:** Ein Klick auf die Kachel loggt das Getränk sofort mit Konfetti und Haptic Feedback – kein Ausfüllen von Excel-Tabellen mehr!
- 🍻 **Runde ausgeben & Gäste ohne Handy:** Mit einem Tap eine Runde Bier oder Schnaps für beliebig viele Freunde gleichzeitig eintragen. Freunde ohne Smartphone können als Gast hinzugefügt werden.
- 🥤 **Mischen-Konfigurator:** Individuelle Mischgetränke (Wodka, Korn, Springer) mit flexiblen Verhältnissen (10:90 bis 50:50) und Glasgrößen.
- 🏆 **Live-Ranking:** Rangliste sortiert nach **Gramm reinem Alkohol** mit relativen Fortschrittsbalken und Anzeige der getrunkenen Drinks.
- 🔥 **Live-Feed mit Reaktionen:** Chronologischer Stream aller Drinks mit Emoji-Reaktionen (🔥, 🍻, 😵, 🫡, 💧).
- ↩️ **5-Sekunden Undo-Toast:** Schnelles Rückgängigmachen direkt nach dem Eintragen.
- 🎊 **Spotify Wrapped Rückblick:** Automatisches Story-Highlight am Ende der Party (oder nächsten Morgen um 10 Uhr) mit animierten Slides: Gesamtalkohol, Bier-Vergleiche, beliebtester Drink, Peak-Hour, Spendierhose und Siegertreppchen 🥇🥈🥉.

---

## Tech-Stack

- **Frontend (Web/PWA):** React 19, Vite, React Router, Tailwind CSS, Canvas-Confetti, Lucide Icons, Vite-PWA
- **Native App (Android & iOS):** Flutter – siehe [`flutter_app/`](./flutter_app)
- **Backend & Database:** Supabase (PostgreSQL, Supabase Realtime, Edge Functions)
- **Hosting:** Vercel (mit SPA Rewrites via `vercel.json`)

---

## 📱 Native App (Flutter)

Neben der PWA gibt es eine echte Android-/iOS-App mit animiertem Startscreen im Ordner [`flutter_app/`](./flutter_app).
Sie nutzt dasselbe Supabase-Backend und denselben Funktionsumfang (Live-Ranking, Feed, Runden, Wrapped, Promille-Radar, Party-PIN).

```bash
cd flutter_app
flutter run --dart-define=DEMO_MODE=true                         # Demo ohne Backend
flutter run --dart-define-from-file=dart_defines.json            # mit deinem Supabase-Projekt
```

Details, Builds und Unterschiede zur Web-App: [`flutter_app/README.md`](./flutter_app/README.md).

---

## Setup & Schnellanleitung (Web)

Eine detaillierte Anleitung zur Datenbank-Einrichtung und den Schlüsseln findest du in [`SETUP.md`](./SETUP.md).

```bash
# Abhängigkeiten installieren
npm install

# Entwicklungsserver starten
npm run dev

# Tests ausführen
npm test

# Build erstellen
npm run build
```
