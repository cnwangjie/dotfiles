# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

The dotfiles + machine-setup repo for `cnwangjie`, driven by **mise bootstrap**
(https://mise.jdx.dev/bootstrap.html). It was migrated off chezmoi — there is no
build system, tests, or linter; every file is either a config symlinked into
`$HOME` or an input to `mise bootstrap`. The repo can live anywhere; it's reached
through the stable `~/.dotfiles` symlink, so the checkout location is pinned in
exactly one line (the self-managing `~/.dotfiles` entry in `[dotfiles]`).

**The repo mirrors `$HOME` 1:1** — every dotfile sits at the repo root under the
same path it has under `$HOME` (`.zshrc`, `.config/…`, `.claude/…`). Only
`README.md`, `CLAUDE.md`, `tasks/`, `.git/`, and the untracked
`.claude/settings.local.json` (this repo's own Claude project config) are
repo-meta rather than dotfiles.

A stable **`~/.dotfiles`** symlink points at this repo (wherever it's checked out),
and every `[dotfiles]`/task source path resolves through `~/.dotfiles`. The symlink
is created manually during bootstrap (mise can't read this config until the link
exists), but `[dotfiles]` also **self-manages** it via a first entry whose source is
the repo's real absolute path — so `mise dotfiles apply` keeps it correct and
`status` reports it. That one entry is the only hardcoded path; to move the repo,
update it (and re-`apply`) or just repoint the symlink. New-machine bootstrap is in
[README.md](README.md).

The mise config is **split** across `.config/mise/config.toml` (the critical core)
and `.config/mise/conf.d/*.toml` (the bulk), all of which mise merges into one
logical global config (it auto-loads `~/.config/mise/conf.d/*.toml`). It's
self-managing — `config.toml` symlinks itself **and** the whole `conf.d/`
directory (one `[dotfiles]` entry, since that dir is wholly ours) into
`~/.config/mise/`, so the conf.d symlink must be applied before mise can read
`[tools]`/`[bootstrap.packages]`/`[tasks]`.

| File                   | Section(s)             | Purpose                                                  |
|------------------------|------------------------|----------------------------------------------------------|
| `config.toml`          | `[settings]`           | `experimental = true`, `dotfiles.root = ~/.dotfiles`     |
| `config.toml`          | `[dotfiles]`           | symlink each repo file → its `$HOME` location (incl. conf.d) |
| `config.toml`          | `[tools]`              | language runtimes (java/python/node/go/…) — the dev baseline |
| `conf.d/tools.toml`    | `[tools]`              | bulky backend tools (`cargo:`/`go:`/`pipx:`); merges with the above |
| `conf.d/packages.toml` | `[bootstrap.packages]`, `[bootstrap.user]` | Homebrew formulae/casks + `login_shell` |
| `conf.d/macos.toml`    | `[bootstrap.macos.defaults]` | macOS user defaults, dumped from the live system |
| `conf.d/tasks.toml`    | `[tasks.bootstrap]`    | renders MCP servers from gopass, merges into `~/.claude.json` |

### Dotfiles (symlinks, not copies)

`~/.dotfiles` symlinks to the repo checkout (bootstrapped by hand, then kept in
sync by the self-managing `~/.dotfiles` entry whose source is the repo's absolute
path — relative would resolve against `dotfiles.root` and loop on itself). Every
other `[dotfiles]` entry symlinks `~/<path>` → `~/.dotfiles/<path>` (same relative
path on both sides). Mapped: `.config/mise/config.toml`, `.zshrc`, `.p10k.zsh`,
`.hammerspoon/init.lua`, and `.config/{ghostty,helix,herdr,zellij,zed}/…`.

The `.claude/*` files (`settings.json`, `hooks/`, `skills/`) are **tracked in git
but intentionally NOT mise-synced** — manage/symlink them by hand. The exception is
`.claude/mcp-servers.json`, a **secret-free skeleton** (not a symlink) that the
`bootstrap` task fills with the Gemini key from gopass at apply time (see below).
`~/.claude` runtime state (cache, projects, sessions, …) is never touched.

## The mental model

```
REPO (anywhere)  ←─ ~/.dotfiles symlink ─  mirrors $HOME 1:1
   │   .config/mise/config.toml  [dotfiles]
   ↓   mise dotfiles apply  →  creates symlinks (sourced via ~/.dotfiles/…)
$HOME  (~/.zshrc etc. are symlinks back into the repo — editing either edits both)
```

Because dotfiles are **symlinks**, editing `.zshrc` here *is* editing `~/.zshrc`;
there is no separate "apply" needed for content changes. `mise bootstrap` is only
needed to (re)create missing symlinks, install packages/tools, or re-run the task.

## Commands

```bash
mise bootstrap --dry-run        # preview everything bootstrap would do
mise bootstrap --yes            # converge: packages → dotfiles → user → tools → task
mise bootstrap                  # same, with confirmation prompts

mise dotfiles status            # which symlinks are missing/out of date
mise dotfiles apply             # (re)create just the symlinks
mise dotfiles add ~/.foo        # ingest a new dotfile into dotfiles.root + [dotfiles]
mise bootstrap packages status  # which brew packages are missing
mise bootstrap packages use brew:foo   # add a package and install it
mise install                    # install missing [tools]
mise run bootstrap              # re-run just the MCP-merge task
mise doctor                     # diagnose mise problems
```

On another machine: `git pull` here, then `mise bootstrap --yes`.

## When editing here

- Dotfile **content**: edit the file at its mirrored repo path (e.g. `.zshrc`,
  `.claude/settings.json`) directly — it's symlinked, so the change is already
  live. No apply step.
- **Adding/removing a managed file**: add a `[dotfiles]` entry in
  `.config/mise/config.toml`, then `mise dotfiles apply`.
- **Packages/tools**: edit `conf.d/packages.toml` / `conf.d/tools.toml`, then
  `mise bootstrap --yes` (or `mise install` for tools only).
- **`[settings]`/`[dotfiles]`**: edit `config.toml` (the core); the conf.d files
  only hold `[tools]`/`[bootstrap.*]`/`[tasks]`.
- `~/.config/mise/config.toml` and the `~/.config/mise/conf.d` dir are symlinks to
  the repo copies — edit the repo copy, never break the symlinks.

## Secrets

No secrets live in this repo. The only secret — the Gemini API key for the
`mcp-image` MCP server — is pulled from **gopass** (`mcp/gemini-api-key`) by
`tasks/merge-claude-mcp.sh` (the `[tasks.bootstrap]` task), which renders
`~/.claude/mcp-servers.json` and merges `.mcpServers` into `~/.claude.json`.
The committed `.claude/mcp-servers.json` has empty placeholder values.

## Caveats (mise bootstrap is experimental, needs mise >= 2026.6.6)

- mise's `brew:` manager pours bottles into `/opt/homebrew` **without** Homebrew
  and coexists with a real brew. It does **not** support `brew services`, so the
  old `restart_service` on `cloudflared`/`smartdns` is dropped — start those
  manually. `brew-cask:` only supports app-bundle casks (dmg/zip/tar); a
  pkg-only cask will fail with a clear error.
- bun-global **CLI tools** are now managed via mise's `npm:` backend in
  `conf.d/tools.toml` (e.g. `npm:wrangler`, `npm:@openai/codex`). Plain libraries
  that ship no binary (aws-sdk, googleapis, etc.) aren't mise tools — install
  per-project. vscode extensions are still **not** managed here (no backend).
- The `chezmoi-daily` skill under `.claude/skills/` documents the old chezmoi
  workflow and is now historical.

## Commit style

Use semantic / Conventional Commit subjects (`feat:`, `fix:`, `chore:`, `docs:`,
`refactor:`, …). Do **not** use dated `YYYY.M.D backup` subjects. Don't push
without being asked.
