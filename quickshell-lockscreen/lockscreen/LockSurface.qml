// LockSurface.qml — one instance per monitor (created by WlSessionLock).
// Layers: [sharp screenshot] <- [blurred+darkened screenshot + UI]. On unlock the top layer
// slides up and fades, revealing the sharp screenshot, then the lock is released.
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland

WlSessionLockSurface {
    id: surface

    property var cfg
    property var auth

    readonly property bool isUiScreen: screen.name === auth.uiScreenName
    readonly property string shotUrl: "file://" + auth.shotDir + "/" + screen.name + ".png"

    color: cfg.fallbackBg                      // opaque (compositors ignore transparent locks anyway)

    FocusScope {
        id: stage
        anchors.fill: parent
        focus: true
        opacity: 0
        Keys.onPressed: event => surface.auth.handleKey(event)

        Component.onCompleted: { forceActiveFocus(); fadeIn.start(); }

        NumberAnimation {
            id: fadeIn
            target: stage; property: "opacity"
            from: 0; to: 1
            duration: surface.cfg.fadeInMs
            easing.type: Easing.OutCubic
        }

        // Bottom layer: the sharp pre-lock screenshot (stands in for the "desktop")
        Image {
            id: sharp
            anchors.fill: parent
            source: surface.shotUrl
            fillMode: Image.PreserveAspectCrop
            asynchronous: false
            cache: false
        }

        // Top layer: blurred + darkened copy, plus all the UI. This is what slides away.
        Item {
            id: lockLayer
            width: parent.width
            height: parent.height

            Rectangle {
                anchors.fill: parent
                color: surface.cfg.fallbackBg
                visible: sharp.status !== Image.Ready
            }
            MultiEffect {
                anchors.fill: parent
                source: sharp
                visible: sharp.status === Image.Ready
                autoPaddingEnabled: false
                blurEnabled: true
                blur: surface.cfg.blurStrength
                blurMax: surface.cfg.blurMax
                brightness: surface.cfg.darken
                saturation: surface.cfg.saturation
            }

            Loader {
                anchors.fill: parent
                active: surface.isUiScreen
                sourceComponent: uiComponent
            }
        }
    }

    Component {
        id: uiComponent
        Item {
            ClockHeader {
                cfg: surface.cfg
                anchors.top: parent.top
                anchors.topMargin: surface.cfg.topMargin
                anchors.horizontalCenter: parent.horizontalCenter
            }
            LoginBox {
                cfg: surface.cfg
                auth: surface.auth
                anchors.centerIn: parent
                anchors.verticalCenterOffset: surface.cfg.loginYOffset
            }
            StatusIcons {
                cfg: surface.cfg
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: surface.cfg.edgeMargin
                anchors.rightMargin: surface.cfg.edgeMargin
            }
            NowPlaying {
                cfg: surface.cfg
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.leftMargin: surface.cfg.edgeMargin
                anchors.bottomMargin: surface.cfg.edgeMargin
            }
            PowerButtons {
                cfg: surface.cfg
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.rightMargin: surface.cfg.edgeMargin
                anchors.bottomMargin: surface.cfg.edgeMargin
            }
            Text {
                visible: surface.auth.testMode
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: surface.cfg.edgeMargin
                text: "TEST MODE · auto-unlock in " + surface.auth.testRemaining + "s"
                color: surface.cfg.textDim
                font.families: surface.cfg.fontText
                font.pixelSize: 13
            }
        }
    }

    // ── Exit: slide the whole lock UI up while fading, then report done ──
    ParallelAnimation {
        id: exitAnim
        NumberAnimation {
            target: lockLayer; property: "y"
            to: -lockLayer.height
            duration: surface.cfg.exitMs
            easing.type: surface.cfg.exitEasing
        }
        NumberAnimation {
            target: lockLayer; property: "opacity"
            to: 0
            duration: surface.cfg.exitMs
            easing.type: surface.cfg.exitEasing
        }
        onFinished: surface.auth.surfaceDone()
    }

    Connections {
        target: surface.auth
        function onUnlockingChanged() { if (surface.auth.unlocking) exitAnim.start(); }
    }
}
