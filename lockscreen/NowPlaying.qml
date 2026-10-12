// NowPlaying.qml — bottom-left card (data comes from Sys.qml). Hidden unless something whitelisted is Playing.
import QtQuick
import Quickshell.Widgets

Item {
    id: np
    property var cfg
    property var sys

    visible: sys.playing
    width: card.width
    height: card.height

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
                    source: np.sys.art
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
                Text {
                    anchors.centerIn: parent
                    visible: artImg.status !== Image.Ready
                    text: String.fromCodePoint(np.cfg.glyphMusic)
                    color: np.cfg.textDim
                    font.family: np.cfg.famIcons
                    font.pixelSize: 26
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: card.width - np.cfg.albumSize - 12 * 3
                spacing: 3
                Text {
                    width: parent.width
                    text: np.sys.title
                    elide: Text.ElideRight
                    color: np.cfg.textColor
                    font.family: np.cfg.famText
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                }
                Text {
                    width: parent.width
                    text: np.sys.artist
                    elide: Text.ElideRight
                    color: np.cfg.textDim
                    font.family: np.cfg.famText
                    font.pixelSize: 13
                }
            }
        }
    }
}
