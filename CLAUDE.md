# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

The chezmoi **source state** for `cnwangjie/dotfiles`. There is no build system, no tests, no linter — every file is a config that gets rendered into `$HOME` by `chezmoi apply`. The repo lives at the canonical chezmoi source location (`~/.local/share/chezmoi`), so editing files here directly is fine.

Currently tracked (all plain files — no templates, no encrypted files, no `run_*` scripts, no `.chezmoiignore`):

| Source path                       | Renders to                          |
|-----------------------------------|-------------------------------------|
| `dot_zshrc`                       | `~/.zshrc`                          |
| `dot_p10k.zsh`                    | `~/.p10k.zsh`                       |
| `dot_hammerspoon/init.lua`        | `~/.hammerspoon/init.lua`           |
| `dot_config/ghostty/config`       | `~/.config/ghostty/config`          |
| `dot_config/helix/config.toml`    | `~/.config/helix/config.toml`       |
| `dot_config/zellij/config.kdl`    | `~/.config/zellij/config.kdl`       |

## The mental model that prevents most mistakes

```
SOURCE (here, ~/.local/share/chezmoi)
   ↓  chezmoi apply
TARGET (computed in memory)
   ↓  written to disk if different
DESTINATION (~ on this machine)
```

When something "didn't update", figure out which transition is missing — usually the user edited destination (`~/.zshrc`) when they should have edited source, or edited source but forgot to `apply`.

## Commands

```bash
chezmoi diff                # what apply would change — run before apply on a fresh machine
chezmoi apply -v            # render source → write to $HOME (-v is required to see anything)
chezmoi -n -v apply         # dry-run

chezmoi edit ~/.zshrc       # opens the source file (dot_zshrc), not the destination
chezmoi re-add ~/.zshrc     # destination drifted ahead → push it back into source
chezmoi merge ~/.zshrc      # 3-way merge if both sides changed

chezmoi add ~/.foo          # ingest a new dotfile (use --encrypt for secrets, --template for per-machine)
chezmoi managed             # list everything chezmoi controls
chezmoi cd                  # cd into source dir (this dir)

chezmoi update -v           # = git pull --rebase --autostash + apply (use on other machines)
chezmoi doctor              # run first when anything looks broken
```

## When editing here

- Files in this repo are the **source state**, not the destination. Editing `dot_zshrc` does nothing until `chezmoi apply` runs.
- After any change, run `chezmoi diff` to confirm what will be written, then `chezmoi apply -v`.
- The `dot_` prefix on filenames maps to `.` in the destination — don't rename `dot_zshrc` to `.zshrc`.
- Filename attribute order is fixed: `[encrypted_][private_][readonly_][empty_][executable_][dot_]<name>[.tmpl]`. Don't reorder.

## Before bulk-adding new directories

Especially anywhere under `~/.config`, `~/.claude`, `~/.cache`, or `~/Library`: write `.chezmoiignore` at the source root **first** to exclude caches/state/secrets. `.chezmoiignore` patterns are target-path-shaped (e.g. `.claude/cache`, not `dot_claude/cache_`) and apply to both `add` and `apply`. Once committed, scrubbing means rewriting git history.

## Commit style

Use semantic / Conventional Commit subjects (`feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, …). Do **not** use dated `YYYY.M.D backup` subjects — older history has them, but new commits should be semantic even when the change is just a backup of drift. Don't push without being asked.
