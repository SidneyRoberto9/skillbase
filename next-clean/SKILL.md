---
name: next-clean
description: Use before every commit in a Next.js project, or when the user asks to enforce standards, fix conventions, or apply the CLAUDE.md rules to changed code. Audits and auto-fixes the changed files against the mandatory conventions — no comments, no Fragment shorthand, cn() for classes, no inline if, no ternary, arrow functions, @/ absolute imports, named exports except App Router files, lucide-first icons, no hard-coded brand colors, a blank line before control statements, a 300-line cap per file, one component per file.
---

# Next Clean Skill

## Objective

Scan the files changed in the current working tree and **automatically correct**
every violation of the project's mandatory code conventions. Do not ask for
permission, do not suggest alternatives — fix the code in place.

This skill mirrors the rules defined in the project's `CLAUDE.md` /
`.claude/CLAUDE.md`. Those files are the source of truth; the rules below are the
baseline applied when the project does not override them.

In a Next.js project the commit hook blocks any commit whose code files changed
after the last run of this skill. Every run ends by writing the commit mark
(Step 6).

---

## Step 0 — Refuse frozen legacy projects

If the repository's absolute path contains `/m4all/<project>` for any project
below, **stop**: change nothing, write no mark, and tell the user the project is
frozen. Run only if the user explicitly reopened that project in this
conversation.

`core`, `eleva-ai`, `elevaflow-ai-service`, `elevaflow`, `elevaflow-ui-server`,
`eleva-hub`, `helpdesk-old`, `inovadocs`, `pg`, `portal_inova`, `portal-e2e`,
`societario`, `uso-proprio`, `venda-imoveis`, `modulo-rh`, `eleva-test`
(including everything inside each of them).

Also **stop** when a merge, cherry-pick or revert is in progress — any of
`git rev-parse -q --verify MERGE_HEAD`, `CHERRY_PICK_HEAD`, `REVERT_HEAD`
succeeds. The staged changes there are other people's code; the commit hook does
not gate those commits. Change nothing, write no mark, and say why you stopped.

---

## Step 1 — Load the rules

1. Read `CLAUDE.md` and `.claude/CLAUDE.md` from the project root if they exist.
2. Extract the mandatory generation rules. If a rule in this skill conflicts with
   the project file, **the project file wins**.
3. If no convention file exists, apply the baseline rules in Step 3.

---

## Step 2 — Determine the scope

The scope is the union of three lists. All three, always:

```bash
git diff --name-only                       # unstaged changes
git diff --cached --name-only              # staged changes
git ls-files --others --exclude-standard   # untracked = new files never staged
```

A new file that was never `git add`-ed is in scope. It is usually the file that
needs the most fixing.

Then filter:

- Keep only `.ts`, `.tsx`, `.js`, `.jsx`.
- **Drop everything under `src/components/ui/`.** Those are shadcn primitives:
  never edit them, even when they changed and even when they break the rules
  below.
- If the user names a folder or file, restrict the scope to that path.

Before editing anything, note which files in scope are **fully staged**: listed
by `git diff --cached --name-only` and not by `git diff --name-only`. Step 6
re-stages them.

---

## Step 3 — Baseline rules (TypeScript / Next.js / React)

Apply these corrections to every file in scope:

### Imports & paths
- ALWAYS absolute imports via the `tsconfig` alias (the m4all standard is `@/*` → `./src/*`). NEVER relative (`./`, `../`).
- If the absolute path does not exist yet, assume it exists — do not fall back to relative.

### Exports
- Use **named exports** for components, hooks, utils, and types.
- EXCEPTION — these files MUST keep their `export default`. Never "fix" them to
  named exports — it breaks the build or silently drops the config:
  - App Router special files: `page`, `layout`, `loading`, `error`,
    `global-error`, `not-found`, `template`, `default`, and the metadata files
    `sitemap`, `robots`, `manifest`, `opengraph-image`, `twitter-image`, `icon`,
    `apple-icon`. Their co-located `metadata` / `generateMetadata` stay named.
  - `middleware` keeps whatever export it has.
  - Tool config files: `next.config.*`, `tailwind.config.*`, `postcss.config.*`,
    `vitest.config.*`, and any other `*.config.*`.
- `route` handlers export their HTTP methods by name (`export const GET = …`);
  they have no default export.

### Functions
- ALL functions and methods MUST be arrow functions.
- NEVER `function` declarations.
- Exported functions MUST be arrow functions.

### Control flow
- NEVER inline `if`. Every `if` MUST use a block with `{}`.
- NEVER ternary operators for control flow or JSX branching — refactor to explicit blocks / early returns / a derived variable.

### Blank line before control statements
- `if`, `for`, `while`, `do`, `switch` and `try` MUST have one blank line above them.
- EXCEPTION — no blank line when the statement is the **first statement of its
  block**: right after the `{` that opens a function, method, class, `if`/`else`
  body, loop body, `try`/`catch`/`finally` body, or right after a `case` /
  `default` label.
- `else`, `else if`, `catch` and `finally` continue the statement before them:
  never put a blank line before them.

