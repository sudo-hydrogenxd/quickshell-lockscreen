// Config.qml — EVERYTHING tweakable lives here: colors, sizes, timings, fonts, media whitelist.
// (QML 8-digit hex colors are #AARRGGBB.)
import QtQuick
import Quickshell

QtObject {
    // ───────────── COLORS ─────────────
    readonly property color textColor:    "#ffffff"
    readonly property color textDim:      "#d9ffffff"
    readonly property color fieldFill:    "#2effffff"   // faint frosted look
    readonly property color fieldStroke:  "#40ffffff"
    readonly property color dotColor:     "#ffffff"     // fully opaque dots
    readonly property color errorColor:   "#ff6b6b"
    readonly property color cardFill:     "#40000000"
    readonly property color cardStroke:   "#1fffffff"
    readonly property color hoverFill:    "#40ffffff"
    readonly property color fallbackBg:   "#0b0b10"     // shown if a screenshot is missing

    // ───────────── BLUR / DARKEN (QtQuick.Effects MultiEffect) ─────────────
    readonly property real blurStrength:  1.0           // 0..1
    readonly property int  blurMax:       64            // px radius at strength 1.0
    readonly property real darken:        -0.25         // brightness -1..1
    readonly property real saturation:    0.1

    // ───────────── FONTS ─────────────
    readonly property var fontDisplay: ["SF Pro Display", "Inter", "Noto Sans", "sans-serif"]
    readonly property var fontText:    ["SF Pro Text", "Inter", "Noto Sans", "sans-serif"]
    readonly property var fontIcons:   ["Symbols Nerd Font", "Symbols Nerd Font Mono", "JetBrainsMono Nerd Font", "FiraCode Nerd Font"]

    // ───────────── SIZES ─────────────
    readonly property int avatarSize:   90
    readonly property int fieldWidth:   260
    readonly property int fieldHeight:  40
    readonly property int fieldPadding: 16
    readonly property int dotSize:      12
    readonly property int dotSpacing:   8
    readonly property int clockSize:    96
    readonly property int dateSize:     22
    readonly property int helloSize:    22
    readonly property int hintSize:     12
    readonly property int topMargin:    64
    readonly property int loginYOffset: 24
    readonly property int edgeMargin:   32
    readonly property int albumSize:    64
    readonly property int cardWidth:    320
    readonly property int statusIconSize: 20
    readonly property int statusTextSize: 14
    readonly property int powerButtonSize: 40
    readonly property int powerIconSize:   20

    // ───────────── TIMINGS (ms) ─────────────
    readonly property int fadeInMs:      450
    readonly property int exitMs:        500            // slide-up + fade
    readonly property int exitEasing:    Easing.OutQuint
    readonly property int shakeMs:       450
    readonly property int shakeAmplitude: 14
    readonly property int statusPollMs:  5000
    readonly property int mediaPollMs:   2000
    readonly property int releaseFallbackMs: 1500       // safety net if an animation never reports finished
    readonly property int lockTimeoutMs: 5000           // quit if the compositor never confirms the lock
    readonly property int testSeconds:   15             // --test auto-unlock

    // ───────────── FORMATS / PATHS ─────────────
    readonly property string dateFormat: "dddd, MMMM d"
    readonly property string timeFormat: "HH:mm"
    readonly property string avatarPath: Quickshell.env("HOME") + "/Pictures/fullpfp.png"
    readonly property string pamService: "quickshell-lockscreen"   // /etc/pam.d/<this>

    // ───────────── NOW PLAYING WHITELIST ─────────────
    // Player names are matched as prefixes against `playerctl -l` (e.g. "spotify", "firefox.instance_1234").
    readonly property var mediaAppPlayers:     ["spotify"]
    readonly property var mediaBrowserPlayers: ["firefox", "chromium", "chrome", "brave", "vivaldi", "zen", "librewolf", "microsoft-edge", "opera"]
    readonly property string mediaUrlContains: "music.youtube.com"   // browser must report this in xesam:url

    // ───────────── NERD FONT CODEPOINTS (Material Design set) ─────────────
    readonly property int glyphWifi:     0xF05A9   // 󰖩
    readonly property int glyphWifiOff:  0xF05AA   // 󰖪
    readonly property int glyphEthernet: 0xF0200   // 󰈀
    readonly property int glyphBatCharging: 0xF0084 // 󰂄
    // index = round(percent / 10): 0..100
    readonly property var glyphBattery: [0xF008E, 0xF007A, 0xF007B, 0xF007C, 0xF007D, 0xF007E, 0xF007F, 0xF0080, 0xF0081, 0xF0082, 0xF0079]
    readonly property int glyphPower:   0xF0425   // 󰐥
    readonly property int glyphRestart: 0xF0709   // 󰜉
    readonly property int glyphSleep:   0xF04B2   // 󰒲
    readonly property int glyphMusic:   0xF075A   // 󰝚
}
