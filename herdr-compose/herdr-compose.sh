#!/usr/bin/env bash
# herdr-compose.sh — declarative Herdr layouts from a YAML file.
#
# Bash port of https://github.com/ropali/herdr-compose. Same CLI and YAML
# format; works when invoked from fish, zsh or bash (it is a standalone
# executable, so your shell does not matter).
#
# Project layout:
#   herdr-compose.sh   this script
#   layouts/           your layouts + the .active pointer (gitignored)
#   examples/          example layouts from the upstream repo
#
# YAML parsing: prefers go-yq (mikefarah), falls back to python3 + PyYAML.
#
# Usage:
#   herdr-compose.sh                       Apply the active default layout
#   herdr-compose.sh apply layout.yaml     Apply a layout
#   herdr-compose.sh apply --dry-run       Preview generated herdr commands
#   herdr-compose.sh show layout.yaml      Print the layout tree
#   herdr-compose.sh validate layout.yaml  Validate a layout
#   herdr-compose.sh use backend           Set the active default layout
#   herdr-compose.sh list                  List saved layouts
#   herdr-compose.sh save layout.yaml --use
#   herdr-compose.sh remove backend
#   herdr-compose.sh init [name]
#   herdr-compose.sh --help

set -euo pipefail

VERSION="0.3.0"

# Project directory (resolves symlinks, so ~/.local/bin/herdr-compose works).
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || printf '%s' "${BASH_SOURCE[0]}")"
PROJECT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"

# ---------------------------------------------------------------------------
# Output helpers
# ---------------------------------------------------------------------------
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  C_RED=$'\033[31m' C_GREEN=$'\033[32m' C_YELLOW=$'\033[33m'
  C_CYAN=$'\033[36m' C_BOLD=$'\033[1m' C_RESET=$'\033[0m'
else
  C_RED="" C_GREEN="" C_YELLOW="" C_CYAN="" C_BOLD="" C_RESET=""
fi

ok() { printf '%s✓%s %s\n' "$C_GREEN$C_BOLD" "$C_RESET" "$*"; }
notice() { printf '%s⚠%s %s\n' "$C_YELLOW$C_BOLD" "$C_RESET" "$*"; }
err() { printf '%sError:%s %s\n' "$C_RED$C_BOLD" "$C_RESET" "$*" >&2; }
die() {
  err "$*"
  exit 1
}

usage() {
  cat <<'EOF'
herdr-compose — declarative workspace layouts for Herdr.

Usage:
  herdr-compose                        Apply the active default layout
  herdr-compose <file>                 Apply a specific layout file
  herdr-compose apply [file] [flags]   Apply a layout
  herdr-compose show [file]            Print the workspace/tab/pane tree
  herdr-compose validate [file]        Validate layout syntax and schema
  herdr-compose use <name>             Set the active default layout
  herdr-compose save <file> [--use]    Copy a layout into ~/.config/herdr-compose
  herdr-compose list                   List saved layouts
  herdr-compose remove <name>          Remove a saved layout
  herdr-compose init [name]            Create a starter layout
  herdr-compose --version              Print version

apply flags:
  --dry-run        Print the herdr commands instead of running them
  -v, --verbose    Log each herdr command
  --save           Also save the layout into ~/.config/herdr-compose/

Environment:
  HERDR_COMPOSE_CONFIG   Layout file to use (same as HERDR_LAYOUT_CONFIG)
  HERDR_COMPOSE_HOME     Layout directory (default: <project>/layouts)

Search order when no file is given:
  1. $HERDR_COMPOSE_CONFIG / $HERDR_LAYOUT_CONFIG
  2. Active default (<layouts>/.active)
  3. <layouts>/herdr-compose.yaml

YAML parsing needs go-yq (`sudo pacman -S go-yq`) or python3 + PyYAML.
EOF
}

# ---------------------------------------------------------------------------
# Paths and config file resolution
# ---------------------------------------------------------------------------
config_dir() {
  printf '%s\n' "${HERDR_COMPOSE_HOME:-$PROJECT_DIR/layouts}"
}

active_pointer() {
  printf '%s/.active\n' "$(config_dir)"
}

