#!/usr/bin/env bash
set -euo pipefail

pane_id="$(
    zellij action new-pane --close-on-exit -- zsh -c \
        "FILETREE_DEFAULT_CMD='$HOME/.config/hIDE/toos/picker.sh <filepath>' $HOME/.cargo/bin/ft"
)"

zellij action next-swap-layout >/dev/null
zellij action next-swap-layout >/dev/null
zellij action focus-pane-id "$pane_id" >/dev/null
