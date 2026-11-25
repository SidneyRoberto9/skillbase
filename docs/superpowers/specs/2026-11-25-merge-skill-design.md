# /merge skill (replaces /zull-merge) — design

## Intent

The staging branch `config/zull-implementation` is renamed to `homolog` in
eleva-management-api and eleva-management-ui. The propagation skill is renamed
from `zull-merge` to `merge` and becomes a chain: `develop → staging → main`.

## Goals

- Rename the branch on origin and locally in both repos (create `homolog` from
  `origin/config/zull-implementation`, delete the old remote branch, rename the
  local branch and its upstream).
- Skill `merge`: staging = every existing branch among `homolog` and
  `config/zull-implementation`, so projects that were not renamed still work.
- Required on origin: `develop`, `main`, and at least one staging branch.
  Otherwise stop before any merge or push.
- Merge `origin/develop` into each staging branch and push, then merge each
  staging branch into `main` and push. Sequential, because `main` depends on
  staging.
- Conflicts resolved with `-X theirs` (the source wins). If a staging branch
  fails, `main` is not touched.

## Non-goals

- Never touch `develop`. No commit or push of the skillbase repo unless asked.
- Updating the external deploy that may track `config/zull-implementation`
  (user's responsibility).

## Approaches

- Chain develop → staging → main (chosen: matches "main coming from those").
- Parallel develop → staging and develop → main (old behavior, rejected).

## Verification

Run the skill's script against a throwaway bare repo with `develop`, `homolog`
and `main` before installing it into `~/.claude/skills/merge`.
