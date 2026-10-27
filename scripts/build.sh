#!/bin/zsh
set -eu
cd "${0:A:h:h}"
export CLANG_MODULE_CACHE_PATH="$PWD/.build/modules"
export SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/modules"
mkdir -p .build/modules .build/cache
swift build --disable-sandbox --cache-path "$PWD/.build/cache" -c release -debug-info-format none
BIN_DIR=$(swift build --disable-sandbox --cache-path "$PWD/.build/cache" -c release --show-bin-path)
# Sign outside cloud-synced Documents, which can add Finder metadata during signing.
STAGING=$(mktemp -d /private/tmp/plustag-monitor.XXXXXX)
trap 'rm -rf "$STAGING"' EXIT
APP="$STAGING/Plustag Monitor AI.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp -X "$BIN_DIR/PlustagMonitor" "$APP/Contents/MacOS/PlustagMonitor"
cp -X Resources/Info.plist "$APP/Contents/Info.plist"
cp -X Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
for resource in "$BIN_DIR"/*.bundle; do
  cp -R -X "$resource" "$APP/Contents/Resources/"
done
xattr -cr "$APP"
codesign --force --deep --sign - "$APP"
OUTPUT_ROOT="${PLUSTAG_OUTPUT_DIR:-$PWD/dist}"
mkdir -p "$OUTPUT_ROOT"
# Replace only this generated app; preserve all source files.
if [[ -d "$OUTPUT_ROOT/Plustag Monitor AI.app" ]]; then
  rm -rf "$OUTPUT_ROOT/Plustag Monitor AI.app"
fi
cp -R -X "$APP" "$OUTPUT_ROOT/"
echo "App creada en: $OUTPUT_ROOT/Plustag Monitor AI.app"
