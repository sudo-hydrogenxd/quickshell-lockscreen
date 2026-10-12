// LoginBox.qml — avatar, greeting, password field (custom dots), hint / attempt count.
import QtQuick
import Quickshell
import Quickshell.Widgets

Column {
    id: box
    property var cfg
    property var auth
    spacing: 14

    property real shakeX: 0
    property bool flashError: false

    readonly property string userName: auth.userName
    readonly property int maxDots: Math.floor((cfg.fieldWidth - 2 * cfg.fieldPadding + cfg.dotSpacing) / (cfg.dotSize + cfg.dotSpacing))

    ClippingRectangle {
        id: avatar
        anchors.horizontalCenter: parent.horizontalCenter
        width: box.cfg.avatarSize
        height: box.cfg.avatarSize
        radius: width / 2
        color: "#33ffffff"

        property int idx: 0
        readonly property bool hasCandidate: idx < box.cfg.avatarPaths.length
        readonly property bool showing: hasCandidate && img.status === Image.Ready

        Image {
            id: img
            anchors.fill: parent
            visible: avatar.showing
            source: avatar.hasCandidate ? "file://" + box.cfg.avatarPaths[avatar.idx] : ""
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(box.cfg.avatarSize * 2, box.cfg.avatarSize * 2)
            asynchronous: false
            onStatusChanged: { if (status === Image.Error) avatar.idx++; }   // try the next candidate
        }
        Text {
            anchors.centerIn: parent
            visible: !avatar.showing
            text: box.userName.charAt(0)
            color: box.cfg.textColor
            font.family: box.cfg.famDisplay
            font.pixelSize: box.cfg.avatarSize * 0.45
            font.weight: Font.Medium
        }
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: box.auth.greeting
        color: box.cfg.textColor
        font.family: box.cfg.famDisplay
        font.pixelSize: box.cfg.helloSize
        font.weight: Font.Medium
    }

    Item {
        id: field
        anchors.horizontalCenter: parent.horizontalCenter
        width: box.cfg.fieldWidth
        height: box.cfg.fieldHeight
        transform: Translate { x: box.shakeX }   // the shake moves only the input

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: box.cfg.fieldFill
            border.width: 1
            border.color: box.flashError ? box.cfg.errorColor : box.cfg.fieldStroke
            Behavior on border.color { ColorAnimation { duration: 180 } }
        }

        Row {
            anchors.centerIn: parent
            spacing: box.cfg.dotSpacing
            Repeater {
                model: Math.min(box.auth.passwordLength, box.maxDots)
                Rectangle {
                    width: box.cfg.dotSize
                    height: box.cfg.dotSize
                    radius: width / 2
                    color: box.cfg.dotColor
                    opacity: 1.0                  // fully opaque, always
                }
            }
        }
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: box.auth.busy ? "Checking…"
            : (box.auth.statusText.length > 0 ? box.auth.statusText : "Enter Password")
        color: (box.auth.statusText.length > 0 && !box.auth.busy) ? box.cfg.errorColor : box.cfg.textDim
        font.family: box.cfg.famText
        font.pixelSize: box.cfg.hintSize
    }

    // ── Wrong password: horizontal shake ──
    SequentialAnimation {
        id: shake
        NumberAnimation { target: box; property: "shakeX"; to: -box.cfg.shakeAmplitude;        duration: box.cfg.shakeMs * 0.12; easing.type: Easing.OutQuad }
        NumberAnimation { target: box; property: "shakeX"; to:  box.cfg.shakeAmplitude;        duration: box.cfg.shakeMs * 0.20; easing.type: Easing.InOutQuad }
        NumberAnimation { target: box; property: "shakeX"; to: -box.cfg.shakeAmplitude * 0.7;  duration: box.cfg.shakeMs * 0.20; easing.type: Easing.InOutQuad }
        NumberAnimation { target: box; property: "shakeX"; to:  box.cfg.shakeAmplitude * 0.7;  duration: box.cfg.shakeMs * 0.20; easing.type: Easing.InOutQuad }
        NumberAnimation { target: box; property: "shakeX"; to: -box.cfg.shakeAmplitude * 0.35; duration: box.cfg.shakeMs * 0.16; easing.type: Easing.InOutQuad }
        NumberAnimation { target: box; property: "shakeX"; to: 0;                              duration: box.cfg.shakeMs * 0.12; easing.type: Easing.OutQuad }
    }
    Timer { id: flashTimer; interval: box.cfg.shakeMs + 200; onTriggered: box.flashError = false }

    Connections {
        target: box.auth
        function onFailCountChanged() {
            box.flashError = true;
            flashTimer.restart();
            shake.restart();
        }
    }
}
