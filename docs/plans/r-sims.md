# Big sims: 10 Rangers hunting 10 hiders, and busy 15v15 / 20v20 fights (r-sims, 2026-11-16)

Branch `r-sims`. The user's brief (testing is on an M3 Mac; test scenes may assume a device 4x stronger than a consumer target; larger
zoomed-out scenes for non-deterministic hunting mechanics; "fairly busy fights under some circumstances"). No names made up, so no ` ??`.

## What is built (as built)
All outside the suite (`Tests/run.gd` reads only `Tests/*_test.gd`), run like `ai_sim.gd`:
- `Tests/sims/field.gd` (shared, not a test): the museum's battle emptied and re-laid as an open grass field of any size, sight on, plus
  `add(side, role, cell, nick, skills)` (a level 1 class unit, up to N open skills of its tree learned and given bar room) and `play(side)` (each unit
  acts by `AI.act`, the turn ends; returns each act's microseconds and the end_turn's). Per-process save/settings files as `ai_sim.gd`.
- `Tests/sims/hunt_10v10.gd`: `godot --headless --path . -s Tests/sims/hunt_10v10.gd -- [still|moving] [n=8] [rounds=20] [wis=16] [debug]`.
- `Tests/sims/busy_fight.gd`: `godot --headless --path . -s Tests/sims/busy_fight.gd -- [15|20 ...] [n=2] [rounds=10] [skills=4] [debug]`.
- `Tests/sims_test.gd` (the suite): one smoke test, 3v3 on a 24 x 12 field, one round of AI turns, 557 ms, 3 checks.
- `Scripts/Perception.gd`: `_seem` (see "Profile").

### Hunt: 10 Rangers seek 10 hiders (60 x 40 field, n = 8 seeds, cap 20 rounds)
Rangers (Ranger role, wisdom 16, Observe learned) start in a column at x 2-4, spread over the height; ten hiders (Rogue role with Hide) are placed at random
in x 12-57. Each hider was seen once where it stood (the Rangers' side holds that sighting, as `ai_sim.gd`'s hunt), cast Hide (debris), stepped up to 2 tiles
and hides under one shared concealment 7 for the whole run; `moving` hiders step 2 tiles again each round. The Rangers act by the AI; the hiders only hide.
A hider is found when some Ranger's read of it is `located()`, checked after the Rangers' turn each round.

| mode | find rate (of 10) | round of first find | round of last find | mean round found | wall time |
|---|---|---|---|---|---|
| still | 0.56 | 12.25 | 18.75 | 14.61 | 36.8 s a seed |
| moving | 0.39 | 13.00 | 17.38 | 14.89 | 37.5 s a seed |

Per seed, found of 10 / first / last: still 2/12/16, 7/12/20, 7/11/20, 7/13/18, 2/12/19, 6/12/18, 8/13/20, 6/13/19; moving 3/13/17, 6/14/19, 4/12/18, 2/13/17,
2/13/15, 4/13/18, 5/13/20, 5/13/15. Read: the first find never comes before round 11: the Rangers spend ten rounds walking (about 3-4 tiles a round, `debug`
shows their x) to where their side last saw the hiders, then Observe. Moving hiders are found about a third less often in 20 rounds (0.39 vs 0.56), as
`ai_sim`'s `hunt-moving` vs `hunt-still`. Ten hiders under cover 7 are never all found in 20 rounds (best seed 8/10). Not tuned; this is the measurement.

