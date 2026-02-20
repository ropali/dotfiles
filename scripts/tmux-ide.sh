#!/bin/bash
# tmux-ide: Open IDE layout with nvim, opencode, and terminal
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

# If invoked as tmux-ide.sh (or any non-ide name), install/update then re-run as ide
if [ "$(basename "$0")" != "ide" ]; then
  self_install
  exit 0
fi

ide() {
  local target_dir="."
  local assistant_cmd="${IDE_ASSISTANT:-opencode}"

  while [ $# -gt 0 ]; do
    case "$1" in
      --ai)
        if [ -z "${2:-}" ]; then
          echo "Error: --ai requires a command" >&2
          return 1
        fi
        assistant_cmd="$2"
        shift 2
        ;;
      --)
        shift
        break
        ;;
      -*)
        echo "Error: Unknown option: $1" >&2
        return 1
        ;;
      *)
        target_dir="$1"
        shift
        ;;
    esac
  done

  # Resolve to absolute path
  target_dir=$(cd "$target_dir" 2>/dev/null && pwd) || {
    echo "Error: Directory does not exist: $1" >&2
    return 1
  }
  local window_name
  window_name="$(basename "$target_dir")"
  if [ -z "$window_name" ] || [ "$window_name" = "/" ]; then
    window_name="editor"
  fi

  # Function to setup the panes for a specific window
  setup_panes() {
    local window_target="$1"
    local dir="$2"

    # First split: create right pane (30% width)
    # This creates Pane 1 (Right)
    tmux split-window -t "${window_target}" -h -p 30 -c "${dir}"

    # Split the left pane vertically
    # This splits Pane 0 (Left), creating a new Pane 1 (Bottom-Left).
    # The previous Pane 1 (Right) becomes Pane 2.
    tmux split-window -t "${window_target}.1" -v -p 25 -c "${dir}"

    # Send commands to each pane
    # Pane 1: Top-Left (nvim)
    # Pane 2: Bottom-Left (terminal)
    # Pane 3: Right (opencode)

    # Wait a bit for panes to initialize
    sleep 0.5

    tmux send-keys -t "${window_target}.1" "cd '${dir}' && nvim ." C-m
    sleep 0.1
    tmux send-keys -t "${window_target}.2" "cd '${dir}'" C-m
    sleep 0.1
    tmux send-keys -t "${window_target}.3" "cd '${dir}' && ${assistant_cmd} ." C-m

    # Select the nvim pane (top-left)
    tmux select-pane -t "${window_target}.1"
  }

  if [ -z "$TMUX" ]; then
    # Not inside a tmux session

    # Check if session 'ide' already exists
    if tmux has-session -t ide 2>/dev/null; then
      # Session exists. Create a new window in it.
      # Get the new window index
      local window_index=$(tmux new-window -t ide -n "$window_name" -c "$target_dir" -P -F "#{window_index}")

      # Setup panes for the new window
      setup_panes "ide:${window_index}" "$target_dir"

      # Attach to the session
      tmux attach-session -t ide
    else
      # Create new session 'ide'
      # Start with a named window to avoid index confusion if needed, but standard new-session starts at index 0 or 1.
      # We capture the window ID/index to be safe, but new-session -d doesn't output it easily without -P.
      # Let's create session detached with explicit window name 'editor'.
      tmux new-session -d -s ide -n "$window_name" -c "$target_dir"

      # Setup panes for the window 'editor' in session 'ide'
      setup_panes "ide:${window_name}" "$target_dir"

      # Attach
      tmux attach-session -t ide
    fi
  else
    # Inside a tmux session
    # Create a new window in the current session
    local window_index=$(tmux new-window -n "$window_name" -c "$target_dir" -P -F "#{window_index}")

    # Setup panes
    setup_panes "${window_index}" "$target_dir"
  fi
}

ide "$@"