expand_path() {
  local p="${1:-}" name value re
  [ -n "$p" ] || return 0
  p="${p/#\~/$HOME}"
  re='\$(\{([A-Za-z_][A-Za-z0-9_]*)\}|([A-Za-z_][A-Za-z0-9_]*))'
  while [[ $p =~ $re ]]; do
    name="${BASH_REMATCH[2]:-${BASH_REMATCH[3]}}"
    value="${!name-}"
    p="${p/"${BASH_REMATCH[0]}"/$value}"
  done
  printf '%s' "$p"
}

active_name() {
  local pointer name
  pointer="$(active_pointer)"
  [ -f "$pointer" ] || return 0
  name="$(<"$pointer")"
  name="${name//[$'\r\n']/}"
  [ -n "$name" ] && [ -f "$(config_dir)/$name" ] && printf '%s' "$name"
  return 0
}

resolve_config_path() {
  local arg="${1:-}" raw candidate base ext dir
  dir="$(config_dir)"

  if [ -n "$arg" ]; then
    raw="$(expand_path "$arg")"
    case "$raw" in
    *.yaml | *.yml) set -- "" ;;
    *) set -- "" ".yaml" ".yml" ;;
    esac
    for ext in "$@"; do
      candidate="${raw}${ext}"
      if [ -f "$candidate" ]; then
        printf '%s' "$candidate"
        return 0
      fi
      base="$(basename "$candidate")"
      if [ -f "$dir/$base" ]; then
        printf '%s' "$dir/$base"
        return 0
      fi
    done
    die "Configuration file '$arg' not found (also checked '$dir')."
  fi

  raw="${HERDR_COMPOSE_CONFIG:-${HERDR_LAYOUT_CONFIG:-}}"
  if [ -n "$raw" ]; then
    raw="$(expand_path "$raw")"
    [ -f "$raw" ] || die "Configuration file specified in environment variable does not exist: $raw"
    printf '%s' "$raw"
    return 0
  fi

  local active
  active="$(active_name)"
  if [ -n "$active" ]; then
    printf '%s/%s' "$dir" "$active"
    return 0
  fi

  if [ -f "$dir/herdr-compose.yaml" ]; then
    printf '%s/herdr-compose.yaml' "$dir"
    return 0
  fi

  die "No layout YAML file found. Checked:
  - $dir/herdr-compose.yaml
Provide a path, set HERDR_COMPOSE_CONFIG, or run: herdr-compose init"
}

# ---------------------------------------------------------------------------
# YAML -> JSON
# ---------------------------------------------------------------------------
yaml_to_json() {
  local file="$1"
  if command -v yq >/dev/null 2>&1 && yq --version 2>&1 | grep -qi 'mikefarah'; then
    yq -o=json '.' "$file"
  elif python3 -c 'import yaml' >/dev/null 2>&1; then
    python3 - "$file" <<'PY'
import json
import sys

import yaml

try:
    with open(sys.argv[1], encoding="utf-8") as fh:
        data = yaml.safe_load(fh)
except Exception as exc:  # noqa: BLE001
    sys.stderr.write(f"Failed to parse YAML: {exc}\n")
    sys.exit(1)

json.dump(data, sys.stdout)
PY
  else
    die "No YAML parser found. Install go-yq (sudo pacman -S go-yq) or python-pyyaml."
  fi
}

load_layout() {
  local file="$1" json
  [ -f "$file" ] || die "Config file not found: $file"
  json="$(yaml_to_json "$file")" || die "Failed to parse YAML file '$file'"
  jq -e 'type == "object" and (.workspaces | type == "array") and (.workspaces | length > 0)' \
    >/dev/null <<<"$json" ||
    die "Layout configuration must contain a non-empty 'workspaces' list"
  printf '%s' "$json"
}

