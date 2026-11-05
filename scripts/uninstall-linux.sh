#!/bin/sh
# Releases every lease, removes hook integrations, the CLI, the autostart entry and NonSleep's state.
set -eu
bindir="${BINDIR:-$HOME/.local/bin}"
config="${XDG_CONFIG_HOME:-$HOME/.config}"
state="${XDG_STATE_HOME:-$HOME/.local/state}"
data="${XDG_DATA_HOME:-$HOME/.local/share}"

pkill -f "$bindir/nonsleep auto" 2>/dev/null || true
pkill -f "$bindir/nonsleep-indicator" 2>/dev/null || true
if [ -x "$bindir/nonsleep" ]; then
    "$bindir/nonsleep" off || true
    "$bindir/nonsleep" integrate all --remove || true
fi
rm -f "$bindir/nonsleep" "$bindir/nonsleep-indicator" \
    "$config/autostart/nonsleep-auto.desktop" "$config/autostart/nonsleep-indicator.desktop" \
    "$data"/icons/hicolor/scalable/apps/nonsleep-*.svg
rm -rf "$config/nonsleep" "$state/nonsleep"
echo "NonSleep removed."
