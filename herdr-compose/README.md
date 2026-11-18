# herdr-compose (bash port)

Declarative workspace layouts for [Herdr](https://herdr.dev), driven by a YAML
file. This is a standalone bash port of
[ropali/herdr-compose](https://github.com/ropali/herdr-compose) with the same
CLI and configuration format.

It works from **fish, zsh or bash** — it is a normal executable, so the shell
you run it from makes no difference.

## Layout of this project

```
herdr-compose/
├── herdr-compose.sh     # the executable
├── layouts/             # your layouts + .active pointer (runtime state)
│   └── herdr-compose.yaml
├── examples/            # example layouts from the upstream repo
│   ├── complex_multi_workspace.yaml
│   ├── full_workspace.yaml
│   └── multi_tab_layout.yaml
└── README.md
```

Everything the tool needs lives here: the script, your layouts and the examples.
No config is written to `~/.config` unless you ask for it.

## Requirements

- `bash` 4.4+ and `jq`
- one YAML parser: `go-yq` (preferred, `sudo pacman -S go-yq`) or `python3` + PyYAML
- `herdr`

## Install

```bash
ln -sf ~/dotfiles/herdr-compose/herdr-compose.sh ~/.local/bin/herdr-compose
```

`~/.local/bin` is already on `PATH` in your fish/zsh setup, so `herdr-compose`
works from any shell. The `hc` shortcut is configured in fish, zsh and bash:

```bash
hc                # same as herdr-compose
hc show           # inspect the active layout
```

## Usage

```bash
herdr-compose                          # apply the active default layout
herdr-compose layouts/herdr-compose.yaml
herdr-compose apply <file> --dry-run    # print the herdr commands only
herdr-compose apply <file> --save       # save into layouts/ and apply
herdr-compose apply <file> -v           # log every herdr call

herdr-compose show [file]               # print the workspace/tab/pane tree
herdr-compose validate [file]           # validate syntax + schema

herdr-compose use <name>                # set active default (copies it here if needed)
herdr-compose list                     # saved layouts + active marker
herdr-compose save <file> [--use]       # copy a layout into layouts/
herdr-compose remove <name>            # delete a saved layout
herdr-compose init [name]              # create a starter layout

herdr-compose --help
herdr-compose --version
```

When no file is given, the search order is:

1. `$HERDR_COMPOSE_CONFIG` or `$HERDR_LAYOUT_CONFIG`
2. the active default (`layouts/.active`)
3. `layouts/herdr-compose.yaml`

Set `HERDR_COMPOSE_HOME` to use a different layout directory.

## YAML format

```yaml
workspaces:
  - name: my-backend
    root: ~/code/my-backend        # default cwd, ~ and $VARS expanded
    focus: true
    env:                           # workspace-level env
      LOG_LEVEL: debug
    tabs:
      - label: editor
        cwd: ~/code/my-backend
        panes:
          - name: editor           # name so other panes can split from it
            command: nvim
            focus: true

          - name: watcher
            direction: right       # right|r|horizontal|h, down|d|bottom|vertical|v
            size: 25%              # percentage or 0.0-1.0 fraction
            command: npm run watch

          - direction: down
            size: 40%
            from: editor           # root|first|previous|prev|<name>|<index>
            command: git status

      - label: database
        panes:
          - command: psql -U postgres
```

Shorthand `panes:` directly on a workspace creates a single tab named after the
workspace, exactly like the Python version.

## Notes

- `--dry-run` shell-quotes arguments (`'npm run dev'`), unlike the Python tool,
  so the printed commands are copy-pasteable.
- The live runner mirrors upstream: workspace create → tab rename/create →
  pane split with `ratio = 1 - size` → wait for the shell → `pane run`.
- `layouts/.active` is runtime state and is gitignored.