### Busy fights: 15v15 and 20v20 (32 x 26 field, 12 tiles apart, n = 2 fights, 4 skills each, level 1, 12 classes mixed)
Units: fighter, ranger, mage, cleric, rogue, bard, berserker, paladin, druid, warlock, wizard, sorcerer in turn (the second side starts three classes
along), each with up to 4 open skills of its tree on the bar. Both sides know where the other stood (the battle's start does this). They fight by the AI
until a side falls or 10 rounds (15v15: 8 rounds, 3.5 left of the winners; 20v20: 10 rounds, 0.5 v 2.0 left).

Target = M3 time x 4 (the user's call). Budgets on the target, my calls: a unit's AI turn 100 ms (a visible hitch; the HUD paces units 450 ms apart, so a
side's whole turn has no budget), a side's `end_turn` 1000 ms (a freeze). Both are compared at p95 and max.

| | here (M3) mean / p95 / max ms | target (x4) mean / p95 / max ms | verdict |
|---|---|---|---|
| 15v15 unit AI turn (n=257) | 83.6 / 268 / 440 | 335 / 1073 / 1760 | OVER (budget 100) |
| 15v15 turns that used a skill (n=113) | 96.8 / 307 / 440 | 387 / 1227 / 1760 | OVER |
| 15v15 side end_turn (n=32) | 183 / 625 / 630 | 731 / 2499 / 2521 | OVER (budget 1000; mean within) |
| 15v15 side turn, acts + end_turn (n=32) | 854 / 2004 / 2016 | 3417 / 8015 / 8063 | no budget |
| 20v20 unit AI turn (n=397) | 102.7 / 318 / 468 | 411 / 1273 / 1870 | OVER |
| 20v20 turns that used a skill (n=183) | 109.1 / 360 / 458 | 436 / 1441 / 1830 | OVER |
| 20v20 side end_turn (n=40) | 356 / 1352 / 1376 | 1422 / 5407 / 5503 | OVER |
| 20v20 side turn (n=40) | 1375 / 3813 / 4086 | 5500 / 15251 / 16342 | no budget |

Far over: a mean AI turn is 3-4x the budget on the target and the p95 ten times it. The heaviest turns are the early rounds with every unit in sight of the
others (round 1 of 15v15 costs 4.2 s here, round 9 with two left 0.1 s). Before the `_seem` fix below, 15v15 (n=1): mean 99.7 / p95 311 / max 516 ms, end_turn
mean 227 ms (so the fix took about 16% off a unit turn and 20% off end_turn).

Frames: headless has none. Run the script with a window (drop `--headless`) and it awaits a frame after each unit and prints the frame times ("frame (one
unit's turn, rendered)", against the same 100 ms budget): an AI turn is one frame's work, so its hitch is that frame's length. Not run here (no display in
this session).

### Profile (the profiling-godot note: temporary `#PERF` wrappers over the functions, an accumulator by name; removed with `git checkout Scripts`)
15v15, one fight, before any fix, inclusive times (here, ms; the instrumented run is about 10% slower):
- `Battle.read()`: 29,493 calls, 0.33 ms each, 9.6 s of the run's ~17 s. About 215 reads per unit turn. Who asks: `suspicious()` 7,136 reads (it reads every other unit,
  from `_watch` at turn's end and the AI's clues), the AI's own `reads` at the start of each act 2,968, `travel()` 2,558, `end_turn`'s `_watch` 1,774,
  `_approach` 12,321 tile reads (0.065 ms each), `_line_up` 783.
- Inside a read, `Perception._seem` was about half: it asked `Unit.stat(&"brood")` of every unit on the field, foes included, for every read (185,000 stat
  calls from `_seem` in one fight, 1.65 M `Unit.stat` calls in all, each looping the unit's effects).
- AI turn phases (calls x ms each): `_line_up` 137 x 28 (3.9 s, the biggest: foresee from every tile in reach), `travel` 103 x 26, `_approach` 103 x 13.5, `_hunt` 19 x 54,
  `_strike` 389 x 6, `suspicious` 341 x 12, `_watch` 135 x 9.8. `_search`/`clues` are small (3 calls, 37 ms each).

Fix made (contained, same result): `Perception._seem` now skips units not on t's own side before asking their Brood (only t's own side's Brood counts), so
a stat read isn't spent on every foe. `persona_test.test_brood` catches it (mutation: inverting the faction test fails "an adjacent ally seems 10% lower too").
Not fixed, on the AI's decisions or too wide to be contained: `_line_up`'s foresee over every reachable tile; `read()` called pairwise several times a turn (a cache of
a unit's reads across one act, or `suspicious()` reusing the act's `reads` and skipping units beyond every viewer's range, would take most of the 215 reads; reads
need to be invalidated by any state change, so it isn't a small edit); a Brood-free fast path in `Unit.stat` (a unit with no `brood` effect answers 0 without
looping its effects); `travel`/`_approach` route planning. These are the next steps if the target hardware can't carry a 15v15.

## Calls (every judgement, for review)
1. **Where**: the museum's own battle scene as the base (tile set, terrain, rules) with its units freed and the map re-laid as grass, not Meadows: Meadows needs a
   party, streams chunks and spawns demons; a plain field isolates the AI. Plain grass has no brush, so the only cover is the hiders' own concealment.
2. **Rangers** are the Ranger role with Observe learned and wisdom set to 16 (as `ai_sim.gd`'s observer; the role's 13 is a level 1 value). Hiders are Rogues with Hide,
   not Rangers: the Rangers' side must not be the hiders'. Hiders do not act (no AI), as in `ai_sim.gd`; they re-take the shared concealment each round and step in `moving`.
3. **Found** = some Ranger's read is `located()` after the Rangers' turn (not the whole side's knowledge): the same test `ai_sim.gd` uses.
4. **Defaults**: n = 8 seeds, 20 rounds, 60 x 40; the hunt takes about 10 minutes for both modes (37 s a seed on the M3), so say `still n=4` for a quick look. The
   busy default is n = 2 fights (about 100 s for both sizes): a fight is the same each seed apart from the dice and the start of the Rangers' column, and a stable mean
   needs few.
5. **Busy budgets** (100 ms a unit turn, 1000 ms an end_turn on the target; no budget for a whole side's turn, paced) are mine; the user gave only the factor 4.
   Both are constants at the top of `busy_fight.gd`.
6. **Units get `skills` = 4 open skills each, level 1** (`field.add`): the AI's cost grows with what a unit has; level 1 with its innate skills alone would flatter it.
   A real level 10 party has more, so these numbers lean low.
7. **The suite**: one smoke test (`Tests/sims_test.gd`, 3v3, one round, 557 ms) because the field builder is shared and a change to Battle/Unit that breaks it should
   show in the suite, not when someone runs a sim. The sims themselves stay out (10 minutes, 100 s).
8. **Script load order**: a sim's script must not name `Role` (or `Branch`, or `Effect` before `Test`) as a type before it names `Test`: the scripts load in a cycle
   and `Role.gd` fails to compile with a hang (the sim hangs, headless). Hence `var _first: Test` at the top of both sims and `Resource`/`Variant` types for roles and
   the field helper (loaded at run time by path). `field.gd` has no `class_name` for the same reason.
9. **One `Scripts/` change**, `Perception._seem` (contained, no decision touched), with the suite as its test; I did not add a test of its own (`test_brood` covers it).

## Tests and mutation spot-checks
- `Tests/sims_test.gd` `test_field_round`: mutation, `play()` not calling `AI.act`: fails "and they went for the foes they were told of".
- `persona_test.test_brood` against the `_seem` change: inverting the side test fails it.
- Suite: final line `8622 checks, 0 failed (924 tests)`; the start was 8619 checks (923 tests), so these are the 3 checks of the one new test.
- `python3 Util/skill.py check` ok; `godot --path . --quit-after 120` only the known "6 resources still in use at exit".

## Undone
- Frame times are untested here (no display); the windowed path in `busy_fight.gd` is written, not run.
- The AI's cost: a 15v15's unit turn is 3-4x the budget on the target; the fixes above are not made.
- A hunt where the rangers start close (they spend ~10 rounds walking, so the find rounds mostly measure walking); a variant with hiders in range from round 1 would
  measure the search itself.
