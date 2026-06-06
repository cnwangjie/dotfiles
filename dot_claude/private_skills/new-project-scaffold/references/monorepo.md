# Monorepo (bun workspaces)

Multiple packages in one repo, managed with bun's native workspaces. One shared Biome config and one base tsconfig at the root; each package extends them and stays thin.

## Layout

```
<name>/
├── package.json          # root: private, workspaces, shared dev deps & scripts
├── biome.json            # extends @illustrix/shared-configs/biome (root only)
├── tsconfig.base.json    # shared compiler options
├── tsconfig.json         # references the packages (optional, for editor)
├── .gitignore
└── packages/
    ├── <pkg-a>/
    │   ├── package.json
    │   ├── tsconfig.json # extends ../../tsconfig.base.json
    │   └── src/index.ts
    └── <pkg-b>/...
```

## Steps

1. **Create the root:**

   ```bash
   mkdir <name> && cd <name>
   bun init -y
   rm -f index.ts        # root holds no source
   mkdir -p packages
   ```

2. **Root `package.json`** — private, with the workspace glob and shared tooling:

   ```json
   {
     "name": "<name>",
     "private": true,
     "workspaces": ["packages/*"],
     "scripts": {
       "lint": "biome check .",
       "format": "biome check --write .",
       "build": "bun run --filter '*' build",
       "typecheck": "tsc -b"
     }
   }
   ```

   `bun run --filter '*' build` runs each package's `build` script. Install shared dev deps once at the root — workspaces hoist them:

   ```bash
   bun add -d @biomejs/biome @illustrix/shared-configs typescript @types/bun
   ```

3. **Root `biome.json`** — the extends-only file from SKILL.md. A single Biome config at the root covers the whole tree; **do not** add `biome.json` inside each package.

4. **`tsconfig.base.json`** at the root — the SKILL.md base compiler options, minus `include` (each package sets its own). Add `"composite": true` so project references work:

   ```jsonc
   {
     "compilerOptions": {
       // ...SKILL.md base compilerOptions...
       "composite": true,
       "declaration": true
     }
   }
   ```

5. **Create packages** with `references/ts-library.md` (for publishable packages) or `references/node-cli.md` (for apps), with these monorepo adjustments:
   - Each package's `tsconfig.json` does `{ "extends": "../../tsconfig.base.json", "compilerOptions": { "outDir": "dist", "rootDir": "src" }, "include": ["src"] }`.
   - No per-package `biome.json`.
   - Cross-package deps use `"<pkg-a>": "workspace:*"` in the consumer's `package.json`, then `bun install` links them.

6. **Verify**: `bun install`, `bun run typecheck`, `bun run build`, `bunx biome check .`, then `git init` + initial commit at the root.

## Notes

- Start with one package if the user is unsure — it's easy to add more later, and an empty monorepo is just overhead.
- The root `tsconfig.json` (with `"references"` pointing at each package) is optional but helps editors resolve cross-package types; add it once there are ≥2 packages that depend on each other.