# ---------------------------------------------------------------------------
# Value normalization (mirrors models.py)
# ---------------------------------------------------------------------------
normalize_ws_json() {
  jq 'if (has("panes") and (has("tabs") | not)) then
        . + {tabs: [{label: (.name // .workspace // .label),
                     cwd: .root,
                     panes: (.panes // []),
                     env: (.env // {})}]}
      else . end'
}

normalize_pane_json() {
  jq 'if type == "string" then {command: .}
      elif type == "object" then .
      else error("Pane definition must be a string or dictionary") end'
}

lower() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }

size_to_fraction() {
  local raw="$1" pct=0 num frac
  raw="${raw#"${raw%%[![:space:]]*}"}"
  raw="${raw%"${raw##*[![:space:]]}"}"
  case "$raw" in
  *%) pct=1 raw="${raw%\%}" ;;
  esac
  if ! [[ $raw =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    die "Invalid size '$1'. Specify a percentage (e.g. '30%') or float (e.g. 0.3)"
  fi
  num="$raw"
  frac="$(awk -v n="$num" -v pct="$pct" 'BEGIN { if (pct || n >= 1) n = n / 100; printf "%.4f", n }')"
  awk -v f="$frac" 'BEGIN { exit !(f > 0 && f < 1) }' ||
    die "Size numeric value must be between 0.0 and 1.0 (or percentage 1..99), got $1"
  frac="${frac%0}"
  frac="${frac%0}"
  frac="${frac%0}"
  frac="${frac%0}"
  frac="${frac%.}"
  printf '%s' "$frac"
}

ratio_for_size() {
  local size="$1" r
  r="$(awk -v s="$size" 'BEGIN { printf "%.4f", 1 - s }')"
  r="${r%0}"
  r="${r%0}"
  r="${r%0}"
  r="${r%0}"
  r="${r%.}"
  printf '%s' "$r"
}

normalize_direction() {
  local raw="${1:-right}" val
  val="$(lower "$raw")"
  val="${val//[[:space:]]/}"
  case "$val" in
  right | r | horizontal | h) printf 'right' ;;
  down | d | bottom | vertical | v) printf 'down' ;;
  *) die "Invalid split direction '$raw'. Supported values: 'right', 'down', 'horizontal', 'vertical'." ;;
  esac
}

env_pairs() {
  local json="${1:-{\}}"
  jq -r 'if type == "object" then to_entries[] | "\(.key)=\(.value)"
         elif type == "array" then .[] | tostring
         else empty end' <<<"$json"
}

# ---------------------------------------------------------------------------
# Runner
# ---------------------------------------------------------------------------
DRY_RUN=0
VERBOSE=0
PANES=()
declare -A PANE_NAMES=()
LAST_PANE_ID=""

run_herdr() {
  if [ "$DRY_RUN" = "1" ]; then
    printf '[DRY-RUN] herdr'
    printf ' %q' "$@"
    printf '\n'
    return 0
  fi
  if [ "$VERBOSE" = "1" ]; then
    printf '[EXEC] herdr' >&2
    printf ' %q' "$@" >&2
    printf '\n' >&2
  fi
  herdr "$@"
}

# Like run_herdr, but discards herdr's own output (still prints dry-run lines).
run_herdr_quiet() {
  if [ "$DRY_RUN" = "1" ]; then
    run_herdr "$@"
  else
    run_herdr "$@" >/dev/null
  fi
}

wait_for_pane() {
  local pane="$1" timeout_s=5 info shell_pid ready i rc
  [ "$DRY_RUN" = "1" ] && return 0

  herdr pane wait-output "$pane" --regex '.+' --timeout 2000 >/dev/null 2>&1 || true

  # Poll until the only foreground process is the pane's shell.
  for ((i = 0; i < 100; i++)); do
    if info="$(herdr pane process-info --pane "$pane" 2>/dev/null)"; then
      shell_pid="$(jq -r '.result.process_info.shell_pid // empty' <<<"$info" 2>/dev/null || true)"
      if [ -n "$shell_pid" ]; then
        ready="$(jq -r --arg sp "$shell_pid" \
          '((.result.process_info.foreground_processes // []) | map(.pid)) == [($sp | tonumber)]' \
          <<<"$info" 2>/dev/null || printf 'false')"
        if [ "$ready" = "true" ]; then
          sleep 0.1
          return 0
        fi
      fi
    else
      rc=$?
      # Older herdr builds do not support process-info; fall back to a delay.
      if [ "$rc" -eq 2 ]; then
        sleep 0.3
        return 0
      fi
    fi
    sleep 0.05
  done
  sleep 0.2
}

apply_pane() {
  local pane_json="$1" pane_idx="$2" tab_cwd="$3" root_pane="$4" ws_id="$5" tab_idx="$6"
  local name command direction size_raw size focus cwd from_ref from_lc env_json source_pane id

  pane_json="$(normalize_pane_json <<<"$pane_json")"
  name="$(jq -r '.name // .id // empty' <<<"$pane_json")"
  command="$(jq -r '.command // .run // empty' <<<"$pane_json")"
  direction="$(normalize_direction "$(jq -r '.direction // .split // "right"' <<<"$pane_json")")"
  size_raw="$(jq -r '.size // .ratio // empty' <<<"$pane_json")"
  focus="$(jq -r '.focus // false' <<<"$pane_json")"
  cwd="$(jq -r '.cwd // empty' <<<"$pane_json")"
  from_ref="$(jq -r '.from // .target // "previous"' <<<"$pane_json")"
  env_json="$(jq -c '.env // {}' <<<"$pane_json")"

  size=""
  [ -n "$size_raw" ] && size="$(size_to_fraction "$size_raw")"
  [ -n "$cwd" ] || cwd="$tab_cwd"

  if [ "$pane_idx" -eq 0 ]; then
    id="$root_pane"
  else
    from_lc="$(lower "$from_ref")"
    if [ -n "${PANE_NAMES[$from_lc]+x}" ]; then
      source_pane="${PANE_NAMES[$from_lc]}"
    elif [[ $from_lc =~ ^(root|first|0)$ ]]; then
      source_pane="${PANES[0]}"
    elif [[ $from_lc =~ ^(previous|prev)$ ]]; then
      source_pane="${PANES[$((${#PANES[@]} - 1))]}"
    elif [[ $from_lc =~ ^[0-9]+$ ]]; then
      if [ "$from_lc" -lt "${#PANES[@]}" ]; then
        source_pane="${PANES[$from_lc]}"
      else
        source_pane="${PANES[$((${#PANES[@]} - 1))]}"
      fi
    else
      source_pane="${PANES[$((${#PANES[@]} - 1))]}"
    fi

    local -a split_args=(pane split "$source_pane" --direction "$direction")
    [ -n "$size" ] && split_args+=(--ratio "$(ratio_for_size "$size")")
    [ -n "$cwd" ] && split_args+=(--cwd "$(expand_path "$cwd")")
    if [ "$focus" = "true" ]; then split_args+=(--focus); else split_args+=(--no-focus); fi
    local kv
    while IFS= read -r kv; do
      [ -n "$kv" ] && split_args+=(--env "$kv")
    done < <(env_pairs "$env_json")

    if [ "$DRY_RUN" = "1" ]; then
      run_herdr "${split_args[@]}"
      id="${ws_id}:t$((tab_idx + 1)):p$((pane_idx + 1))"
    else
      local res
      res="$(herdr "${split_args[@]}")" || die "Failed to split pane ${source_pane}"
      id="$(jq -r '.result.pane.pane_id // empty' <<<"$res")"
      [ -n "$id" ] || die "Could not read pane id from herdr response"
    fi
    PANES+=("$id")
  fi

  LAST_PANE_ID="$id"

  if [ -n "$command" ]; then
    wait_for_pane "$id"
    run_herdr_quiet pane run "$id" "$command"
  fi
}

apply_tab() {
  local tab_json="$1" tab_idx="$2" ws_json="$3" ws_id="$4" initial_tab_id="$5" initial_root_pane="$6"
  local label tab_cwd first_pane_cwd ws_root effective_cwd tab_id root_pane pane_count i pname

  label="$(jq -r '.label // .name // empty' <<<"$tab_json")"
  tab_cwd="$(jq -r '.cwd // empty' <<<"$tab_json")"
  first_pane_cwd="$(jq -r '.panes[0].cwd // empty' <<<"$tab_json" 2>/dev/null || true)"
  ws_root="$(jq -r '.root // empty' <<<"$ws_json")"
  effective_cwd="${first_pane_cwd:-${tab_cwd:-$ws_root}}"

  if [ "$tab_idx" -eq 0 ]; then
    tab_id="$initial_tab_id"
    root_pane="$initial_root_pane"
    if [ -n "$label" ]; then
      run_herdr_quiet tab rename "$tab_id" "$label" || true
    fi
  else
    local -a tab_args=(tab create --workspace "$ws_id")
    [ -n "$effective_cwd" ] && tab_args+=(--cwd "$(expand_path "$effective_cwd")")
    [ -n "$label" ] && tab_args+=(--label "$label")
    local kv
    while IFS= read -r kv; do
      [ -n "$kv" ] && tab_args+=(--env "$kv")
    done < <(env_pairs "$(jq -c '.env // {}' <<<"$tab_json")")

    if [ "$DRY_RUN" = "1" ]; then
      run_herdr "${tab_args[@]}"
      root_pane="${ws_id}:t$((tab_idx + 1)):p1"
    else
      local res
      res="$(herdr "${tab_args[@]}")" || die "Failed to create tab"
      root_pane="$(jq -r '.result.root_pane.pane_id // empty' <<<"$res")"
      [ -n "$root_pane" ] || die "Could not read root pane from herdr response"
    fi
  fi

  PANES=("$root_pane")
  PANE_NAMES=()
  pane_count="$(jq '.panes | length' <<<"$tab_json")"
  for ((i = 0; i < pane_count; i++)); do
    apply_pane "$(jq -c ".panes[$i]" <<<"$tab_json")" "$i" "$effective_cwd" "$root_pane" "$ws_id" "$tab_idx"
    pname="$(jq -r '.name // .id // empty' <<<"$(normalize_pane_json <<<"$(jq -c ".panes[$i]" <<<"$tab_json")")")"
    if [ -n "$pname" ]; then
      PANE_NAMES["$(lower "$pname")"]="$LAST_PANE_ID"
    fi
  done
}

apply_workspace() {
  local ws_json="$1" ws_idx="$2"
  local name root focus ws_cwd ws_id tab_id root_pane tab_count t

  ws_json="$(normalize_ws_json <<<"$ws_json")"
  name="$(jq -r '.name // .workspace // .label // empty' <<<"$ws_json")"
  [ -n "$name" ] || die "Workspace missing required field 'name'"
  root="$(jq -r '.root // empty' <<<"$ws_json")"
  focus="$(jq -r '.focus // false' <<<"$ws_json")"
  ws_cwd="$(jq -r '.tabs[0].panes[0].cwd // .tabs[0].cwd // .root // empty' <<<"$ws_json" 2>/dev/null || true)"

  local -a ws_args=(workspace create --label "$name")
  [ -n "$ws_cwd" ] && ws_args+=(--cwd "$(expand_path "$ws_cwd")")
  if [ "$focus" = "true" ]; then ws_args+=(--focus); else ws_args+=(--no-focus); fi
  local kv
  while IFS= read -r kv; do
    [ -n "$kv" ] && ws_args+=(--env "$kv")
  done < <(env_pairs "$(jq -c '.env // {}' <<<"$ws_json")")

  if [ "$DRY_RUN" = "1" ]; then
    run_herdr "${ws_args[@]}"
    ws_id="w${ws_idx}"
    tab_id="${ws_id}:t1"
    root_pane="${ws_id}:p1"
  else
    local res
    res="$(herdr "${ws_args[@]}")" || die "Failed to create workspace '$name'"
    ws_id="$(jq -r '.result.workspace.workspace_id // empty' <<<"$res")"
    tab_id="$(jq -r '.result.tab.tab_id // empty' <<<"$res")"
    root_pane="$(jq -r '.result.root_pane.pane_id // empty' <<<"$res")"
    [ -n "$ws_id" ] && [ -n "$root_pane" ] || die "Could not parse workspace response from herdr"
  fi

  tab_count="$(jq '.tabs | length' <<<"$ws_json" 2>/dev/null || printf 0)"
  for ((t = 0; t < tab_count; t++)); do
    apply_tab "$(jq -c ".tabs[$t]" <<<"$ws_json")" "$t" "$ws_json" "$ws_id" "$tab_id" "$root_pane"
  done
}

apply_layout_json() {
  local json="$1" ws_count w
  if [ "$DRY_RUN" != "1" ] && ! command -v herdr >/dev/null 2>&1; then
    die "herdr is not installed or not in PATH."
  fi
  ws_count="$(jq '.workspaces | length' <<<"$json")"
  for ((w = 0; w < ws_count; w++)); do
    apply_workspace "$(jq -c ".workspaces[$w]" <<<"$json")" "$((w + 1))"
  done
}

# ---------------------------------------------------------------------------
# Tree rendering (mirrors utils.render_layout_tree)
# ---------------------------------------------------------------------------
render_tree() {
  local json="$1" ws_count w tab_count t pane_count i
  local ws name focus root tab label cwd tab_prefix sub_prefix conn
  local pname pcmd pdir psize pfrom pfocus line

  printf 'Layout Summary:\n'
  ws_count="$(jq '.workspaces | length' <<<"$json")"
  for ((w = 0; w < ws_count; w++)); do
    ws="$(normalize_ws_json <<<"$(jq -c ".workspaces[$w]" <<<"$json")")"
    name="$(jq -r '.name // .workspace // .label' <<<"$ws")"
    focus="$(jq -r '.focus // false' <<<"$ws")"
    root="$(expand_path "$(jq -r '.root // empty' <<<"$ws")")"
    line="Workspace $((w + 1)): ${name}"
    [ "$focus" = "true" ] && line+=" (focused)"
    [ -n "$root" ] && line+=" [root: ${root}]"
    printf '%s\n' "$line"

    tab_count="$(jq '.tabs | length' <<<"$ws")"
    if [ "$tab_count" -eq 0 ]; then
      printf '  └─ (default tab)\n'
      continue
    fi

    for ((t = 0; t < tab_count; t++)); do
      local tab_json
      tab_json="$(jq -c ".tabs[$t]" <<<"$ws")"
      if [ "$t" -eq $((tab_count - 1)) ]; then
        tab_prefix="  └─ "
        sub_prefix="     "
      else
        tab_prefix="  ├─ "
        sub_prefix="  │  "
      fi
      label="$(jq -r '.label // .name // empty' <<<"$tab_json")"
      [ -n "$label" ] || label="tab-$((t + 1))"
      cwd="$(expand_path "$(jq -r '.cwd // empty' <<<"$tab_json")")"
      line="${tab_prefix}Tab $((t + 1)): ${label}"
      [ -n "$cwd" ] && line+=" [cwd: ${cwd}]"
      printf '%s\n' "$line"

      pane_count="$(jq '.panes | length' <<<"$tab_json")"
      if [ "$pane_count" -eq 0 ]; then
        printf '%s└─ (root pane)\n' "$sub_prefix"
        continue
      fi

      for ((i = 0; i < pane_count; i++)); do
        local pane_json
        pane_json="$(normalize_pane_json <<<"$(jq -c ".panes[$i]" <<<"$tab_json")")"
        if [ "$i" -eq $((pane_count - 1)) ]; then conn="└─ "; else conn="├─ "; fi
        pname="$(jq -r '.name // .id // empty' <<<"$pane_json")"
        pcmd="$(jq -r '.command // .run // empty' <<<"$pane_json")"
        pdir="$(normalize_direction "$(jq -r '.direction // .split // "right"' <<<"$pane_json")")"
        pfrom="$(jq -r '.from // .target // "previous"' <<<"$pane_json")"
        pfocus="$(jq -r '.focus // false' <<<"$pane_json")"

        line="${sub_prefix}${conn}Pane $((i + 1))"
        [ -n "$pname" ] && line+=" [${pname}]"
        if [ "$i" -eq 0 ]; then
          line+=" [root pane]"
        else
          local raw_size fraction
          raw_size="$(jq -r '.size // .ratio // empty' <<<"$pane_json")"
          fraction="$(size_to_fraction "$raw_size")"
          line+=" [split ${pdir}, size ${fraction}]"
          [ "$pfrom" != "previous" ] && line+=" (from ${pfrom})"
        fi
        [ "$pfocus" = "true" ] && line+=" (focused)"
        [ -n "$pcmd" ] && line+=" -> \`${pcmd}\`"
        printf '%s\n' "$line"
      done
    done
  done
}

# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------
validate_json() {
  local json="$1" ws_count w tab_count t pane_count i ws tab pane
  ws_count="$(jq '.workspaces | length' <<<"$json")"
  for ((w = 0; w < ws_count; w++)); do
    ws="$(normalize_ws_json <<<"$(jq -c ".workspaces[$w]" <<<"$json")")"
    [ -n "$(jq -r '.name // .workspace // .label // empty' <<<"$ws")" ] ||
      die "Workspace $((w + 1)) is missing required field 'name'"
    tab_count="$(jq '.tabs | length' <<<"$ws")"
    for ((t = 0; t < tab_count; t++)); do
      tab="$(jq -c ".tabs[$t]" <<<"$ws")"
      pane_count="$(jq '.panes | length' <<<"$tab" 2>/dev/null || printf 0)"
      for ((i = 0; i < pane_count; i++)); do
        pane="$(normalize_pane_json <<<"$(jq -c ".panes[$i]" <<<"$tab")")"
        normalize_direction "$(jq -r '.direction // .split // "right"' <<<"$pane")" >/dev/null
        local raw_size
        raw_size="$(jq -r '.size // .ratio // empty' <<<"$pane")"
        if [ -n "$raw_size" ]; then
          size_to_fraction "$raw_size" >/dev/null
        fi
      done
    done
  done
}

# ---------------------------------------------------------------------------
# CLI commands
# ---------------------------------------------------------------------------
apply_cli() {
  local file="" dry=0 verbose=0 save=0 path json
  while [ $# -gt 0 ]; do
    case "$1" in
    --dry-run) dry=1 ;;
    -v | --verbose) verbose=1 ;;
    --save) save=1 ;;
    -h | --help)
      usage
      return 0
      ;;
    -*)
      die "Unknown option: $1"
      ;;
    *) file="$1" ;;
    esac
    shift
  done
  DRY_RUN="$dry"
  VERBOSE="$verbose"

  path="$(resolve_config_path "$file")"
  json="$(load_layout "$path")"

  if [ "$save" = "1" ]; then
    save_one "$path" ""
  fi

  printf 'Applying layout from %s...\n' "$path"
  apply_layout_json "$json"
  ok "Layout created successfully!"
}

