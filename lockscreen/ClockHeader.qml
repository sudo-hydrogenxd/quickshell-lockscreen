// ClockHeader.qml — date above a large time, top center.
import QtQuick
import Quickshell

Column {
    id: header
    property var cfg
    spacing: 0

    SystemClock { id: clock; precision: SystemClock.Minutes }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatDateTime(clock.date, header.cfg.dateFormat)
        color: header.cfg.textColor
        font.family: header.cfg.famDisplay
        font.pixelSize: header.cfg.dateSize
        font.weight: Font.Medium
    }
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatDateTime(clock.date, header.cfg.timeFormat)
        color: header.cfg.textColor
        font.family: header.cfg.famDisplay
        font.pixelSize: header.cfg.clockSize
        font.weight: Font.DemiBold
    }
}
