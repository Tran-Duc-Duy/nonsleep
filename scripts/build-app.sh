#!/bin/sh
# Builds build/NonSleep.app (menu bar app + bundled `nonsleep` CLI). No Xcode project needed.
#   VERSION=1.2.3          version written to Info.plist (default 0.0.0-dev)
#   ARCHS="arm64 x86_64"   universal binary (needs full Xcode); default: this Mac's arch
set -eu
cd "$(dirname "$0")/.."

version="${VERSION:-0.0.0-dev}"
app="build/NonSleep.app"

arch_flags=""
for arch in ${ARCHS:-}; do arch_flags="$arch_flags --arch $arch"; done

# shellcheck disable=SC2086 # arch_flags is a deliberately split word list
swift build -c release $arch_flags --product NonSleepBar
# shellcheck disable=SC2086
swift build -c release $arch_flags --product nonsleep
# shellcheck disable=SC2086
bin="$(swift build -c release $arch_flags --show-bin-path)"

rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$bin/NonSleepBar" "$bin/nonsleep" "$app/Contents/MacOS/"
sed "s/@VERSION@/$version/g" Resources/Info.plist > "$app/Contents/Info.plist"

# AppIcon.icns from the 1024px master (regenerate the master with scripts/make-icon.swift).
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
iconset="$scratch/AppIcon.iconset"
mkdir -p "$iconset"
for px in 16 32 128 256 512; do
    sips -z "$px" "$px" Resources/AppIcon.png --out "$iconset/icon_${px}x${px}.png" >/dev/null
    sips -z "$((px * 2))" "$((px * 2))" Resources/AppIcon.png --out "$iconset/icon_${px}x${px}@2x.png" >/dev/null
done
iconutil -c icns "$iconset" -o "$app/Contents/Resources/AppIcon.icns"

codesign --force --sign - "$app/Contents/MacOS/nonsleep"
codesign --force --sign - "$app"

echo "$app"