SAVED_PATH=""
save_one() {
  local src="$1" use="${2:-}" dir name
  dir="$(config_dir)"
  name="$(basename "$src")"
  case "$name" in
  *.yaml | *.yml) ;;
  *) name="${name}.yaml" ;;
  esac
  mkdir -p "$dir"
  if [ "$(readlink -f "$src")" != "$(readlink -f "$dir/$name")" ]; then
    cp "$src" "$dir/$name"
  fi
  ok "Saved configuration file to: $dir/$name"
  if [ "$use" = "1" ]; then
    printf '%s\n' "$name" >"$(active_pointer)"
    ok "Set active default layout configuration to: $name"
  elif [ -z "$(active_name)" ]; then
    printf '%s\n' "$name" >"$(active_pointer)"
  fi
  SAVED_PATH="$dir/$name"
}

cmd_use() {
  [ $# -ge 1 ] || die "usage: herdr-compose use <name>"
  local resolved dir name
  resolved="$(resolve_config_path "$1")"
  dir="$(config_dir)"
  if [ "$(dirname "$resolved")" != "$dir" ]; then
    save_one "$resolved" ""
    resolved="$SAVED_PATH"
  fi
  name="$(basename "$resolved")"
  printf '%s\n' "$name" >"$(active_pointer)"
  ok "Active default layout configuration set to: $name"
}

cmd_save() {
  local src="" use=0
  while [ $# -gt 0 ]; do
    case "$1" in
    --use | -u | --active) use=1 ;;
    -*) die "Unknown option: $1" ;;
    *) src="$1" ;;
    esac
    shift
  done
  [ -n "$src" ] || die "usage: herdr-compose save <file> [--use]"
  local resolved
  resolved="$(resolve_config_path "$src")"
  load_layout "$resolved" >/dev/null
  save_one "$resolved" "$use"
}

