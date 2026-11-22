# AI turn cost in busy fights (r-aiperf, 2026-11-16)

Branch `r-aiperf`. Goal (the user): "fairly busy fights under some circumstances" must fit the budgets `Tests/sims/busy_fight.gd` sets (100 ms a unit turn, 1000 ms an
end_turn on the target = M3 x 4) without changing what the AI decides. No names made up, so no ` ??`.

## Reading (profile, 15v15, n=1, temporary #PERF wrappers, removed)
- `Battle.read()` was 55% of the run (28,507 calls, 0.27 ms); inside a read most was `Unit.stat()` (1.3 M calls a fight): each call looped every effect of the unit
  (`e.stat != s` on a String against a StringName), expanded the query's tags, and `_effects()` re-gathered the unit's effect list on every call outside a read
  (590 K gathers). `Unit._effects()` already held the list for one `Battle.read()`; nothing held it across the dozens of reads a loop makes.
- Big callers: `suspicious()` (reads every unit; from `_first_look` at each unit's turn start and from `_watch`), the AI's initial reads, `_sightings` (travel),
  `_line_up` (`skill_range` per tile x skill x foe: 27 K calls), `_strike`'s weighing, `_approach`/`route`, `_check_stall`.

## Calls
1. **One mechanism, no new state in Battle**: `Unit.begin_read()`/`end_read()` (already there, one use in `Battle.read`) become a "stretch in which nothing's effects
   change", nestable. Inside one, a unit holds its effect list per viewer (`_fx`), dropped as the outermost stretch begins (`_epoch`) and whenever the unit's
   cell, footing or steadied differs from when it was held (so `Battle.standing()`'s planning steps read the ground they stand on). Previously the hold lasted one read.
2. **`Unit.stat()` in a stretch** loops only the effects of that stat (`_stat_fx`, a per-stat index built once, same order, so the sum is bit-identical). Outside a
   stretch the old path. `Tags.expand` runs only when an effect that asks for tags turns up.
3. **Where stretches are opened (pure planning only, nothing mutates inside)**: `Battle.suspicious`, `_sightings`, `route` (wrapper over `_route`), `_check_stall`'s
   seen test; `AI._reads` (act's, flee's and interrupt's reads), `_strike`'s weighing up to the cast, `_line_up` up to the walk, `_approach`, `_steady`,
   `_could_strike`, `_best_target`. Not scoped on purpose: `_look_harder` (`doubt` -> `suspect` emits signals), `_switch`, anything that casts or walks.
4. **Rejected**: a read cache across a whole act (every caster of `timed`/`on_passives`/items would have to invalidate: ~30 write sites; one miss changes decisions);
   a distance bound on `_line_up`'s tiles (a tile's footing changes `skill_range`, so a bound is not strict); skipping far units in `suspicious`.
5. `busy_fight.gd` prints `digest=` (a hash of every act's log): two runs decide alike iff it matches. Baseline and after are equal.
6. Pre-existing, not changed: a unit's first `on_passives` access can sync slots lazily inside a read (`Unit._sync_new`), so the list held in that read may be one
   effect short of a fresh gather (seen in borrowed_time_test, perception_test's darkstone and glamour tests). The old one-read hold behaved the same; a wider
   stretch could widen it if a first access fell inside one. No difference in either sim or the suite.

## Proof
- `Tests/sims/ai_sim.gd` (default 8 seeds), before vs after: `diff` empty (deterministic: two baseline runs were identical too).
- `busy_fight` digests before = after: 15v15 900342985, 20v20 2563641691 (n=2).
- Temporary checker (removed): every cache hit compared with a fresh gather. busy_fight 15v15: 1,155,097 hits, 0 mismatches. Suite: only the lazy-sync case above, all
  inside a single `read`.
- Suite: `8663 checks, 0 failed (927 tests)` before and after (no test added or changed). skill.py check ok; launch only the known "6 resources still in use".

## Numbers (M3, n=2 fights; target = x4)
| | before mean / p95 ms | after mean / p95 ms |
|---|---|---|
| 15v15 unit turn | 80.4 / 216.5 | 37.7 / 74.9 |
| 15v15 end_turn | 200 / 651 | 121.8 / 347 |
| 20v20 unit turn | 100.5 / 259.9 | 44.4 / 82.3 |
| 20v20 end_turn | 424.7 / 1406 | 232.6 / 679 |

On the target (x4): 15v15 unit turn mean 151 / p95 300 ms (budget 100: mean and p95 still over, 2.1x better); end_turn mean 487 / p95 1387 (mean now within 1000).
20v20: unit turn 178 / 329, end_turn 930 / 2714.

## Undone (next, if still needed)
- `suspicious()` reads every unit per call (about 5 ms; 327 calls a fight): a per-turn reuse needs invalidation on any state change.
- `_look_harder` (10 ms per unit at each side's turn start), `Perception.unit` itself (~0.17 ms a read: `_seem`'s brood loop over allies, `_range`).
- `skill_range` still ~0.04 ms a call in `_line_up`.
