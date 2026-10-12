// LockSurface.qml — the REAL ext-session-lock surface, one per monitor.
// Normal/peek modes: static (the slide happens in Overlay.qml over the live desktop).
// Instant mode ("ui" style): the lock is already engaged, so the UI slides in over the wallpaper here.
import QtQuick
import Quickshell
import Quickshell.Wayland

WlSessionLockSurface {
    id: surface
    property var cfg
    property var auth
    property var sys

    color: cfg.fallbackBg            // opaque; compositors ignore transparent locks anyway

    property real intro: auth.instantUi ? 0 : 1

    FocusScope {
        anchors.fill: parent
        focus: true
        // Every surface forwards keys, so typing works on whichever monitor has keyboard focus.
        Keys.onPressed: event => surface.auth.handleKey(event)
        Component.onCompleted: {
            forceActiveFocus();
            if (surface.auth.instantUi) introAnim.start();
        }

        NumberAnimation {
            id: introAnim
            target: surface
            property: "intro"
            from: 0; to: 1
            duration: surface.cfg.slideInMs
            easing.type: Easing.OutQuint
            onFinished: surface.auth.introDone = true
        }

        Curtain {
            anchors.fill: parent
            cfg: surface.cfg
            auth: surface.auth
            sys: surface.sys
            screenName: surface.screen ? surface.screen.name : ""
            uiOpacity: surface.auth.sleepHide ? 0 : surface.intro
            uiY: (surface.intro - 1) * height
        }
    }
}
