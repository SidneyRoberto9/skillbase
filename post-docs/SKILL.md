---
name: post-docs
description: After implementing a feature, updates the project documentation to match the change — CLAUDE.md, the docs/ folder, and endpoint/route references. Use when the user says to update the docs, document a feature, refresh CLAUDE.md, or finalize a change with documentation.
---

# Post-Feature Docs Skill

## Objective

Keep the project's documentation in sync with the code that just changed. After a
feature lands, detect what changed and update the relevant docs so they reflect
reality. Documentation language MUST match the **existing docs of that project** —
do not assume English. `CLAUDE.md` is typically English, but several projects keep
`docs/` in Portuguese (e.g. eleva-messaging: `docs/modulos/motoboy.md` → `# Módulo:
MOTOBOY`). Detect the language of the file you are editing and write in it.

---

## Step 1 — Detect what changed

Build the change set from git:

```bash
git diff --stat
git diff                 # unstaged
git diff --cached        # staged
git log -1 --stat        # if the work was just committed
```

Summarize the behavioral delta: new endpoints/routes, new components, new
config/env vars, new domain modules, changed contracts, removed features.

---

## Step 2 — Locate the docs that must change

Check each of these and decide if the change set affects it:

1. **`CLAUDE.md` / `.claude/CLAUDE.md`** — architecture, commands, ports, auth,
   conventions, env vars, domain map. Update any section the change invalidates.
2. **`docs/` folder** — the real m4all layout is per-module:
   `docs/modulos/<module>.md` (e.g. `motoboy.md`, `correios.md`,
   `notificacoes-email.md`), plus top-level reports like `README.md`,
   `RELATORIO-CONSOLIDADO.md`, `AUDITORIA-*.md`, `FEATURE-FLAGS.md`. Update the
   existing module page; create one only when a new module has none.
   **Mirror api ↔ ui:** when both `<project>-api/docs` and `<project>-ui/docs`
   carry the same `modulos/` tree, update the matching page on both sides.
3. **Endpoint/route catalogs** — if the project keeps an endpoint reference or
   route table, add/edit entries with method, path, guard/role, and a
   request/response example. (Most projects document endpoints inside the module
   page rather than a separate catalog — follow whatever the project already does.)
4. **`README` / env samples** — if env vars or run commands changed.

---

## Step 3 — Update rules

- Match the existing structure, heading style, and language of each doc
  (English or Portuguese — whichever that file already uses).
- For endpoints: document HTTP method, full path, required guard/role
  (e.g. `@AdminAccess`), request DTO/body, and a concrete example payload.
- For components: document purpose, every prop/input and its type, and notable
  behavior/peculiarities. Cover both framework variants when the project ships
  both (e.g. React and Angular).
- Do not document what did not change. Do not invent behavior — read the code.
- Remove doc sections describing features that were deleted.

---

## Step 4 — Verify consistency

- Re-read each edited doc against the code to confirm names, paths, props, and
  types are exact.
- Ensure cross-references and the docs index/table of contents still resolve.

---

## Step 5 — Report

List the docs touched and why:
`<doc>: <section> updated/created — reflects <change>`.
Flag any code change you intentionally did NOT document and why.
