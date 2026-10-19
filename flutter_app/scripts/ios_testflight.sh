#!/usr/bin/env bash
# Baut ein signiertes iOS-Release (IPA) und laedt es zu App Store Connect hoch,
# von wo es in TestFlight erscheint. Laeuft auf einem macOS-Runner (GitHub Actions).
#
# Signiert wird manuell mit einem Apple-Distribution-Zertifikat (.p12) und einem
# App-Store-Provisioning-Profil; hochgeladen mit einem App-Store-Connect-API-Key.
# Einrichtung: docs/TESTFLIGHT.md
set -euo pipefail
cd "$(dirname "$0")/.."

for var in BUILD_NUMBER IOS_DIST_CERT_P12_BASE64 IOS_DIST_CERT_PASSWORD \
  IOS_PROVISIONING_PROFILE_BASE64 ASC_KEY_ID ASC_ISSUER_ID ASC_KEY_P8; do
  if [[ -z "${!var:-}" ]]; then
    echo "::error::Secret $var fehlt (siehe flutter_app/docs/TESTFLIGHT.md)."
    exit 1
  fi
done

work="${RUNNER_TEMP:-$(mktemp -d)}/ios-signing"
mkdir -p "$work"
keychain="$work/signing.keychain-db"
keychain_password="$(openssl rand -base64 24)"

cleanup() {
  security delete-keychain "$keychain" >/dev/null 2>&1 || true
  rm -rf "$work"
}
trap cleanup EXIT

# --- Zertifikat in eine temporaere Keychain -------------------------------
echo "$IOS_DIST_CERT_P12_BASE64" | base64 --decode >"$work/dist.p12"
security create-keychain -p "$keychain_password" "$keychain"
security set-keychain-settings -lut 21600 "$keychain"
security unlock-keychain -p "$keychain_password" "$keychain"
security import "$work/dist.p12" -P "$IOS_DIST_CERT_PASSWORD" -A -t cert -f pkcs12 -k "$keychain"
security set-key-partition-list -S apple-tool:,apple: -k "$keychain_password" "$keychain" >/dev/null
security list-keychains -d user -s "$keychain" $(security list-keychains -d user | tr -d '"')

# --- Provisioning-Profil installieren --------------------------------------
profile="$work/appstore.mobileprovision"
echo "$IOS_PROVISIONING_PROFILE_BASE64" | base64 --decode >"$profile"
security cms -D -i "$profile" >"$work/profile.plist"
profile_uuid="$(/usr/libexec/PlistBuddy -c 'Print :UUID' "$work/profile.plist")"
profile_name="$(/usr/libexec/PlistBuddy -c 'Print :Name' "$work/profile.plist")"
team_id="$(/usr/libexec/PlistBuddy -c 'Print :TeamIdentifier:0' "$work/profile.plist")"
app_id="$(/usr/libexec/PlistBuddy -c 'Print :Entitlements:application-identifier' "$work/profile.plist")"
bundle_id="${app_id#"$team_id".}"
echo "Profil: $profile_name ($profile_uuid), Team $team_id, Bundle $bundle_id"

# Xcode < 16 und Xcode >= 16 suchen an unterschiedlichen Orten.
for dir in "$HOME/Library/MobileDevice/Provisioning Profiles" \
  "$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles"; do
  mkdir -p "$dir"
  cp "$profile" "$dir/$profile_uuid.mobileprovision"
done

# --- Runner-Target fuer Release auf manuelles Signing umstellen -----------
# (nur im CI-Checkout; im Repo bleibt automatisches Signing fuer Xcode-Nutzer)
ruby -e 'require "xcodeproj"' 2>/dev/null || gem install xcodeproj --no-document
ruby -rxcodeproj -e '
  project = Xcodeproj::Project.open("ios/Runner.xcodeproj")
  target = project.targets.find { |t| t.name == "Runner" }
  config = target.build_configurations.find { |c| c.name == "Release" }
  s = config.build_settings
  s["CODE_SIGN_STYLE"] = "Manual"
  s["DEVELOPMENT_TEAM"] = ARGV[0]
  s["CODE_SIGN_IDENTITY"] = "Apple Distribution"
  s["CODE_SIGN_IDENTITY[sdk=iphoneos*]"] = "Apple Distribution"
  s["PROVISIONING_PROFILE_SPECIFIER"] = ARGV[1]
  abort "Bundle-ID passt nicht zum Profil: #{s["PRODUCT_BUNDLE_IDENTIFIER"]} != #{ARGV[2]}" \
    unless s["PRODUCT_BUNDLE_IDENTIFIER"] == ARGV[2]
  project.save
' "$team_id" "$profile_name" "$bundle_id"

cat >"$work/ExportOptions.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>app-store-connect</string>
  <key>signingStyle</key>
  <string>manual</string>
  <key>teamID</key>
  <string>$team_id</string>
  <key>provisioningProfiles</key>
  <dict>
    <key>$bundle_id</key>
    <string>$profile_name</string>
  </dict>
  <key>uploadSymbols</key>
  <true/>
</dict>
</plist>
PLIST

# --- Build -----------------------------------------------------------------
flutter build ipa --release \
  --build-number="$BUILD_NUMBER" \
  --dart-define-from-file=dart_defines.json \
  --export-options-plist="$work/ExportOptions.plist"

ipa="$(find build/ios/ipa -maxdepth 1 -name '*.ipa' | head -n 1)"
[[ -n "$ipa" ]] || { echo "::error::Keine IPA gefunden."; exit 1; }

# --- Upload ----------------------------------------------------------------
mkdir -p "$HOME/.appstoreconnect/private_keys"
key_file="$HOME/.appstoreconnect/private_keys/AuthKey_$ASC_KEY_ID.p8"
printf '%s\n' "$ASC_KEY_P8" >"$key_file"
trap 'rm -f "$key_file"; cleanup' EXIT

xcrun altool --upload-app --type ios --file "$ipa" \
  --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID"

echo "Hochgeladen: Build $BUILD_NUMBER. Nach der Verarbeitung (meist 5–30 min) erscheint er in TestFlight."