```ts
export const total = (items: Item[]) => {
  if (items.length === 0) {
    return 0
  }
  let sum = 0

  for (const item of items) {
    sum += item.price
  }
  return sum
}
```

The first `if` opens the function body, so it has no blank line. The `for` follows
another statement, so it gets one.

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

### Colors
- NEVER hard-code a color value (hex, `rgb()`, `hsl()`) in a class or a style:
  `text-[#660099]`, `bg-[rgb(…)]`, `style={{ color: "#660099" }}`.
- Replace it with the project's theme token: the Tailwind theme color or CSS
  variable (for example `--eleva-*`) that holds that value. Look it up in
  `tailwind.config.*` and the global CSS.
- If no token holds that value, leave it and list it in the report — never
  invent a token.

### Components & files
- ONE component per file. The only multi-symbol file allowed is `page.tsx`.
- Every component except `page.tsx` MUST be an arrow function.
- Domain-Driven folder structure (App Router): organize by domain under
  `src/app/(application)/<domain>`, keeping page / content / feature-component split.

### File size — 300 lines max
- A file in scope that is **new**, or that had 300 lines or fewer at `HEAD` and
  has more than 300 now, MUST end with 300 lines or fewer. Lines at `HEAD`:
  `git show HEAD:<path> | wc -l` (the command fails for a new file).
- Split it **by responsibility**, not by line ranges: move hooks, helpers/utils,
  constants and lookup tables, and types each into their own file, placed where
  the project already keeps that kind of file (or next to the original). Do it
  even when the file holds a single component: one component per file is not
  enough. Every new file follows all the rules above. Update every import.
- A file that was already over 300 lines at `HEAD` is **not** split: list it in
  the report as pre-existing.

### Icons
- Prefer `lucide-react`. Use `@remixicon/react` only when lucide has no matching
  icon. Custom SVGs come from `src/components/icons/`.
- When you touch a remixicon import, switch it to the lucide equivalent if one
  exists.
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
4. Do not reformat or restyle code outside the blocks you fix.
5. If a fix could change what renders (untangling a JSX ternary, splitting a
   file), make the minimal correct change and flag it in the report.

---

## Step 5 — Verify

Run the checklist over every touched file (mirrors the project's
"Lint Obrigatório"):

- [ ] No relative imports — all via `@/`
- [ ] All functions and inner callbacks are arrow functions
- [ ] No comments of any kind
- [ ] No Fragment shorthand `<>` — `<Fragment>` only
- [ ] If `cn()` exists: no template-string/concatenated classes
- [ ] No inline `if` / no control-flow ternary
- [ ] Named exports, except App Router special files
- [ ] Blank line before every non-first `if` / `for` / `while` / `do` / `switch` / `try`
- [ ] No hard-coded color values that a token holds
- [ ] No new or newly-grown file over 300 lines
- [ ] Icons: lucide first, remixicon only without a lucide match
- [ ] Nothing under `src/components/ui/` was edited

Then run the project's checks:

- `biome.json` / `biome.jsonc` exists → `npm run biome:check` when that script
  exists, otherwise `npx biome check <files in scope>`.
- No Biome → `npm run tc` and `npm run build` (each when the script exists).
  Do not rely on `npm run lint` when it runs `next lint`: that command was
  removed in Next 16.
- `vitest` in `package.json` → `npm run test:run` when that script exists,
  otherwise `npx vitest run`.

Fix anything the checks surface. A check that cannot run (no `node_modules`,
offline) is reported as such — never skipped silently.

---

## Step 6 — Re-stage, then write the commit mark

1. **Re-stage** so the commit contains the fixes, not the old staged content:
   - `git add` every file that was fully staged when the run started (Step 2).
   - `git add` every new file you created by splitting one of those files.
   - Files that were partially staged (staged and unstaged changes): do not
     stage them; list them in the report so the caller re-stages them.
   - Never stage files that were not staged before the run.
2. **Write the mark — only when the scope was the full changed set from Step 2.**
   After a run limited to a folder or file, do not write it: say in the report
   that the commit stays blocked until a full run.
   Otherwise, as the very last action, even when nothing needed fixing:

```bash
touch "$(git rev-parse --git-dir)/next-clean.ok"
```

The commit hook compares the code files' modification times with this mark: any
later edit to a code file requires another run before committing. Never write
the mark when Step 0 stopped the run.

---

## Report

One line per fix: `<file>: <rule violated> → fixed`. Then, when not empty:

- **Not fixed** — what could not be fixed safely, for manual review.
- **May change rendering** — fixes flagged in Step 4.
- **Pre-existing over 300 lines** — files not split, with their line count.
- **Re-stage needed** — partially staged files that were fixed.
- **Mark** — written, or not written and why.
- **Checks** — each command run and its result, or why it could not run.

---

## Hard rules for the assistant

- Do NOT suggest alternatives.
- Do NOT ask whether a different style is acceptable.
- Do NOT justify a violation.
- Never edit files under `src/components/ui/`.
- Auto-correct every infraction in the touched code before reporting done.
