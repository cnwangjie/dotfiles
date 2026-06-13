# dotfiles

Personal dotfiles + machine setup for `cnwangjie`, driven by
[**mise bootstrap**](https://mise.jdx.dev/bootstrap.html) (migrated off chezmoi).

The repo **mirrors `$HOME` 1:1**: every dotfile lives at the repo root under the
same path it has under `$HOME` (`.zshrc`, `.config/…`, `.claude/…`). The single
source of truth is [`.config/mise/config.toml`](.config/mise/config.toml), which
declares dotfile symlinks, tools, Homebrew packages, login shell, and a final
bootstrap task. See [CLAUDE.md](CLAUDE.md) for the working model and caveats.

The repo can live **anywhere** — pick a location and export it as `$DOTFILES`
(used throughout this guide). It is exposed through a stable **`~/.dotfiles`**
symlink, and every config path resolves through `~/.dotfiles`, so the repo can be
moved later just by repointing that one symlink.

## Bootstrap a fresh machine

### 1. Install mise (>= 2026.6.6 — bootstrap/dotfiles are that new)

```sh
curl https://mise.run | sh        # or: brew install mise / cargo binstall mise
```

### 2. Clone this repo and link `~/.dotfiles`

```sh
export DOTFILES="$HOME/.dotfiles-repo"   # anywhere you like
git clone <repo-url> "$DOTFILES"
ln -s "$DOTFILES" ~/.dotfiles            # the stable symlink everything resolves through
```

To **move** the repo later: `mv "$DOTFILES" "$NEW" && ln -sfn "$NEW" ~/.dotfiles`.
Nothing else changes — no path is hardcoded in the repo.

### 3. Seed the global mise config

`mise bootstrap` reads `~/.config/mise/config.toml`, but on a fresh machine that
file doesn't yet know about this repo. Add **just these lines** to it to bootstrap
the self-managing setup:

```toml
# ~/.config/mise/config.toml
[settings]
experimental = true
dotfiles.root = "~/.dotfiles"

[dotfiles]
"~/.config/mise/config.toml" = "~/.dotfiles/.config/mise/config.toml"  # pull in the full config
```

### 4. Apply the seed, then bootstrap

```sh
mise trust ~/.config/mise/config.toml
mise dotfiles apply        # replaces this file with a symlink to the repo's
                           # full .config/mise/config.toml (via ~/.dotfiles)
mise bootstrap --dry-run   # review: packages, tools, remaining dotfiles, login shell, task
mise bootstrap --yes       # converge everything
```

After step 4, `~/.config/mise/config.toml` is a symlink into the repo, so the full
config (all packages/tools/dotfiles) is live and the seed lines are no longer needed.

## Day-to-day

```sh
# dotfile CONTENT changes: just edit the file (it's a symlink — change is live)
$EDITOR ~/.zshrc

# add a new managed dotfile: add a [dotfiles] entry, then
mise dotfiles apply

# add a package / tool: edit [bootstrap.packages] / [tools], then
mise bootstrap --yes        # or `mise install` for tools only

# sync another machine
git -C ~/.dotfiles pull && mise bootstrap --yes
```

## Secrets

No secrets in the repo. The only one — the Gemini API key for the `mcp-image` MCP
server — is read from **gopass** (`mcp/gemini-api-key`) by the `[tasks.bootstrap]`
task ([`tasks/merge-claude-mcp.sh`](tasks/merge-claude-mcp.sh)), which renders
`~/.claude/mcp-servers.json` and merges `.mcpServers` into `~/.claude.json`.

## Caveats

- mise bootstrap is **experimental**; dry-run before applying.
- `brew:` pours bottles into `/opt/homebrew` without Homebrew (coexists with a real
  brew) but has no `brew services`, and `brew-cask:` only handles app-bundle casks.
- bun globals and vscode extensions are no longer managed here.
