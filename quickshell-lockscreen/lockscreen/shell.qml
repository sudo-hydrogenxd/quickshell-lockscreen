// shell.qml — entry point. Owns the session lock, PAM, and all shared state.
// Launch via the `qslock` wrapper (it takes the screenshots first).
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam

ShellRoot {
    id: root

    Config { id: conf }

    // ── Provided by the qslock wrapper ──
    readonly property string shotDir: Quickshell.env("QSLOCK_SHOT_DIR") || ""
    readonly property bool testMode: Quickshell.env("QSLOCK_TEST") === "1"
    // UI goes on the focused monitor; falls back to the first screen.
    readonly property string uiScreenName: {
        const want = Quickshell.env("QSLOCK_FOCUSED");
        const names = Quickshell.screens.map(s => s.name);
        if (names.indexOf(want) >= 0) return want;
        return names.length > 0 ? names[0] : "";
    }

    // ── Shared state ──
    property string buffer: ""                 // what the user is typing (never displayed, never logged)
    readonly property int passwordLength: buffer.length
    property string submitted: ""              // handed to PAM, then wiped
    property bool busy: false
    property bool unlocking: false
    property bool released: false
    property int failCount: 0
    property string statusText: ""
    property int doneCount: 0
    property int testRemaining: conf.testSeconds

    // ── Keyboard (every surface forwards here, so it works on whichever monitor has focus) ──
    function handleKey(event) {
        event.accepted = true;
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

    // ── Unlock choreography: animate first, release the lock only after ──
    function beginUnlock() {
        if (unlocking) return;
        unlocking = true;                      // surfaces start their exit animation
        doneCount = 0;
        fallbackTimer.start();
    }
    function surfaceDone() {
        doneCount++;
        if (doneCount >= Quickshell.screens.length) release();
    }
    function release() {
        if (released) return;
        released = true;
        lock.locked = false;                   // ext_session_lock unlock_and_destroy
        quitTimer.start();
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

    WlSessionLock {
        id: lock
        locked: true

        // After the compositor drops the lock, the process is done.
        onSecureChanged: { if (!secure && root.released) Qt.quit(); }

        LockSurface { cfg: conf; auth: root }
    }

    // ── Timers ──
    Timer {                                    // exits if the lock never engages (e.g. another locker is active)
        interval: conf.lockTimeoutMs
        running: true
        onTriggered: { if (!lock.secure) Qt.quit(); }
    }
    Timer {                                    // fallback if an animation never reports finished
        id: fallbackTimer
        interval: conf.exitMs + conf.releaseFallbackMs
        onTriggered: root.release()
    }
    Timer {                                    // fallback quit if `secure` never flips back
        id: quitTimer
        interval: 800
        onTriggered: Qt.quit()
    }
    Timer {                                    // --test: auto-unlock countdown
        interval: 1000
        repeat: true
        running: root.testMode && !root.unlocking
        onTriggered: {
            root.testRemaining--;
            if (root.testRemaining <= 0) root.beginUnlock();
        }
    }
}
