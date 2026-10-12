// SessionPanel.qml — session control content for the resting curtain.
// Top: date, time, greeting. Bottom: numbered action buttons, "Slide down to <action>", handle.
// Dragging the curtain down (or Down key) performs the selected action — see shell.qml.
import QtQuick
import Quickshell

Item {
    id: panel
    property var cfg
    property var auth
    property real availH: 0                    // visible curtain height

    width: parent.width
    height: availH

    // shrink both groups together on short screens so they never overlap
    readonly property real fit: Math.min(1, availH / (cfg.sessionTopMargin + topCol.height + botCol.height + 28 + 16))

    SystemClock { id: clk; precision: SystemClock.Minutes }

    Column {
        id: topCol
        anchors.top: parent.top
        anchors.topMargin: panel.cfg.sessionTopMargin * panel.fit
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 2
        scale: panel.fit
        transformOrigin: Item.Top

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clk.date, panel.cfg.dateFormat)
            color: panel.cfg.textColor
            font.family: panel.cfg.famDisplay
            font.pixelSize: panel.cfg.sessionDateSize
            font.weight: Font.Medium
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clk.date, panel.cfg.timeFormat)
            color: panel.cfg.textColor
            font.family: panel.cfg.famDisplay
            font.pixelSize: panel.cfg.sessionClockSize
            font.weight: Font.DemiBold
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: panel.auth.sessionGreeting
            color: panel.cfg.textDim
            font.family: panel.cfg.famText
            font.pixelSize: 18
        }
    }

    Column {
        id: botCol
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 28 * panel.fit
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 0
        scale: panel.fit
        transformOrigin: Item.Bottom

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 14

            Repeater {
                model: panel.cfg.sessionActions
                delegate: Item {
                    id: cell
                    required property var modelData
                    required property int index
                    readonly property bool selected: panel.auth.sessionIndex === index
                    width: 88
                    height: panel.cfg.sessionButtonSize + 24

                    Rectangle {
                        id: circle
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: panel.cfg.sessionButtonSize
                        height: width
                        radius: width / 2
                        color: cell.selected ? panel.cfg.hoverFill : (area.containsMouse ? panel.cfg.fieldFill : panel.cfg.cardFill)
                        border.width: cell.selected ? 2 : 1
                        border.color: cell.selected ? panel.cfg.textColor : panel.cfg.cardStroke
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.centerIn: parent
                            text: String.fromCodePoint(cell.modelData.glyph)
                            color: panel.cfg.textColor
                            font.family: panel.cfg.famIcons
                            font.pixelSize: panel.cfg.powerIconSize + 2
                        }
                    }
                    Rectangle {                // number badge (press the key to act instantly)
                        x: circle.x + circle.width - 14
                        y: circle.y - 4
                        width: 20; height: 20; radius: 10
                        color: panel.cfg.textColor
                        Text {
                            anchors.centerIn: parent
                            text: cell.index + 1
                            color: "#111111"
                            font.family: panel.cfg.famText
                            font.pixelSize: 12
                            font.weight: Font.Bold
                        }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        text: cell.modelData.label
                        color: cell.selected ? panel.cfg.textColor : panel.cfg.textDim
                        font.family: panel.cfg.famText
                        font.pixelSize: 13
                        font.weight: cell.selected ? Font.DemiBold : Font.Normal
                    }
                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (cell.modelData.id === "lock" && panel.cfg.lockInstantOnClick) panel.auth.runSessionAction(cell.index);
                            else panel.auth.selectSession(cell.index);
                        }
                    }
                }
            }
        }
        Item { width: 1; height: 50 }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: panel.cfg.sessionActions[panel.auth.sessionIndex].slide
            color: panel.cfg.textColor
            font.family: panel.cfg.famText
            font.pixelSize: 15
            font.weight: Font.Medium
        }
        Item { width: 1; height: 6 }
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 40; height: 4; radius: 2
            color: panel.cfg.textDim
        }
    }
}
