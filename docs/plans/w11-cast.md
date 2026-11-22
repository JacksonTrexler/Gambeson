# AI turn cost: the cast (w11-cast, 2026-11-22)
Goal: unit turn down (15v15 n=2 `busy_fight`, M3); digest 3296533323 must not change; suite 0 failed, count not dropped. No cross-stretch cache.
Files: Scripts/AI.gd, Battle.gd, Unit.gd, Perception.gd, Tests/ai_tactics_test.gd.
Tools: `S/ab-w11.sh [n]` interleaved A/B (base-w11 = tip 8ed1542 vs this worktree); perf copies `S/perf-w11*` (perfwrap.py + get_stack tallies).

## Profile (tip, 15v15 n=2; counts over 2 fights, 267 unit turns, 43 ms mean)
Stat machinery dominates: ~214K `_on_passives` (21 us), ~180K `_gather_effects` (25 us) a fight, from held-fx builds (one per unit per stretch/epoch) and r0 gathers.
Builds by epoch opener: reacts<react_with 14.4K (one per react_with), read<_hunt 13.9K, _line_up 11.8K, _reads 11.4K, suspicious<_first_look 13.4K, _look_harder 7.4K, _sightings<travel 8.5K, ...
r0 gathers (70K): settle<restless<disturbed 10K, cover 11K (_fight/_lose_cover/inspect/travel), evaluators 5.5K, slot_count/lv 6K...
Reads 29K: suspicious 6.9K, _reads 5.6K, _tile_read 5K, _sightings 4.2K, _look_harder 2.7K.

## Steps (A/B unit turn mean, base ~42-43)
1. `_hunt`: its post-walk re-read of every unit in one stretch (was one epoch a read: 13.9K held builds).
2. `Battle.react()` asks only reaction-tagged passives (`reactions_of(o, REACTION)` -> `Unit.on_passives_tagged`, `_on_passives(tag)` filters on the tag before `equipped()`/`lapsed()`); `react_with` checks `done` before `reacts()`. react 826 -> 144 ms. Premise (every skill whose behaviour defines `react()` carries `reaction`) is Util/skill.py check's rule; the new test restates it over the files.
3. `_line_up`: leaves on no skills / no move before reading each foe (`helpless()` per foe).
4. `restless()` asks the undead tag before `disturbed()` (10K r0 gathers, settle); `Perception.cover` in one stretch (1+KINDS stat reads, one gather); `evaluators` asks `evaluates()` before `asleep()`.
5. `_look_harder`: `suspicious()` inside the loop's stretch (was a fresh epoch: ~4.7K rebuilds); `_first_look` = `_inspect_first(suspicious())`.
6. `Unit.slots` one pass (was `_own()` dedup then a second); `Unit.link` skips items lending nothing (feeds `equipped()` -> every `_on_passives`).
7. `Unit.rank` held per stretch (`held(&"rank")`: skill -> rank before a primed Chant and `allowed`, which apply after): 53K calls, many repeats. Biggest single step after react.

## Calls
- Digest 3296533323 unchanged in every step; ai_sim's 26 SIM lines identical to base.
- Reaction filter by TAG, not by "behaviour overrides react()": GDScript's `get_script_method_list()` lists inherited methods, so an override can't be seen at run time, and source text isn't kept in exports. The tag is the documented contract (Glossary, skill.py check). A reacting skill left untagged would silently never react: the test's file scan + skill.py check guard it.
- `reactions_of(u)` itself unchanged (equip_test and Snapping Turtle ask for all with behaviours); only `react()` passes the tag.
- NOT taken (no test can prove them): out-of-range viewer skip, `_sightings` pre-walk gate (travel: cover after the walk depends on marks/traps/afflicts), skipping ally reads in `suspicious` (hint can come from a low-recon reader, no cheap exact precondition), `in_range`/`_seem` caching. No cross-stretch cache.
- Micro-stretches only where the whole body is reads (cover). `_chain`'s head (~10 r0 stats, ~0.4%), `can_afford`, `actives` held: left, under measurement noise.
- Remaining floor: a warm read is ~100 us (29K a fight, ~25% of a turn: `Perception.unit`'s ~54 stat calls, `_seem` 14 brood stats); a held build ~25 us (`_on_passives` 18 of it: `slots` 5, `slot_cost` per passive 6); `_approach`/`route` 1.4 s of 10 (left: the Opportunist card edits it).

## Final (15v15 n=2, back-to-back A/B x3, M3; base = 8ed1542)
| | before mean / p95 | after mean / p95 |
|---|---|---|
| unit turn ms | 42.9, 44.9, 43.2 / ~72 | 37.7, 36.9, 38.1 / ~63 |
| end_turn ms | 56.1-58.5 | 56.6-58.5 (unchanged) |
Unit turn -14% (43.7 -> 37.6). At M3 x 4: ~150 ms against 100 (still OVER; was ~175). end_turn ~230 (within 1000).
Suite: 10814 -> 10871 checks (+57: the new test), 1 failed = `tooling_test.test_icons` (disturbance, grave_aura, opportunist, seaborn: fails identically at the base tip in a worktree; card ?249 / w11-icons), 1030 tests. skill.py check ok; launch log clean (only "8 resources still in use").
Test: `ai_tactics_test.test_cast_cost_answers_as_before` (slots, restless, cover, evaluators, reaction-tagged passives, link, held rank, suspicious with reads in hand, the tag premise). Mutation spot-checks, all caught: restless with `not disturbed()` (2 fail), rank held +1 (14), `_on_passives` ignoring the tag (4), evaluators dropping `asleep()` (3; needed a sleeping evaluator in the field).
