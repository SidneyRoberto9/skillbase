# /merge skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace `zull-merge` with `merge` (develop → staging → main) and rename `config/zull-implementation` to `homolog` in eleva-management-api and eleva-management-ui.

**Architecture:** The merge logic moves out of SKILL.md prose into `merge/merge.sh`, so it can be tested against a throwaway bare repo (`merge/test.sh`). SKILL.md only says when and how to run it.

**Tech Stack:** bash, git 2.43 (worktrees).

**Spec:** `docs/superpowers/specs/2026-11-25-merge-skill-design.md`

## Global Constraints

- Staging candidates, in order: `homolog`, `config/zull-implementation`. Every one that exists on origin is processed.
- Required on origin: `develop`, `main`, at least one staging branch. Otherwise exit 1 before any merge/push.
- Conflicts: `-X theirs`. Never touch `develop`. Merge source is always an `origin/*` ref after fetch.
- No commit/push of skillbase unless the user asks. Keep the user's pending edit in `auto-commit/SKILL.md` untouched.

## Review Focus

- The current branch is a target (in-place merge): the tree must end on the same branch, and a failed merge must be aborted, not left in conflict.
- The local staging branch does not exist yet (only `origin/homolog`): the worktree must create it tracking origin.
- A staging merge fails: `main` must not be touched.
- Only the legacy `config/zull-implementation` exists: it must work as staging.
- Neither staging branch exists: exit 1, nothing pushed.

---

### Task 1: `merge` skill

**Files:**
- Move: `zull-merge/` → `merge/` (`git mv`)
- Rewrite: `merge/SKILL.md` (`name: merge`)
- Create: `merge/merge.sh`, `merge/test.sh`
- Modify: `README.md:19` (row for the skill)

**Interfaces:**
- Produces: `bash merge.sh` run inside a git repo; prints `OK|DIVERGIU|FALHA ...: <target> ← <source>` per step and final SHAs; exit 0 only if every step is OK.

- [ ] **Step 1: Write `merge/test.sh`** — builds a bare origin + clone in `mktemp -d`, with a file conflicting between develop and homolog. Asserts:
  - homolog case: `origin/homolog` and `origin/main` contain develop's commit; the conflicting file has develop's content on both; `origin/develop` SHA unchanged; the clone is still on its starting branch.
  - in-place case: started on `homolog`, same assertions, ends on `homolog`, clean tree.
  - legacy case: only `config/zull-implementation` exists, same assertions.
  - no-staging case: exit 1, `origin/main` unchanged.
- [ ] **Step 2: Run `bash merge/test.sh`** — expected FAIL (merge.sh missing).
- [ ] **Step 3: Implement `merge/merge.sh`** — `merge_into TARGET SOURCE`: worktree unless TARGET is the current branch, `merge --ff-only origin/TARGET`, `merge -X theirs --no-edit SOURCE` (abort on failure), push, always remove the worktree. Loop: each staging ← `origin/develop`, then `main` ← each `origin/<staging>`; stop at first failure.
- [ ] **Step 4: Run `bash merge/test.sh`** — expected `PASS` for all four cases.
- [ ] **Step 5: Rewrite SKILL.md + README row**, install: `rsync -a --delete merge/ ~/.claude/skills/merge/ && rm -rf ~/.claude/skills/zull-merge`.

### Task 2: Rename branch in API and UI

**Files:** none (git refs in `eleva-management-api` and `eleva-management-ui`).

- [ ] **Step 1:** In each repo: `git push origin origin/config/zull-implementation:refs/heads/homolog`, `git push origin --delete config/zull-implementation`, `git branch -m config/zull-implementation homolog`, `git branch -u origin/homolog homolog`, `git fetch --prune`.
- [ ] **Step 2: Verify** `git branch -a` in each repo shows `homolog` and `origin/homolog`, and no `zull`.
