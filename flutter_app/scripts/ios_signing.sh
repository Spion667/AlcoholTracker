#!/usr/bin/env bash
# Hilfsskript fuer das iOS-Signing ohne Mac (braucht nur openssl, z. B. Git Bash).
#
#   scripts/ios_signing.sh csr                  -> erzeugt Schluessel + CSR
#   scripts/ios_signing.sh p12 distribution.cer -> erzeugt .p12 + Base64 fuer GitHub
#   scripts/ios_signing.sh profile X.mobileprovision -> Base64 des Profils fuer GitHub
#
# Die Dateien landen in ./ios-signing/ (per .gitignore ausgeschlossen).
# Den privaten Schluessel niemals committen oder weitergeben.
set -euo pipefail
cd "$(dirname "$0")/.."
out="ios-signing"
mkdir -p "$out"

case "${1:-}" in
  csr)
    if [[ -f "$out/dist.key" ]]; then
      echo "$out/dist.key existiert schon – nicht ueberschrieben." >&2
      exit 1
    fi
    openssl genrsa -out "$out/dist.key" 2048
    openssl req -new -key "$out/dist.key" -out "$out/dist.csr" \
      -subj "/CN=AlcoholTracker Distribution/C=DE"
    echo "CSR: $out/dist.csr -> bei developer.apple.com als 'Apple Distribution' hochladen."
    ;;
  p12)
    cer="${2:?Pfad zur heruntergeladenen .cer-Datei angeben}"
    read -r -s -p "Passwort fuer die .p12 (wird Secret IOS_DIST_CERT_PASSWORD): " password
    echo
    openssl x509 -inform DER -in "$cer" -out "$out/dist.pem"
    # -legacy: macOS 'security import' versteht die OpenSSL-3-Standardverschluesselung nicht.
    legacy=()
    openssl pkcs12 -help 2>&1 | grep -q -- '-legacy' && legacy=(-legacy)
    openssl pkcs12 -export ${legacy[@]+"${legacy[@]}"} -inkey "$out/dist.key" -in "$out/dist.pem" \
      -out "$out/dist.p12" -passout "pass:$password"
    base64 <"$out/dist.p12" | tr -d '\n' >"$out/dist.p12.base64"
    echo "Fertig: Inhalt von $out/dist.p12.base64 -> Secret IOS_DIST_CERT_P12_BASE64"
    ;;
  profile)
    profile="${2:?Pfad zur heruntergeladenen .mobileprovision-Datei angeben}"
    base64 <"$profile" | tr -d '\n' >"$out/profile.base64"
    echo "Fertig: Inhalt von $out/profile.base64 -> Secret IOS_PROVISIONING_PROFILE_BASE64"
    ;;
  *)
    sed -n '2,9p' "$0"
    exit 1
    ;;
esac
