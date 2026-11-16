#!/bin/zsh
# Runs the AI sim with one constant at each value in turn: Tests/sims/sweep.sh CONSTANT "v1 v2 v3" [sim args...]
# (e.g. SUSPICIOUS "0.5 1 2" hunt n=10). The constant is edited in Scripts/AI.gd or Scripts/Battle.gd and put back after.
# Only `const NAME := number` lines. Prints the SIM lines for each value, headed "== CONSTANT value".
C=$1; VALUES=(${=2}); shift 2
cd "${0:A:h}/../.."
F=$(grep -lE "^const ${C} :=" Scripts/AI.gd Scripts/Battle.gd | head -1)
[ -z "$F" ] && { echo "no const $C"; exit 1; }
cp "$F" "$F.sweep"
trap 'mv "$F.sweep" "$F"' EXIT INT TERM
for v in $VALUES; do
	cp "$F.sweep" "$F"
	sed -i '' -E "s/^(const ${C} := )[-0-9.]+/\1${v}/" "$F"
	echo "== $C $v: $(grep -E "^const ${C} :=" "$F" | cut -c1-40)"
	caffeinate -dims godot --headless --path . -s Tests/sims/ai_sim.gd -- "$@" 2>&1 | grep -E "^SIM|SCRIPT ERROR|Parse Error"
done
