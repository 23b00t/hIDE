#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage:
  git-diff.sh workspace [pane-id] [cwd] [git-diff-rev-or-range...]
EOF
  exit 1
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
picker_script="$script_dir/picker.sh"

mode="${1:-}"
[[ -n "$mode" ]] || usage
shift

pane_id="${1:-${ZELLIJ_PANE_ID:-}}"
if [[ $# -gt 0 ]]; then
  shift
fi

cwd="${1:-$PWD}"
if [[ $# -gt 0 ]]; then
  shift
fi

ref_args=("$@")

if ! command -v git >/dev/null 2>&1; then
  echo "git is required." >&2
  exit 1
fi

if ! repo_root="$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)"; then
  echo "Directory is not inside a Git repository: $cwd" >&2
  exit 1
fi

sanitize_path_segment() {
  local input="${1:-working-tree}"
  input="$(printf '%s' "$input" | tr -cs '[:alnum:]._-' '-')"
  input="${input#-}"
  input="${input%-}"
  printf '%s' "${input:-working-tree}"
}

git_diff_file() {
  local target="$1"
  local -a cmd=(git -C "$repo_root" --no-pager diff --no-ext-diff)
  if [[ ${#ref_args[@]} -gt 0 ]]; then
    cmd+=("${ref_args[@]}")
  fi
  cmd+=(-- "$target")
  "${cmd[@]}"
}

git_diff_file_to_output() {
  local target="$1"
  local output_file="$2"
  local -a cmd=(git -C "$repo_root" --no-pager diff --no-ext-diff --output="$output_file")
  if [[ ${#ref_args[@]} -gt 0 ]]; then
    cmd+=("${ref_args[@]}")
  fi
  cmd+=(-- "$target")
  "${cmd[@]}"
}

git_diff_names() {
  local -a cmd=(git -C "$repo_root" --no-pager diff --no-ext-diff --name-only -z --relative)
  if [[ ${#ref_args[@]} -gt 0 ]]; then
    cmd+=("${ref_args[@]}")
  fi
  "${cmd[@]}"
}

git_diff_stat() {
  local -a cmd=(git -C "$repo_root" --no-pager diff --no-ext-diff --stat --relative)
  if [[ ${#ref_args[@]} -gt 0 ]]; then
    cmd+=("${ref_args[@]}")
  fi
  "${cmd[@]}"
}

open_workspace_tree() {
  local target_dir="$1"
  [[ -n "$pane_id" ]] || return 0
  "$picker_script" -i "$pane_id" --cwd "$target_dir" -p ft
}

ref_spec="${ref_args[*]:-}"

case "$mode" in
  workspace)
    repo_name="$(basename "$repo_root")"
    repo_hash="$(printf '%s' "$repo_root" | sha1sum | cut -c1-12)"
    ref_slug="$(sanitize_path_segment "${ref_spec:-working-tree}")"
    workspace_dir="${TMPDIR:-/tmp}/hide-git-diff/${repo_name}-${repo_hash}/${ref_slug}"

    mkdir -p "$workspace_dir"
    find "$workspace_dir" -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +

    mapfile -d '' diff_files < <(git_diff_names)

    summary_file="$workspace_dir/_summary.txt"
    {
      printf 'repo: %s\n' "$repo_root"
      printf 'cwd: %s\n' "$cwd"
      printf 'spec: %s\n\n' "${ref_spec:-working tree}"
      if [[ ${#diff_files[@]} -eq 0 ]]; then
        printf 'No diff files found.\n'
      else
        git_diff_stat
      fi
    } >"$summary_file"

    for rel_path in "${diff_files[@]}"; do
      [[ -n "$rel_path" ]] || continue
      out_file="$workspace_dir/$rel_path.diff"
      mkdir -p "$(dirname "$out_file")"
      git_diff_file_to_output "$rel_path" "$out_file"
    done

    open_workspace_tree "$workspace_dir"
    printf 'Diff workspace ready: %s\n' "$workspace_dir"
    ;;
  *)
    usage
    ;;
esac
