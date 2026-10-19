# Android → APK direkt verteilen

Die APK wird auf GitHub Actions gebaut, mit einem festen eigenen Schlüssel signiert und als
GitHub-Release abgelegt. Von dort lädst du sie herunter und schickst sie den Testern
(Messenger, Drive, …). Ein Play-Console-Konto ist nicht nötig.

**Application ID:** `com.alcoholtracker.alcohol_tracker`

## Warum ein eigener Schlüssel?

Android installiert ein Update nur, wenn es mit **demselben Schlüssel** signiert ist wie die
installierte Version. Ohne eigenen Schlüssel signiert der Build mit einem zufälligen
Debug-Schlüssel. Dann geht ein Update nur über Deinstallieren, und dabei ist das Profil weg.

> **Schlüssel verloren = keine Updates mehr.** Alle Tester müssten neu installieren und
> verlieren ihr Profil. `android-signing/` deshalb sicher sichern (Passwortmanager, zweites Medium).
> Für einen späteren Play-Store-Start lässt sich derselbe Schlüssel als Upload-Key verwenden.

## Einmalige Einrichtung

### 1. Schlüssel erzeugen

Braucht nur `openssl` (macOS/Linux, unter Windows Git Bash):

```bash
cd flutter_app
scripts/android_keystore.sh          # fragt nach einem Passwort
```

Ergebnis in `android-signing/` (per `.gitignore` ausgeschlossen):

| Datei | Zweck |
| --- | --- |
| `upload.p12` | der Schlüssel (PKCS12-Keystore, Alias `upload`) |
| `upload.p12.base64` | Inhalt für das GitHub-Secret |
| `key.properties` | für lokale Release-Builds (siehe unten) |

### 2. GitHub konfigurieren

Repo → *Settings* → *Secrets and variables* → *Actions*.

**Secrets:** `ANDROID_KEYSTORE_BASE64` (Inhalt von `upload.p12.base64`),
`ANDROID_KEYSTORE_PASSWORD` (Passwort aus Schritt 1).

**Variables:** `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, optional `WEB_BASE_URL`
(dieselben Werte wie in der Web-App).

## Release erstellen

Der Workflow muss auf dem Default-Branch (`main`) liegen, damit GitHub den manuellen Start anbietet.

*Actions* → **Flutter App** → *Run workflow* → Branch wählen → Häkchen
**„Signierte Android-APK als GitHub-Release veröffentlichen"** → *Run*.

Nach ca. 7 Minuten liegt unter *Releases* `alcoholtracker-<version>-<build>.apk`.
Die Build-Nummer (= `versionCode`) ist die Run-Nummer und steigt automatisch. Updates lassen
sich deshalb immer über die vorige Version installieren.

Das Repo ist privat: Tester können die Release-Seite nicht öffnen. Die APK also selbst
herunterladen und weitergeben.

## Installation bei Testern

1. APK öffnen (aus Messenger, Downloads, …).
2. Android fragt einmalig, ob diese App (z. B. WhatsApp oder Chrome) **unbekannte Apps
   installieren** darf → erlauben.
3. Google Play Protect kann warnen, weil die App nicht aus dem Play Store stammt →
   *Details* → *Trotzdem installieren*.

Updates: neue APK genauso öffnen. Die Daten bleiben erhalten.

Wer vorher eine der unsignierten Test-APKs (Artefakte vor Einrichtung des Schlüssels)
installiert hatte, muss diese **einmal** deinstallieren.

> Laut Ankündigung von Google verlangt Android künftig auch für Apps außerhalb des Play Stores
> eine Entwickler-Verifizierung (zuerst in einzelnen Ländern, weltweit ab 2027). Bis dahin
> funktioniert die Installation wie oben beschrieben.

## Lokal bauen (optional)

```bash
cp android-signing/key.properties android/key.properties
flutter build apk --release --dart-define-from-file=dart_defines.json
```

`android/key.properties` ist per `.gitignore` ausgeschlossen. Ohne diese Datei (und ohne die
CI-Umgebungsvariablen) fällt der Build auf den Debug-Schlüssel zurück.
