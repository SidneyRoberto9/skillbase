#!/usr/bin/env bash
# develop → staging (homolog and/or config/zull-implementation) → main, pushing each step.
# Conflicts: -X theirs (the source wins). Never touches develop. Stops at the first failure.
set -u

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "PARADO — não é um repositório git"; exit 1; }
git remote get-url origin >/dev/null 2>&1 || { echo "PARADO — sem remote origin"; exit 1; }
git fetch -q origin --prune || { echo "FALHA fetch"; exit 1; }

on_origin() { git rev-parse --verify --quiet "refs/remotes/origin/$1" >/dev/null; }

for b in develop main; do
  on_origin "$b" || { echo "PARADO — origin/$b não existe"; exit 1; }
done
STAGING=""
for b in homolog config/zull-implementation; do
  if on_origin "$b"; then STAGING="$STAGING $b"; fi
done
[ -n "$STAGING" ] || { echo "PARADO — nenhuma branch de homologação (homolog, config/zull-implementation) no origin"; exit 1; }

CURRENT=$(git symbolic-ref --short HEAD 2>/dev/null || echo "")

# merge_into TARGET SOURCE: bring TARGET up to origin/TARGET, merge SOURCE, push.
# In place when TARGET is checked out here, otherwise in a temporary worktree.
merge_into() {
  local target=$1 src=$2 dir=. wt="" status=OK
  if [ "$target" != "$CURRENT" ]; then
    wt=$(mktemp -d)
    git worktree add -q "$wt" "$target" 2>/dev/null || { rm -rf "$wt"; echo "FALHA worktree: $target"; return 1; }
    dir=$wt
  fi
  if [ "$(git -C "$dir" rev-list --count "origin/$target..HEAD")" != 0 ]; then
    status=DIVERGIU   # local has commits not on origin (ahead or diverged): never push them
  elif ! git -C "$dir" merge -q --ff-only "origin/$target"; then
    status="FALHA ff"
  elif ! git -C "$dir" merge -q -X theirs --no-edit "$src"; then
    git -C "$dir" merge --abort 2>/dev/null
    status="FALHA merge"
  elif ! git -C "$dir" push -q origin "$target"; then
    status="FALHA push"
  fi
  [ -z "$wt" ] || git worktree remove --force "$wt"
  echo "$status: $target ← $src"
  [ "$status" = OK ]
}

for s in $STAGING; do merge_into "$s" "origin/develop" || exit 1; done
for s in $STAGING; do merge_into main "origin/$s" || exit 1; done
for b in develop $STAGING main; do echo "$b $(git rev-parse --short "origin/$b")"; done
