// Config.qml — EVERYTHING tweakable lives here: colors, sizes, timings, fonts, media whitelist.
// (QML 8-digit hex colors are #AARRGGBB.)
import QtQuick
import Quickshell

QtObject {
    // ───────────── COLORS ─────────────
    readonly property color textColor:    "#ffffff"
    readonly property color textDim:      "#d9ffffff"
    readonly property color tintColor:    "#4d000000"   // wallpaper tint (no blur). Raise alpha for darker.
    readonly property color fieldFill:    "#2effffff"   // faint frosted look
    readonly property color fieldStroke:  "#40ffffff"
    readonly property color dotColor:     "#ffffff"     // fully opaque dots
    readonly property color errorColor:   "#ff6b6b"
    readonly property color cardFill:     "#40000000"
    readonly property color cardStroke:   "#1fffffff"
    readonly property color hoverFill:    "#40ffffff"
    readonly property color fallbackBg:   "#0b0b10"     // used if the wallpaper can't be read

    // ───────────── FONTS (first installed family in each list wins) ─────────────
    readonly property var fontDisplay: ["SF Pro Display", "Inter", "Noto Sans", "sans-serif"]
    readonly property var fontText:    ["SF Pro Text", "Inter", "Noto Sans", "sans-serif"]
    readonly property var fontIcons:   ["Symbols Nerd Font", "Symbols Nerd Font Mono", "JetBrainsMono Nerd Font", "FiraCode Nerd Font"]
    function pickFont(list) {
        const have = Qt.fontFamilies();
        for (let i = 0; i < list.length; i++) if (have.indexOf(list[i]) >= 0) return list[i];
        return list[list.length - 1];
    }
    readonly property string famDisplay: pickFont(fontDisplay)
    readonly property string famText: pickFont(fontText)
    readonly property string famIcons: pickFont(fontIcons)

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
    readonly property int loginBottomMargin: 72         // login stack sits bottom-center
    readonly property int edgeMargin:   32
    readonly property int albumSize:    64
    readonly property int cardWidth:    320
    readonly property int statusIconSize: 20
    readonly property int statusTextSize: 14
    readonly property int powerButtonSize: 40
    readonly property int powerIconSize:   20
    readonly property real peekFraction: 0.33           // --peek: how much of the screen the curtain covers
    readonly property int peekClockSize: 72             // clock inside the peek curtain
    readonly property int peekDateSize:  20

    // ── --session (session control) ──
    readonly property real sessionFraction: 0.43        // how much of the screen the session curtain covers
    readonly property int sessionClockSize: 72
    readonly property int sessionDateSize:  18
    readonly property int sessionButtonSize: 56
    readonly property int sessionTopMargin: 56          // clock group distance from the top of the screen

    // ───────────── TIMINGS (ms) ─────────────
    readonly property int slideInMs:     500            // lock slide-in (normal mode)
    readonly property int exitMs:        500            // slide-up reveal after correct password
    readonly property int exitEasing:    Easing.OutQuint
    readonly property int commitMs:      380            // peek: finishing the slide down / snapping back
    readonly property int dismissMs:     420            // peek: click-elsewhere slide up
    readonly property int sessionResetMs: 2500          // session: curtain returns if a command somehow didn't end the session
    readonly property real commitThreshold: 0.2         // peek: drag this fraction of the remaining distance to commit
    readonly property int unlockSettleMs: 60            // wait between releasing the lock and starting the reveal
    readonly property int shakeMs:       450
    readonly property int shakeAmplitude: 14
    readonly property int statusPollMs:  5000
    readonly property int mediaPollMs:   2000
    readonly property int lockTimeoutMs: 5000           // quit if the compositor never confirms the lock
    readonly property int testSeconds:   15             // --test auto-unlock (counts from when the lock engages)

    // ───────────── TEXT / PATHS ─────────────
    readonly property string peekLabel:  "Slide down to lock"
    readonly property bool   peekShowClock: true
    // Lock button: true = lock immediately on click; false = select it like the others (then drag down).
    readonly property bool   lockInstantOnClick: false
    // --instant: "ui" = lock engages immediately and the UI slides in over the wallpaper;
    //            "curtain" = same slide-over-desktop as normal mode.
    readonly property string instantStyle: "ui"
    readonly property string dateFormat: "dddd, MMMM d"
    readonly property string timeFormat: "HH:mm"
    // First readable file wins; falls back to an initial letter.
    readonly property var avatarPaths: [
        Quickshell.env("HOME") + "/Pictures/fullpfp.png",
        Quickshell.env("HOME") + "/.face",
        "/var/lib/AccountsService/icons/" + Quickshell.env("USER")
    ]
    // Background: with Noctalia installed, its current wallpaper is used automatically.
    // Otherwise (or to override it) set an ABSOLUTE path, e.g. Quickshell.env("HOME") + "/Pictures/lock.jpg",
    // or a solid colour like "color:#101018". "~" is not expanded.
    readonly property string customWallpaper: ""
    readonly property bool   preferCustomWallpaper: false   // true = always use customWallpaper, even with Noctalia
    readonly property string pamService: "quickshell-lockscreen"   // /etc/pam.d/<this>

    // ───────────── GREETINGS ─────────────
    // {name} becomes your capitalized username. One line is picked per lock (so the curtain and the
    // lock surface always agree). Delete or add lines freely.
    readonly property int greetingRefreshMin: 5        // re-pick the greeting this often (minutes) while locked
    readonly property real funnyChance: 0.5            // chance of a funny/JJK line instead of a time-based one
    // hour of day (0-23) where each bucket starts. night wraps past midnight until lateNight.
    readonly property var greetingHours: ({ morning: 5, afternoon: 12, evening: 17, night: 21, lateNight: 1 })
    readonly property var greetings: ({
        morning: [
            "Good morning, {name}",
            "Rise and shine, {name}",
            "Coffee first, {name}",
            "Up already, {name}?",
            "New day, new you, {name}"
        ],
        afternoon: [
            "Good afternoon, {name}",
            "Still going, {name}?",
            "Post-lunch slump, {name}?",
            "Did you eat, {name}?"
        ],
        evening: [
            "Good evening, {name}",
            "Golden hour, {name}",
            "Dinner plans, {name}?",
            "Day's almost done, {name}"
        ],
        night: [
            "Moonlit session, {name}?",
            "Night owl, {name}",
            "Just one more commit, {name}?",
            "Burning the midnight oil, {name}?"
        ],
        lateNight: [
            "Go to sleep, bro.",
            "Bro. Bed. Now.",
            "Nothing good happens at 3 a.m., {name}",
            "Sleep is free, {name}",
            "The bed misses you, {name}"
        ],
        funny: [
            "Noodles, {name}?",
            "What's good, {name}?",
            "Yo, {name}",
            "Did you drink water, {name}?",
            "Touch grass later, {name}",
            "How many tabs are open, {name}?",
            "Lighter than air, {name}",
            "Explosive as always, {name}",
            "Nah, I'd win.",
            "Nanami says clock out, {name}",
            "Are you {name} because you're strong?",
        ]
    })

    // ───────────── NOW PLAYING WHITELIST ─────────────
    // Player names are matched as prefixes against `playerctl -l` (e.g. "spotify", "firefox.instance_1234").
    readonly property var mediaAppPlayers:     ["spotify"]
    readonly property var mediaBrowserPlayers: ["firefox", "chromium", "chrome", "brave", "vivaldi", "zen", "librewolf", "microsoft-edge", "opera"]
    readonly property string mediaUrlContains: "music.youtube.com"   // browser must report this in xesam:url

    // ───────────── NERD FONT CODEPOINTS (Material Design set) ─────────────
    readonly property int glyphWifi:     0xF05A9
    readonly property int glyphWifiOff:  0xF05AA
    readonly property int glyphEthernet: 0xF0200
    readonly property int glyphBatCharging: 0xF0084
    // index = round(percent / 10): 0..100
    readonly property var glyphBattery: [0xF008E, 0xF007A, 0xF007B, 0xF007C, 0xF007D, 0xF007E, 0xF007F, 0xF0080, 0xF0081, 0xF0082, 0xF0079]
    readonly property int glyphPower:   0xF0425
    readonly property int glyphRestart: 0xF0709
    readonly property int glyphSleep:   0xF04B2
    readonly property int glyphMusic:   0xF075A
    readonly property int glyphLock:    0xF033E
    readonly property int glyphLogout:  0xF0343

    // ───────────── SESSION ACTIONS (order = number keys 1..N) ─────────────
    // cmd is an argv array, run detached. "lock" is special (engages the real lock, no cmd).
    // Hyprland >= 0.55 (Lua config): exit is the Lua dispatcher string below. uwsm users: use ["uwsm","stop"] instead.
    readonly property int sessionDefault: 4             // index selected when session mode opens (4 = Shut down)
    // lockFirst: engage the real lock, then run cmd (so Sleep wakes up to the lockscreen).
    readonly property var sessionActions: [
        { id: "lock",     label: "Lock",      slide: "Slide down to lock",      glyph: glyphLock,    cmd: [] },
        { id: "logout",   label: "Log out",   slide: "Slide down to log out",   glyph: glyphLogout,  cmd: ["hyprctl", "dispatch", "hl.dsp.exit()"] },
        { id: "restart",  label: "Restart",   slide: "Slide down to restart",   glyph: glyphRestart, cmd: ["systemctl", "reboot"] },
        { id: "sleep",    label: "Sleep",     slide: "Slide down to sleep",     glyph: glyphSleep,   cmd: ["systemctl", "suspend"], lockFirst: true },
        { id: "shutdown", label: "Shut down", slide: "Slide down to shut down", glyph: glyphPower,   cmd: ["systemctl", "poweroff"] }
    ]

    // Session greeting: sessionMain shows with this chance, otherwise a line from the pool.
    readonly property string sessionMain: "See ya soon."
    readonly property real sessionMainChance: 0.5
    readonly property var sessionGreetings: [
        "Done for today, {name}?",
        "Save your work first, {name}",
        "Take care, {name}",
        "Drink some water, {name}",
        "Go touch grass, {name}",
        "Rest well, {name}",
        "Leaving so soon, {name}?",
        "Domain Retraction: Session",
    ]
}
