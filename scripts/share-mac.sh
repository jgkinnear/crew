#!/bin/sh
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

xcodebuild -project Crew.xcodeproj -scheme Crew -configuration Release \
  -derivedDataPath ./DerivedData \
  -destination 'platform=macOS' \
  -clonedSourcePackagesDirPath ./SourcePackages \
  CODE_SIGN_IDENTITY="-" build

APP="$ROOT/DerivedData/Build/Products/Release/Crew.app"
mkdir -p "$ROOT/release"
codesign --force --deep --sign - --timestamp=none "$APP"
ZIP="$ROOT/release/Crew-mac-arm64.zip"
rm -f "$ZIP"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$ZIP"

echo
echo "Share this file:"
echo "  $ZIP"
echo
echo "Teammate, after unzipping:"
echo "  xattr -cr /path/to/Crew.app"
echo "then open Crew.app."
