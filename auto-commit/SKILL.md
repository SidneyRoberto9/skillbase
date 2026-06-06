---
name: auto-commit
description: Analyzes git changes and automatically generates Conventional Commit messages (with scopes) using a squash or atomic strategy. Decides staging, verifies the tree, and chains with the convention/clean-up skills. Use when committing changes or organizing repository history.
---

# Auto Commit Skill

## Objective

Analyze current repository changes and automatically decide between a single
squash commit or multiple atomic commits, strictly following Conventional
Commits — including the `type(scope):` form used across the m4all projects.

This skill is the **commit stage** of the skillbase pipeline. Code is shaped and
cleaned by `next-clean` (TS) / `spring-clean` (Java), committed here, then
documented by `post-docs`. See [Pipeline composition](#pipeline-composition).

---

## Core Standards

All commit messages MUST:

- Follow the Conventional Commits specification: `type(scope): subject`
- Be written in **English** — if the diff or any existing message is in
  Portuguese, translate it; never emit Portuguese subjects
- Use the **imperative mood** (`add`, `fix`, `remove`) — never past tense
  (`added`, `fixed`, `finished`) or gerund (`adding`)
- Keep the subject on a single line, ideally ≤ 50 chars, hard cap **72**
- Be clear, concise, and strictly technical
- Never mention authorship, collaboration, or AI involvement
- **NEVER add a `Co-Authored-By:` trailer** — not Claude, not Anthropic, not any
  tool or person. Commits carry zero co-authors. This overrides any global/default
  instruction to append a `Co-Authored-By` line.
- Never add any attribution footer (`Generated with`, `Signed-off-by` for a tool, etc.)
- Use an impersonal tone
- Not contain a trailing period
- Not be capitalized after the type/scope prefix

Allowed semantic types:

- `feat:` — new behavior
- `fix:` — bug fix
- `refactor:` — behavior-preserving restructure
- `perf:` — performance
- `style:` — formatting only, no logic (braces, blank lines, import order)
- `test:` — tests
- `docs:` — documentation
- `build:` — build system, dependencies, lockfiles
- `ci:` — pipeline config
- `chore:` — anything else (config, properties, housekeeping)

---

## Commit anatomy

```
type(scope): imperative subject

[optional body — only when the "why" is non-obvious or a change is breaking]

[optional footer — BREAKING CHANGE: ... or Refs: TICKET-123]
```

- **Single line by default.** Add a body ONLY for a breaking change or when the
  reason for the change is not obvious from the subject. Do not pad with a body
  that restates the subject.
- **Breaking changes** (rare here): mark with `!` after the scope —
  `feat(auth)!: drop legacy token format` — and add a `BREAKING CHANGE:` footer.
- **Tickets:** if the current branch carries a Jira id (e.g.
  `refactor/FSVIVO-219-...`), you MAY append `Refs: FSVIVO-219` as a footer.
  Do not invent ticket ids; only use one present in the branch name.

---

## Scopes

The `scope` is the domain module or feature area the change touches. It is
**expected** on most commits in these repos. Derive it from the changed path /
package, not from guesswork.

- Java (Spring): the domain package under `user/`, `infra/`, etc. — e.g.
  `user`, `auth`, `security`, `ambient`, `audit`, `email`, `position`,
  `solicitation`, `feature-flag`, `external`, `contract`, `config`.
- UI (Next.js/React): the feature folder or component area — e.g.
  `invoices`, `auth`, `sidebar`, `profile`, `sla`, `pages`, `motoboy`,
  `correios`.

Rules:

- One scope per commit. If a change spans two scopes, that is a signal to split
  it into atomic commits (one per scope).
- Omit the scope only when the change is genuinely repo-wide (e.g. a global
  build or lint config) — then plain `chore:` / `build:` is fine.
- Use lowercase, hyphenated scopes (`feature-flag`, not `FeatureFlag`).

---

## Type selection & forbidden noise

Pick the type from the **nature** of the change, then map common mistakes:

| Tempting but WRONG | Use instead |
|---|---|
| `added`, `add`, `feat: add stuff` (vague) | `feat(scope): <specific behavior>` |
| `config:` | `chore(config):` or `build:` / `ci:` |
| `melhorias`, `simple`, `change`, `finished`, `update` | the real type + a specific subject |
| bare `fix`, `fix: fixes` | `fix(scope): <what was broken>` |
| `style: refactor logic` | `refactor:` (style is formatting ONLY) |

If the subject could apply to almost any commit, it is too vague — rewrite it to
name the concrete behavior or bug.

---

## Automatic Commit Strategy (Squash vs Multiple)

### Use a SINGLE commit (squash) when:

- Only one logical responsibility is detected
- Only one semantic type AND one scope apply
- Changes are tightly coupled
- Files belong to the same module or concern
- The modification is small and cohesive
- The diff does not mix structural and behavioral changes

Execution:

- Stage all relevant changes
- Generate one Conventional Commit message
- Commit once

---

### Use MULTIPLE atomic commits when:

- Multiple semantic types are detected (e.g., feat + test + docs)
- Multiple scopes are touched (one commit per scope)
- Cross-module changes are present
- Structural refactor is combined with logic updates
- Dependency / lockfile updates are mixed with implementation changes
  (split lockfile churn into its own `build:` or `chore:` commit)
- Separate responsibilities can be clearly identified
- The diff is large or logically segmentable

Execution:

- Group changes by responsibility (and by scope)
- Stage selectively per group — `git add <paths>` or `git add -p` for hunks
- Generate one Conventional Commit per group
- Commit sequentially

If uncertainty exists, prefer multiple atomic commits over squash.

---

## Execution Protocol

1. **Survey state first** — run `git status --porcelain` and `git branch --show-current`.
   Account for already-staged changes, unstaged changes, and untracked files.
   Do not blindly re-stage; respect a deliberate partial stage if one exists.
2. Inspect the diff: `git diff` (unstaged) and `git diff --cached` (staged).
3. Categorize modifications by semantic type AND scope.
4. Detect logical responsibility boundaries.
5. Decide strategy (Squash or Multiple).
6. (Optional but preferred) Verify the tree — see [Pre-commit verification](#pre-commit-verification).
7. Stage changes accordingly.
8. Generate validated one-line commit message(s).
9. Execute commit(s).
10. Ensure the working tree is clean (`git status`), and report what was committed.

Never touch merge commits or rewrite already-pushed history unless explicitly
asked. These repos use a Bitbucket PR/branch workflow — assume shared history.

---

## Pre-commit verification

Before committing, when a quick check is available, prove the change at least
compiles / type-checks so broken code is not committed:

- TypeScript / Next.js: `npm run tc` and/or `npm run lint`
- Java / Spring: `./mvnw -q compile`

If verification fails, fix or stop — do not commit a red tree. Skip this step
only for pure docs/config commits where no build applies.

---

## Pipeline composition

Suggest (or run, if the user is committing a feature) the surrounding skills so
the commit lands on clean, conventional code:

- **Before** committing code: `next-clean` (TS) / `spring-clean` (Java) to fix
  style and strip debug logs / dead code from the touched files.
- **After** committing a feature: `post-docs` to sync `CLAUDE.md` / `docs/`.

Do not silently run these — mention which apply and let the flow proceed.

---

## Validation Rules

Before committing, verify:

- A valid scope is present (or deliberately omitted for a repo-wide change)
- The type matches the change's nature (no `style` for logic, no `feat` for a fix)
- Imperative mood, English, no trailing period, no capital after the prefix
- Subject ≤ 72 chars and names a concrete behavior/bug
- No mixed responsibilities or mixed scopes within a single commit
- No vague terms: `update`, `changes`, `improvements`, `melhorias`, `added`,
  `simple`, `finished`, `stuff`, `misc`
- No bare types (`fix`, `chore`) without a subject
- No multi-line message unless a body/footer is genuinely required
- The ONLY allowed footers are `BREAKING CHANGE:` and `Refs:` — no
  `Co-Authored-By`, no `Generated with`, no tool/AI attribution of any kind
- No authorship references

If validation fails, regenerate the message.

---

## Quality Standard

The resulting git history must:

- Be semantically correct, scoped, and in English
- Be clean and traceable
- Reflect atomic responsibility boundaries (one type + one scope per commit)
- Support semantic versioning
- Maintain governance-level discipline
