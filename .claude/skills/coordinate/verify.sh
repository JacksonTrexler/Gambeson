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
[ -x $H/t.sh ] || { echo "SUITE NOT RUN: $H/t.sh is missing"; exit 1; }
OUT=$($H/t.sh $W); echo "$OUT" | tail -15
echo "$OUT" | grep -q " checks, 0 failed" || { echo "SUITE DID NOT PASS (no '0 failed' line)"; exit 1; }
godot --path . --quit-after 120 > $L/launch-$N.log 2>&1
grep -E "ERROR|SCRIPT ERROR" $L/launch-$N.log | grep -v "resources still in use at exit" | head -5
echo "launch done"
