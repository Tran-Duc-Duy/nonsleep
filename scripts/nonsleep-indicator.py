#!/usr/bin/env python3
"""NonSleep tray indicator for Linux.

A thin frontend: every decision stays in the `nonsleep` CLI, which this polls through
`nonsleep status --json` and drives with `nonsleep on|off|sleep`. No lease logic, no
inhibitor handling, no state of its own — if the indicator dies, nothing changes.

    nonsleep-indicator                 run the tray icon (GTK3 + AppIndicator)
    nonsleep-indicator --once          print one waybar/polybar JSON line and exit
    nonsleep-indicator --interval 10   poll every 10 s instead of 5

The tray needs python3-gi, gir1.2-gtk-3.0 and gir1.2-ayatanaappindicator3-0.1 (on GNOME
also the AppIndicator shell extension, shipped by default on Ubuntu). `--once` needs
none of them, so waybar/polybar/scripts work on a bare system.
"""

import argparse
import json
import shutil
import subprocess
import sys
from datetime import datetime, timezone

# Keys are the `mode` values of `nonsleep status --json` (schema 1), plus `unavailable`
# for "the CLI did not answer", which is a frontend concern the CLI never reports.
ICONS = {
    "awake": "nonsleep-awake-symbolic",
    "normal": "nonsleep-normal-symbolic",
    "suspended": "nonsleep-paused-symbolic",
    "foreign": "nonsleep-paused-symbolic",
    "unavailable": "nonsleep-error-symbolic",
}
# Used when NonSleep's own icons were not installed (running from a checkout, or a theme
# that ignores hicolor): plain freedesktop names every icon theme carries.
FALLBACK_ICONS = {
    "awake": "display-brightness-symbolic",
    "normal": "weather-clear-night-symbolic",
    "suspended": "media-playback-pause-symbolic",
    "foreign": "dialog-warning-symbolic",
    "unavailable": "dialog-error-symbolic",
}
LABELS = {
    "awake": "awake",
    "normal": "normal",
    "suspended": "paused",
    "foreign": "other tool",
    "unavailable": "unavailable",
}
PRESETS = [("45 minutes", "45m"), ("2 hours", "2h"), ("Until off", None)]
SCHEMA = 1


class CLIError(Exception):
    """`nonsleep` exited non-zero; the message is its stderr."""


def cli(binary, *args, timeout=15):
    result = subprocess.run(
        [binary, *args], capture_output=True, text=True, timeout=timeout, check=False
    )
    if result.returncode != 0:
        raise CLIError((result.stderr or result.stdout).strip() or f"exit {result.returncode}")
    return result.stdout


def status(binary):
    """The parsed report, or an `unavailable` stand-in carrying the reason."""
    try:
        report = json.loads(cli(binary, "status", "--json"))
    except FileNotFoundError:
        return {"mode": "unavailable", "headline": f"{binary} not found"}
    except (CLIError, subprocess.TimeoutExpired, json.JSONDecodeError, OSError) as error:
        return {"mode": "unavailable", "headline": f"nonsleep status failed: {error}"}
    if report.get("schema") != SCHEMA:
        report["headline"] = (
            f"unsupported status schema {report.get('schema')} (indicator expects {SCHEMA})"
        )
        report["mode"] = "unavailable"
    return report


def parse_time(text):
    if not text:
        return None
    try:
        return datetime.fromisoformat(text.replace("Z", "+00:00"))
    except ValueError:
        return None


