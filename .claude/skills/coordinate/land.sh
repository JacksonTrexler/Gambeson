#!/bin/zsh
# Usage: land.sh <branch> [<branch>...]. Lands finished builder branches on the integration branch.
# The first branch's worktree ($S/wt-<branch>) is the batch: main and the other branches merge into it,
# appended-section conflicts are kept on both sides (union.py), then verify.sh, then fast-forward, push,
# and remove every worktree and branch. Stops and says why on any failure. S (the session scratchpad) comes from
# the environment, else from the `S = ` line of brief-common.md beside this script.
set -u
H=${0:a:h}
MAIN=/Users/jtrex/projects/Gambeson
S=${S:-$(sed -n 's/^S = //p' $H/brief-common.md | head -1)}
[ -d "$S" ] || { echo "STOP: scratchpad S not found (set S=...)"; exit 1; }
[ $# -ge 1 ] || { echo "usage: land.sh <branch> [<branch>...]"; exit 1; }
INT=$(git -C $MAIN rev-parse --abbrev-ref HEAD)
B=$1; W=$S/wt-$B
[ -d $W ] || { echo "STOP: no worktree $W"; exit 1; }
[ -z "$(git -C $W status --porcelain)" ] || { echo "STOP: $W has uncommitted changes"; git -C $W status --short | head; exit 1; }
for src in $INT ${@:2}; do
  if ! git -C $W merge -q --no-edit $src; then
    CONF=($(git -C $W diff --name-only --diff-filter=U))
    REAL=()
    for f in $CONF; do
      case $f in
        (todo.md|docs/*.md|docs/*/*.md|Scripts/Glossary.gd|Scripts/Tags.gd) python3 $H/union.py $W/$f && git -C $W add $f ;;
        (*) REAL+=$f ;;
      esac
    done
    [ ${#REAL} -eq 0 ] || { echo "STOP: real conflicts merging $src into $B: $REAL (send back to the builder)"; exit 1; }
    git -C $W commit -q --no-edit || { echo "STOP: merge commit of $src failed"; exit 1; }
    echo "merged $src (appended sections kept both sides: $CONF)"
  else
    echo "merged $src"
  fi
done
OUT=$(caffeinate -dims $H/verify.sh $W 2>&1); echo "$OUT" | tail -12
echo "$OUT" | grep -q " checks, 0 failed" || { echo "STOP: verify did not pass"; exit 1; }
echo "$OUT" | grep -q "check FAILED" && { echo "STOP: a tool check failed"; exit 1; }
[ -z "$(git -C $MAIN status --porcelain --untracked-files=no)" ] || { echo "STOP: main tree has uncommitted edits (user or another session)"; exit 1; }
git -C $MAIN merge --ff-only -q $B || { echo "STOP: not a fast-forward (main moved); rerun"; exit 1; }
git -C $MAIN push -q origin $INT || { echo "STOP: push failed"; exit 1; }
echo "landed $(git -C $MAIN log --oneline -1)"
for b in $@; do
  git -C $MAIN worktree remove --force $S/wt-$b 2>/dev/null
  git -C $MAIN branch -q -D $b 2>/dev/null   # merged: its tip is in $INT now
done
echo "removed: $@"
