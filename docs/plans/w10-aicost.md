# AI turn cost: the per-read floor (w10-aicost, 2026-11-22)
Goal: unit turn / end_turn down further (15v15 n=2 `busy_fight`, M3 shared CPU); digest must not change; suite 0 failed.
Files: Scripts/Unit.gd (so far).

## Baseline (tip 90e374e)
Digest is **3296533323** at this tip (card said 47676114: that was before w9-aiplate/typing merges changed AI decisions; same on 3 runs here, so it is the reference now).
unit turn mean 62.2 / p95 ~102; end_turn 77 / p95 230. Suite 10789 checks, 0 failed (1025 tests).

## Profile (in-stretch micro-bench, `S/bench_w10.gd`, us per call)
kit 205 cold / 91 in stretch (a read asks it twice), defense 47, `mod` 27 (!), `insightful` 28: `mod()` -> `scaling()` loops `on_passives`, which was rebuilt (22 us) on EVERY call, even in a stretch.
gather 24, r0 gathers (no stretch) 138K of 218K in a 15v15 (react/helpless/stopped/affinity...).

## Done (all in Scripts/Unit.gd unless noted; each a stretch contract: Unit.begin_read() = nothing changes passives, effects, items)
1. `kit`, `defense()` (no tags), `core_stats()` (new), a unit's strengths/weaknesses pair (Perception) held per stretch with `held`/`hold`; getters return copies. read 363 -> 192 us.
2. `on_passives` found once per stretch, with the effects: `_held_fx` builds the null-viewer entry from `_on_passives()` and passes it to `_gather_effects`. `mod()`/`scaling()` rebuilt it (22 us) on every call: mod 27 -> 5 us, read 192 -> 119 us (bench, unit 0 read by others).
3. Micro-stretches (begin_read/end_read inside) in `reacts`, `stopped`, `helpless`, `rank`, `actives`: their several stats share one effects gather (r0 gathers 138K -> 70K of 218K -> 176K gathers per 15v15).
4. `Perception.embellish`: returns {} before ranking the six stats when nothing is puffed (was a 12-stat sort per `insight` read). `insight` 57 -> ~9 us.
5. `Battle._tile_read(u, c)` (route's `dread_of`, `known_ground`): a planner's tile read kept for the stretch while u stands where it did (key epoch, u, u.cell); callers read only. Tile reads 24K -> 5K a fight.
6. `bonus_slots()` asks `slot_count()` once, not per hotbar slot.
Test: `ai_tactics_test.test_stretch_holds_what_a_read_asks` (held = plain answers in a stretch, copies not shared, a fresh stretch finds a disabled passive and a Defense effect). Mutation spot-checks, both caught: `on_passives` returning the held array itself (copy check fails); `begin_read` not bumping the epoch (3 of 4 checks fail).

## Calls
- Digest reference is 3296533323 (card's 47676114 predates w9-aiplate/typing merges; unchanged by every step here, ai_sim output diff empty).
- Cross-stretch cache behind a mutation version: NOT built. timed/slots/items/hotbar/learned are mutated by ~35 sites in Battle/Unit/Behaviours/tests with no single hook (`timed[e] = `, `.erase`, `learned.append`, `weapon = `); a missed site would give stale stats silently. Widened and shared the existing stretch instead (items 1-5): sound by the stretch contract.
- Held values keyed by `&"kit"`, `&"defense"`, `&"core"`, `&"strengths"`: StringName keys; the other held keys are Skill/Unit objects, no collision.

## Final (15v15 n=2, back-to-back A/B x3, M3 shared CPU; base = 90e374e)
| | before mean / p95 | after mean / p95 |
|---|---|---|
| unit turn ms | 56.0-57.9 / ~93 | 41.4-42.6 / ~71 |
| end_turn ms | 69-71 / ~210 | 55.7-57.6 / ~177 |
(first run of the day, slower CPU: base 62.2 / 77.) Unit turn -26%, end_turn -18%. At M3 x 4: unit turn ~168 ms against the 100 budget (still OVER; was ~230); end_turn ~225 (within 1000).
Suite: 10789 -> 10793 checks, 0 failed (1026 tests); launch log clean.

## Tried, dropped / not done
- Out-of-range viewer skip in `_sightings`/`suspicious` (in_range 0 foes can't locate): sight range covers nearly everyone in the sim (w9: ~3%); not built.
- `_sightings(u)` before a walk is used only if the walker ends in cover; can't know that exactly before the move (footing, afflicts, marks add concealment). Left.
- `in_range` loops the whole side per read (~25 us x 14K): a per-stretch cache needs positions of all side members in its key. Left (~3%).
- `_seem` brood loop over allies (24 us a read): same position-dependence. Left.
- Remaining time is cast (`_cast` ~8 ms x 307, 22% of act: reactions, evaluators, 70K r0 gathers) and the unit reads of `_reads`, `_look_harder`, `_first_look`, `_sightings` (~0.1 ms each, ~18K per fight).
