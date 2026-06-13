# TS library (npm package)

A publishable TypeScript package: clean ESM exports, generated `.d.ts` type declarations, and a `dist/` that's what gets published. Built with bun, types emitted with `tsc`.

## Steps

1. **Initialize:**

   ```bash
   mkdir <name> && cd <name>
   bun init -y
   mkdir -p src && mv index.ts src/index.ts 2>/dev/null || touch src/index.ts
   ```

2. **Install deps:**

   ```bash
   bun add -d @biomejs/biome @illustrix/shared-configs typescript @types/bun
   ```

3. **tsconfig** — start from the SKILL.md base, but a library must emit declarations. Override these keys:

   ```jsonc
   {
     "compilerOptions": {
       // ...SKILL.md base...
       "noEmit": false,
       "declaration": true,
       "emitDeclarationOnly": true,
       "outDir": "dist",
       "rootDir": "src"
     },
     "include": ["src"]
   }
   ```

   `bun build` produces the JS; `tsc` produces only the `.d.ts` files (hence `emitDeclarationOnly`).

4. **`package.json`** — configure it as a proper publishable ESM package:

   ```json
   {
     "name": "<name>",
     "version": "0.1.0",
     "type": "module",
     "module": "dist/index.js",
     "types": "dist/index.d.ts",
     "exports": {
       ".": {
         "types": "./dist/index.d.ts",
         "import": "./dist/index.js"
       }
     },
     "files": ["dist"],
     "sideEffects": false,
     "scripts": {
       "build": "bun build ./src/index.ts --outdir dist --target node && tsc",
       "dev": "bun build ./src/index.ts --outdir dist --target node --watch",
       "lint": "biome check .",
       "format": "biome check --write .",
       "prepublishOnly": "bun run build"
     }
   }
   ```

   Notes:
   - `files: ["dist"]` keeps source out of the published tarball.
   - `prepublishOnly` guarantees a fresh build before `bun publish` / `npm publish`.
   - If the library is browser-oriented, use `--target browser` instead of `node`.

5. **`.gitignore`** — the SKILL.md version already ignores `dist`. Good: built output shouldn't be committed.

6. **Verify**: `bun install && bun run build`, confirm `dist/index.js` and `dist/index.d.ts` both exist, `bunx biome check .`, then `git init` + initial commit.

## Notes

- Remind the user to set a real `name` (scoped like `@illustrix/<name>` if it belongs to their org) and to choose `private: true` vs. publishable before the first `bun publish`.
- For multiple entry points, add more keys under `exports` and build each entry.
- This recipe stays dependency-light (just `bun build` + `tsc`). If the user later wants bundling niceties (multiple formats, treeshaking reports), `tsup` is the usual upgrade — suggest it, don't impose it.
