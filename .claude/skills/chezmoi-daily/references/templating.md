# Templating

Read this when:
- Per-machine variation is needed (work vs personal, Linux vs macOS, hostname-specific).
- A user is iterating on a `.tmpl` and getting wrong output.
- A user is unsure whether to use a template or just two separate files.

## When to template, when not to

Template if **any one** of these is true:
- The file content depends on machine identity (hostname, OS, arch, work/personal flag).
- The file embeds a secret you want to pull from a password manager / env var at apply time.
- The file references paths that differ between machines (e.g., `$HOME` is fine raw, but `/opt/homebrew` vs `/usr/local` for Apple Silicon vs Intel benefits from a template).

Don't template if:
- The file is identical everywhere — adding `.tmpl` just adds rendering cost and a foot-gun.
- The variation is small enough to live in `.zshrc.local` or similar machine-local sidecar that chezmoi doesn't manage. Sometimes the right move is `create_dot_zshrc.local` (created once, never overwritten) and source it from `dot_zshrc`.

## Built-in variables (the ones you'll actually use)

| Path                          | Example value                  |
|-------------------------------|--------------------------------|
| `.chezmoi.os`                 | `darwin`, `linux`, `windows`   |
| `.chezmoi.arch`               | `amd64`, `arm64`               |
| `.chezmoi.hostname`           | machine short hostname         |
| `.chezmoi.fqdnHostname`       | fully qualified hostname       |
| `.chezmoi.username`           | OS username                    |
| `.chezmoi.homeDir`            | absolute path to home          |
| `.chezmoi.sourceDir`          | absolute path to source repo   |
| `.chezmoi.kernel.osrelease`   | linux kernel version, etc.     |
| `.chezmoi.osRelease.id`       | distro id (`ubuntu`, `fedora`) |
| `.chezmoi.osRelease.versionID`| distro version                 |

`chezmoi data` dumps everything (including custom `[data]`) as JSON. Pipe to `jq` to explore.

## Custom data — `[data]` in chezmoi.toml

```toml
# ~/.config/chezmoi/chezmoi.toml  (machine-local; NEVER commit)
[data]
    email = "wj@personal.example"
    work = false
    git_signing_key = "0xABC123..."
```

Then in any `.tmpl`:

```gotmpl
[user]
    name = Wang Jie
    email = {{ .email | quote }}
{{- if .work }}
    signingkey = {{ .git_signing_key | quote }}
{{- end }}
```

`chezmoi.toml` itself is *not* in the dotfiles repo. It's the machine's identity. To bootstrap it on new machines, use `init.tmpl` (see below).

## Conditionals — the patterns that cover 90% of needs

```gotmpl
{{- /* OS branch */ -}}
{{ if eq .chezmoi.os "darwin" }}
export HOMEBREW_PREFIX=/opt/homebrew
{{ else if eq .chezmoi.os "linux" }}
export HOMEBREW_PREFIX=/home/linuxbrew/.linuxbrew
{{ end }}

{{- /* Hostname branch */ -}}
{{ if eq .chezmoi.hostname "work-laptop" }}
export AWS_PROFILE=work
{{ end }}

{{- /* Distro-specific */ -}}
{{ if and (eq .chezmoi.os "linux") (eq .chezmoi.osRelease.id "ubuntu") }}
alias open=xdg-open
{{ end }}
```

`{{-` and `-}}` strip surrounding whitespace; without them you get blank lines wherever a conditional is false. For dotfiles this is usually harmless but for files like `~/.ssh/config` whitespace matters semantically — use the dashes by default.

## Debugging — never apply just to check

```bash
# Render a tiny expression with current data:
chezmoi execute-template '{{ .chezmoi.os }} / {{ .chezmoi.hostname }}'

# Render a whole file from the source repo:
chezmoi cd
chezmoi execute-template < dot_zshrc.tmpl

# Render with stub data (test "what would this produce on Linux?"):
chezmoi execute-template --init --promptString os=linux < dot_zshrc.tmpl
```

When a template "produces wrong output", the first move is to reproduce via `execute-template`. If output looks right but `apply` writes something different, the issue is filename attributes, not the template.

## init.tmpl — bootstrapping chezmoi.toml on a new machine

A file named `.chezmoi.toml.tmpl` at the source root is a special template: chezmoi runs it during `init` to generate the local `chezmoi.toml`. Use this to prompt for machine identity:

```gotmpl
{{- $work := promptBoolOnce . "work" "Is this a work machine" -}}
{{- $email := promptStringOnce . "email" "Git email" -}}

[data]
    work = {{ $work }}
    email = {{ $email | quote }}
```

`promptBoolOnce` / `promptStringOnce` ask only the first time, then persist the answer. This is how to keep one `init` flow that handles every machine without committing per-machine config.

## Shared partials — `.chezmoitemplates/`

Put reusable snippets in `.chezmoitemplates/aliases.tmpl`, then in any other template:

```gotmpl
{{ template "aliases.tmpl" . }}
```

Useful for shared shell aliases that you want in both `.zshrc.tmpl` and `.bashrc.tmpl`. The `.` passes current data into the partial.

## Common errors

| Error                                                  | Cause                                                                  |
|--------------------------------------------------------|------------------------------------------------------------------------|
| `template: ...: undefined variable "$.work"`           | Variable not in `[data]` on this machine. `chezmoi data` to confirm.   |
| Output has stray blank lines / semicolons              | Missing `{{- -}}` whitespace trim around conditionals.                 |
| `template: ...: function "foo" not defined`            | chezmoi has a curated function set; not all `text/template` funcs apply. Check the chezmoi reference for available template functions. |
| Renders fine via `execute-template`, breaks on `apply` | Filename attribute issue, not the template. Check for `private_`/perms drift. |
