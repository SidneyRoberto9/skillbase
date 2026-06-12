# skillbase

Personal collection of [Claude Code](https://claude.com/claude-code) skills kept
in a single repository that acts as the **source of truth** (the "cloud"). The
`ai-sync` skill mirrors this repo into your local install so every machine runs
the exact same set of skills.

---

## Skills

| Skill | What it does |
|-------|--------------|
| **next-clean** | Audits & auto-fixes changed TypeScript / Next.js / React files: no comments, no `<>` Fragment shorthand, `cn()` for classes, arrow functions, `@/` absolute imports, named exports (except App Router files), no inline `if` / ternary, lucide icons, one component per file. |
| **spring-clean** | Audits & auto-fixes changed Java / Spring Boot files: constructor injection, explicit `ResponseEntity.status().body()`, braced `if`s, record DTOs over `Map.of`, `@Valid` validation, global `@RestControllerAdvice` error handling. |
| **auto-commit** | Analyzes the working tree and creates Conventional Commits — auto-chooses squash vs atomic, adds `type(scope)`, English / imperative, verifies the tree, and **never adds a `Co-Authored-By` trailer**. |
| **post-docs** | After a feature lands, syncs the docs to match: `CLAUDE.md`, `docs/modulos/<module>.md` (mirrored api ↔ ui), endpoint references. Keeps each doc in its existing language (PT / EN). |
| **ai-sync** | Mirrors this repo's skills into your local Claude install. Pulls the latest repo, installs/updates every skill, and **deletes any installed skill that is not in this repo**. |
| **zull-merge** | Propagates `develop` to `config/zull-implementation` and `main` in parallel (merge + push), with `develop` winning conflicts (`-X theirs`). All-or-nothing: aborts if any of the three branches is missing on `origin`; never touches `develop` (reads `origin/develop` only); off-branch targets run in worktrees that are always cleaned up. |

They compose into a pipeline:

```
next-clean / spring-clean  →  auto-commit  →  post-docs
   (fix + clean code)          (commit)        (document)
```

---

## ⚠️ WARNING — `ai-sync` DELETES your installed skills

> **`ai-sync` is a destructive mirror. This repository always wins.**
>
> Any skill currently in your install directory (`~/.claude/skills/`, or
> `%USERPROFILE%\.claude\skills\` on Windows) that is **NOT** in this repository
> will be **permanently deleted**. After a sync, your install contains *exactly*
> the skills in this repo — nothing else.
>
> If you have a local-only skill you want to keep, **add it to this repo first**,
> otherwise it is gone.

---

## Install `ai-sync`

`ai-sync` bootstraps everything else: you install it once by hand, then it
installs and keeps every other skill in sync.

### Prerequisites

- `git`
- Claude Code installed
- A bash shell:
  - **Linux / macOS** — built in
  - **Windows** — Git Bash (ships with [Git for Windows](https://git-scm.com/download/win)) or WSL

### Linux / macOS

```bash
# 1. Clone the repo (your local working copy of the "cloud")
git clone https://github.com/SidneyRoberto9/skillbase.git ~/skillbase

# 2. Bootstrap: copy ai-sync into your Claude skills install (one time only)
mkdir -p ~/.claude/skills
cp -a ~/skillbase/ai-sync ~/.claude/skills/ai-sync

# 3. Open Claude Code inside the repo and run the skill
cd ~/skillbase
claude          # then type:  /ai-sync
```

### Windows — Git Bash

Open **Git Bash** and run the same steps (`~` maps to `C:\Users\<you>`):

```bash
git clone https://github.com/SidneyRoberto9/skillbase.git ~/skillbase
mkdir -p ~/.claude/skills
cp -a ~/skillbase/ai-sync ~/.claude/skills/ai-sync
cd ~/skillbase
claude          # then type:  /ai-sync
```

### Windows — PowerShell (bootstrap copy)

Prefer PowerShell? Do the clone + copy there, then run `/ai-sync` from Claude Code
inside the repo:

```powershell
git clone https://github.com/SidneyRoberto9/skillbase.git $env:USERPROFILE\skillbase
New-Item -ItemType Directory -Force $env:USERPROFILE\.claude\skills | Out-Null
Copy-Item -Recurse -Force $env:USERPROFILE\skillbase\ai-sync $env:USERPROFILE\.claude\skills\ai-sync
```

> On Windows, `ai-sync` itself runs through **Git Bash or WSL** (it uses `rsync`,
> falling back to `cp`). Make sure one is available before running `/ai-sync`.

---

## Sync (every time after)

To update a machine so it matches the repo:

```bash
cd ~/skillbase
git pull
```

Then in Claude Code:

```
/ai-sync
```

`ai-sync` pulls the latest, mirrors every skill into your install directory, and
**deletes anything not in the repo** (see the warning above). It lists what was
added, updated, and removed when it finishes.

---

## Editing skills

Edit skills **in this repo**, never in `~/.claude/skills/` — the next sync
overwrites the install. The flow is:

1. Edit the skill here.
2. Commit with `auto-commit`, then `git push`.
3. Run `/ai-sync` on each machine to pull the change in.
