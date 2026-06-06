---
name: next-clean
description: Audits and auto-fixes modified files against the project's mandatory code conventions (no comments, no Fragment shorthand, cn() for classes, no inline if, no ternary, arrow functions, @/ absolute imports, named exports except App Router files, lucide icons, one component per file). Use before committing, when the user asks to enforce standards, fix conventions, or apply the CLAUDE.md rules to changed code.
---

# Next Clean Skill

## Objective

Scan the files modified in the current working tree and **automatically correct**
every violation of the project's mandatory code conventions. Do not ask for
permission, do not suggest alternatives — fix the code in place.

This skill mirrors the rules defined in the project's `CLAUDE.md` /
`.claude/CLAUDE.md`. Those files are the source of truth; the rules below are the
baseline applied when the project does not override them.

---

## Step 1 — Load the rules

1. Read `CLAUDE.md` and `.claude/CLAUDE.md` from the project root if they exist.
2. Extract the mandatory generation rules. If a rule in this skill conflicts with
   the project file, **the project file wins**.
3. If no convention file exists, apply the baseline rules in Step 3.

---

## Step 2 — Determine the scope

Audit only what changed, never the whole repo unless explicitly asked:

```bash
git diff --name-only          # unstaged
git diff --cached --name-only # staged
```

If the user names a folder or file, restrict the scope to that path.

---

## Step 3 — Baseline rules (TypeScript / Next.js / React)

Apply these corrections to every modified file in scope:

### Imports & paths
- ALWAYS absolute imports via the `tsconfig` alias (the m4all standard is `@/*` → `./src/*`). NEVER relative (`./`, `../`).
- If the absolute path does not exist yet, assume it exists — do not fall back to relative.

### Exports
- Use **named exports** for components, hooks, utils, and types.
- EXCEPTION — Next.js App Router special files MUST keep their `export default`:
  `page`, `layout`, `loading`, `error`, `not-found`, `template`, `default`, and
  the `route` handler / `middleware`. Never "fix" these to named exports — it
  breaks the build. Their co-located `metadata` / `generateMetadata` stay named.

### Functions
- ALL functions and methods MUST be arrow functions.
- NEVER `function` declarations.
- Exported functions MUST be arrow functions.

### Control flow
- NEVER inline `if`. Every `if` MUST use a block with `{}`.
- NEVER ternary operators for control flow or JSX branching — refactor to explicit blocks / early returns / a derived variable.

### Comments
- NO comments in code — neither line (`//`) nor block (`/* */`). Remove every
  comment from any block you touch. If an explanation is truly needed, it lives
  outside the code (docs/commit), never inline.

### React / JSX
- NEVER the Fragment shorthand `<>...</>`. Import `Fragment` from `react` and use
  `<Fragment>...</Fragment>` explicitly.

### Tailwind classes
- If the project exposes a `cn(...)` helper (clsx + tailwind-merge), ALWAYS compose
  classes through it: `className={cn("flex items-center", isActive && "bg-primary")}`.
- NEVER template strings or manual concatenation for `className`, and never a
  ternary inside the class string.

### Components & files
- ONE component per file. The only multi-symbol file allowed is `page.tsx`.
- Every component except `page.tsx` MUST be an arrow function.
- Domain-Driven folder structure (App Router): organize by domain under
  `src/app/(application)/<domain>`, keeping page / content / feature-component split.

### Icons
- Icons ALWAYS from `lucide-react`, or custom SVGs from `src/components/icons/`.
- NEVER icons from any other library.

### Cleanup that travels with the rules
- Remove `console.log` and dead/commented-out code from any block you touch.

---

## Step 4 — Apply

1. For each file in scope, read it and locate violations.
2. Edit the file to comply. Rewrite the affected block fully — do not leave
   non-compliant code "for backward compatibility".
3. When a fix forces a signature or import change, propagate it to all usages so
   the project still compiles.

---

## Step 5 — Verify

Before finishing, run the mandatory checklist over every touched file (mirrors
the project's "Lint Obrigatório"):

- [ ] No relative imports — all via `@/`
- [ ] All functions and inner callbacks are arrow functions
- [ ] No comments of any kind
- [ ] No Fragment shorthand `<>` — `<Fragment>` only
- [ ] If `cn()` exists: no template-string/concatenated classes
- [ ] No inline `if` / no control-flow ternary
- [ ] Named exports, except App Router special files

Then confirm the project still builds / type-checks:

```bash
npm run tc    # tsc --noEmit, when available
npm run lint  # when available
```

Fix anything the checks surface, then report a concise list:
`<file>: <rule violated> → fixed`.

---

## Hard rules for the assistant

- Do NOT suggest alternatives.
- Do NOT ask whether a different style is acceptable.
- Do NOT justify a violation.
- Auto-correct every infraction in the touched code before reporting done.
