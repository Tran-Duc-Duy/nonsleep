#!/bin/sh
# Installs NonSleep for the current user on Linux. No root needed.
#   ~/.local/bin/nonsleep                          the CLI (override with BINDIR=…)
#   ~/.config/autostart/nonsleep-auto.desktop      runs `nonsleep auto` in your desktop session
# Options: --no-autostart   skip the autostart entry
#          --indicator      also install the tray indicator: ~/.local/bin/nonsleep-indicator,
#                           its icons, and an autostart entry for it
# Works from a release tarball (prebuilt `nonsleep` next to this script) or from the repo (builds it).
set -eu
here="$(cd "$(dirname "$0")" && pwd)"
bindir="${BINDIR:-$HOME/.local/bin}"
datadir="${XDG_DATA_HOME:-$HOME/.local/share}"
autostart_dir="${XDG_CONFIG_HOME:-$HOME/.config}/autostart"
autostart="$autostart_dir/nonsleep-auto.desktop"

want_autostart=1
want_indicator=0
for arg in "$@"; do
    case "$arg" in
    --no-autostart) want_autostart=0 ;;
    --indicator) want_indicator=1 ;;
    *)
        echo "install: unknown option $arg (--no-autostart, --indicator)" >&2
        exit 2
        ;;
    esac
done

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

if [ "$want_autostart" -eq 1 ]; then
    echo "==> Autostart: $autostart"
    mkdir -p "$autostart_dir"
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

if [ "$want_indicator" -eq 1 ]; then
    # Repo layout: scripts/ + assets/linux/icons. Release tarball: both next to install.sh.
    icons="$here/icons"
    [ -d "$icons" ] || icons="$here/../assets/linux/icons"
    if [ ! -f "$here/nonsleep-indicator.py" ] || [ ! -d "$icons" ]; then
        echo "install: --indicator needs nonsleep-indicator.py and its icons next to $here" >&2
        exit 1
    fi
    echo "==> Installing $bindir/nonsleep-indicator"
    install -m 0755 "$here/nonsleep-indicator.py" "$bindir/nonsleep-indicator"
    icondir="$datadir/icons/hicolor/scalable/apps"
    mkdir -p "$icondir"
    for icon in "$icons"/nonsleep-*.svg; do install -m 0644 "$icon" "$icondir/"; done
    gtk-update-icon-cache -q -t -f "$datadir/icons/hicolor" 2>/dev/null || true

    mkdir -p "$autostart_dir"
    cat > "$autostart_dir/nonsleep-indicator.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=NonSleep (tray)
Comment=Tray indicator: lid-closed mode, leases, timers
Exec=$bindir/nonsleep-indicator
X-GNOME-Autostart-enabled=true
EOF
    command -v python3 >/dev/null 2>&1 ||
        echo "    (python3 not found — the indicator needs python3, GTK 3 and AppIndicator bindings)"
    echo "    Start it now with: nonsleep-indicator &"
fi

echo "==> Done. Try: nonsleep status   (and: nonsleep integrate all)"
case ":$PATH:" in *":$bindir:"*) ;; *) echo "    (add $bindir to PATH)" ;; esac
