#!/bin/sh
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

ZIP="${1:-$ROOT/release/Crew-mac-arm64.zip}"
APP="${2:-$ROOT/DerivedData/Build/Products/Release/Crew.app}"
KEY="${SPARKLE_ED25519_KEY:-}"

if [ ! -f "$ZIP" ] || [ ! -d "$APP" ]; then
  echo "Need a built Crew.app and zip. Run scripts/share-mac.sh first."
  exit 1
fi
if [ -z "$KEY" ]; then
  echo "SPARKLE_ED25519_KEY is not set."
  exit 1
fi

TOOLS="$ROOT/release/sparkle-tools"
mkdir -p "$TOOLS"
if [ ! -x "$TOOLS/sign_update" ]; then
  curl -fsSL -o "$TOOLS/Sparkle.tar.xz" "https://github.com/sparkle-project/Sparkle/releases/download/2.10.0/Sparkle-2.10.0.tar.xz"
  tar -xJf "$TOOLS/Sparkle.tar.xz" -C "$TOOLS"
fi

KEYFILE="$(mktemp)"
trap 'rm -f "$KEYFILE"' EXIT
printf '%s' "$KEY" > "$KEYFILE"

SIGNATURE="$("$TOOLS/sign_update" --ed-key-file "$KEYFILE" -p "$ZIP")"
LENGTH="$(stat -f%z "$ZIP")"
SHORT="$(defaults read "$APP/Contents/Info" CFBundleShortVersionString)"
BUILD="$(defaults read "$APP/Contents/Info" CFBundleVersion)"
PUBDATE="$(LC_ALL=C date -u '+%a, %d %b %Y %H:%M:%S +0000')"

if ! gh release view updates --repo jgkinnear/crew >/dev/null 2>&1; then
  gh release create updates --repo jgkinnear/crew --target master --title "Crew updates" --notes "Latest Crew build. Installed copies check this release."
fi

gh release upload updates "$ZIP" --repo jgkinnear/crew --clobber

ASSET_URL="$(gh api repos/jgkinnear/crew/releases/tags/updates --jq '.assets[] | select(.name=="Crew-mac-arm64.zip") | .url')"
if [ -z "$ASSET_URL" ]; then
  echo "Could not find the uploaded zip on the updates release."
  exit 1
fi

APPCAST="$ROOT/release/appcast.xml"
cat > "$APPCAST" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>Crew</title>
    <item>
      <title>Version ${SHORT}</title>
      <pubDate>${PUBDATE}</pubDate>
      <sparkle:version>${BUILD}</sparkle:version>
      <sparkle:shortVersionString>${SHORT}</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
      <enclosure
        url="${ASSET_URL}"
        sparkle:edSignature="${SIGNATURE}"
        sparkle:os="macos"
        length="${LENGTH}"
        type="application/octet-stream"/>
    </item>
  </channel>
</rss>
EOF

gh release upload updates "$APPCAST" --repo jgkinnear/crew --clobber
echo "Published Crew ${SHORT} (${BUILD}) to the updates release."
