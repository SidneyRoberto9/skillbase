# next-clean Restore + Commit Gate Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore `next-clean` to skillbase with the new rules, and block any Claude commit in a Next.js repo until `next-clean` has run on the changed files.

**Architecture:** The skill writes a mark file when it finishes. The existing PreToolUse commit hook denies a `git commit` in a Next.js repo when a staged in-scope file is newer than that mark. `auto-commit` runs `next-clean` first so the gate rarely fires. `MasterUIRulesFixer` becomes a pointer to the skill.

**Tech Stack:** Markdown skills, Python 3.12 stdlib hook, git.

**Spec:** `docs/superpowers/specs/2026-11-23-next-clean-design.md`

## Global Constraints

- npm only (never pnpm/yarn/bun) in any command a skill tells the agent to run.
- Never run `git commit` directly. Commits only through the `auto-commit` skill, only when the user asks. Never stage `zull-merge/SKILL.md` (unrelated pending change).
- Skill and agent text in English.
- Commit mark: `"$(git rev-parse --git-dir)/next-clean.ok"`.
- Next.js repo = `package.json` at the git top level lists `next` in `dependencies` or `devDependencies`.
- In-scope files: `.ts`, `.tsx`, `.js`, `.jsx`, outside `src/components/ui/`.
- File cap: 300 lines, for files that are new or crossed 300 in this change.
- Frozen legacy list (verbatim from the spec): `core/*`, `eleva-ai`, `elevaflow-ai-service`, `elevaflow/*`, `elevaflow-ui-server`, `eleva-hub`, `helpdesk-old`, `inovadocs/*`, `pg/*`, `portal_inova`, `portal-e2e`, `societario`, `uso-proprio/*`, `venda-imoveis`, `modulo-rh/*`, `eleva-test`.

## Review Focus

- `git -C <dir> commit` or `cd <dir> && git commit` from another cwd: the gate checks `<dir>`, and the message lint still runs. Today `git -C <dir> commit` skips the lint entirely (the `(\s|^)-C\s` early exit is meant for `git commit -C <rev>`). Pinned by Task 1 tests 7 and 8.
- Multi-commit `auto-commit` run with `git add -p`: with no edits after next-clean, every commit passes. Pinned by Task 1 test 2 (mtime-based, staged content irrelevant).
- Non-Next repos (Spring API, skillbase itself, no `package.json`): never blocked. Task 1 test 4.
- Commit containing only docs, `package.json` or `src/components/ui/` files: not blocked. Task 1 test 5.
- Frozen legacy path not reopened by the user: the skill refuses and changes nothing. Task 2 legacy scenario.

---

### Task 1: Commit gate in `enforce-auto-commit.py`

**Files:**
- Modify: `~/.claude/hooks/enforce-auto-commit.py`
- Create: `~/.claude/hooks/test_enforce_auto_commit.py`

