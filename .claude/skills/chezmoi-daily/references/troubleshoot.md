# Troubleshooting

Read this when something is wrong and you need a diagnosis path. Always start with the universal triage:

```bash
chezmoi doctor          # 80% of setup issues caught here
chezmoi data            # are template variables what you think they are?
chezmoi diff            # what does chezmoi want to change?
chezmoi -n -v apply     # dry run with verbose output
```

If the issue isn't obvious from these, find the symptom below.

## Symptom: `chezmoi diff` shows nothing but the file looks wrong

The file is in sync per chezmoi's view, but the user disagrees with the content. Likely causes:

1. **Wrong source file.** They edited `dot_zshrc` but the active managed file is `dot_zshrc.tmpl`, or vice versa. Run `chezmoi managed | grep zshrc` to see what chezmoi is actually applying.
2. **Template renders to current content by coincidence** on this machine but produces wrong output on another. Test with `chezmoi execute-template < dot_zshrc.tmpl`.
3. **Shell caches.** `.zshrc` was applied but the running shell still has the old env. `exec zsh` to reload.

## Symptom: `chezmoi apply` succeeds but file unchanged

1. `chezmoi -v apply` — verbose mode logs each file action. If the file isn't listed, chezmoi doesn't see a diff.
2. Check `chezmoi managed $FILE`. If it returns nothing, the file isn't actually managed (typo in path, or file was never added).
3. If managed but not changing: source content is byte-identical to destination. `chezmoi cd` and verify the source file you think you edited got saved.

## Symptom: `chezmoi update` pulls but doesn't apply

`chezmoi update` = `git pull --autostash --rebase` then `chezmoi apply`. If apply runs but no files change, the changes you pulled might be:
- only to scripts (`run_*`) — those execute but don't write files visibly. Look at the verbose log.
- only to `chezmoi.toml.tmpl` or `.chezmoiignore` — these affect config, not files.
- guarded by a template condition that's false on this machine.

To confirm what was pulled: `chezmoi git log -- -n5` then `chezmoi git show HEAD`.

## Symptom: `run_once_` script ran twice

By definition `run_once_` is keyed on content hash. It re-ran because:
1. **Content changed.** Including any whitespace/comment edit. Including a templated script whose rendered output changed because data changed.
2. **State DB was reset.** New machine, deleted state, or a different `--config` was used.

To inspect: `chezmoi state dump | jq '.scriptState'`. Each entry has the hash and run timestamp.

## Symptom: encrypted file shows binary diff or "decryption failed"

1. `chezmoi doctor` — does it report age/gpg working?
2. Identity file exists and readable? `ls -la ~/.config/chezmoi/key.txt`.
3. Recipient in `chezmoi.toml` matches the identity? Compare against `age-keygen -y ~/.config/chezmoi/key.txt`.
4. Was the file encrypted to a different recipient? Check git log for changes to `recipient` / `recipients`. If the user rotated keys, every encrypted file needs `chezmoi re-add`.

## Symptom: `dot_bashrc` literally appeared in `$HOME`

Either:
1. The file was added to the source tree without going through `chezmoi add` (e.g., dragged into `~/.local/share/chezmoi/`). It wasn't created by an `apply`. Move it out and re-add properly.
2. A `literal_` prefix is in play upstream of `dot_`, or a `.literal` suffix is on a parent dir. Read `references/filename-attributes.md` § stacking.

## Symptom: "permission denied" on apply

Usually:
- A `private_` source file targets a destination that the user can't chmod (e.g., inside a directory not owned by them).
- chezmoi is trying to write to `/etc` or another root-owned path. chezmoi runs as the invoking user — it doesn't sudo. If you genuinely need root-owned dotfiles, use a `run_*` script that calls `sudo` explicitly, or run a separate `chezmoi apply` as root with a different source (rare and usually a sign the design is off).

## Symptom: template renders empty / wrong

Reproduce with `execute-template`. If output is empty:
1. The conditional evaluated false. Print the variable: `chezmoi execute-template '{{ .work }} / {{ .chezmoi.os }}'`.
2. The variable is undefined — `{{ .work }}` for a missing key returns `<no value>` and may make a conditional false. `chezmoi data | jq '.work'` to confirm.
3. Whitespace stripping with `{{- -}}` collapsed everything. Remove the dashes temporarily and rerender.

## Symptom: merge conflict between source and destination

User edited both. Don't try to manually reconcile.

```bash
chezmoi merge ~/.bashrc
```

Opens a 3-way merge with:
- left: source (what's in the repo)
- middle: target (what chezmoi would apply)
- right: destination (what's currently in $HOME)

Save and exit; chezmoi writes the result back to source. Then `chezmoi apply` to push to destination.

If the user wants destination to win wholesale: `chezmoi re-add ~/.bashrc`.
If source should win wholesale: `chezmoi apply --force ~/.bashrc`.

## Symptom: "I want to undo my last apply"

There is no `chezmoi undo`. Recovery options:
1. If the source repo is committed: `chezmoi git -- reset --hard HEAD~1 && chezmoi apply` rolls source back, which on next apply restores the previous content.
2. If you only want to revert one file: `chezmoi git -- checkout HEAD~1 -- <source-path> && chezmoi apply`.
3. Pre-`apply` safety net: always `chezmoi diff` first. For risky changes, `chezmoi -n -v apply`.

## Symptom: `chezmoi init` clones an old version

`chezmoi init <url>` clones the default branch. If the repo's default isn't what you want:

```bash
chezmoi init <url> --branch main
```

For a fork or specific commit, init normally then `chezmoi git -- checkout <ref>`.

## When all else fails

```bash
chezmoi --debug apply 2>&1 | less
```

`--debug` prints every internal decision: which files it considered, which templates it rendered, which scripts it skipped. It's verbose but it tells the truth.

For bug reports / asking for help: `chezmoi doctor` output is the first thing the chezmoi maintainers ask for. Lead with it.
