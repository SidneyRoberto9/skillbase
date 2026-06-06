---
name: ai-sync
description: Synchronizes the locally-installed Claude skills with the cloud source of truth in this repository. Pulls the latest repo, then mirrors every skill into ~/.claude/skills, deleting any installed skill that is not in the repo (cloud wins). Use to install/update skills, sync skills from the cloud, refresh skills on this machine, or reset local skills to match the repo.
---

# AI Sync Skill

## Objective

Make the machine's installed skills an **exact mirror** of the skills repository
(the cloud source of truth). The repo wins: every skill in the repo is installed
or updated locally, and any locally-installed skill that is **not** in the repo is
deleted. After a sync, `~/.claude/skills/` contains exactly the repo's skills and
nothing else.

This is intentionally destructive toward local-only skills — that is the point of
a mirror. Always show what will be removed and confirm before deleting.

---

## Concepts

- **CLOUD / source of truth** — this git repository (`skillbase`), tracked by the
  `origin` remote. A *skill* is any top-level directory that contains a `SKILL.md`.
  Non-skill files at the repo root (`.git`, `README`, `MEMORY.md`, etc.) are not skills.
- **LOCAL / install target** — the personal skills directory Claude Code loads:
  `~/.claude/skills/`. (For a project-scoped sync, the target is the project's
  `.claude/skills/` instead — only use this when the user asks for it.)

Direction is **cloud → local** only. Editing happens in the repo; this skill never
writes back into the repo. To publish local repo edits to the cloud, commit and
push the repo (use the `auto-commit` skill), then run this sync.

---

## Step 1 — Refresh the cloud

From the repo root, make sure the working copy reflects the remote:

```bash
ROOT=$(git rev-parse --show-toplevel)
git -C "$ROOT" fetch origin
git -C "$ROOT" status -sb
```

- If the branch is behind, fast-forward: `git -C "$ROOT" pull --ff-only`.
- If the repo has **uncommitted or unpushed** skill edits, STOP and surface them —
  do not sync a stale or diverged state. Offer to commit/push first (`auto-commit`).
- If there is no remote yet (fresh repo), sync from the local repo as-is and note
  that the cloud is not published.

---

## Step 2 — Enumerate both sides

```bash
DEST="$HOME/.claude/skills"
mkdir -p "$DEST"

# Cloud skills = top-level dirs containing SKILL.md
for d in "$ROOT"/*/; do [ -f "$d/SKILL.md" ] && basename "$d"; done | sort   # CLOUD set

# Installed skills = dirs under the install target
for d in "$DEST"/*/; do [ -d "$d" ] && basename "$d"; done | sort            # LOCAL set
```

Compute the three groups and report them before touching anything:

- **Add** — in cloud, not installed
- **Update** — in both (will be overwritten from cloud)
- **Remove** — installed, not in cloud (will be **deleted**)

---

## Step 3 — Confirm deletions

If the **Remove** set is non-empty, list every skill to be deleted and confirm
with the user before proceeding. This is the only irreversible part. The user's
standing intent ("delete installed, keep only cloud") authorizes the mirror, but
always name what disappears (e.g. an unrelated installed skill like `smart-commit`).

---

## Step 4 — Mirror

```bash
# 1. Install / update every cloud skill (exact copy, prune stale files inside each)
for d in "$ROOT"/*/; do
  [ -f "$d/SKILL.md" ] || continue
  name=$(basename "$d")
  rsync -a --delete "$d" "$DEST/$name/"
done

# 2. Remove installed skills that are not in the cloud
for d in "$DEST"/*/; do
  name=$(basename "$d")
  [ -f "$ROOT/$name/SKILL.md" ] || rm -rf "$d"
done
```

Notes:

- `rsync --delete` makes each skill folder an exact copy — files deleted in the
  cloud skill also vanish locally.
- Never delete `$DEST` itself, dotfiles at its root, or plugin-managed dirs; only
  per-skill directories are in scope.
- If `rsync` is unavailable, fall back to `rm -rf "$DEST/$name" && cp -a "$d" "$DEST/$name"`.

---

## Step 5 — Validate

For every installed skill, confirm it loads cleanly:

- `SKILL.md` exists and its frontmatter parses.
- The frontmatter `name:` **equals** its directory name (Claude Code requires this).
- No skill directory is missing a `SKILL.md`.

Fix or flag any mismatch (a `name:`/folder drift means the rename was incomplete in
the repo — correct it in the repo, not in the install target).

---

## Step 6 — Report

Print a concise summary:

```
ai-sync — mirrored <N> skills from <origin/branch>
  added:   <names>
  updated: <names>
  removed: <names>
```

State the install target path and remind the user that local edits belong in the
repo, not in `~/.claude/skills/` (the next sync overwrites them).
