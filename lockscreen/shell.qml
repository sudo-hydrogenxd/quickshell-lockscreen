// shell.qml — entry point. Owns the session lock, PAM, the curtain state machine and all shared state.
// Launch via the `qslock` wrapper.
//
// Modes (QSLOCK_MODE):  slide (default) | instant | peek | session
//   slide   : curtain slides down over the live desktop, then the real lock engages
//   instant : lock engages immediately (hypridle-safe); the UI slides in over the wallpaper
//             (Config.instantStyle = "curtain" makes it behave like slide instead)
//   peek    : curtain slides in to cover a third of the screen; drag down / Down key locks,
//             click elsewhere dismisses
//   session : like peek, but the curtain rests at Config.sessionFraction and shows session control:
//             Lock / Log out / Restart / Sleep / Shut down. Pick one, then drag the curtain down (or press Down)
//             to do it. Number keys act instantly, Left/Right select, Esc/Up/click-outside dismiss.
// Unlock: lock is released first, then the curtain (still covering the screen) slides up
// over your real desktop.
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam

ShellRoot {
    id: root

    Config { id: conf }
    Sys { id: sysData; cfg: conf }          // NOTE: not named "sys" — `sys: sys` would bind to itself

    // ── Provided by the qslock wrapper ──
    readonly property string mode: {
        const m = Quickshell.env("QSLOCK_MODE");
        return (m === "peek" || m === "instant" || m === "session") ? m : "slide";
    }
    // the behaviour actually used
    readonly property string flow: (mode === "instant" && conf.instantStyle === "curtain") ? "slide" : mode
    readonly property bool sessionMode: flow === "session"
    readonly property bool peekMode: flow === "peek" || flow === "session"   // "curtain rests, UI hidden until pulled"
    readonly property bool instantUi: flow === "instant"
    readonly property bool testMode: Quickshell.env("QSLOCK_TEST") === "1"
    readonly property var wallpapers: {
        try { return JSON.parse(Quickshell.env("QSLOCK_WALLPAPERS") || "{}"); }
        catch (e) { return {}; }
    }
    // UI goes on the focused monitor; falls back to the first screen.
    readonly property string uiScreenName: {
        const want = Quickshell.env("QSLOCK_FOCUSED");
        const names = Quickshell.screens.map(s => s.name);
        if (names.indexOf(want) >= 0) return want;
        return names.length > 0 ? names[0] : "";
    }
    readonly property real peekP: sessionMode ? conf.sessionFraction : conf.peekFraction

    // ── Greeting: picked ONCE (no tracked dependencies), shared by the curtain and the lock surface ──
    readonly property string userName: {
        const u = Quickshell.env("USER") || "user";
        return u.charAt(0).toUpperCase() + u.slice(1);
    }
    function bucketName(h) {
        const t = conf.greetingHours;
        if (h >= t.night || h < t.lateNight) return "night";
        if (h < t.morning)                   return "lateNight";
        if (h < t.afternoon)                 return "morning";
        if (h < t.evening)                   return "afternoon";
        return "evening";
    }
    function pickGreeting() {
        const g = conf.greetings;
        const bucket = g[bucketName(new Date().getHours())];
        const pool = (Math.random() < conf.funnyChance && g.funny.length > 0) ? g.funny : bucket;
        const line = pool[Math.floor(Math.random() * pool.length)];
        return line.replace(/\{name\}/g, userName);
    }
    property string greeting: pickGreeting()
    property string greetingBucket: bucketName(new Date().getHours())
    property double greetingStamp: Date.now()
    function refreshGreeting() {
        greeting = pickGreeting();
        greetingBucket = bucketName(new Date().getHours());
        greetingStamp = Date.now();
    }

    // ── Session greeting (picked once) ──
    function pickSessionGreeting() {
        const pool = conf.sessionGreetings;
        const line = (Math.random() < conf.sessionMainChance || pool.length === 0)
                     ? conf.sessionMain
                     : pool[Math.floor(Math.random() * pool.length)];
        return line.replace(/\{name\}/g, userName);
    }
    readonly property string sessionGreeting: pickSessionGreeting()

    // ── Curtain state (shared by every monitor so they move together) ──
    // curtainP: 0 = fully above the screen, 1 = fully covering. curtainFade: opacity.
    property real curtainP: flow === "instant" ? 1 : 0
    property real curtainFade: flow === "instant" ? 1 : 0
    property bool lockRequested: flow === "instant"
    property bool peeking: peekMode
    property bool dismissing: false
    property bool unlocking: false
    property bool revealing: false
    property bool introDone: flow !== "instant"     // instant mode: the lock surface's UI slide-in finished

    // ── Auth state ──
    property string buffer: ""                 // what the user is typing (never displayed, never logged)
    readonly property int passwordLength: buffer.length
    property string submitted: ""              // handed to PAM, then wiped
    property bool busy: false
    property int failCount: 0
    property string statusText: ""
    property int testRemaining: conf.testSeconds

    // ── Animation helpers ──
    property var afterP: null
    function runP(to, ms, easing, then) {
        pAnim.stop();
        afterP = then || null;
        pAnim.to = to;
        pAnim.duration = ms;
        pAnim.easing.type = easing;
        pAnim.start();
    }
    function runFade(to, ms, easing) {
        fadeAnim.stop();
        fadeAnim.to = to;
        fadeAnim.duration = ms;
        fadeAnim.easing.type = easing;
        fadeAnim.start();
    }
    function stopCurtainAnim() { pAnim.stop(); afterP = null; }

    NumberAnimation {
        id: pAnim
        target: root
        property: "curtainP"
        onFinished: { const f = root.afterP; root.afterP = null; if (f) f(); }
    }
    NumberAnimation { id: fadeAnim; target: root; property: "curtainFade" }
    Timer {                                    // a power command that didn't end the session (it failed?): hand the screen back
        id: sessionResetTimer
        interval: conf.sessionResetMs
        onTriggered: {
            root.sessionBusy = false;
            root.leaving = false;
            root.peeking = true;
            root.runP(root.peekP, conf.commitMs, Easing.OutQuint);
        }
    }
    Timer {                                    // Sleep: let the lock engage first, then suspend
        id: lockCmdTimer
        interval: 450
        onTriggered: { Quickshell.execDetached(conf.sessionActions[root.sessionIndex].cmd); sleepRevealTimer.start(); }
    }
    Timer {
        id: sleepRevealTimer
        interval: 4000
        onTriggered: { root.sleepHide = false; root.leaving = false; }
    }

    Component.onCompleted: {
        if (flow === "slide") {
            runFade(1, conf.slideInMs * 0.8, Easing.OutCubic);
            runP(1, conf.slideInMs, Easing.OutQuint, () => { root.lockRequested = true; });
        } else if (peekMode) {
            runFade(1, conf.slideInMs * 0.8, Easing.OutCubic);
            runP(peekP, conf.slideInMs, Easing.OutQuint);       // slide in and rest at the peek position
        }
    }

    // ── Peek mode ──
    function overlayKey(event) {
        event.accepted = true;
        if (!peeking) return;
        if (sessionMode) { sessionKey(event); return; }
        if (event.key === Qt.Key_Down) commitPeek();
        else if (event.key === Qt.Key_Escape || event.key === Qt.Key_Up) dismissPeek();
    }
    // ── Session control ──
    property int sessionIndex: conf.sessionDefault
    property bool sessionBusy: false
    // Only Lock and Sleep (lock first) reveal the lockscreen UI; every other action just fades the curtain.
    readonly property bool sessionShowsLock: {
        if (!sessionMode) return true;
        const a = conf.sessionActions[sessionIndex];
        return a.id === "lock" || a.lockFirst === true;
    }
    property bool sleepHide: false
    property bool leaving: false               // a power action is in flight: curtain drops without the login UI

    function selectSession(i) {
        if (sessionBusy || !peeking) return;
        sessionIndex = i;
    }
    function runSessionAction(i) {             // number keys, Lock click, or a committed drag / Down key
        if (!sessionMode || !peeking || sessionBusy) return;
        sessionIndex = i;
        const a = conf.sessionActions[i];
        if (a.id === "lock") { lockNow(); return; }
        if (a.lockFirst) { sleepHide = true; leaving = true; lockNow(() => lockCmdTimer.start()); return; }
        sessionBusy = true;                    // Log out / Restart / Shut down: curtain falls, command fires
        leaving = true;
        peeking = false;
        runP(1, conf.commitMs, Easing.OutQuint);
        Quickshell.execDetached(a.cmd);
        sessionResetTimer.restart();
    }
    function sessionKey(event) {
        if (sessionBusy) return;
        const n = conf.sessionActions.length;
        switch (event.key) {
        case Qt.Key_Down:   commitPeek(); return;
        case Qt.Key_Escape:
        case Qt.Key_Up:     dismissPeek(); return;
        case Qt.Key_Left:   selectSession((sessionIndex + n - 1) % n); return;
        case Qt.Key_Right:  selectSession((sessionIndex + 1) % n); return;
        }
        if (event.key >= Qt.Key_1 && event.key < Qt.Key_1 + n) runSessionAction(event.key - Qt.Key_1);
    }

    function dragTo(p) { curtainP = Math.max(peekP, Math.min(1, p)); }
    function releaseDrag() {
        if (curtainP >= peekP + conf.commitThreshold * (1 - peekP)) commitPeek();
        else runP(peekP, conf.commitMs, Easing.OutQuint);
    }
    function commitPeek() {                    // drag released past the threshold, or Down key
        if (!peeking) return;
        if (sessionMode) runSessionAction(sessionIndex);
        else lockNow();
    }
    function lockNow(then) {                   // curtain drops to full, then the real lock engages
        if (!peeking) return;
        peeking = false;
        runP(1, conf.commitMs, Easing.OutQuint, () => { root.lockRequested = true; if (then) then(); });
    }
    function dismissPeek() {
        if (!peeking) return;
        peeking = false;
        dismissing = true;
        runFade(0, conf.dismissMs, Easing.OutCubic);
        runP(0, conf.dismissMs, Easing.OutQuint, () => Qt.quit());   // never locked; just leave
    }

    // ── Keyboard (lock surfaces forward here) ──
    function handleKey(event) {
        event.accepted = true;
        if (sleepHide) { sleepHide = false; leaving = false; }
        if (unlocking || busy) return;
        switch (event.key) {
        case Qt.Key_Return:
        case Qt.Key_Enter:     submit(); return;
        case Qt.Key_Backspace: buffer = buffer.slice(0, -1); return;
        case Qt.Key_Escape:    buffer = ""; return;
        }
        if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_U) { buffer = ""; return; }
        const t = event.text;
        if (t.length > 0) {
            const c = t.charCodeAt(0);
            if (c >= 32 && c !== 127) buffer += t;
        }
    }

    function submit() {
        if (busy || unlocking || buffer.length === 0) return;
        submitted = buffer;
        buffer = "";                           // cleared immediately after every attempt
        busy = true;
        if (!pam.start()) {
            busy = false;
            submitted = "";
            statusText = "Authentication unavailable";
        }
    }

    // ── Unlock: release the lock FIRST, then reveal the live desktop by sliding the curtain up ──
    function beginUnlock() {
        if (unlocking) return;
        unlocking = true;
        introDone = true;
        lockRequested = false;                 // -> WlSessionLock.locked = false (unlock_and_destroy)
        revealTimer.start();
        quitFallback.start();
    }

    PamContext {
        id: pam
        config: conf.pamService                // file in /etc/pam.d (configDirectory default)

        onPamMessage: {
            if (pam.responseRequired) {
                if (root.submitted.length > 0) {
                    pam.respond(root.submitted);
                    root.submitted = "";       // wipe our copy right after handing it over
                } else {
                    pam.abort();
                }
            }
        }

        onCompleted: result => {
            root.submitted = "";
            root.busy = false;
            if (result === PamResult.Success) {
                root.statusText = "";
                root.beginUnlock();
            } else if (result === PamResult.Failed) {
                root.failCount++;
                root.statusText = "Incorrect password · attempt " + root.failCount;
            } else if (result === PamResult.MaxTries) {
                root.failCount++;
                root.statusText = "Too many attempts · attempt " + root.failCount;
            } else {
                root.statusText = "Authentication error";
            }
        }

        onError: error => {
            root.submitted = "";
            root.busy = false;
        }
    }

    // ── The real lock (engages only when lockRequested becomes true) ──
    WlSessionLock {
        id: lock
        locked: root.lockRequested
        LockSurface { cfg: conf; auth: root; sys: sysData }
    }

    // ── Curtain windows: one per monitor, always mapped, hidden behind the lock while locked ──
    Variants {
        model: Quickshell.screens
        delegate: Overlay { cfg: conf; auth: root; sys: sysData }
    }

    // ── Timers ──
    Timer {                                    // keep the greeting fresh while the screen stays locked
        interval: 30000                        // 30s tick: catches a bucket change right after suspend/resume
        repeat: true
        running: true
        onTriggered: {
            const b = root.bucketName(new Date().getHours());
            if (b !== root.greetingBucket || Date.now() - root.greetingStamp >= conf.greetingRefreshMin * 60000)
                root.refreshGreeting();
        }
    }
    Timer {                                    // quit if the lock never engages (e.g. another locker is active)
        interval: conf.lockTimeoutMs
        running: root.lockRequested
        onTriggered: { if (!lock.secure && !root.unlocking) Qt.quit(); }
    }
    Timer {                                    // let the compositor drop the lock before the reveal starts
        id: revealTimer
        interval: conf.unlockSettleMs
        onTriggered: {
            root.revealing = true;
            root.runFade(0, conf.exitMs, Easing.OutCubic);
            root.runP(0, conf.exitMs, conf.exitEasing, () => quitTimer.start());
        }
    }
    Timer { id: quitTimer; interval: 80; onTriggered: Qt.quit() }
    Timer {                                    // safety net if an animation never reports finished
        id: quitFallback
        interval: conf.unlockSettleMs + conf.exitMs + 1500
        onTriggered: Qt.quit()
    }
    Timer {                                    // --test: auto-unlock countdown (starts once the lock engages)
        interval: 1000
        repeat: true
        running: root.testMode && root.lockRequested && !root.unlocking
        onTriggered: {
            root.testRemaining--;
            if (root.testRemaining <= 0) root.beginUnlock();
        }
    }
}