def countdown(end, now=None):
    """"12m" / "1h20m" until `end`, or None when there is no deadline."""
    if end is None:
        return None
    seconds = int((end - (now or datetime.now(timezone.utc))).total_seconds())
    if seconds <= 0:
        return "0m"
    hours, minutes = divmod(seconds // 60, 60)
    return f"{hours}h{minutes:02d}m" if hours else f"{minutes}m"


def soonest_expiry(leases, now=None):
    """When the first lease runs out — the countdown worth putting in a 10-character bar."""
    ends = [end for end in (parse_time(lease.get("expiresAt")) for lease in leases) if end]
    return countdown(min(ends), now) if ends else None


def lease_line(lease):
    owner = f"pid {lease['ownerPID']}" if lease.get("ownerPID") is not None else "detached"
    left = countdown(parse_time(lease.get("expiresAt")))
    if left:
        owner += f", {left} left"
    return f"{lease.get('reason', lease.get('id', '?'))} ({owner})"


def power_line(power):
    if not power:
        return None
    facts = [
        "lid closed" if power.get("lidClosed") else "lid open",
        "battery" if power.get("onBattery") else "AC",
    ]
    if power.get("batteryPercent") is not None:
        facts.append(f"{power['batteryPercent']}%")
    if power.get("externalDisplay"):
        facts.append("external display")
    if power.get("thermal") and power["thermal"] != "nominal":
        facts.append(f"thermal {power['thermal']}")
    return " · ".join(facts)


def summarize(report):
    """Everything a frontend shows: `text`, `tooltip`, `class`/`alt`, and the icon name."""
    mode = report.get("mode", "unavailable")
    if mode not in ICONS:
        mode = "unavailable"
    leases = report.get("leases") or []
    text = LABELS[mode]
    soonest = soonest_expiry(leases)
    if mode == "awake" and soonest:
        text = f"awake {soonest}"

    if mode == "suspended":
        reason = report.get("blockedBy") or report.get("headline", "safety cut-out")
        lines = [
            "Normal sleep active (safety cut-out)",
            f"↳ Paused: {reason}",
        ]
        power = power_line(report.get("power"))
        if power:
            lines.append(power)
        lines.append(
            "Leases on hold: "
            + (", ".join(lease_line(lease) for lease in leases) if leases else "none")
            + " (resumes when charging)"
        )
    elif mode == "unavailable":
        lines = ["NonSleep unavailable", f"↳ {report.get('headline', 'CLI failed')}"]
    else:
        lines = [report.get("headline", LABELS[mode])]
        power = power_line(report.get("power"))
        if power:
            lines.append(power)
        lines.append(
            "Leases: "
            + (", ".join(lease_line(lease) for lease in leases) if leases else "none")
        )
    agents = report.get("agents") or []
    lines.append(
        "Agents: "
        + (", ".join(f"{a['name']} · pid {a['pid']}" for a in agents) if agents else "idle")
    )
    return {
        "text": text,
        "alt": mode,
        "class": mode,
        "tooltip": "\n".join(lines),
        "icon": mode,
    }


def pick_icon(mode, has_icon):
    """NonSleep's own icon when the theme has it, a stock freedesktop one otherwise."""
    name = ICONS[mode]
    return name if has_icon(name) else FALLBACK_ICONS[mode]


class Indicator:
    """GTK/AppIndicator shell around the pure helpers above."""

    def __init__(self, binary, interval):
        global Gtk, GLib, AppIndicator  # noqa: PLW0603 - imported late so --once needs no GTK
        import gi

        gi.require_version("Gtk", "3.0")
        try:
            gi.require_version("AyatanaAppIndicator3", "0.1")
            from gi.repository import AyatanaAppIndicator3 as AppIndicator
        except ValueError:
            gi.require_version("AppIndicator3", "0.1")
            from gi.repository import AppIndicator3 as AppIndicator
        from gi.repository import GLib, Gtk

        self.binary = binary
        self.interval = interval
        self.report = {}
        self.indicator = AppIndicator.Indicator.new(
            "nonsleep",
            FALLBACK_ICONS["normal"],
            AppIndicator.IndicatorCategory.SYSTEM_SERVICES,
        )
        self.indicator.set_status(AppIndicator.IndicatorStatus.ACTIVE)
        self.menu = Gtk.Menu()
        self.indicator.set_menu(self.menu)

    def run(self):
        self.refresh()
        GLib.timeout_add_seconds(self.interval, self.refresh)
        Gtk.main()

    def refresh(self):
        self.report = status(self.binary)
        view = summarize(self.report)
        theme = Gtk.IconTheme.get_default()
        self.indicator.set_icon_full(pick_icon(view["icon"], theme.has_icon), view["tooltip"])
        self.indicator.set_title(f"NonSleep: {view['text']}")
        self.rebuild_menu(view)
        return True  # keep the timeout alive

    def rebuild_menu(self, view):
        for child in self.menu.get_children():
            self.menu.remove(child)

        for line in view["tooltip"].split("\n"):
            item = Gtk.MenuItem(label=line)
            item.set_sensitive(False)
            self.menu.append(item)
        self.menu.append(Gtk.SeparatorMenuItem())

        for label, duration in PRESETS:
            self.append_action(f"Keep awake: {label}", self.on_keep_awake, duration)
        self.append_action("Keep awake: custom…", self.on_custom)
        self.menu.append(Gtk.SeparatorMenuItem())
        off_label = "Turn off (cancel leases on hold)" if view["class"] == "suspended" else "Turn off (allow sleep)"
        self.append_action(off_label, self.on_off)
        self.append_action("Sleep now", self.on_sleep)
        self.menu.append(Gtk.SeparatorMenuItem())
        self.append_action("Quit indicator", lambda *_: Gtk.main_quit())
        self.menu.show_all()

    def append_action(self, label, handler, *args):
        item = Gtk.MenuItem(label=label)
        item.connect("activate", handler, *args)
        self.menu.append(item)

    def act(self, *args):
        try:
            cli(self.binary, *args)
        except (CLIError, subprocess.TimeoutExpired, OSError) as error:
            self.alert(str(error))
        self.refresh()

    def on_keep_awake(self, _item, duration):
        if duration:
            self.act("on", duration)
        else:
            self.act("on")

    def on_off(self, _item):
        self.act("off")

    def on_sleep(self, _item):
        self.act("sleep")

    def on_custom(self, _item):
        dialog = Gtk.Dialog(title="Keep awake for…")
        dialog.set_modal(True)
        dialog.add_buttons("Cancel", Gtk.ResponseType.CANCEL, "Keep awake", Gtk.ResponseType.OK)
        entry = Gtk.Entry(text="90m", activates_default=True)
        dialog.set_default_response(Gtk.ResponseType.OK)
        box = dialog.get_content_area()
        box.set_spacing(8)
        box.set_border_width(12)
        box.add(Gtk.Label(label="Duration — 45m, 2h, 1h30m, 90s:"))
        box.add(entry)
        dialog.show_all()
        response = dialog.run()
        duration = entry.get_text().strip()
        dialog.destroy()
        if response == Gtk.ResponseType.OK and duration:
            self.act("on", duration)

    def alert(self, message):
        dialog = Gtk.MessageDialog(
            modal=True,
            message_type=Gtk.MessageType.ERROR,
            buttons=Gtk.ButtonsType.CLOSE,
            text="NonSleep",
            secondary_text=message,
        )
        dialog.run()
        dialog.destroy()


def main(argv=None):
    parser = argparse.ArgumentParser(description="NonSleep tray indicator for Linux")
    parser.add_argument("--once", action="store_true", help="print one waybar JSON line and exit")
    parser.add_argument("--interval", type=int, default=5, help="poll seconds (default: 5)")
    parser.add_argument(
        "--bin", default=shutil.which("nonsleep") or "nonsleep", help="path to the nonsleep CLI"
    )
    args = parser.parse_args(argv)

    if args.once:
        view = summarize(status(args.bin))
        del view["icon"]
        print(json.dumps(view))
        # Always 0: the JSON itself carries `"class": "unavailable"`, and waybar/polybar
        # hide a module whose command fails instead of showing that state.
        return 0

    if args.interval < 1:
        parser.error("--interval must be at least 1 second")
    try:
        Indicator(args.bin, args.interval).run()
    except (ImportError, ValueError) as error:
        print(
            f"nonsleep-indicator: no GTK AppIndicator bindings ({error}).\n"
            "  Debian/Ubuntu: sudo apt install python3-gi gir1.2-gtk-3.0 "
            "gir1.2-ayatanaappindicator3-0.1\n"
            "  Fedora:        sudo dnf install python3-gobject gtk3 libayatana-appindicator-gtk3\n"
            "  Or use `nonsleep-indicator --once` from waybar/polybar instead.",
            file=sys.stderr,
        )
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
