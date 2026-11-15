#!/bin/zsh
# Usage: t.sh <worktree> [test words...]. Runs the Gambeson suite there; kills it on a script error.
W=$1; shift
LOG=$W/../$(basename $W).test.log
cd $W
godot --headless --path . -s Tests/run.gd -- "$@" > $LOG 2>&1 &
P=$!
for i in {1..900}; do
  if ! kill -0 $P 2>/dev/null; then break; fi
  if grep -qE "Parse Error|Compile Error|Failed to load script|SCRIPT ERROR" $LOG; then sleep 1; kill $P 2>/dev/null; echo "KILLED: script error"; break; fi
  sleep 0.5
done
grep -E "Parse Error|Compile Error|Failed to load|SCRIPT ERROR|FAIL|String formatting|checks, " $LOG | head -60
