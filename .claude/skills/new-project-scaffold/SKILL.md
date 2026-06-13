---
name: new-project-scaffold
description: Scaffold a new project following the user's personal conventions — bun for package management and runtime, TypeScript (latest), Biome for linting (extending @illustrix/shared-configs/biome), strict tsconfig, git initialized, and React+Vite+Tailwind CSS for web frontends. Use this skill whenever the user wants to start, create, bootstrap, scaffold, set up, or initialize a new project, repo, app, package, library, CLI, server, or monorepo — even if they don't name bun, biome, vite, or these tools explicitly. Triggers on phrases like "新建一个项目", "创建一个 React 应用", "做一个 npm 库", "搭个 CLI", "start a new app", "set up a TypeScript library", "bootstrap a monorepo".
---

# New Project Scaffold

Scaffold a new TypeScript project the way this user likes it. The goal is a project that's ready to write code in within seconds: bun installed, Biome wired up, strict types on, git initialized — no dead config to clean up later.

## Core conventions (apply to every project)

These hold regardless of project type. The per-type recipes below build on them.

- **Runtime & package manager: `bun`.** Never `npm`/`yarn`/`pnpm`. Install with `bun add` / `bun add -d`, run scripts with `bun run`, execute one-off tools with `bunx`.
- **Always latest versions.** Don't pin versions in templates — let `bun add <pkg>` resolve the latest. The user explicitly wants the newest TypeScript, React, etc.
- **TypeScript everywhere**, with a strict, modern, bundler-resolution tsconfig (template below).
- **Biome for lint + format**, extending the user's shared config. If a starter template ships ESLint/Prettier, rip it out (see "Removing ESLint/Prettier").
- **Git initialized** with a sensible `.gitignore`.
- Keep `package.json` scripts minimal but real: at least `lint` and `format`; add `dev`/`build` per type.

## Step 1 — Determine type, name, and location

Figure out which of these the user wants. If it's genuinely ambiguous, ask one short question; otherwise infer from their words ("app/前端/页面" → web, "库/package/publish" → library, "CLI/脚本/server/后端" → node, "monorepo/多包" → monorepo).

| Type | Use when | Recipe |
|------|----------|--------|
| Web frontend (React) | UI, SPA, dashboard, web app | `references/web-react.md` (Vite + Tailwind) |
| Node / Bun / CLI | server, API, CLI tool, script | `references/node-cli.md` |
| TS library (npm package) | publishable package with type exports | `references/ts-library.md` |
| Monorepo | multiple packages, bun workspaces | `references/monorepo.md` |

Confirm the **project name** and **target directory** (default: a new subdirectory named after the project in the current working directory). Then **read the matching reference file** and follow it — each one is a complete recipe that assumes the shared conventions and config below.

## Step 2 — Apply the shared config

Every project (and every package inside a monorepo) gets these. Write them after the type-specific scaffold runs.

### Biome — `biome.json`

The shared config (`@illustrix/shared-configs/biome`) already defines the formatter, linter rules, and VCS integration. The local file only extends it. Add the dependency and the config:

```bash
bun add -d @biomejs/biome @illustrix/shared-configs
```

```json
{
  "$schema": "https://biomejs.dev/schemas/2.4.16/schema.json",
  "extends": ["@illustrix/shared-configs/biome"]
}
```

Bump the `$schema` version to match the `@biomejs/biome` version `bun add` actually installed (`bunx biome --version`), so editor schema validation stays accurate.

Scripts in `package.json`:

```json
{
  "scripts": {
    "lint": "biome check .",
    "format": "biome check --write ."
  }
}
```

### TypeScript — `tsconfig.json`

Strict, modern, bundler resolution — the bun-native baseline. Per-type recipes adjust a few keys (e.g. libraries emit declarations, React adds `"jsx"`), noted in their files.

```json
{
  "compilerOptions": {
    "lib": ["ESNext"],
    "target": "ESNext",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "moduleDetection": "force",
    "allowImportingTsExtensions": true,
    "verbatimModuleSyntax": true,
    "noEmit": true,
    "strict": true,
    "skipLibCheck": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,
    "noUncheckedIndexedAccess": true,
    "esModuleInterop": true,
    "isolatedModules": true,
    "types": ["bun"]
  },
  "include": ["src"]
}
```

Install bun's types so `"types": ["bun"]` resolves:

```bash
bun add -d typescript @types/bun
```

### `.gitignore`

```gitignore
node_modules
dist
build
coverage
*.log
.DS_Store
.env
.env.local
.env.*.local
```

Note: **commit `bun.lock`** — don't ignore it. It's bun's lockfile and belongs in version control.

### Git

```bash
git init && git add -A && git commit -m "chore: scaffold project"
```

Only make the initial commit once everything else (config, install) is in place, so the first commit is a clean working baseline.

## Removing ESLint / Prettier

Some starters (notably `bun create vite … react-ts`) ship ESLint. Biome replaces both ESLint and Prettier, so remove the redundant tooling to avoid two linters fighting:

```bash
bun remove eslint @eslint/js typescript-eslint eslint-plugin-react-hooks eslint-plugin-react-refresh globals prettier 2>/dev/null
rm -f eslint.config.js .eslintrc* .prettierrc* prettier.config.js
```

Then drop any `lint` script that calls eslint and replace it with the Biome scripts above.

## Finishing up

After scaffolding, verify it actually works before declaring done:

```bash
bun install
bunx biome check .   # may report fixable issues on starter code — run `bun run format` to clean up
bun run build        # if the type has a build step
```

Then give the user a 2-3 line summary: where the project is, the key commands (`bun run dev` / `lint` / `format`), and anything they still need to do (e.g. set a package name before publishing a library).
