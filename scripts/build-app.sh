#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="Codex Pulse"
BUILD_DIR="$ROOT/.build/release"
APP_DIR="$ROOT/dist/$APP_NAME.app"
STAGING_ROOT="$(mktemp -d "${TMPDIR%/}/codex-pulse-build.XXXXXX")"
STAGED_APP_DIR="$STAGING_ROOT/$APP_NAME.app"
CONTENTS="$STAGED_APP_DIR/Contents"

trap 'rm -rf "$STAGING_ROOT"' EXIT

cd "$ROOT"
swift build -c release

mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources"
cp "$BUILD_DIR/CodexUsage" "$CONTENTS/MacOS/CodexUsage"

plutil -create xml1 "$CONTENTS/Info.plist"
plutil -insert CFBundleName -string "$APP_NAME" "$CONTENTS/Info.plist"
plutil -insert CFBundleDisplayName -string "$APP_NAME" "$CONTENTS/Info.plist"
plutil -insert CFBundleExecutable -string "CodexUsage" "$CONTENTS/Info.plist"
plutil -insert CFBundleIdentifier -string "com.tuttokey.codex-pulse" "$CONTENTS/Info.plist"
plutil -insert CFBundlePackageType -string "APPL" "$CONTENTS/Info.plist"
plutil -insert CFBundleShortVersionString -string "1.0.0" "$CONTENTS/Info.plist"
plutil -insert CFBundleVersion -string "1" "$CONTENTS/Info.plist"
plutil -insert LSMinimumSystemVersion -string "14.0" "$CONTENTS/Info.plist"
plutil -insert LSUIElement -bool true "$CONTENTS/Info.plist"
plutil -insert NSHighResolutionCapable -bool true "$CONTENTS/Info.plist"

xattr -cr "$STAGED_APP_DIR"
codesign --force --deep --sign - "$STAGED_APP_DIR"
codesign --verify --deep --strict "$STAGED_APP_DIR"

mkdir -p "$ROOT/dist"
rm -rf "$APP_DIR"
ditto --norsrc --noextattr "$STAGED_APP_DIR" "$APP_DIR"
print "Built: $APP_DIR"
