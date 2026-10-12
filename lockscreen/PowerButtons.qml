// PowerButtons.qml — bottom right: shutdown / restart / sleep.
import QtQuick
import Quickshell

Row {
    id: buttons
    property var cfg
    spacing: 12

    Repeater {
        model: [
            { glyph: buttons.cfg.glyphPower,   cmd: ["systemctl", "poweroff"] },
            { glyph: buttons.cfg.glyphRestart, cmd: ["systemctl", "reboot"]   },
            { glyph: buttons.cfg.glyphSleep,   cmd: ["systemctl", "suspend"]  }
        ]
        delegate: Rectangle {
            id: btn
            required property var modelData
            width: buttons.cfg.powerButtonSize
            height: buttons.cfg.powerButtonSize
            radius: width / 2
            color: area.containsMouse ? buttons.cfg.hoverFill : buttons.cfg.cardFill
            border.width: 1
            border.color: buttons.cfg.cardStroke
            Behavior on color { ColorAnimation { duration: 120 } }

            Text {
                anchors.centerIn: parent
                text: String.fromCodePoint(btn.modelData.glyph)
                color: buttons.cfg.textColor
                font.family: buttons.cfg.famIcons
                font.pixelSize: buttons.cfg.powerIconSize
            }
            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached(btn.modelData.cmd)
            }
        }
    }
}
