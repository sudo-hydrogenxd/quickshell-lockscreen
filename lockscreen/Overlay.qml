// Overlay.qml — a normal layer-shell window (NOT the lock) that animates the Curtain over the
// live desktop: slide-in before locking, the peek curtain, and the reveal after unlocking.
// It stays mapped (hidden behind the lock) the whole time so the reveal is seamless.
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: win
    required property var modelData
    property var cfg
    property var auth
    property var sys

    screen: modelData
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qslock-curtain"
    WlrLayershell.keyboardFocus: auth.peeking ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Empty input region = clicks fall through to the desktop (used while revealing / dismissing).
    Region { id: passThrough }
    mask: (auth.revealing || auth.dismissing) ? passThrough : null

    SystemClock { id: clk; precision: SystemClock.Minutes }

    readonly property real uiOpacity: {
        // session: a power action is running; don't flash the password box while the curtain falls
        if (auth.leaving || !auth.sessionShowsLock) return 0;
        // instant/"ui": the lock surface animates the UI in; keep ours hidden until that's done
        if (auth.instantUi && !auth.introDone) return 0;
        // peek: UI stays hidden until you pull the curtain down
        if (!auth.peekMode || auth.lockRequested || auth.revealing) return 1;
        return Math.max(0, Math.min(1, (auth.curtainP - auth.peekP) / 0.3));
    }
    readonly property real hintOpacity: {
        if (!auth.peekMode || auth.lockRequested || auth.revealing) return 0;
        return Math.max(0, Math.min(1, 1 - (auth.curtainP - auth.peekP) / 0.2));
    }

    FocusScope {
        anchors.fill: parent
        focus: true
        Keys.onPressed: event => win.auth.overlayKey(event)

        Item {
            id: sheet
            width: parent.width
            height: parent.height
            y: (win.auth.curtainP - 1) * height
            opacity: win.auth.curtainFade

            Curtain {
                anchors.fill: parent
                cfg: win.cfg
                auth: win.auth
                sys: win.sys
                screenName: win.screen ? win.screen.name : ""
                uiOpacity: win.uiOpacity
            }

            // Peek content, pinned to the bottom edge of the curtain: mini clock, label, handle
            Column {
                visible: win.hintOpacity > 0 && !win.auth.sessionMode
                opacity: win.hintOpacity
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 28
                spacing: 2

                Text {
                    visible: win.cfg.peekShowClock
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clk.date, win.cfg.dateFormat)
                    color: win.cfg.textColor
                    font.family: win.cfg.famDisplay
                    font.pixelSize: win.cfg.peekDateSize
                    font.weight: Font.Medium
                }
                Text {
                    visible: win.cfg.peekShowClock
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clk.date, win.cfg.timeFormat)
                    color: win.cfg.textColor
                    font.family: win.cfg.famDisplay
                    font.pixelSize: win.cfg.peekClockSize
                    font.weight: Font.DemiBold
                }
                Item { width: 1; height: 14 }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: win.cfg.peekLabel
                    color: win.cfg.textColor
                    font.family: win.cfg.famText
                    font.pixelSize: 15
                    font.weight: Font.Medium
                }
                Item { width: 1; height: 6 }
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 40; height: 4; radius: 2
                    color: win.cfg.textDim
                }
            }

            // Session control: fills the visible part of the curtain; status icons sit at its top-right.
            SessionPanel {
                visible: win.auth.sessionMode && win.hintOpacity > 0
                opacity: win.hintOpacity
                cfg: win.cfg
                auth: win.auth
                availH: win.height * win.auth.peekP
                anchors.bottom: parent.bottom
            }
            StatusIcons {
                visible: win.auth.sessionMode && win.hintOpacity > 0
                opacity: win.hintOpacity
                cfg: win.cfg
                sys: win.sys
                anchors.right: parent.right
                anchors.rightMargin: win.cfg.edgeMargin
                y: (1 - win.auth.curtainP) * sheet.height + win.cfg.edgeMargin
            }
        }

        // Peek interaction: drag the curtain down, or click anywhere below it to dismiss.
        MouseArea {
            id: ptr
            anchors.fill: parent
            enabled: win.auth.peeking
            z: win.auth.sessionMode ? -1 : 1      // session: the panel's buttons get the mouse first, drags fall through to here
            property real startY: 0
            property real startP: 0
            property bool dragging: false
            cursorShape: dragging ? Qt.ClosedHandCursor : Qt.ArrowCursor

            onPressed: mouse => {
                if (mouse.y <= win.auth.curtainP * height + 10) {
                    dragging = true;
                    startY = mouse.y;
                    startP = win.auth.curtainP;
                    win.auth.stopCurtainAnim();
                } else {
                    win.auth.dismissPeek();
                }
            }
            onPositionChanged: mouse => {
                if (dragging) win.auth.dragTo(startP + (mouse.y - startY) / height);
            }
            onReleased: {
                if (dragging) { dragging = false; win.auth.releaseDrag(); }
            }
        }
    }
}
