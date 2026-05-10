---
name: chezmoi-daily
description: Use this skill whenever the user works with chezmoi for dotfiles management — adding/editing/applying files, syncing across machines, writing .tmpl templates, run_ scripts, encrypted files, or troubleshooting apply/diff issues. Trigger this even when the user does not say "chezmoi" by name but is clearly working in `~/.local/share/chezmoi`, editing files prefixed with `dot_`/`private_`/`encrypted_`, asking how to "add my .bashrc to dotfiles", or asking "why didn't my dotfile change show up after pulling".
---

# chezmoi daily operations

Your job is to keep three states consistent and to make the user reach for the right command without thinking.

## The three states (anchor every answer here)

```
SOURCE STATE        →   TARGET STATE        →   DESTINATION STATE
~/.local/share/         (computed in-memory     ~  (the actual files
chezmoi/                from source +              on disk in $HOME)
                        templates + data)
```

- `chezmoi add $FILE`         copies `$HOME/$FILE` → source, encoding metadata in the filename.
- `chezmoi apply`             renders source → target → writes target onto destination if they differ.
- `chezmoi diff`              shows destination ↔ target. **Always run before apply on an unfamiliar machine.**
- `chezmoi re-add`            destination has drifted ahead of source — push destination back into source.
- `chezmoi edit $FILE`        opens the source file that produces `$FILE`. Use this, not raw `$EDITOR ~/.local/share/...`, because it handles decryption and `.tmpl` paths transparently.

When a user asks "why didn't X update", their mental model collapsed two of these states. Ask which file they edited and where, then narrate which transition is missing.

## Decision tree: adding a file

```
Is the file sensitive (keys, tokens)?
├─ yes → chezmoi add --encrypt $FILE         (configure age/gpg first; see references/encryption.md)
└─ no  → does its content vary per machine (hostname, OS, work vs personal)?
         ├─ yes → chezmoi add --template $FILE   (creates a .tmpl, edit it; see references/templating.md)
         └─ no  → chezmoi add $FILE
```

After any add: run `chezmoi diff`. It must be empty. If it isn't, the filename attributes (perms, dot_, etc.) didn't round-trip — see references/filename-attributes.md.

## Decision tree: syncing across machines

```
On the new machine, first time?
├─ yes → chezmoi init <repo-url>          (clones into source dir, does NOT apply)
│        chezmoi diff                      (read every line; dotfiles can break a shell login)
│        chezmoi apply -v
│
└─ no, routine pull?
         chezmoi update -v                 (= git pull --autostash --rebase + apply)
         # If you want a preview step:
         chezmoi git pull -- --autostash --rebase
         chezmoi diff
         chezmoi apply -v
```

`-v` is not optional advice — without it, apply is silent on success and you can't tell whether anything ran.

For dry runs: `chezmoi -n -v apply`. Use this when the diff hints at a destructive change (file removal, perm change on something privileged).

## Decision tree: "I changed something, now what?"

```
Where did you edit?
├─ source dir (`chezmoi cd` then $EDITOR, or `chezmoi edit $FILE`)
│   → chezmoi diff && chezmoi apply
│
├─ destination (~/.bashrc directly)
│   → chezmoi re-add                       (re-adds ALL drifted managed files)
│   → or:  chezmoi re-add ~/.bashrc        (just one)
│   → then commit in source repo
│
└─ both, conflicting
    → chezmoi merge $FILE                  (3-way merge: source / target / destination)
```

`chezmoi edit --apply` and `chezmoi edit --watch` exist for tight inner loops — use `--watch` when iterating on a template you keep getting wrong.

## Templates: the only debugging command that matters

Never iterate a template by `apply → check → edit → apply`. Use `execute-template`:

```bash
chezmoi execute-template '{{ .chezmoi.os }}-{{ .chezmoi.hostname }}'
chezmoi execute-template < dot_zshrc.tmpl
chezmoi data                              # full variable dump as JSON
```

When a user shows you a `.tmpl` that "produces wrong output", your first move is to reproduce it via `execute-template` with their data, not to read the template and guess.

See `references/templating.md` for variables, conditionals, per-machine `[data]` sections, and the `.chezmoitemplates` shared-partial directory.

## Scripts (run_*)

These execute during `chezmoi apply`. Filename prefix decides cadence and ordering:

| Prefix              | Runs when                                  |
|---------------------|--------------------------------------------|
| `run_`              | every `apply`                               |
| `run_once_`         | once per unique content hash (lifetime)    |
| `run_onchange_`     | when the rendered content changes          |
| `..._before_...`    | before file updates in this apply pass     |
| `..._after_...`     | after file updates in this apply pass      |

Combinable: `run_once_before_install-brew.sh.tmpl` runs once, before files, gets templated.

State for `_once_`/`_onchange_` lives in chezmoi's persistent state DB — NOT in the source repo, NOT in git. If a user says "my run_once script ran twice", they almost certainly edited it (which changed the hash). Details and gotchas in `references/scripts.md`.

