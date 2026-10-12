#!/usr/bin/env bash
# install.sh — copies everything into place. Run from this folder: ./install.sh
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"

echo "→ QML config  -> ~/.config/quickshell/lockscreen"
mkdir -p ~/.config/quickshell/lockscreen
cp "$here"/lockscreen/*.qml ~/.config/quickshell/lockscreen/

echo "→ launcher    -> ~/.local/bin/qslock"
mkdir -p ~/.local/bin
install -Dm755 "$here/qslock" ~/.local/bin/qslock

echo "→ PAM service -> /etc/pam.d/quickshell-lockscreen (sudo)"
sudo install -Dm644 "$here/pam/quickshell-lockscreen" /etc/pam.d/quickshell-lockscreen

echo
echo "Done. Try:  qslock --peek --test   or   qslock --session"
