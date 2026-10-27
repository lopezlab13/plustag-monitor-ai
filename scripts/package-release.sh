#!/bin/zsh
set -eu
cd "${0:A:h:h}"
VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Resources/Info.plist)
ARCH=$(uname -m)
OUTPUT="$PWD/release"
# Do not replace the developer's running copy or its Accessibility identity.
export PLUSTAG_OUTPUT_DIR="$PWD/.build/release-app"
./scripts/build.sh
mkdir -p "$OUTPUT"
ZIP="Plustag-Monitor-AI-${VERSION}-macOS-${ARCH}.zip"
STAGING=$(mktemp -d /private/tmp/plustag-release.XXXXXX)
trap 'rm -rf "$STAGING"' EXIT
cp -R -X "$PLUSTAG_OUTPUT_DIR/Plustag Monitor AI.app" "$STAGING/"
APP="$STAGING/Plustag Monitor AI.app"
xattr -cr "$APP"
codesign --force --deep --sign - "$APP"
codesign --verify --deep --strict "$APP"
/usr/bin/ditto -c -k --norsrc --keepParent "$APP" "$OUTPUT/$ZIP"
cp docs/INSTALACION.md "$OUTPUT/INSTALACION.md"
(cd "$OUTPUT" && shasum -a 256 "$ZIP" INSTALACION.md > SHA256SUMS.txt)
echo "Descarga preparada: $OUTPUT/$ZIP"
