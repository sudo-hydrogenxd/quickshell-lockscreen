// StatusIcons.qml — top right: network icon + battery icon/percent (data comes from Sys.qml).
import QtQuick

Row {
    id: status
    property var cfg
    property var sys
    spacing: 14

    function glyph(cp) { return String.fromCodePoint(cp); }

    readonly property string netGlyph: sys.net === "wifi" ? glyph(cfg.glyphWifi)
                                     : sys.net === "eth"  ? glyph(cfg.glyphEthernet)
                                     :                      glyph(cfg.glyphWifiOff)
    readonly property string batGlyph: {
        if (sys.batPercent < 0) return "";
        if (sys.batState === "Charging") return glyph(cfg.glyphBatCharging);
        const i = Math.max(0, Math.min(10, Math.round(sys.batPercent / 10)));
        return glyph(cfg.glyphBattery[i]);
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: status.netGlyph
        color: status.cfg.textColor
        font.family: status.cfg.famIcons
        font.pixelSize: status.cfg.statusIconSize
    }
    Row {
        visible: status.sys.batPercent >= 0
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: status.batGlyph
            color: status.cfg.textColor
            font.family: status.cfg.famIcons
            font.pixelSize: status.cfg.statusIconSize
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: status.sys.batPercent + "%"
            color: status.cfg.textColor
            font.family: status.cfg.famText
            font.pixelSize: status.cfg.statusTextSize
            font.weight: Font.Medium
        }
    }
}
