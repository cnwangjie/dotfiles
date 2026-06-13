# Node / Bun / CLI

A backend service, API, or command-line tool that runs directly on bun — no bundler needed in dev, bun executes TypeScript natively.

## Steps

1. **Initialize with bun:**

   ```bash
   mkdir <name> && cd <name>
   bun init -y
   ```

   `bun init` creates `package.json`, `index.ts`, a `tsconfig.json`, `.gitignore`, and a README. You'll overwrite the config files with the user's conventions.

2. **Move entry into `src/`:** the SKILL.md tsconfig uses `"include": ["src"]`. Move the entry there:

   ```bash
   mkdir -p src && mv index.ts src/index.ts 2>/dev/null || touch src/index.ts
   ```

3. **Apply shared config** — write `biome.json`, `tsconfig.json`, `.gitignore` per SKILL.md, and install deps:

   ```bash
   bun add -d @biomejs/biome @illustrix/shared-configs typescript @types/bun
   ```

4. **`package.json`** — set `"type": "module"`, point `main` at the entry, and add scripts:

   ```json
   {
     "type": "module",
     "main": "src/index.ts",
     "scripts": {
       "dev": "bun --watch src/index.ts",
       "start": "bun src/index.ts",
       "lint": "biome check .",
       "format": "biome check --write ."
     }
   }
   ```

5. **If it's a CLI** (the user said "命令行/CLI/工具"), make it executable:
   - Add a shebang as the first line of `src/index.ts`: `#!/usr/bin/env bun`
   - Add a `bin` field: `"bin": { "<name>": "src/index.ts" }`
   - Consider a flags/args parser only if the CLI is non-trivial — bun exposes `process.argv` and there's `util.parseArgs` built in; reach for a library (e.g. `commander`) only when subcommands warrant it.

6. **Verify**: `bun install && bun run src/index.ts` (or `bun run dev`), `bunx biome check .`, then `git init` + initial commit.

## Notes

- No build step is needed to run on bun. If the user needs a distributable binary, `bun build --compile --outfile <name> src/index.ts` produces a standalone executable — mention it, don't add it by default.
- Keep `"types": ["bun"]` in tsconfig so `Bun.*` APIs and bun globals type-check.
