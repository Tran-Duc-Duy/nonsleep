#!/bin/sh
# Installs NonSleep for the current user on Linux. No root needed.
#   ~/.local/bin/nonsleep                         the CLI (override with BINDIR=…)
#   ~/.config/autostart/nonsleep-auto.desktop     runs `nonsleep auto` in your desktop session
# Options: --no-autostart   skip the autostart entry
# Works from a release tarball (prebuilt `nonsleep` next to this script) or from the repo (builds it).
set -eu
here="$(cd "$(dirname "$0")" && pwd)"
bindir="${BINDIR:-$HOME/.local/bin}"
autostart="${XDG_CONFIG_HOME:-$HOME/.config}/autostart/nonsleep-auto.desktop"

if ! command -v systemd-inhibit >/dev/null 2>&1; then
    echo "install: systemd-inhibit not found; NonSleep for Linux needs systemd-logind." >&2
    exit 1
fi

if [ -x "$here/nonsleep" ]; then
    binary="$here/nonsleep"
else
    echo "==> Building nonsleep"
    cd "$here/.."
    swift build -c release --product nonsleep
    binary="$(swift build -c release --show-bin-path)/nonsleep"
fi

echo "==> Installing $bindir/nonsleep"
mkdir -p "$bindir"
install -m 0755 "$binary" "$bindir/nonsleep"

if [ "${1:-}" != "--no-autostart" ]; then
    echo "==> Autostart: $autostart"
    mkdir -p "$(dirname "$autostart")"
    cat > "$autostart" <<EOF
[Desktop Entry]
Type=Application
Name=NonSleep (auto)
Comment=Keep the laptop awake with the lid closed while AI agents work
Exec=$bindir/nonsleep auto
NoDisplay=true
X-GNOME-Autostart-enabled=true
EOF
fi

echo "==> Done. Try: nonsleep status   (and: nonsleep integrate all)"
case ":$PATH:" in *":$bindir:"*) ;; *) echo "    (add $bindir to PATH)" ;; esac
