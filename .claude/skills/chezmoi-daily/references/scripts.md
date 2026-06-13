# run_ scripts

Read this when:
- A user wants to bootstrap a machine (install Homebrew, clone vim plugins, register a launchd agent).
- A `run_once_` script is re-running unexpectedly, or not running at all.
- A user is unsure which prefix to pick.

## What scripts are

Files in the source dir whose names start with `run_` are executed during `chezmoi apply`. They are NOT written to the destination — the script body runs and that's it. They are the "hook" mechanism for things chezmoi can't model as files.

The order in a single `apply`:

```
run_*_before_*    →   file updates (writes/diffs)   →   run_*_after_*
                          ↑
                  run_* without before/after run interleaved
                  with files in alphabetical order
```

## Cadence prefixes

| Prefix          | Runs when                                          | State stored where                |
|-----------------|----------------------------------------------------|-----------------------------------|
| `run_`          | every `apply`                                       | nowhere — always runs             |
| `run_once_`     | first time chezmoi sees this exact content (SHA-256) | persistent state DB              |
| `run_onchange_` | every time content (post-template) differs from last run | persistent state DB          |

`run_once_` keys on **content hash, not filename** — renaming the script doesn't trigger a re-run, but editing it does. This is the single most common surprise.

## Position prefixes

| Combine with cadence prefix as     | Effect                                  |
|------------------------------------|-----------------------------------------|
| `run_before_`, `run_once_before_`, `run_onchange_before_` | Runs before any file writes in this apply |
| `run_after_`, `run_once_after_`, `run_onchange_after_`    | Runs after all file writes in this apply  |

Order between `before_` scripts (or between `after_` scripts) is alphabetical — name them `run_once_before_00-brew.sh`, `run_once_before_10-clone-vim-plugins.sh` to control sequence.

## Filename grammar

```
run_[once_|onchange_][before_|after_]<descriptive-name>[.tmpl]
```

The trailing `.tmpl` makes the script body itself templated — useful when the script needs to branch on OS:

```bash
# run_onchange_install-pkgs.sh.tmpl
#!/bin/sh
{{ if eq .chezmoi.os "darwin" }}
brew bundle --file=/dev/stdin <<EOF
{{ include "Brewfile" }}
EOF
{{ else if eq .chezmoi.os "linux" }}
sudo apt-get update && sudo apt-get install -y vim tmux ripgrep
{{ end }}
```

Note: the `_onchange_` cadence is keyed on **rendered content**, so when you bump a package version in `Brewfile`, the script reruns automatically next apply. This is the standard pattern for "keep these packages installed".

## Idempotency is not optional

`run_` scripts run every apply. `run_once_` runs once **per machine where chezmoi has tracked it** — but on a new machine it runs again from scratch. Either way: write scripts that are safe to re-run.

```bash
# Bad — fails on second run
mkdir ~/.config/foo

# Good
mkdir -p ~/.config/foo

# Bad — appends every time
echo 'export FOO=1' >> ~/.zshrc.local

# Good — let chezmoi manage ~/.zshrc.local instead, don't shell-append
```

## Common gotchas

- **Shebang required.** A script without `#!` won't run reliably across machines. `#!/bin/sh` for portable, `#!/usr/bin/env bash` if you need bash.
- **Empty rendered template = skipped.** A `run_*.tmpl` that renders to whitespace doesn't execute. Useful intentionally; surprising when a conditional unexpectedly produces nothing.
- **Dry run doesn't run scripts.** `chezmoi -n apply` skips them. To test for real, apply on a throwaway VM/container or in a known-recoverable state.
- **`run_once_` re-running.** Either content changed (most common) or persistent state was reset (e.g., new machine, deleted state DB). Confirm with `chezmoi state dump`.
- **Permissions.** chezmoi sets the executable bit when running, you don't need `executable_` on scripts. Don't add it — it does nothing useful and clutters the filename.
- **Scripts can't see chezmoi's in-memory state.** They're plain shell. If a script needs the same data the templates have, render it via the script's `.tmpl` body or call `chezmoi data` from inside the script and parse JSON.

## Inspecting state

```bash
chezmoi state dump            # full JSON of what's been run
chezmoi state delete-bucket --bucket scriptState   # force re-run of all _once_/_onchange_
```

`delete-bucket` is the nuclear option — only when a user genuinely wants to re-bootstrap.

## When to use a script vs a managed file

| Need                                                         | Use                                  |
|--------------------------------------------------------------|--------------------------------------|
| File that exists on disk with templated content              | regular `.tmpl`                      |
| One-time setup (install Homebrew, clone a repo)              | `run_once_before_*`                  |
| Keep a package list in sync with a `Brewfile` / `apt list`   | `run_onchange_*.sh.tmpl` that includes the list  |
| Edit a third-party file (e.g., append to system file)        | `modify_` prefix on the target file  |
| Run on every apply unconditionally                           | `run_*` (rare; usually a smell)      |
