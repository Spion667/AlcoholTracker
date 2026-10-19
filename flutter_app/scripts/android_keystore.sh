#!/usr/bin/env bash
# Erzeugt den Android-Signaturschluessel (PKCS12-Keystore) – braucht nur openssl.
#
#   scripts/android_keystore.sh
#
# Ergebnis in ./android-signing/ (per .gitignore ausgeschlossen):
#   upload.p12         Keystore – sicher aufbewahren, ohne ihn keine Updates moeglich
#   upload.p12.base64  Inhalt fuer das GitHub-Secret ANDROID_KEYSTORE_BASE64
#   key.properties     fuer lokale Release-Builds nach android/key.properties kopieren
set -euo pipefail
cd "$(dirname "$0")/.."
out="android-signing"
alias="upload"

if [[ -f "$out/upload.p12" ]]; then
  echo "$out/upload.p12 existiert schon – nicht ueberschrieben." >&2
  exit 1
fi
mkdir -p "$out"

read -r -s -p "Passwort fuer den Keystore (mind. 6 Zeichen, wird Secret ANDROID_KEYSTORE_PASSWORD): " password
echo
if [[ ${#password} -lt 6 ]]; then
  echo "Passwort zu kurz." >&2
  exit 1
fi

# 10 000 Tage (~27 Jahre): Google Play verlangt eine Gueltigkeit ueber 2033 hinaus.
openssl req -x509 -newkey rsa:2048 -sha256 -days 10000 -nodes \
  -keyout "$out/upload.key" -out "$out/upload.crt" -subj "/CN=AlcoholTracker/C=DE" 2>/dev/null
openssl pkcs12 -export -name "$alias" -inkey "$out/upload.key" -in "$out/upload.crt" \
  -out "$out/upload.p12" -passout "pass:$password"
rm "$out/upload.key"

base64 <"$out/upload.p12" | tr -d '\n' >"$out/upload.p12.base64"
# Git Bash unter Windows: "pwd -W" liefert C:/... statt /c/..., das versteht Gradle.
dir="$(pwd -W 2>/dev/null || pwd)"
cat >"$out/key.properties" <<PROPS
storeFile=$dir/$out/upload.p12
storePassword=$password
keyAlias=$alias
keyPassword=$password
PROPS

echo "Fertig. SHA-256-Fingerabdruck (fuer spaeter, z. B. App Links):"
openssl x509 -in "$out/upload.crt" -noout -fingerprint -sha256
echo "Secrets: ANDROID_KEYSTORE_BASE64 = Inhalt von $out/upload.p12.base64, ANDROID_KEYSTORE_PASSWORD = dein Passwort"
