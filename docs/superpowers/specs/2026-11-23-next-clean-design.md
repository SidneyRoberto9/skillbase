# next-clean: restore, extend, and run before every Next.js commit

Approved 2026-11-23. Small change: short design.

## Intent

`next-clean` was removed from this repo in `85661e9` but is still installed and
still the convention fixer for the m4all Next.js UIs. Bring it back as the single
source of the UI conventions, add the rules the team uses now, and make it run
automatically before any commit Claude makes in a Next.js project.

## Goals

- `next-clean/SKILL.md` back in the repo, with the rule changes below.
- Every Claude commit in a Next.js repo is preceded by a `next-clean` pass.
- `MasterUIRulesFixer` stops duplicating the rules.

## Non-goals

- Updating the folder-structure rule (kept as it is today).
- Splitting files that were already over 300 lines before the change.
- Gating commits made by hand in a terminal: the hook only sees Claude's commits.

## Approaches

| Approach | Trade-off | Verdict |
|---|---|---|
| Hook + skill | Hook enforces deterministically; the skill runs in the conversation that wrote the code, so it knows the intent when splitting a file by responsibility | **Picked** |
| Agent | Still needs a hook to be triggered; starts without the conversation's context; one agent spawn per commit | Dropped |
| CLAUDE.md instruction only | No code, but can be forgotten | Dropped |

## Design

### 1. `next-clean/SKILL.md` (restored from the installed copy, then changed)

- **Legacy guard:** refuse to run inside the frozen m4all legacy projects
  (`core/*`, `eleva-ai`, `elevaflow-ai-service`, `elevaflow/*`,
  `elevaflow-ui-server`, `eleva-hub`, `helpdesk-old`, `inovadocs/*`, `pg/*`,
  `portal_inova`, `portal-e2e`, `societario`, `uso-proprio/*`, `venda-imoveis`,
  `modulo-rh/*`, `eleva-test`) unless the user explicitly reopened that project
  in the conversation.
- **Scope:** add untracked files (`git ls-files --others --exclude-standard`);
  only `.ts/.tsx/.js/.jsx`; skip `src/components/ui/` (shadcn primitives).
- **Icons:** `lucide-react` first; `@remixicon/react` only when lucide has no
  matching icon; custom SVGs in `src/components/icons/`; no other library.
- **Colors:** no hard-coded brand hex; use the theme tokens / Tailwind classes.
- **Blank line before control statements:** `if`, `for`, `while`, `do`,
  `switch`, `try` are preceded by one blank line, unless they are the first
  statement of their block (function, method, class, `if`/loop body, `case`).
- **300-line cap:** a file that is new, or that crossed 300 lines in this
  change, is split by responsibility into more files (components, hooks,
  utils). Files already over 300 lines before the change are listed in the
  report, not split.
- **Verification:** if `biome.json` exists, `npm run biome:check` (or
  `npx biome check` on the touched files); otherwise `npm run tc` and
  `npm run build`. If the project uses Vitest, also run its tests.
  (`next lint` no longer exists on Next 16.)
- **From MasterUIRulesFixer:** report what could not be fixed safely; flag
  refactors that may change rendered output; never reformat outside scope.
- **Commit mark:** last step writes `"$(git rev-parse --git-dir)/next-clean.ok"`.

### 2. `~/.claude/hooks/enforce-auto-commit.py` (existing commit gate, extended)

On a `git commit`, if the repo root `package.json` lists `next`, and any staged
in-scope file that exists on disk is newer than the commit mark (or there is no
mark), deny with: run the `next-clean` skill, then commit again. Uses file
mtime, not staged content, so `git add -p` and multi-commit runs keep working.

### 3. `auto-commit/SKILL.md`

Step 0: if the repo root `package.json` lists `next`, run `next-clean` before
surveying and staging, so the hook rarely has to block.

### 4. `~/.claude/agents/MasterUIRulesFixer.md`

Reduced to a pointer: read and follow `~/.claude/skills/next-clean/SKILL.md` on
the given scope. Kept for bulk folder cleanups in an isolated context.

## Left to the builder

- Exact wording of the new rules and the deny message.
- How the hook finds the target repo (payload `cwd`, `git -C`, `cd … &&`).
- Testing: a RED/GREEN subagent run on a fixture repo for the skill
  (writing-skills), and one runnable script that feeds payloads to the hook.
