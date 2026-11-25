#!/usr/bin/env bash
# Self-check for merge.sh against throwaway repos. Usage: bash test.sh
set -u
MERGE="$(cd "$(dirname "$0")" && pwd)/merge.sh"
ROOT=$(mktemp -d)
trap 'rm -rf "$ROOT"' EXIT
FAILS=0

ok() {
  if eval "$2"; then echo "PASS: $1"; else echo "FAIL: $1"; FAILS=$((FAILS + 1)); fi
}

# make_repo STAGING: bare origin ($O) + clone (cwd). main, develop and STAGING
# each change f.txt from the same base, so both hops of the chain conflict.
make_repo() {
  T=$(mktemp -d -p "$ROOT")
  O="$T/origin.git"
  git init -q --bare "$O"
  git clone -q "$O" "$T/repo" 2>/dev/null
  cd "$T/repo" || exit 1
  git config user.email t@t && git config user.name t && git config commit.gpgsign false
  echo base > f.txt && git add f.txt && git commit -qm base && git branch -M main
  if [ -n "$1" ]; then git checkout -qb "$1" main && echo staging > f.txt && git commit -qam staging; fi
  git checkout -qb develop main && echo develop > f.txt && git commit -qam develop
  git checkout -q main && echo main > f.txt && git commit -qam main
  git push -q origin --all 2>/dev/null
  DEV=$(git rev-parse develop)
  MAIN=$(git rev-parse main)
}

# expect_ok NAME STAGING START: chain succeeds, develop wins on staging and main.
expect_ok() {
  N=$1 S=$2 START=$3
  make_repo "$S"
  [ "$START" = "$S" ] || git branch -qD "$S"   # local staging absent: worktree must create it
  git checkout -q "$START"
  OUT=$(bash "$MERGE" 2>&1); RC=$?
  ok "$N: exit 0" '[ $RC -eq 0 ] || { echo "$OUT"; false; }'
  ok "$N: develop wins on $S" '[ "$(git -C "$O" show "$S:f.txt")" = develop ]'
  ok "$N: develop wins on main" '[ "$(git -C "$O" show main:f.txt)" = develop ]'
  ok "$N: main contains $S" 'git -C "$O" merge-base --is-ancestor "$S" main'
  ok "$N: develop untouched" '[ "$(git -C "$O" rev-parse develop)" = "$DEV" ]'
  ok "$N: still on $START, clean, no leftover worktree" \
    '[ "$(git symbolic-ref --short HEAD)" = "$START" ] && [ -z "$(git status --porcelain)" ] && [ "$(git worktree list | wc -l)" -eq 1 ]'
}

expect_ok homolog homolog develop
expect_ok in-place homolog homolog
expect_ok legacy config/zull-implementation develop

# No staging branch on origin: stop before touching anything.
make_repo ""
OUT=$(bash "$MERGE" 2>&1); RC=$?
ok "no staging: exit 1" '[ $RC -eq 1 ]'
ok "no staging: main untouched" '[ "$(git -C "$O" rev-parse main)" = "$MAIN" ]'

# Local homolog diverged from origin: chain stops, homolog and main untouched.
make_repo homolog
HOM=$(git rev-parse homolog)
git checkout -q homolog && git reset -q --hard main~1 && echo x > g.txt && git add g.txt && git commit -qm local
git checkout -q develop
OUT=$(bash "$MERGE" 2>&1); RC=$?
ok "diverged: exit 1" '[ $RC -eq 1 ]'
ok "diverged: homolog and main untouched" \
  '[ "$(git -C "$O" rev-parse homolog)" = "$HOM" ] && [ "$(git -C "$O" rev-parse main)" = "$MAIN" ]'

# Local main ahead of origin (unpushed commit): nothing may be pushed to main.
make_repo homolog
git checkout -q main && echo wip > w.txt && git add w.txt && git commit -qm wip
git checkout -q develop
OUT=$(bash "$MERGE" 2>&1); RC=$?
ok "ahead: exit 1" '[ $RC -eq 1 ]'
ok "ahead: unpushed commit stays local" '[ "$(git -C "$O" rev-parse main)" = "$MAIN" ]'

[ "$FAILS" -eq 0 ] && echo "ALL PASS" || { echo "$FAILS FAILED"; exit 1; }
