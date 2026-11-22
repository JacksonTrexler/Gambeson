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
