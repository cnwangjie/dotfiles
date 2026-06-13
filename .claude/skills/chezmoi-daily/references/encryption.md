# Encrypting files

Read this when:
- A user wants to commit secrets (SSH keys, API tokens, GPG keys) into the dotfiles repo.
- An `encrypted_` file shows up as a binary diff or fails to decrypt.
- The user is choosing between age and gpg.

## Backends

chezmoi supports four: **age**, **gpg**, **git-crypt**, **transcrypt**. Default recommendation:

- **age** — modern, simple, single recipient or multiple. No keyserver, no web of trust. The right choice for solo dotfiles.
- **gpg** — pick this only if you already have a working gpg setup or need to share with others using gpg.
- **git-crypt / transcrypt** — operate at the git layer rather than chezmoi's; only relevant when the team already standardized on them.

This guide covers age. For gpg, the commands are the same; configuration differs.

## One-time setup (age)

```bash
# 1. Generate a key
age-keygen -o ~/.config/chezmoi/key.txt
# Public key prints to stderr — copy it.

# 2. Tell chezmoi to use age
chezmoi edit-config         # opens chezmoi.toml
```

In `chezmoi.toml`:

```toml
encryption = "age"

[age]
    identity = "~/.config/chezmoi/key.txt"
    recipient = "age1abc...xyz"           # the public key from step 1
```

`key.txt` is the private key. **Never commit it.** It belongs only on machines that should be able to decrypt. Back it up out-of-band (1Password, USB, etc.) — losing it means losing access to every encrypted file in the repo.

For multiple machines, the simplest model: same age key on every machine. For multiple users sharing a repo: use `recipients = [...]` (plural) listing each user's public key.

## Adding an encrypted file

```bash
chezmoi add --encrypt ~/.ssh/id_ed25519
```

This:
1. Reads the file from `$HOME`.
2. Encrypts it with the configured recipient.
3. Writes it to the source dir as `encrypted_private_dot_ssh/encrypted_private_id_ed25519` (with `.age` suffix internally).
4. The plaintext stays in `$HOME`. Re-running `chezmoi diff` shows nothing because chezmoi decrypts on the fly to compare.

## Editing an encrypted file

```bash
chezmoi edit ~/.ssh/id_ed25519
```

chezmoi decrypts to a temp file, opens your editor, re-encrypts on save. Don't `chezmoi cd` and edit the ciphertext directly — that won't work.

## Encrypted templates

Yes, they compose: `encrypted_dot_secrets.tmpl`. chezmoi decrypts first, then renders. Useful when a config file embeds secrets but also needs branching:

```gotmpl
[github]
{{- if .work }}
    token = {{ .work_github_token }}
{{- else }}
    token = {{ .personal_github_token }}
{{- end }}
```

with the secrets coming from `[data]` in `chezmoi.toml` (which is machine-local and not committed).

## What encryption does NOT protect

- **The fact that a file exists.** Filenames are visible in the repo.
- **File size.** Roughly proportional to plaintext size.
- **The destination file at rest.** Once applied, `~/.ssh/id_ed25519` is plaintext on disk. Encryption is for the source repo only.

## Pitfalls

- **`encrypted_` prefix without backend configured** → `apply` fails with "no encryption configured". Set `encryption = "age"` first.
- **Forgot to add the public key as recipient on a new machine** → `apply` will fail to decrypt. The fix is to re-encrypt with both old and new recipients (run `chezmoi re-add` after editing recipients).
- **Committed `key.txt` by accident.** Treat it like a leaked private key: rotate, re-encrypt all files with new recipient. `git filter-repo` to scrub history if the repo is public.
- **`.gitignore` for the key.** chezmoi's source dir has its own `.gitignore`. Make sure `key.txt` (or wherever the identity lives) is excluded if it's anywhere under the source tree. The default location `~/.config/chezmoi/key.txt` is outside the source dir, which is the right setup.
- **Diff shows binary noise.** Means decryption failed. Check `encryption =` is set, the identity file exists and is readable, and the recipient matches.

## Quick check after setup

```bash
chezmoi doctor
```

Should report `ok` for `age-command` (or `gpg-command`). If not, you'll see the exact issue.
