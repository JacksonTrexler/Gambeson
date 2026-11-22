# AI turn cost (w9-aiturn, 2026-11-22)
Goal: unit AI turn <=25 ms here (100 ms target), end_turn <=250 ms here (1000), `busy_fight.gd` digest unchanged (15v15 n=2: 47676114).
Files: Scripts/AI.gd, Battle.gd, Unit.gd, Perception.gd. No names made up.

## Baseline (15v15 n=2, M3, shared CPU)
unit turn mean 70.1 / p95 130; end_turn 241.7 / p95 565.

## Profile (inclusive, #PERF wrappers, removed)
read 28K calls 0.22 ms (6 s of 12 s); suspicious 308 x 7.4 ms; _look_harder 115 x 16; _line_up 126 x 8.6 (skill_range 22K calls, 1 s);
_approach/route 1.3 s; cast 133 x 10 ms; _sightings 90 x 7.5. Unit.stat memo (per-stretch plain-stat) tried: no gain, dropped.
Perception.unit per read ~0.3 ms: _seem .08 (brood loop), defense .05, insight .04, kit .04, _range .04, _levels .03.

## Done
1. `Battle.skill_reach` (skill_range less target part, same float ops); `_line_up` takes per-tile distance and per-skill reach once, foes' sizes once. 
2. `_look_harder`: reads in one stretch (broken around a doubt), reads passed to `_first_look` -> `suspicious(o, known)`.
3. `survey` passes (centre, reach) to `suspicious`: skips candidates it would filter out anyway.
Result 15v15 n=2: unit turn 61 (p95 100), end_turn 104 (p95 230), digest same.
4. `Unit._held_fx(viewer)`: a viewer that saw through none of the unit's timed effects shares the null view (one gather, not one per viewer). `Perception._seem`: returns a shared UNFRONTED factors dict when nothing fronts/broods.
5. `Unit.held(key)/hold(key, v)`: per-stretch memo kept with the effects (dropped with them: new stretch, or unit on another tile). Used by `Battle.skill_reach` (per skill) and `Battle.ambushes` (per target; checked against both cells, since the target may be the planner standing elsewhere).
6. Test `ai_tactics_test.test_planning_holds_and_bounds` (mutation: `>=` for `>` in suspicious's tile bound fails it; the unit-bound line is not covered, no unit hint at the boundary in the museum).

## Final (15v15 n=2, back-to-back A/B, M3 shared CPU)
| | before mean / p95 | after mean / p95 |
|---|---|---|
| unit turn ms | 68.4 / 124.8 | 58.8 / 96.3 |
| end_turn ms | 235 / 554 | 100 / 216 |
Target (x4): unit turn 235 (budget 100: still OVER), end_turn 403 (p95 865: within 1000).
busy_fight digest 47676114 before = after; ai_sim output diff empty; suite 10780 checks, 0 failed (1023 tests).

## Tried, dropped
- Unit.stat plain-value memo (no measurable gain: stat call count isn't the cost); `_line_up` footing-keyed reach cache (noise).
- Out-of-range foe skip in `suspicious`: only ~3% of its reads are in_range 0 in the sim (everyone is in sight).

## Next (not done)
- Per-read floor ~250 us in a stretch: `Unit.kit` (~45 us: actives/passives rebuilt via equipped()/items()/_sync_new per slot), `defense()` ~25, `_dim` ~25, `trickery` ~18. A unit-level cross-stretch cache needs a mutation version on Unit (timed/slots/items/hotbar edits have no single hook).
- `route()`/`_approach` (8 neighbours x line x dread tile reads, ~1 s of 9 s): memoize tile reads per stretch (callers might mutate a shared Read).
- `react()` asks every unit's `on_passives` per moment (~0.5 s); `_sightings` and `_first_look` after each travel read all 29 units again.
