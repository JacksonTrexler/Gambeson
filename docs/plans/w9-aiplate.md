# w9-aiplate (2026-11-22)
Card: Deathlust log line; AI plate slot lapses as Power runs down; price sure_crit doubling in crit-loop forecast.
Files: Scripts/{Battle,HUD,AI}.gd, Tests/{deathlust,plating}_test.gd.
## Decisions
1. Log line: Battle.passive() now passes stat &"exhaustion" (amount 0) from neutralize()/_settle_wear(); HUD._on_passive logs "X's Deathlust eases its exhaustion" when stat is that (generic, no skill name), before the slot-flash early return; amount not shown (counts are floats, signal amount is int); no Overlay.face styling since no amount to round.
## Done
1. log line + deathlust_test.test_log_line.
## Next
2, 3.
