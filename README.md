# dotfiles

Personal dotfiles + machine setup for `cnwangjie`, driven by
[**mise bootstrap**](https://mise.jdx.dev/bootstrap.html) (migrated off chezmoi).

The repo **mirrors `$HOME` 1:1**: every dotfile lives at the repo root under the
same path it has under `$HOME` (`.zshrc`, `.config/…`, `.claude/…`). The source of
truth is the mise config under `.config/mise/`: the critical core —
[`config.toml`](.config/mise/config.toml) (`[settings]` + the dotfile symlink map)
— plus [`conf.d/*.toml`](.config/mise/conf.d) that mise merges automatically
(`tools.toml`, `packages.toml`, `tasks.toml`). See [CLAUDE.md](CLAUDE.md) for the
working model and caveats.

The repo can live **anywhere** — pick a location and export it as `$DOTFILES`
(used throughout this guide). It is exposed through a stable **`~/.dotfiles`**
symlink, and every config path resolves through `~/.dotfiles`. The checkout
location is pinned in exactly one place — the self-managing `~/.dotfiles` entry in
`[dotfiles]` — so moving the repo means repointing the symlink and updating that
one line.

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

To **move** the repo later: `mv "$DOTFILES" "$NEW" && ln -sfn "$NEW" ~/.dotfiles`,
then point the self-managing `"~/.dotfiles"` entry in
[`.config/mise/config.toml`](.config/mise/config.toml) at `$NEW` and re-run
`mise dotfiles apply`. That entry is the only hardcoded path in the repo (its
source must be absolute — a relative one would resolve against `dotfiles.root` and
loop the link onto itself).

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
mise dotfiles apply        # seed → symlink config.toml into the repo (via ~/.dotfiles)
mise trust "$DOTFILES"     # the live config now resolves into the repo — trust
                           # it too, or [settings]/[dotfiles] are silently ignored
mise dotfiles apply        # run AGAIN: the full config.toml is active now, so this
                           # symlinks the conf.d/ dir (+ remaining dotfiles). Needed
                           # before bootstrap, which loads config once at start and
                           # runs packages before its own dotfiles phase — so
                           # [tools]/[bootstrap.packages]/[tasks] must already be linked.
mise bootstrap --dry-run   # review: packages, tools, remaining dotfiles, login shell, task
mise bootstrap --yes       # converge everything
```

After step 4, `~/.config/mise/config.toml` and the `conf.d/` dir are symlinks into the
repo, so the full config (all packages/tools/dotfiles) is live and the seed lines are
no longer needed.

## Day-to-day

```sh
# dotfile CONTENT changes: just edit the file (it's a symlink — change is live)
$EDITOR ~/.zshrc

# add a new managed dotfile: add a [dotfiles] entry, then
mise dotfiles apply

# add a package / tool: edit conf.d/packages.toml / conf.d/tools.toml, then
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
- bun-global CLI tools are managed via mise's `npm:` backend (`conf.d/tools.toml`);
  vscode extensions are not managed here.
