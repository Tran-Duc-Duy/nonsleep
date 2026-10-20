#!/bin/sh
# Builds NonSleep from source and installs it for the current user:
#   ~/Applications/NonSleep.app, then `nonsleep setup` (one administrator dialog) for the
#   sudoers rule, the reaper LaunchAgent and the ~/.local/bin/nonsleep link.
# Downloaded the app from Releases instead? Open it and click "Finish setup…".
set -eu
cd "$(dirname "$0")/.."

apps="$HOME/Applications"

scripts/build-app.sh
app="build/NonSleep.app"

echo "==> Installing $apps/NonSleep.app"
mkdir -p "$apps"
osascript -e 'quit app id "dev.nonsleep.app"' 2>/dev/null || true
rm -rf "$apps/NonSleep.app"
cp -R "$app" "$apps/"

echo "==> Setup (sudoers rule, reaper LaunchAgent, CLI link)"
"$apps/NonSleep.app/Contents/MacOS/nonsleep" setup

open "$apps/NonSleep.app"
echo "==> Done. Try: nonsleep status"
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) echo "    (add ~/.local/bin to PATH)" ;; esac