**Interfaces:**
- Produces: deny reason that contains the string `next-clean` and lists the stale files; reads the mark `<git-dir>/next-clean.ok` (written by Task 2's skill).
- Functions: `target_dir(cmd: str, cwd: str) -> str` (value of `git -C <dir>`, else the last `cd <dir>` before `git`, else `cwd`); `stale_files(cmd: str, cwd: str) -> list[str]` (in-scope files newer than the mark, all of them if no mark; `[]` when not a git repo or not Next.js).

- [ ] **Step 1: Write the failing tests** in `test_enforce_auto_commit.py`: each builds a temp git repo, sets file mtimes with `os.utime` (no sleeps), pipes `{"tool_name":"Bash","tool_input":{"command":...},"cwd":...}` into the hook via `subprocess`, and asserts on stdout. Plain `assert`, runnable as `python3 test_enforce_auto_commit.py`. Valid message everywhere unless stated: `feat(ui): add order card`.
  1. `test_next_repo_without_mark_denies`: Next repo, staged `src/a.tsx`, no mark → `permissionDecision == "deny"`, reason contains `next-clean` and `src/a.tsx`.
  2. `test_mark_newer_than_files_allows`: mark mtime > `src/a.tsx` mtime → empty stdout.
  3. `test_file_edited_after_mark_denies`: `src/a.tsx` mtime > mark → deny.
  4. `test_non_next_repo_allows`: `package.json` without `next`, and a repo with no `package.json` → empty stdout.
  5. `test_out_of_scope_files_allow`: only `README.md`, `package.json`, `src/components/ui/button.tsx` staged, no mark → empty stdout.
  6. `test_deleted_file_ignored`: staged deletion of a committed `src/old.tsx`, no other change → empty stdout.
  7. `test_dir_resolution`: payload `cwd` is an unrelated dir; `git -C <repo> commit -m ...` and `cd <repo> && git commit -m ...` → deny.
  8. `test_dash_C_dir_still_lints_message`: non-Next repo, `git -C <repo> commit -m "Bad Message."` → deny with the Conventional Commits reason.
  9. `test_commit_all_checks_unstaged_tracked`: tracked `src/a.tsx` modified but unstaged, newer than mark, `git commit -a -m ...` → deny.

- [ ] **Step 2: Run the tests, verify they fail**
  Run: `python3 ~/.claude/hooks/test_enforce_auto_commit.py`
  Expected: AssertionError on test 1.

- [ ] **Step 3: Implement** `target_dir` and `stale_files`, and call the gate right after `COMMIT_RE` matches, before the message early exits. Staged list: `git diff --cached --name-only --diff-filter=d`; with `-a`/`--all` also `git diff --name-only --diff-filter=d`. Fix the reuse-message early exit so `-C` only counts after the `commit` token. The next-clean deny reason says: run the `next-clean` skill (Skill tool: next-clean) on these files, then commit again; it does not append the auto-commit message footer.

- [ ] **Step 4: Run the tests, verify they pass**
  Run: `python3 ~/.claude/hooks/test_enforce_auto_commit.py`
  Expected: no output, exit 0.

- [ ] **Step 5: Live check through the harness:** in a scratchpad Next fixture repo (`package.json` with `next`, staged `src/a.tsx`, no mark), run `git commit -m "feat(ui): add order card"` with the Bash tool. Expected: blocked by the hook with the `next-clean` reason, no commit created (`git log` empty).

### Task 2: Restore and extend `next-clean`

**Files:**
- Create: `next-clean/SKILL.md` (from `git show 85661e9^:next-clean/SKILL.md`)
- Install: `~/.claude/skills/next-clean/SKILL.md` (copy)
- Test fixtures and checks: scratchpad only

**Interfaces:**
- Produces: the mark `<git-dir>/next-clean.ok` as the skill's last step (consumed by Task 1's hook).

- [ ] **Step 1: Restore the file** from `85661e9^` into `next-clean/SKILL.md`. Check: `diff next-clean/SKILL.md ~/.claude/skills/next-clean/SKILL.md` prints nothing.

- [ ] **Step 2: Build the fixture and its check script** in the scratchpad: `make-fixture.sh <dir>` creates a git repo with `package.json` (`next`, `react`, `lucide-react`, `@remixicon/react`), `tsconfig.json` with `@/*` → `./src/*`, `src/lib/utils.ts` with `cn`, an initial commit containing `src/components/orders/legacy-list.tsx` (350 lines) and `src/components/ui/button.tsx` (uses a `function` declaration), then these uncommitted changes:
  - a one-line edit in `legacy-list.tsx`;
  - staged `src/components/orders/order-card.tsx`: an `if` that is the first statement of its function, an `if` and a `for` that follow other statements with no blank line, `RiHomeLine` from `@remixicon/react`, `className="text-[#660099]"`;
  - staged `src/components/orders/order-board.tsx`: 320 lines mixing a data hook, a filter util and two components;
  - untracked `src/components/orders/order-badge.tsx` with `import { cn } from "../../lib/utils"`.

  `check-fixture.sh <dir>` prints PASS/FAIL for each expectation:
  - The blank line is added before the non-first `if` and the `for`, and not before the first-statement `if`.
  - No `RiHomeLine`; a `lucide-react` icon is used instead.
  - No `#660099` left in `src/`.
  - `order-board.tsx` and every file split out of it are at most 300 lines each.
  - `legacy-list.tsx` is still over 300 lines.
  - `button.tsx` is unchanged (`git diff --quiet`).
  - `order-badge.tsx` has no relative import.
  - The mark `.git/next-clean.ok` exists.

