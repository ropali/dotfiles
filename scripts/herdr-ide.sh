#!/bin/bash
# herdr-ide: Open an IDE layout as a new tab in the current Herdr workspace
# Usage: ide [--ai <command>] [directory]
# Example: ide .
#          ide ~/projects/myapp
#          ide --ai codex .

INSTALL_BIN="$HOME/.local/bin"
INSTALL_TARGET="$INSTALL_BIN/ide"

self_install() {
  mkdir -p "$INSTALL_BIN"
  local script_path
  script_path="$(realpath "$0")"

  if [ ! -x "$script_path" ] && [ -w "$script_path" ]; then
    chmod +x "$script_path"
  fi

  ln -sf "$script_path" "$INSTALL_TARGET"
}

# If invoked as herdr-ide.sh (or any non-ide name), install/update then re-run as ide
if [ "$(basename "$0")" != "ide" ]; then
  self_install
  exit 0
fi

target_dir="."
assistant_cmd="${IDE_ASSISTANT:-opencode}"
dry_run=0

while [ $# -gt 0 ]; do
  case "$1" in
  --ai)
    if [ -z "${2:-}" ]; then
      echo "Error: --ai requires a command" >&2
      exit 1
    fi
    assistant_cmd="$2"
    shift 2
    ;;
  --dry-run)
    dry_run=1
    shift
    ;;
  --)
    shift
    break
    ;;
  -*)
    echo "Error: Unknown option: $1" >&2
    exit 1
    ;;
  *)
    target_dir="$1"
    shift
    ;;
  esac
done

target_dir=$(cd "$target_dir" 2>/dev/null && pwd) || {
  echo "Error: Directory does not exist: $target_dir" >&2
  exit 1
}

tab_name="$(basename "$target_dir")"
if [ -z "$tab_name" ] || [ "$tab_name" = "/" ]; then
  tab_name="editor"
fi

for bin in herdr jq; do
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "Error: $bin not found in PATH" >&2
    exit 1
  fi
done

if ! herdr status server >/dev/null 2>&1; then
  echo "Error: Herdr server is not running. Start 'herdr' first." >&2
  exit 1
fi

# Current workspace: inherited env when run from inside a Herdr pane,
# otherwise the server's focused workspace.
if [ -n "${HERDR_WORKSPACE_ID:-}" ]; then
  ws_id="$HERDR_WORKSPACE_ID"
else
  ws_id="$(herdr workspace list 2>/dev/null | jq -r '.result.workspaces[] | select(.focused) | .workspace_id' | head -n1)"
fi

if [ -z "$ws_id" ] || [ "$ws_id" = "null" ]; then
  echo "Error: Could not determine the current Herdr workspace." >&2
  exit 1
fi

quote() {
  printf '%q' "$1"
}

if [ "$dry_run" -eq 1 ]; then
  echo "[DRY-RUN] herdr tab create --workspace $ws_id --cwd $(quote "$target_dir") --label $(quote "$tab_name") --focus"
  echo "[DRY-RUN] herdr pane split <root-pane> --direction right --ratio 0.7 --cwd $(quote "$target_dir") --no-focus"
  echo "[DRY-RUN] herdr pane split <root-pane> --direction down --ratio 0.75 --cwd $(quote "$target_dir") --no-focus"
  echo "[DRY-RUN] herdr pane run <root-pane> 'nvim .'"
  echo "[DRY-RUN] herdr pane run <agent-pane> $(quote "$assistant_cmd .")"
  exit 0
fi

tab_res="$(herdr tab create --workspace "$ws_id" --cwd "$target_dir" --label "$tab_name" --focus)" || {
  echo "Error: failed to create tab in workspace $ws_id" >&2
  exit 1
}

root_pane="$(jq -r '.result.root_pane.pane_id // empty' <<<"$tab_res")"
if [ -z "$root_pane" ]; then
  echo "Error: could not read root pane from Herdr response" >&2
  exit 1
fi

agent_pane="$(
  herdr pane split "$root_pane" --direction right --ratio 0.7 --cwd "$target_dir" --no-focus |
    jq -r '.result.pane.pane_id // empty'
)"
if [ -z "$agent_pane" ]; then
  echo "Error: could not split right pane" >&2
  exit 1
fi

herdr pane split "$root_pane" --direction down --ratio 0.75 --cwd "$target_dir" --no-focus >/dev/null || {
  echo "Error: could not split bottom pane" >&2
  exit 1
}

wait_ready() {
  herdr pane wait-output "$1" --regex '.+' --timeout 4000 >/dev/null 2>&1 || sleep 0.4
}

run_in_pane() {
  local pane="$1"
  shift
  wait_ready "$pane"
  herdr pane run "$pane" "$*" >/dev/null || echo "Warning: failed to run command in $pane" >&2
}

run_in_pane "$root_pane" "nvim ."
run_in_pane "$agent_pane" "$assistant_cmd ."

# If launched from outside Herdr, attach so the new tab is visible
if [ "${HERDR_ENV:-}" != "1" ]; then
  exec herdr
fi
