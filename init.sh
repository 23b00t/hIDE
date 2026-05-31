#!/usr/bin/env bash

# 1. Check for $HOME/.cargo/bin/ft, install with cargo if missing or not executable
if ! [ -x "$HOME/.cargo/bin/ft" ]; then
  echo "[hIDE:init] Installing 'filetree' via cargo..."
  cargo install filetree
fi

# 2. Recursively symlink the entire project (mirror structure) to ~/.config/hIDE, except helix/config.toml, README.md, and init.sh
SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HIDE_CONFIG="$HOME/.config/hIDE"

if [ ! -d "$SCRIPT_ROOT" ]; then
  echo "[hIDE:init] Error: SCRIPT_ROOT not found: $SCRIPT_ROOT" >&2
  exit 1
fi

echo "[hIDE:init] Setting up hIDE config in $HIDE_CONFIG..."
echo "[hIDE:init] Get a coffee while we set things up! ☕"

find "$SCRIPT_ROOT" -mindepth 1 \
  -path "$SCRIPT_ROOT/.git" -prune -o \
  -path "$SCRIPT_ROOT/helix/config.toml" -prune -o \
  -name 'README.md' -prune -o \
  -name 'init.sh' -prune -o \
  -print | while read -r path; do
    rel_path="${path#$SCRIPT_ROOT/}"
    [ -z "$rel_path" ] && continue
    [ "$rel_path" = "helix/config.toml" ] && continue
    [ "$rel_path" = "README.md" ] && continue
    [ "$rel_path" = "init.sh" ] && continue
    target="$HIDE_CONFIG/$rel_path"
    if [ -d "$path" ]; then
      mkdir -p "$target"
    elif [ -f "$path" ]; then
      mkdir -p "$(dirname "$target")"
      ln -sf "$path" "$target"
    fi
  done

# 3. Symlink ./helix/config.toml to helix config dir, ensuring dirs
HE_DIR="$HOME/.config/helix"
mkdir -p "$HE_DIR"
if [ -f "$SCRIPT_ROOT/helix/config.toml" ]; then
  ln -sf "$SCRIPT_ROOT/helix/config.toml" "$HE_DIR/config.toml"
  ln -sf "$SCRIPT_ROOT/helix/languages.toml" "$HE_DIR/languages.toml"
fi

# 4. Setup permanent aliases for all shells via ~/.hIDE_aliases
ALIASES_FILE="$HOME/.hIDE_aliases"

write_alias() {
  local name="$1"
  local cmd="$2"
  if ! grep -qx "alias $name="*"" "$ALIASES_FILE" 2>/dev/null; then
    echo "alias $name='$cmd'" >> "$ALIASES_FILE"
  fi
}

write_alias init-hIDE "zellij --config-dir=\$HOME/.config/hIDE/zellij --layout=\$HOME/.config/hIDE/zellij/layouts/default.kdl"
write_alias hIDE "zellij action new-tab --layout=\$HOME/.config/hIDE/zellij/layouts/ide.kdl --layout-dir=\$HOME/.config/hIDE/zellij/layouts"

# 5. Source ~/.hIDE_aliases from relevant shell rc/profile script, if not yet present
SHELL_NAME="$(basename -- "$SHELL")"
PROFILE_FILES=()

if [ "$SHELL_NAME" = "zsh" ]; then
  # zsh: Prefer ~/.zprofile, fallback to ~/.profile
  [ -f "$HOME/.zprofile" ] && PROFILE_FILES+=("$HOME/.zprofile")
  PROFILE_FILES+=("$HOME/.profile")
else
  # bash and others: Prefer ~/.profile
  PROFILE_FILES+=("$HOME/.profile")
fi

SRC_LINE="[ -f \"$ALIASES_FILE\" ] && source \"$ALIASES_FILE\""
ADDED=0
for pf in "${PROFILE_FILES[@]}"; do
  # Add sourcing line if not already present
  if [ -w "$pf" ]; then
    if ! grep -Fxq "$SRC_LINE" "$pf"; then
      echo "$SRC_LINE" >> "$pf"
      ADDED=1
      echo "[hIDE:init] Aliases will be loaded for shell sessions via $pf."
      break
    fi
  fi
  # If file doesn't exist, create it and add line
  if [ ! -f "$pf" ]; then
    echo "$SRC_LINE" > "$pf"
    ADDED=1
    echo "[hIDE:init] Aliases file sourcing added to $pf."
    break
  fi
  done

if [ $ADDED -eq 0 ]; then
  echo "[hIDE:init] Please ensure to source $ALIASES_FILE in your shell init (e.g., .profile/.zprofile)."
fi

# End of init script
