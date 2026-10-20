#!/bin/sh
# Restores normal sleep and removes everything NonSleep installed.
set -eu

app="$HOME/Applications/NonSleep.app"
cli="$app/Contents/MacOS/nonsleep"

osascript -e 'quit app id "dev.nonsleep.app"' 2>/dev/null || true
if [ -x "$cli" ]; then
    "$cli" integrate all --remove || true
    "$cli" setup --remove
fi
rm -rf "$app" "$HOME/Library/Application Support/NonSleep"

echo "NonSleep removed. pmset disablesleep is now: $(ioreg -r -c IOPMrootDomain -d1 | awk -F'= ' '/"SleepDisabled"/ {print $2}')"
