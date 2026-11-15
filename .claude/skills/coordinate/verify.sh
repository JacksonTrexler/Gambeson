#!/bin/zsh
# Usage: verify.sh <worktree>. The merge gate: Util checks, a fresh import, the full suite, a launch check.
# Logs go beside the worktree (its parent directory). Run it under `caffeinate -dims`.
W=${1:a}; H=${0:a:h}; N=$(basename $W); L=${W:h}
cd $W
for t in skill mechanic role unit icon item tile; do
  [ -f Util/$t.py ] || continue
  python3 Util/$t.py check > /dev/null 2>&1 && echo "$t check ok" || { echo "$t check FAILED"; python3 Util/$t.py check 2>&1 | tail -5; }
done
godot --headless --path . --import > $L/import-$N.log 2>&1
$H/t.sh $W | tail -15
godot --path . --quit-after 120 > $L/launch-$N.log 2>&1
grep -E "ERROR|SCRIPT ERROR" $L/launch-$N.log | grep -v "resources still in use at exit" | head -5
echo "launch done"
