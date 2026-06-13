# Web frontend — React + Vite + bun

A lightweight React SPA. Vite for dev server and build, bun as package manager and script runner, Biome instead of the ESLint that the Vite template ships with, and Tailwind CSS (v4) as the default styling layer.

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

5. **Add Tailwind CSS (latest, v4).** This is the default styling layer for web projects. Tailwind v4 uses a Vite plugin — there is **no** `tailwind.config.js` and **no** PostCSS config to write; configuration lives in CSS.

   ```bash
   bun add tailwindcss @tailwindcss/vite
   ```

   Register the plugin in `vite.config.ts` (alongside the React plugin):

   ```ts
   import { defineConfig } from 'vite'
   import react from '@vitejs/plugin-react'
   import tailwindcss from '@tailwindcss/vite'

   export default defineConfig({
     plugins: [react(), tailwindcss()],
   })
   ```

   Then make the project's main stylesheet import Tailwind — replace the contents of `src/index.css` with:

   ```css
   @import "tailwindcss";
   ```

   The Vite template already imports `./index.css` in `src/main.tsx`, so this is all that's needed. Write the demo UI with Tailwind utility classes (e.g. `className="flex gap-4 p-6"`) rather than hand-rolled CSS, and drop the template's `App.css` if it's now unused. Customize the theme (colors, fonts, breakpoints) with `@theme { ... }` directives inside `index.css` when needed — that's the v4 replacement for the old config file. Heads-up: Biome's CSS linter may flag the `@theme` at-rule as unknown; if you add a `@theme` block and `biome check` complains, disable Biome's CSS linter for that file or add `@theme` to the allowed at-rules rather than removing the customization.

6. **tsconfig.** The Vite template's split tsconfigs are fine to keep — they already set `"jsx": "react-jsx"`, `strict`, and bundler resolution. Make sure `strict: true` and add the strictness extras the user wants (`noUncheckedIndexedAccess`, `noUnusedLocals`, `noUnusedParameters`) to `tsconfig.app.json` if absent. You don't need the SKILL.md base tsconfig here — Vite's is purpose-built for the browser. (`"types": ["bun"]` is unnecessary for a browser app; skip it.)

7. **`.gitignore`** — Vite's template already ignores `node_modules`, `dist`, logs. Just make sure it covers `.env*` and `.DS_Store`; merge in the SKILL.md entries if missing.

8. **Verify**: `bun install && bun run build && bunx biome check .` (the build also confirms Tailwind compiles), then `git init` + initial commit.

## Notes

- Default to the SPA template. Only reach for Next.js if the user explicitly asks for SSR/full-stack — and warn them bun's runtime support for Next is partial (Vite is the smoother bun experience).
- `tsc -b && vite build` keeps a real type-check in the build; don't drop the `tsc` step.
- Tailwind v4 is configless by design — if you find yourself reaching for `tailwind.config.js` or `npx tailwindcss init`, stop: that's the v3 workflow. In v4, theme customization is `@theme` in `index.css` and the build is driven by `@tailwindcss/vite`.
