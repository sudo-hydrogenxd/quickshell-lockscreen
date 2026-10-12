// NowPlaying.qml — bottom-left card. playerctl only, whitelist from Config, only while Playing.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

Item {
    id: np
    property var cfg

    property string art: ""
    property string title: ""
    property string artist: ""

    visible: title.length > 0
    width: card.width
    height: card.height

    // Builds a shell script from the Config whitelist. Prints "art~|~title~|~artist" for the
    // first player that is (Spotify) OR (a browser whose xesam:url contains the URL match) AND Playing.
    readonly property string script: {
        const pat = list => list.length > 0 ? list.map(x => x + "*").join("|") : "__none__";
        return [
            'for p in $(playerctl -l 2>/dev/null); do',
            '  [ "$(playerctl -p "$p" status 2>/dev/null)" = "Playing" ] || continue',
            '  ok=0',
            '  case "$p" in',
            '    ' + pat(cfg.mediaAppPlayers) + ') ok=1 ;;',
            '    ' + pat(cfg.mediaBrowserPlayers) + ')',
            '      url="$(playerctl -p "$p" metadata xesam:url 2>/dev/null)"',
            '      case "$url" in *' + cfg.mediaUrlContains + '*) ok=1 ;; esac ;;',
            '  esac',
            '  [ "$ok" = 1 ] || continue',
            "  playerctl -p \"$p\" metadata --format '{{mpris:artUrl}}~|~{{title}}~|~{{artist}}'",
            '  exit 0',
            'done',
            'exit 0'
        ].join("\n");
    }

    function parse(raw) {
        const t = raw.replace(/\n+$/, "");
        if (t.length === 0) { art = ""; title = ""; artist = ""; return; }
        const p = t.split("~|~");
        art = p[0] || "";
        title = p[1] || "";
        artist = p[2] || "";
    }

    Process {
        id: proc
        command: ["bash", "-c", np.script]
        stdout: StdioCollector { onStreamFinished: np.parse(text) }
    }
    Timer {
        interval: np.cfg.mediaPollMs
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: { if (!proc.running) proc.running = true; }
    }

    Rectangle {
        id: card
        width: np.cfg.cardWidth
        height: np.cfg.albumSize + 24
        radius: 18
        color: np.cfg.cardFill
        border.width: 1
        border.color: np.cfg.cardStroke

        Row {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12

            ClippingRectangle {
                width: np.cfg.albumSize
                height: np.cfg.albumSize
                radius: 10
                color: "#33ffffff"
                Image {
                    id: artImg
                    anchors.fill: parent
                    source: np.art
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
                Text {
                    anchors.centerIn: parent
                    visible: artImg.status !== Image.Ready
                    text: String.fromCodePoint(np.cfg.glyphMusic)
                    color: np.cfg.textDim
                    font.families: np.cfg.fontIcons
                    font.pixelSize: 26
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: card.width - np.cfg.albumSize - 12 * 3
                spacing: 3
                Text {
                    width: parent.width
                    text: np.title
                    elide: Text.ElideRight
                    color: np.cfg.textColor
                    font.families: np.cfg.fontText
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                }
                Text {
                    width: parent.width
                    text: np.artist
                    elide: Text.ElideRight
                    color: np.cfg.textDim
                    font.families: np.cfg.fontText
                    font.pixelSize: 13
                }
            }
        }
    }
}
