# quickshell-lockscreen

A lockscreen for Hyprland built with [Quickshell](https://quickshell.org). It is a drop-in replacement for `hyprlock`, with a slide-in curtain animation, a peek mode and a session-control menu. Authentication goes through PAM, and the lock itself uses the Wayland session-lock protocol.

> **Note:** this project was vibe-coded with Claude (an AI assistant) and has only been tested on my own setup. Expect rough edges, and read the code before trusting it with your lock screen.

## Features

- **Slide / instant / peek / session modes** behind a single `qslock` launcher
- **Peek:** the curtain rests at about a third of the screen. Drag down (or press Down) to lock, click elsewhere to cancel.
- **Session control:** Lock, Log out, Restart, Sleep and Shut down, numbered 1-5. Pick one, then drag the curtain down (or press Down) to do it. Number keys act instantly.
- **Wallpaper:** Noctalia's current wallpaper per monitor when available, or your own image/colour via `customWallpaper`
- Time-based and random greetings, battery/network icons, a "now playing" card
- Everything tweakable lives in one file, `Config.qml`

## Requirements

- Hyprland (the logout command targets the 0.55+ Lua config)
- Quickshell
- `jq`, `playerctl`, `flock` (util-linux)
- A Nerd Font (for the icons)
- Optional: Noctalia, for automatic wallpaper detection (otherwise set `customWallpaper`)

## Install

```
git clone https://github.com/sudo-hydrogenxd/quickshell-lockscreen
cd quickshell-lockscreen
./install.sh
```

This copies the QML files to `~/.config/quickshell/lockscreen`, the launcher to `~/.local/bin/qslock`, and a PAM service file to `/etc/pam.d/quickshell-lockscreen` (needs sudo). Make sure `~/.local/bin` is on your `PATH`.

## Usage

```
qslock              # lock with a slide-in over your desktop
qslock --instant    # lock engages immediately, UI slides in (use this from hypridle)
qslock --peek       # curtain rests at 1/3; drag down to lock
qslock --session    # session control menu
qslock --test       # combine with any mode: auto-unlock 15s after the lock engages
```

Example Hyprland (Lua) binds:

```lua
hl.bind("SUPER + L", hl.dsp.exec_cmd("qslock --peek"))
hl.bind("SUPER + Escape", hl.dsp.exec_cmd("qslock --session"))
```

### Session control keys

| Key | Action |
|---|---|
| 1-5 | Run that action instantly |
| Left / Right | Select an action |
| Down | Do the selected action (same as dragging down) |
| Esc / Up | Dismiss without doing anything |

## Configuration

Edit `~/.config/quickshell/lockscreen/Config.qml`. No reinstall is needed; just run `qslock` again.

- `customWallpaper` / `preferCustomWallpaper`: set your own lockscreen background (an absolute path or `color:#rrggbb`). Wallpaper auto-detection only works with Noctalia, so on any other setup set this.
- `sessionFraction`: how tall the session curtain is
- `sessionTopMargin`: how far the clock sits from the top
- `sessionActions`: the buttons and the commands they run
- `lockInstantOnClick`: whether clicking Lock locks immediately or just selects it
- Greetings, colours, fonts, timings and the media whitelist are all in the same file

The gap between the button labels and the "Slide down to…" hint is the spacer `Item { width: 1; height: 50 }` in `SessionPanel.qml`.

### Notes

- **Wallpaper:** `qslock` asks Noctalia for the wallpaper (`noctalia msg wallpaper-get`). Without Noctalia you get `customWallpaper`, or a plain dark background if that is empty.
- **Log out** runs `hyprctl dispatch 'hl.dsp.exit()'`, the Lua-config form for Hyprland 0.55+. On uwsm, change it to `["uwsm", "stop"]`.
- **Sleep** locks first, then suspends. It is experimental: hiding the lock UI until wake-up may not behave the same on every setup.
- The avatar is read from `~/Pictures/fullpfp.png`, then `~/.face`. Change `avatarPaths` in `Config.qml` if yours lives elsewhere.

## License

MIT
