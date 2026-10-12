// Sys.qml — shared live data (network, battery, now-playing). One instance, so the overlay
// curtain and the lock surface always show identical values (no pop-in at handoff).
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: sys
    property var cfg

    // network / battery (read from /sys)
    property string net: "off"        // wifi | eth | off
    property int batPercent: -1       // -1 = no battery
    property string batState: ""

    // now playing (playerctl, whitelisted, Playing only)
    property string art: ""
    property string title: ""
    property string artist: ""
    readonly property bool playing: title.length > 0

    readonly property string mediaScript: {
        const pat = list => list.length > 0 ? list.map(x => x + "*").join("|") : "__none__";
        return [
            'for p in $(playerctl -l 2>/dev/null); do',
            '  [ "$(playerctl -p "$p" status 2>/dev/null)" = "Playing" ] || continue',
            '  ok=0',
            '  case "$p" in',
            '    ' + pat(cfg.mediaAppPlayers) + ') ok=1 ;;',
            '    ' + pat(cfg.mediaBrowserPlayers) + ')',
            '      url="$(playerctl -p "$p" metadata xesam:url 2>/dev/null)"',
            '      case "$url" in *' + cfg.mediaUrlContains + '*) ok=1 ;; esac ;;',
            '  esac',
            '  [ "$ok" = 1 ] || continue',
            "  playerctl -p \"$p\" metadata --format '{{mpris:artUrl}}~|~{{title}}~|~{{artist}}'",
            '  exit 0',
            'done',
            'exit 0'
        ].join("\n");
    }

    function parseMedia(raw) {
        const t = raw.replace(/\n+$/, "");
        if (t.length === 0) { art = ""; title = ""; artist = ""; return; }
        const p = t.split("~|~");
        art = p[0] || "";
        title = p[1] || "";
        artist = p[2] || "";
    }

    property Process netProc: Process {
        command: ["sh", "-c", [
            'eth=0; wifi=0',
            'for d in /sys/class/net/*; do',
            '  [ -e "$d/device" ] || continue',
            '  [ "$(cat "$d/operstate" 2>/dev/null)" = up ] || continue',
            '  if [ -d "$d/wireless" ] || [ -d "$d/phy80211" ]; then wifi=1; else eth=1; fi',
            'done',
            'if [ $eth = 1 ]; then echo eth; elif [ $wifi = 1 ]; then echo wifi; else echo off; fi'
        ].join("\n")]
        stdout: StdioCollector { onStreamFinished: sys.net = text.trim() || "off" }
    }

    property Process batProc: Process {
        command: ["sh", "-c", [
            'for b in /sys/class/power_supply/BAT*; do',
            '  [ -r "$b/capacity" ] || continue',
            '  echo "$(cat "$b/capacity")|$(cat "$b/status")"; exit 0',
            'done',
            'echo none'
        ].join("\n")]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = text.trim();
                if (t === "none" || t === "") { sys.batPercent = -1; return; }
                const p = t.split("|");
                sys.batPercent = parseInt(p[0]);
                sys.batState = p[1] || "";
            }
        }
    }

    property Process mediaProc: Process {
        command: ["bash", "-c", sys.mediaScript]
        stdout: StdioCollector { onStreamFinished: sys.parseMedia(text) }
    }

    property Timer statusTimer: Timer {
        interval: sys.cfg.statusPollMs
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!sys.netProc.running) sys.netProc.running = true;
            if (!sys.batProc.running) sys.batProc.running = true;
        }
    }
    property Timer mediaTimer: Timer {
        interval: sys.cfg.mediaPollMs
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: { if (!sys.mediaProc.running) sys.mediaProc.running = true; }
    }
}
