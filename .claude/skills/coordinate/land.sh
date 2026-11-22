#!/bin/zsh
# Usage: land.sh <branch> [<branch>...]. Lands finished builder branches straight on origin/main, from worktrees.
# The first branch's worktree ($S/wt-<branch>) is the batch: origin/main and the other branches merge into it,
# appended-section conflicts are kept on both sides (union.py), then verify.sh, then `git push origin HEAD:main`
# (fast-forward only, never forced). A rejected push (someone landed first) means fetch, merge, re-verify, retry
# (up to 3 times). Never writes in the main tree (/Users/jtrex/projects/Gambeson): the user and other sessions work there.
# Afterwards the batch's worktrees and local branches are removed; no remote branch is ever deleted.
# Stops and says why on any failure. S (the session scratchpad) comes from the environment, else from the
# `S = ` line of brief-common.md beside this script.
set -u
H=${0:a:h}
MAIN=/Users/jtrex/projects/Gambeson
S=${S:-$(sed -n 's/^S = //p' $H/brief-common.md | head -1)}
[ -d "$S" ] || { echo "STOP: scratchpad S not found (set S=...)"; exit 1; }
[ $# -ge 1 ] || { echo "usage: land.sh <branch> [<branch>...]"; exit 1; }
B=$1; W=$S/wt-$B
[ -d $W ] || { echo "STOP: no worktree $W"; exit 1; }
for b in $@; do
  [ -z "$(git -C $S/wt-$b status --porcelain)" ] || { echo "STOP: wt-$b has uncommitted changes"; git -C $S/wt-$b status --short | head; exit 1; }
done
merge_in() {   # merge_in <src>: merge into the batch worktree, unioning appended docs
  local src=$1
  if ! git -C $W merge -q --no-edit $src; then
    local CONF=($(git -C $W diff --name-only --diff-filter=U)) REAL=() f
    for f in $CONF; do
      case $f in
        (todo.md|docs/*.md|docs/*/*.md|Scripts/Glossary.gd|Scripts/Tags.gd) python3 $H/union.py $W/$f && git -C $W add $f ;;
        (*) REAL+=$f ;;
      esac
    done
    [ ${#REAL} -eq 0 ] || { echo "STOP: real conflicts merging $src into $B: $REAL (send back to the builder)"; return 1; }
    git -C $W commit -q --no-edit || { echo "STOP: merge commit of $src failed"; return 1; }
    echo "merged $src (appended sections kept both sides: $CONF)"
  else
    echo "merged $src"
  fi
}
for b in ${@:2}; do merge_in $b || exit 1; done
for try in 1 2 3; do
  git -C $W fetch -q origin || { echo "STOP: fetch failed"; exit 1; }
  merge_in origin/main || exit 1
  OUT=$(caffeinate -dims $H/verify.sh $W 2>&1); echo "$OUT" | tail -12
  echo "$OUT" | grep -q " checks, 0 failed" || { echo "STOP: verify did not pass"; exit 1; }
  echo "$OUT" | grep -q "check FAILED" && { echo "STOP: a tool check failed"; exit 1; }
  if git -C $W push -q origin HEAD:main; then
    echo "landed $(git -C $W log --oneline -1) on origin/main"
    for b in $@; do
      git -C $MAIN worktree remove --force $S/wt-$b 2>/dev/null
      git -C $MAIN branch -q -D $b 2>/dev/null   # its tip is in origin/main now
    done
    echo "removed: $@"
    exit 0
  fi
  echo "push rejected (origin/main moved): fetch, merge, re-verify (try $try)"
done
echo "STOP: push rejected 3 times"; exit 1
