#!/bin/sh
# Releases every lease, removes hook integrations, the CLI, the autostart entry and NonSleep's state.
set -eu
bindir="${BINDIR:-$HOME/.local/bin}"
config="${XDG_CONFIG_HOME:-$HOME/.config}"
state="${XDG_STATE_HOME:-$HOME/.local/state}"

pkill -f "$bindir/nonsleep auto" 2>/dev/null || true
if [ -x "$bindir/nonsleep" ]; then
    "$bindir/nonsleep" off || true
    "$bindir/nonsleep" integrate all --remove || true
fi
rm -f "$bindir/nonsleep" "$config/autostart/nonsleep-auto.desktop"
rm -rf "$config/nonsleep" "$state/nonsleep"
echo "NonSleep removed."
