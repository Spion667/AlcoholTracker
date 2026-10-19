#!/usr/bin/env bash
# Schreibt dart_defines.json aus Umgebungsvariablen (CI).
# Mit REQUIRE_SUPABASE=true bricht das Skript ab, wenn URL oder Key fehlen.
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ "${REQUIRE_SUPABASE:-false}" == "true" ]] &&
  [[ -z "${SUPABASE_URL:-}" || -z "${SUPABASE_PUBLISHABLE_KEY:-}" ]]; then
  echo "::error::SUPABASE_URL und SUPABASE_PUBLISHABLE_KEY fehlen (Repo-Variablen)."
  exit 1
fi

jq -n \
  --arg url "${SUPABASE_URL:-}" \
  --arg key "${SUPABASE_PUBLISHABLE_KEY:-}" \
  --arg web "${WEB_BASE_URL:-}" \
  '{SUPABASE_URL: $url, SUPABASE_PUBLISHABLE_KEY: $key, WEB_BASE_URL: $web}' \
  >dart_defines.json

if [[ -z "${SUPABASE_URL:-}" ]]; then
  echo "::warning::Keine Supabase-Konfiguration – die App zeigt beim Start den Konfigurationsfehler."
fi
