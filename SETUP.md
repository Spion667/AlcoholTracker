# AlcoholTracker 2.0 – Setup & Deployment Guide

## 1. Supabase SQL-Migration ausführen (Wichtig!)

Öffne dein Supabase Dashboard:
1. Gehe zu **SQL Editor** &rarr; **New query**.
2. Öffne die Datei [`supabase/migrations/001_party_schema.sql`](./supabase/migrations/001_party_schema.sql), kopiere den gesamten Inhalt hinein und klicke auf **Run**.
3. *(Optional für automatische Push-Benachrichtigungen)*: Öffne [`supabase/migrations/002_cron.sql`](./supabase/migrations/002_cron.sql), füge den Inhalt in eine neue Query ein und führe ihn aus.

Damit sind alle Tabellen (`parties`, `profiles`, `party_members`, `drinks`, `reactions`, `push_subscriptions`), Trigger und Realtime-Streams eingerichtet.

---

## 2. Umgebungsvariablen (.env & Vercel)

Erstelle deine lokale `.env` (oder überprüfe sie):
```bash
VITE_SUPABASE_URL=https://<dein-projekt>.supabase.co
VITE_SUPABASE_PUBLISHABLE_KEY=sb_publishable_<dein-key>
```
> **Wichtig:** Verwende in Browsern immer den **Publishable Key** (beginnt mit `sb_publishable_...`), nicht den Secret Key!

Trage die gleichen beiden Variablen in Vercel unter **Project Settings &rarr; Environment Variables** ein.

---

## 3. Lokale Entwicklung

```bash
npm install
npm run dev
```

Die App öffnet sich unter `http://localhost:5173`.
- **Install-Hinweis / PWA:** Im Browser erscheint der Screen zum Hinzufügen auf den Homescreen. Klicke unten auf *„Im Browser fortfahren (Test-Modus)“*, um die App direkt auf deinem Rechner zu testen.
- **Auf Smartphones:** Öffne die URL in Safari (iOS) oder Chrome (Android) und füge sie wie auf dem Screen beschrieben zum Home-Bildschirm hinzu.

---

## 4. Tests & Build

```bash
# Tests ausführen
npm test

# Linter prüfen
npm run lint

# Produktions-Build erstellen
npm run build
```

---

## 5. Native App (Flutter)

Die Android-/iOS-App liegt in [`flutter_app/`](./flutter_app) und verwendet dasselbe Supabase-Projekt.

```bash
cd flutter_app
cp dart_defines.example.json dart_defines.json   # URL + Publishable Key eintragen
flutter pub get
flutter run --dart-define-from-file=dart_defines.json
```

Ohne Backend: `flutter run --dart-define=DEMO_MODE=true`. Builds, Signing und Architektur: [`flutter_app/README.md`](./flutter_app/README.md).

