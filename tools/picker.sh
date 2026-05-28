#!/usr/bin/env bash
set -euo pipefail

script_path="$(realpath "$0")"
pane_id="${PICKER_PANE_ID:-}"
picker=""
files=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -i|--pane-id)
      [[ $# -ge 2 ]] || {
        echo "Missing value for $1" >&2
        exit 1
      }
      pane_id="$2"
      shift 2
      ;;
    -p|--picker)
      [[ $# -ge 2 ]] || {
        echo "Missing value for $1" >&2
        exit 1
      }
      picker="$2"
      shift 2
      ;;
    --)
      shift
      files+=("$@")
      break
      ;;
    -*)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
    *)
      files+=("$1")
      shift
      ;;
  esac
done

if [[ -n "$picker" ]]; then
  case "$picker" in
    yz)
      zellij action new-pane -f --close-on-exit --width 90% --height 90% --blocking -- env \
        PICKER_PANE_ID="$pane_id" \
        EDITOR="$script_path" \
        yazi && zellij action hide-floating-panes >/dev/null 2>&1
      ;;
    ft)
      exec zellij action new-pane -f -x 0 -y 0 --width 15% --height 100% --close-on-exit -- env \
        PICKER_PANE_ID="$pane_id" \
        FILETREE_DEFAULT_CMD="$script_path <filepath>" \
        $HOME/.cargo/bin/ft
      ;;
    *)
      echo "Unknown picker: $picker" >&2
      exit 1
      ;;
  esac
fi

if [[ -n "$pane_id" ]]; then
  # Jump directly to the original Helix pane instead of relying on directional focus.  
  zellij action focus-pane-id "$pane_id" >/dev/null 2>&1
else
  zellij action move-focus "Right"
fi

# Called by yazi/ft as: $EDITOR <file1> <file2> ...
for file in "${files[@]}"; do
  [ -n "$file" ] || continue

  esc="$file"
  esc="${esc//\\/\\\\}"      # Escape backslashes
  esc="${esc//\"/\\\"}"      # Escape double quotes
  esc="${esc//\$/\\\$}"      # Escape dollar signs
  esc="${esc//\`/\\\`}"      # Escape backticks

  # ensure Helix normal mode, then command mode, then open file
  zellij action write 27
  zellij action write-chars ":open \"$esc\""
  zellij action write 13
done
