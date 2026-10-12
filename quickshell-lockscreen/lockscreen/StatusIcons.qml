// StatusIcons.qml — top right: network icon + battery icon/percent, read straight from /sys.
import QtQuick
import Quickshell
import Quickshell.Io

Row {
    id: status
    property var cfg
    spacing: 14

    property string net: "off"        // wifi | eth | off
    property int batPercent: -1       // -1 = no battery
    property string batState: ""

    function glyph(cp) { return String.fromCodePoint(cp); }

    readonly property string netGlyph: net === "wifi" ? glyph(cfg.glyphWifi)
                                     : net === "eth"  ? glyph(cfg.glyphEthernet)
                                     :                  glyph(cfg.glyphWifiOff)
    readonly property string batGlyph: {
        if (batPercent < 0) return "";
        if (batState === "Charging") return glyph(cfg.glyphBatCharging);
        const i = Math.max(0, Math.min(10, Math.round(batPercent / 10)));
        return glyph(cfg.glyphBattery[i]);
    }

    Process {
        id: netProc
        command: ["sh", "-c", [
            'eth=0; wifi=0',
            'for d in /sys/class/net/*; do',
            '  [ -e "$d/device" ] || continue',
            '  [ "$(cat "$d/operstate" 2>/dev/null)" = up ] || continue',
            '  if [ -d "$d/wireless" ] || [ -d "$d/phy80211" ]; then wifi=1; else eth=1; fi',
            'done',
            'if [ $eth = 1 ]; then echo eth; elif [ $wifi = 1 ]; then echo wifi; else echo off; fi'
        ].join("\n")]
        stdout: StdioCollector { onStreamFinished: status.net = text.trim() || "off" }
    }

    Process {
        id: batProc
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
                if (t === "none" || t === "") { status.batPercent = -1; return; }
                const p = t.split("|");
                status.batPercent = parseInt(p[0]);
                status.batState = p[1] || "";
            }
        }
    }

    Timer {
        interval: status.cfg.statusPollMs
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!netProc.running) netProc.running = true;
            if (!batProc.running) batProc.running = true;
        }
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: status.netGlyph
        color: status.cfg.textColor
        font.families: status.cfg.fontIcons
        font.pixelSize: status.cfg.statusIconSize
    }
    Row {
        visible: status.batPercent >= 0
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: status.batGlyph
            color: status.cfg.textColor
            font.families: status.cfg.fontIcons
            font.pixelSize: status.cfg.statusIconSize
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: status.batPercent + "%"
            color: status.cfg.textColor
            font.families: status.cfg.fontText
            font.pixelSize: status.cfg.statusTextSize
            font.weight: Font.Medium
        }
    }
}
