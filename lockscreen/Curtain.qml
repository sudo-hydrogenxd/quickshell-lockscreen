// Curtain.qml — the lock "sheet": Noctalia wallpaper + tint (no blur) + all UI.
// Used by BOTH the overlay window (slide animations over the live desktop) and the real
// lock surface, so the handoff between them is pixel-identical.
import QtQuick
import Quickshell

Item {
    id: curtain
    property var cfg
    property var auth
    property var sys
    property string screenName: ""
    property real uiOpacity: 1
    property real uiY: 0              // vertical offset of the UI group (used for the instant-mode slide-in)

    readonly property bool isUi: screenName === auth.uiScreenName
    readonly property string wpPrimary: (cfg.preferCustomWallpaper && cfg.customWallpaper !== "")
                                 ? cfg.customWallpaper
                                 : (auth.wallpapers[screenName] || cfg.customWallpaper)
    // Too small for the screen (e.g. a live-wallpaper preview thumbnail)? Use customWallpaper instead,
    // or the plain fallback colour if that is empty.
    readonly property bool wpLowRes: cfg.minWallpaperScreenFraction > 0
                                     && wpPrimary !== cfg.customWallpaper
                                     && probe.status === Image.Ready
                                     && probe.implicitWidth < width * cfg.minWallpaperScreenFraction
    readonly property string wp: wpLowRes ? cfg.customWallpaper : wpPrimary
    readonly property bool wpIsColor: wp.indexOf("color:") === 0
    readonly property bool wpIsFile: wp.length > 0 && !wpIsColor

    // Noctalia colors are #RRGGBB[AA]; QML wants #AARRGGBB.
    function parseColor(s) {
        const c = s.slice(6);
        if (c.length === 9) return "#" + c.slice(7, 9) + c.slice(1, 7);
        return c;
    }

    Image {                           // invisible probe: only used to read the wallpaper's real size
        id: probe
        visible: false
        width: 1; height: 1
        source: (curtain.wpPrimary.length > 0 && curtain.wpPrimary.indexOf("color:") !== 0)
                ? "file://" + curtain.wpPrimary.split("/").map(encodeURIComponent).join("/") : ""
        asynchronous: false
        cache: true
    }
    Rectangle {
        anchors.fill: parent
        color: curtain.wpIsColor ? curtain.parseColor(curtain.wp) : curtain.cfg.fallbackBg
    }
    Image {
        anchors.fill: parent
        visible: curtain.wpIsFile
        source: curtain.wpIsFile ? "file://" + curtain.wp.split("/").map(encodeURIComponent).join("/") : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: false
        cache: true
    }
    Rectangle { anchors.fill: parent; color: curtain.cfg.tintColor }   // tint, no blur

    Loader {
        anchors.fill: parent
        active: curtain.isUi
        opacity: curtain.uiOpacity
        transform: Translate { y: curtain.uiY }
        sourceComponent: uiComponent
    }

    Component {
        id: uiComponent
        Item {
            ClockHeader {
                cfg: curtain.cfg
                anchors.top: parent.top
                anchors.topMargin: curtain.cfg.topMargin
                anchors.horizontalCenter: parent.horizontalCenter
            }
            LoginBox {
                cfg: curtain.cfg
                auth: curtain.auth
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: curtain.cfg.loginBottomMargin
            }
            StatusIcons {
                cfg: curtain.cfg
                sys: curtain.sys
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: curtain.cfg.edgeMargin
                anchors.rightMargin: curtain.cfg.edgeMargin
            }
            NowPlaying {
                cfg: curtain.cfg
                sys: curtain.sys
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.leftMargin: curtain.cfg.edgeMargin
                anchors.bottomMargin: curtain.cfg.edgeMargin
            }
            PowerButtons {
                cfg: curtain.cfg
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.rightMargin: curtain.cfg.edgeMargin
                anchors.bottomMargin: curtain.cfg.edgeMargin
            }
            Text {
                visible: curtain.auth.testMode
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 16
                text: curtain.auth.lockRequested
                      ? "TEST MODE · auto-unlock in " + curtain.auth.testRemaining + "s"
                      : "TEST MODE"
                color: curtain.cfg.textDim
                font.family: curtain.cfg.famText
                font.pixelSize: 13
            }
        }
    }
}