cmd_list() {
  local dir active files=() f count plural ws_str name_tag is_active json
  dir="$(config_dir)"
  active="$(active_name)"

  if [ ! -d "$dir" ]; then
    printf "No saved configuration files found in '%s'\n" "$dir"
    printf "Tip: Run 'herdr-compose init' or 'herdr-compose save <file.yaml>'.\n"
    return 0
  fi

  mapfile -t files < <(find "$dir" -maxdepth 1 -type f \( -name '*.yaml' -o -name '*.yml' \) | sort)
  if [ "${#files[@]}" -eq 0 ]; then
    printf "No saved configuration files found in '%s'\n" "$dir"
    printf "Tip: Run 'herdr-compose init' or 'herdr-compose save <file.yaml>'.\n"
    return 0
  fi

  printf "Saved configuration files in '%s':\n\n" "$dir"
  local idx=0
  for f in "${files[@]}"; do
    idx=$((idx + 1))
    local base
    base="$(basename "$f")"
    if json="$(yaml_to_json "$f" 2>/dev/null)" &&
      count="$(jq -er '.workspaces | length' <<<"$json" 2>/dev/null)"; then
      plural="s"
      [ "$count" -eq 1 ] && plural=""
      ws_str="($count workspace${plural})"
    else
      ws_str="(invalid configuration)"
    fi
    name_tag="${C_CYAN}${C_BOLD}${base}${C_RESET}"
    is_active=""
    if [ -n "$active" ] && [ "$base" = "$active" ]; then
      is_active=" ${C_YELLOW}${C_BOLD}★ [active default]${C_RESET}"
    fi
    printf '  %d. %s %s%s\n' "$idx" "$name_tag" "$ws_str" "$is_active"
  done
}