## Filename attributes — the most frequent source of confusion

A managed file's name encodes target path and properties. Order matters and is fixed:

```
[encrypted_][private_][readonly_][empty_][executable_][dot_]<name>[.tmpl]
```

Examples:
- `dot_bashrc`                              → `~/.bashrc`
- `private_dot_ssh/private_config`          → `~/.ssh/config` with 0600
- `encrypted_private_dot_ssh/private_id_ed25519` → encrypted SSH key
- `executable_dot_local/bin/executable_my-script.tmpl` → templated, +x

Other useful ones: `symlink_`, `modify_`, `create_`, `remove_`, `literal_` (escape hatch — stop parsing), and the `.literal` suffix. Full table and stacking rules in `references/filename-attributes.md`.

When a user says "I added it but the perms are wrong" or "it created a file called `dot_bashrc` in my home dir", check ordering and `literal_` first.

## `.chezmoiignore` — what NOT to manage

A file at the source root named `.chezmoiignore` lists patterns of **target** paths (home-relative) that chezmoi should pretend don't exist. It affects both `apply` (won't write) and `add` (won't ingest). Patterns use gitignore-like globs.

```
# ~/.local/share/chezmoi/.chezmoiignore
.cache
.local/state
.claude/cache
.claude/sessions
.claude/history.jsonl
.DS_Store
```

Three reasons this matters more than it looks:

1. **It runs before `add`.** If a user does `chezmoi add ~/.claude` and `~/.claude/cache` is in `.chezmoiignore`, `cache` is silently skipped. This is the right default — write `.chezmoiignore` *first*, then bulk-add fearlessly.
2. **Without it, `chezmoi add <dir>` ingests everything**, including caches, machine-state, secrets the user forgot about. Once it's in the source repo and committed, scrubbing means rewriting git history.
3. **Patterns themselves can be templated.** Append `.tmpl` to the file (`.chezmoiignore.tmpl`) and it's rendered with template data — useful for "ignore this file on darwin only".

The pattern is target-path-shaped, not source-filename-shaped: write `.claude/cache`, not `dot_claude/cache_`. Subdirectories work; trailing `/` isn't required for directory matches.

When a user is about to `chezmoi add` a directory whose siblings include cache/state/secret content (any subdir of `~/.config`, `~/.claude`, `~/.cache`, `~/Library`...), the answer always starts with "first check / write `.chezmoiignore`".

## Troubleshooting flow

Always start here, in this order:

```
1. chezmoi doctor          # config, encryption, git, editor — catches 80% of setup issues
2. chezmoi data             # is the variable you're using actually defined?
3. chezmoi managed | grep   # is the file actually under chezmoi at all? (or `unmanaged` for the inverse)
4. chezmoi diff             # what does chezmoi *think* needs to change?
5. chezmoi -n -v apply      # dry-run the change
6. chezmoi apply -v         # do it for real
```

For deeper symptoms, see `references/troubleshoot.md` (apply silently does nothing, template renders empty, encrypted file shows as binary diff, run_once re-runs every apply, etc.).

## What this skill does NOT do

- Don't recommend chezmoi-specific shell aliases or third-party wrappers; the CLI is the contract.
- Don't suggest committing the persistent state DB or the chezmoi config file (`chezmoi.toml`) into the dotfiles repo — both are machine-local by design.
- Don't `git pull` directly inside the source dir; use `chezmoi update` or `chezmoi git pull -- --autostash --rebase` so chezmoi knows.
- Don't run `chezmoi apply` first thing on a new machine — `chezmoi diff` first.

## Migrating in (the user's current state)

The user is moving existing dotfiles into chezmoi. The right order is:

1. `chezmoi init`                                (no remote yet — local source repo)
2. **Before any bulk `add`, write `.chezmoiignore`.** Walk the parent directory you're about to ingest. If it contains caches, state files, history, or secrets you don't want versioned, list them now. Cheap to do, painful to undo. (See the `.chezmoiignore` section above.)
3. For each file/dir: `chezmoi add ~/.foo`. Don't bulk-add a whole directory blindly; review prefixes after each add via `chezmoi cd && ls`.
4. After every add, `chezmoi diff` must be empty. If not, the prefix encoding lost something — fix the source filename, not the destination.
5. Use `chezmoi managed` to audit what's been ingested so far. `chezmoi unmanaged ~/.config` to spot what's still hand-managed.
6. Anything per-machine: re-add with `--template`, then edit the `.tmpl` to use `{{ if eq .chezmoi.hostname "..." }}`.
7. Anything secret: `chezmoi forget` then `chezmoi add --encrypt`. Make sure age/gpg config is in `chezmoi.toml` first.
8. Once stable, `chezmoi cd && git add -A && git commit && git push` (or use `autoCommit`/`autoPush`), and switch other machines via `chezmoi init <url>`.

Don't try to migrate everything in one session. Migrate one tool's config at a time (zsh, then git, then ssh, then editor) and verify with `diff` between each.
