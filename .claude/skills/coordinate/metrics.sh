#!/bin/zsh
# Usage: metrics.sh <branch> <model> <effort> <subagent_tokens> <tool_uses> <duration_ms> <result>
# Appends one line per finished delegate to docs/agents/metrics.csv (in the tree you run it from, or $CSV).
# The numbers come from the task notification (its <usage> block), so no timer agent is needed.
set -u
[ $# -eq 7 ] || { echo "usage: metrics.sh <branch> <model> <effort> <tokens> <tool_uses> <duration_ms> <result>"; exit 1; }
CSV=${CSV:-$(git rev-parse --show-toplevel)/docs/agents/metrics.csv}
mkdir -p ${CSV:h}
[ -f $CSV ] || cat > $CSV <<'H'
# One line per finished delegate (builder, docs keeper, floater). Written by .claude/skills/coordinate/metrics.sh.
# tokens, tool_uses and duration_ms come from each task notification's <usage>; the user suggested haiku-low timer
# agents, but notifications already carry these numbers, so timers are optional. result: landed, blocked, dropped.
date,branch,model,effort,subagent_tokens,tool_uses,duration_ms,result
H
echo "$(date +%F),$1,$2,$3,$4,$5,$6,$7" >> $CSV
tail -1 $CSV