- [ ] **Step 3: RED.** Copy the fixture to `A/`. Dispatch a subagent (sonnet, medium) with the current skill text: "Follow this skill on the repo at A/. No npm install is possible; report verification commands that cannot run." Run `check-fixture.sh A`. Expected: FAIL on the new-rule lines (blank lines, 300 lines, untracked file, `button.tsx`, hex, remixicon, mark). Record the agent's report verbatim.

- [ ] **Step 4: Edit `next-clean/SKILL.md`** with the spec's section 1, each item placed where it applies:
  - Legacy guard: a new Step 0.
  - Scope additions: in Step 2.
  - Icons, colors, blank line and 300-line rules: in Step 3.
  - Verification: in Step 5, replacing the `npm run lint` block.
  - MasterUIRulesFixer report items: in the report.
  - Mark: the last step.
  - Update the description to name the new rules.

  Leave the folder-structure rule as it is.

- [ ] **Step 5: GREEN.** Copy the fixture to `B/`, dispatch the same prompt with the new skill, run `check-fixture.sh B`. Expected: all PASS. Then copy the fixture to `<scratchpad>/m4all/inovadocs/fixture/` and dispatch the same prompt there. Expected: the agent refuses, and `git status --porcelain` is identical before and after. On any FAIL: tighten the wording for the specific rationalization in the report, rerun only the failing scenario.

- [ ] **Step 6: Install:** `cp next-clean/SKILL.md ~/.claude/skills/next-clean/SKILL.md`. Check: `diff -q` prints nothing.

### Task 3: `auto-commit` step 0 and `MasterUIRulesFixer` pointer

**Files:**
- Modify: `auto-commit/SKILL.md` (`# Execution Protocol`, before `## 1. Survey repository state`)
- Modify: `~/.claude/agents/MasterUIRulesFixer.md`
- Install: `~/.claude/skills/auto-commit/SKILL.md` (copy)

- [ ] **Step 1: Add `## 0. Next.js projects`** to `auto-commit`: if `package.json` at the git top level lists `next`, invoke the `next-clean` skill before step 1 and include its fixes in the survey.
- [ ] **Step 2: Replace the agent body** after the frontmatter with: read `~/.claude/skills/next-clean/SKILL.md` and follow it on the scope given in the prompt. The description says it runs `next-clean` in an isolated context for bulk folder cleanups. Keep the `## Como chamar` examples.
- [ ] **Step 3: Install and verify:** `cp auto-commit/SKILL.md ~/.claude/skills/auto-commit/SKILL.md`. Then `grep -n "next-clean" ~/.claude/skills/auto-commit/SKILL.md ~/.claude/agents/MasterUIRulesFixer.md`: each file has a match. `grep -c "Fragment" ~/.claude/agents/MasterUIRulesFixer.md` prints `0`, so the rules live only in the skill.

### Finish

- [ ] Run `python3 ~/.claude/hooks/test_enforce_auto_commit.py` and `check-fixture.sh B` once more; both pass.
- [ ] Commit the skillbase changes (`next-clean/SKILL.md`, `auto-commit/SKILL.md`, `docs/superpowers/`) through the `auto-commit` skill, only when the user asks.
