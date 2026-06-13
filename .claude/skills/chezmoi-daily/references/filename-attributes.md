# Filename attributes

chezmoi encodes target path, perms, encryption, and rendering mode into the source filename. Read this when:
- A user is confused about why a file landed in the wrong place or with wrong perms.
- An add operation produced an unexpected source filename.
- The rendered destination filename literally contains `dot_` or `private_`.

## Prefix order (left to right, fixed)

For regular files:

```
[encrypted_][private_][readonly_][empty_][executable_][dot_]<name>[.tmpl]
```

For directories: `[private_][readonly_][dot_]<name>` (no `executable_`, `empty_`, `encrypted_`).

For special types, the type prefix replaces the regular slot: `symlink_`, `modify_`, `create_`, `remove_`. Don't combine these with each other.

## Reference table

| Prefix        | Effect                                                                 |
|---------------|------------------------------------------------------------------------|
| `dot_`        | Rename to leading dot. `dot_bashrc` → `.bashrc`.                       |
| `literal_`    | Stop parsing prefixes. `literal_dot_file` → `dot_file` literally.      |
| `empty_`      | Ensure file exists, even if rendered content is empty.                  |
| `executable_` | Set +x on target.                                                       |
| `private_`    | Strip group/world perms (→ 0600 / 0700).                                |
| `readonly_`   | Strip write perms.                                                      |
| `symlink_`    | Source contents = link target path. Creates a symlink, not a file.      |
| `modify_`     | Treat source as a script that reads existing target on stdin and writes new content on stdout. Use for files chezmoi must edit in-place rather than overwrite. |
| `create_`     | Only create if target doesn't exist; never overwrite.                   |
| `remove_`     | Delete the corresponding target on apply.                               |
| `encrypted_`  | Source is ciphertext; decrypt before rendering/applying.                |

| Suffix        | Effect                                                                 |
|---------------|------------------------------------------------------------------------|
| `.tmpl`       | Render as Go text/template before writing to target.                    |
| `.literal`    | Stop parsing suffixes. `script.tmpl.literal` → target keeps `.tmpl`.    |

## Stacking — worked examples

| Source filename                                | Target              | Properties                      |
|-----------------------------------------------|---------------------|---------------------------------|
| `dot_bashrc`                                   | `~/.bashrc`         | regular file                    |
| `dot_bashrc.tmpl`                              | `~/.bashrc`         | rendered from template          |
| `executable_dot_local/bin/executable_dotfiles-sync` | `~/.local/bin/dotfiles-sync` | +x, dir + file both prefixed   |
| `private_dot_ssh/private_config`               | `~/.ssh/config`     | dir 0700, file 0600             |
| `encrypted_private_dot_ssh/encrypted_private_id_ed25519` | `~/.ssh/id_ed25519` | encrypted, 0600          |
| `readonly_dot_npmrc.tmpl`                      | `~/.npmrc`          | rendered, no write perms        |
| `create_dot_zshrc.local`                       | `~/.zshrc.local`    | created once, never re-applied  |
| `remove_dot_pythonrc`                          | `~/.pythonrc`       | deleted on apply                |
| `symlink_dot_vimrc`                            | `~/.vimrc`          | symlink; source contents = path |
| `literal_dot_underscore`                       | `dot_underscore`    | escape hatch                    |

## When chezmoi picks the wrong prefix on `add`

`chezmoi add` infers prefixes from current file mode. So:
- A file with mode 0600 → `private_`.
- A file with +x → `executable_`.
- A `.` filename → `dot_`.

If you add a 0644 file then later `chmod 0600` the destination, `chezmoi diff` will flag it but won't auto-rename the source. Either:
1. `chezmoi forget` then re-add, or
2. `chezmoi cd` and rename the source file to add `private_` manually.

## Common pitfalls

- **Whole directory has wrong perms.** Directory prefixes apply independently. `dot_ssh/private_config` gives the file 0600 but leaves `~/.ssh` as 0755 — should be `private_dot_ssh/private_config`.
- **Templated filename.** Use `dot_config/git/config.tmpl` not `dot_config_git_config.tmpl` — slashes are preserved as path separators.
- **`literal_` is always last-resort.** If a real dotfile is named, e.g., `.dot_something`, you need `literal_dot_dot_something` — first `dot_` is the leading dot, second `dot_` becomes the literal `dot_`. Read it twice before committing.
