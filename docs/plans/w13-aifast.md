# AI fast turns (w13-aifast, 2026-11-23)
Goal (the user: "raise the budget provided players dont actually spend time waiting for large factions"; 20/80 shortcuts OK; AI decisions may change):
follower fast path; overlap planning with animation; cheap far-from-foe routine if measured; measure player-perceived wait 15 / 30-unit side turns (M3 x4) before/after;
busy_fight digest pin -> outcome checks; raise budget only as far as measured.
Base = origin/main daf5c1d.

## Readings
- HUD `_act_alone`: `together` (default true) runs AI.act for EVERY unit in ONE frame (no await between units), then waits out walks. So a side's whole AI time is one frozen frame: the player-perceived wait. pace > 0 only when watched; tests use pace 0 (sync).
- Leaders: `Unit.follows` (Command.join: player's party; Battle 637). AI factions have none today; busy_fight has none.
- Skill to command: `Command.cha_of(l)` (cha mod + command_mod); at +0 or below "it can only be told to move".

- end_turn at 30v30 (here): next side's `_look_harder` in the turn setter ~220 ms; body ~60-110 (`_watch` loop 30-48, `tick` 28, `_check_stall` 28).
- Walk feedback is short (Overlay.STEP_TIME 0.07 s/tile); a used skill's number shows 0.9 s.

## Calls
- Skilled leader = `Command.cha_of(l) > 0` (cha mod + command_mod; Command's own line: at +0 a leader "can only tell it to move").
- Calm follower (`AI._calm`): `follows` set, same faction (a poser keeps its own path), leader alive, not stopped, skilled, `Command.hears(l, u)` (covers Disturbed either end and party reach) and `read(u, l).located()`.
  Not calm: hurt since its last act (meta `calm_hp`, written by `AI.act`: AI-private, no Unit var, keeps Unit.gd clear of the w13-invest merge), Downed, channeling, `Unit.behaviour` set (skittish/recovering/undine/craven: natures, not preferences), restless, cc (`afflicted(&"cc")`), held or holding, betrayed = `last_hit_by` is its own side, its party or its leader.
- Drill (`AI._drill`): reads only units within move_left + longest reach + DRILL_MARGIN 2 (and the leader); `_remember`, `_heal`, strike, else walk on the leader's aim (meta `aim`: set by `_strike` casts and the full turn's approach target; generic "what it went after"), else its own `_best_target`, else `_keep_up`; strike loop. Skips temper, tends' tending, support, summon, line_up, steady, starve, dress, search/scry/hunt, switch, replenish. Healers keep `_heal` (a role, not a preference).
- Frame per unit (HUD `_act_alone`, together, pace > 0): `await process_frame` after each act: walks/numbers show while the next plans. Same decisions (sync in tests: pace 0).
- Opening looks lazy (`Battle.lazy_looks`, set by HUD when pace > 0; never the player's side): the setter queues them; `_act_alone` takes one a frame over the 1 s turn change (`_wait(work)`); a unit still owing one takes it as it acts (`AI.act` -> `looks_done(u)`); `end_turn` flushes. Decision change: a late unit's look comes after earlier ones acted.
- end_turn under the last walks (HUD, pace > 0): `_act_alone` calls `battle.end_turn()` before waiting out pace and walks; `_on_turn` waits `_closing` so the turn change shows after them; `busy` stays on (no input). `ended` guards a second end_turn (one-side order).
- Far-from-foe routine: not built. The drill already covers followers with no foe near (keep up); for leaders/loners the 15/30 sims start 12 tiles apart and close in by round 2, so no measurable share (w9: ~3% of reads out of range).
- Digest pin dropped: busy_fight prints "OUTCOME ok|FAIL" (each fight: >= size/3 fall, someone left standing, no unit alive at the end that never moved or acted). Other docs naming 3296533323 (todo.md, queue.md, todo/systems.md) are not mine to edit: the docs keeper should retire ?245.
- Suite: no test pinned AI output the fast path changed (10969 checks before and after the AI change; followers are rare in tests).

## Measure (busy_fight `lead`: parties of 5 in 3x2 blocks, leader cha 14; n=2, rounds 10; M3, x4 = target)
Wait model (`busy_fight` "side wait"): stare = time on the target with no walk or number showing while the side computes.
One frame (old HUD): a side's acts + end_turn (+ the next side's looks, in its setter) in one frame = all stare.
Frame per unit (new): acts in order; an act starting while an earlier walk (tiles x 0.07 s) or number (0.9 s) still shows is covered up to that end (a stutter, not a stare); looks one a frame over the 1 s turn change, the rest inside each act; end_turn covered by the last feedback.

### Results (A/B x2 interleaved, `S/ab-w13.sh`, base = daf5c1d + this busy_fight; target ms = M3 x 4)
Before = base AI, old HUD (one frame). After = this branch, new HUD (frame per unit).
| side turn, player stare (target) | before mean / p95 | after mean / p95 |
|---|---|---|
| 15 a side (lead) | 1190 / 2800 | 218 / 737 |
| 30 a side (lead) | 4300 / 9800 | 776 / 3210 |
| 15 a side (no parties) | 1162 / 2755 | 136 / 665 |
After, 30 a side, mean stare split: acts 580, end_turn 188 (rounds 1-2 are the p95: acts ~0.3 s each, walks 0.07 s/tile cover little).
CPU: unit turn (lead) 15: 132 -> 113 ms target; 30: 213 -> 194 (drill on ~43% of acts). end_turn 15: 219 -> 152; 30: 870 -> 396 (looks moved out). No parties: unit turn 132 -> 130, same outcome (fallen 28.0 both).
Fights with parties end a little bigger (more acts a side turn: 9.4 vs 7.3 at 15), so one-frame totals per side are not lower; per act they are.
- Budget call: `busy_fight.TURN_BUDGET_MS` 100 -> 200 (a unit plans in its own frame while earlier walks/numbers show; a 3-tile walk is 0.21 s). 15v15 mean 113-130 within, p95 ~220 still over. New side stare budget = SIDE_BUDGET_MS 1000: 15 within, 30 OVER at p95 (3.2 s; mean 0.78 s within).

## Done
1. busy_fight: `lead`, wait model + breakdown, OUTCOME checks, `debug` per-turn stare. (commit 2)
2. AI `_calm`/`_drill`, act wrapper (`_full`), HUD frame per unit, lazy looks, end_turn under walks. Suite 10969 / 0 / 1032. (6484404)
3. Test `ai_tactics_test.test_calm_followers_drill` (calm table: unskilled, hurt, cc, leader down, out of reach, struck by leader, Restless; stoic follower drills when calm, holds when hurt; owed looks taken at own act). Mutations, all caught: hurt check off, cc off, betrayed off, `<= 0` -> `< 0`, drill never taken, hears off, act skipping `looks_done(u)`.
4. Budget 200 ms, side stare reported against 1000 ms. Suite 10989 checks, 0 failed (1033 tests). skill.py check ok; launch log clean (8 resources only).
## Next (not done)
- 30-a-side p95: round 1-2 acts (~300 ms target each) outlast the walks before them. Levers: `_check_stall` nearest-pair first (exact, ~28 ms here a turn), tick loop (28), `_watch` (30); drill for leaderless units far from foes.
- Visual check not taken (timing only, no layout change).
