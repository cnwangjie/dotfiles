# Web frontend — React + Vite + bun

A lightweight React SPA. Vite for dev server and build, bun as package manager and script runner, Biome instead of the ESLint that the Vite template ships with.

## Steps

1. **Scaffold with the Vite React-TS template** (bun runs the create command, no npm):

   ```bash
   bun create vite <name> --template react-ts
   cd <name>
   ```

   This gives you `src/`, `index.html`, a Vite config, three tsconfigs (`tsconfig.json` + `tsconfig.app.json` + `tsconfig.node.json`), and an ESLint setup.

2. **Strip out ESLint** — see "Removing ESLint / Prettier" in SKILL.md. The Vite react-ts template is the main reason that section exists.

3. **Add Biome** and the shared config, and write `biome.json` (extends only) per SKILL.md. Replace the template's lint script:

   ```json
   {
     "scripts": {
       "dev": "vite",
       "build": "tsc -b && vite build",
       "preview": "vite preview",
       "lint": "biome check .",
       "format": "biome check --write ."
     }
   }
   ```

4. **Upgrade everything to latest.** The template may pin older versions. Refresh the majors the user cares about:

   ```bash
   bun add react@latest react-dom@latest
   bun add -d typescript@latest vite@latest @vitejs/plugin-react@latest @types/react@latest @types/react-dom@latest
   ```

5. **tsconfig.** The Vite template's split tsconfigs are fine to keep — they already set `"jsx": "react-jsx"`, `strict`, and bundler resolution. Make sure `strict: true` and add the strictness extras the user wants (`noUncheckedIndexedAccess`, `noUnusedLocals`, `noUnusedParameters`) to `tsconfig.app.json` if absent. You don't need the SKILL.md base tsconfig here — Vite's is purpose-built for the browser. (`"types": ["bun"]` is unnecessary for a browser app; skip it.)

6. **`.gitignore`** — Vite's template already ignores `node_modules`, `dist`, logs. Just make sure it covers `.env*` and `.DS_Store`; merge in the SKILL.md entries if missing.

7. **Verify**: `bun install && bun run build && bunx biome check .`, then `git init` + initial commit.

## Notes

- Default to the SPA template. Only reach for Next.js if the user explicitly asks for SSR/full-stack — and warn them bun's runtime support for Next is partial (Vite is the smoother bun experience).
- `tsc -b && vite build` keeps a real type-check in the build; don't drop the `tsc` step.