cmd_remove() {
  [ $# -ge 1 ] || die "usage: herdr-compose remove <name>"
  local dir target name
  dir="$(config_dir)"
  for name in "$1" "${1}.yaml" "${1}.yml"; do
    target="$dir/$(basename "$name")"
    if [ -f "$target" ]; then
      rm -f "$target"
      if [ "$(basename "$target")" = "$(active_name)" ]; then
        rm -f "$(active_pointer)"
      fi
      ok "Removed saved configuration file: $(basename "$target")"
      return 0
    fi
  done
  die "Saved configuration file '$1' not found in '$dir'."
}

cmd_show() {
  local path json
  path="$(resolve_config_path "${1:-}")"
  json="$(load_layout "$path")"
  printf "Layout loaded from '%s':\n\n" "$path"
  render_tree "$json"
}

cmd_validate() {
  local path json count
  path="$(resolve_config_path "${1:-}")"
  json="$(load_layout "$path")"
  validate_json "$json"
  count="$(jq '.workspaces | length' <<<"$json")"
  ok "Configuration file '$path' is valid."
  printf '  Defined workspaces: %s\n' "$count"
}

cmd_init() {
  local arg="" overwrite=0 set_active=1 target
  while [ $# -gt 0 ]; do
    case "$1" in
    --overwrite | -f) overwrite=1 ;;
    --no-active) set_active=0 ;;
    -*) die "Unknown option: $1" ;;
    *) arg="$1" ;;
    esac
    shift
  done

  if [ -z "$arg" ]; then
    target="$(config_dir)/herdr-compose.yaml"
  else
    local raw
    raw="$(expand_path "$arg")"
    case "$raw" in
    *.yaml | *.yml) ;;
    *) raw="${raw}.yaml" ;;
    esac
    case "$raw" in
    */*) target="$raw" ;;
    *) target="$(config_dir)/$raw" ;;
    esac
  fi

  if [ -f "$target" ] && [ "$overwrite" -ne 1 ]; then
    notice "Target template file already exists: $target"
    return 0
  fi

  mkdir -p "$(dirname "$target")"
  cat >"$target" <<'YAML'
# Herdr Compose Workspace Layout Configuration
# Learn more about Herdr at https://herdr.dev

workspaces:
  - name: main
    root: ~/Workspace/my-project
    focus: true
    tabs:
      - label: editor
        cwd: ~/Workspace/my-project
        panes:
          - name: main_editor
            command: nvim
            focus: true

          - name: sidebar
            direction: right
            size: 20%
            command: opencode

          - name: status
            direction: down
            size: 30%
            from: main_editor
            command: git status

      - label: dev-server
        panes:
          - command: npm run dev
YAML

  ok "Created starter layout config at: $target"
  if [ "$set_active" -eq 1 ] && [ "$(dirname "$target")" = "$(config_dir)" ]; then
    printf '%s\n' "$(basename "$target")" >"$(active_pointer)"
    ok "Set active default layout configuration to: $(basename "$target")"
  fi
}

# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------
main() {
  if [ $# -eq 0 ]; then
    apply_cli
    return 0
  fi

  local first="$1"
  case "$first" in
  -h | --help)
    usage
    return 0
    ;;
  -V | --version)
    printf 'herdr-compose %s\n' "$VERSION"
    return 0
    ;;
  apply)
    shift
    apply_cli "$@"
    ;;
  validate)
    shift
    cmd_validate "$@"
    ;;
  show)
    shift
    cmd_show "$@"
    ;;
  use | select | set-default)
    shift
    cmd_use "$@"
    ;;
  init)
    shift
    cmd_init "$@"
    ;;
  save)
    shift
    cmd_save "$@"
    ;;
  list)
    shift
    cmd_list "$@"
    ;;
  remove | rm | delete)
    shift
    cmd_remove "$@"
    ;;
  *)
    # A file path, or flags such as --dry-run, imply `apply`.
    apply_cli "$@"
    ;;
  esac
}

main "$@"
