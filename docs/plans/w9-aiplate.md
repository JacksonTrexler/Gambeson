# w9-aiplate (2026-11-22)
Card: Deathlust log line; AI plate slot lapses as Power runs down; price sure_crit doubling in crit-loop forecast.
Files: Scripts/{Battle,HUD,AI}.gd, Tests/{deathlust,plating}_test.gd.
## Decisions
1. Log line: Battle.passive() now passes stat &"exhaustion" (amount 0) from neutralize()/_settle_wear(); HUD._on_passive logs "X's Deathlust eases its exhaustion" when stat is that (generic, no skill name), before the slot-flash early return; amount not shown (counts are floats, signal amount is int); no Overlay.face styling since no amount to round.
2. Plate lapse: hook `Behaviour.slot_works(holder, rank, spent := 0)` (+ `Unit.plate_works(s, spent)`, `Unit.power_share(spent)`; Power Armor override updated): Power as if `spent` more had gone, nothing taken. `AI._plated()` counts blocks (<= `AI.BLOCKS` = 3, a guess: blows before its holder rests) whose slot still works after the earlier blocks' tolls (BLOW each) and scales worth by blocks/BLOCKS. Own plates only (`_dress`); a foe's plates in `_blocks` not changed. Existing plating_test.test_ai_weighs_tolls value 3.0 -> 1.0 (Power Armor I at full Energy lapses after 1 block).
3. sure_crit: `AI.score()` glance line now `dmg *= (2 if sure_crit else 1) * (1-glance) + 0.5*glance` (as_rolled doubles a crit hit, a glance stays half). In score, not Forecast.per: the loop ratio (worth/plain) cancels a per-hit factor, so it prices every follow-up too. Test: chaser_test.test_forecast_counts_crit_loops (+1 check, a sure_crit vs same skill without).
## Done
1. log line + deathlust_test.test_log_line.
2. plate lapse + plating_test.test_ai_plate_lapses (table).
3. sure_crit + chaser_test check.
Mutations (each failed, reverted): no log (HUD) -> test_log_line; plate_works spent 0 -> test_ai_plate_lapses + test_ai_weighs_tolls; sure_crit factor 1.0 -> chaser check.
Test fix: deathlust test_log_line frees its HUD (else HUD._process hits the freed battle and the run is killed).
## Next
full suite, launch check, report.
