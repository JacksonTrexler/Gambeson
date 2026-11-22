# AI turn cost: the warm-read floor (w12-warm, 2026-11-22)
Goal: unit turn down (15v15 n=2 `busy_fight`, M3); digest 3296533323 must not change; ai_sim output identical; suite 0 failed, count not dropped. No cross-stretch cache. Start 13:01. Base = tip 5e61ef1 (copy `S/base-w12`; `S/ab-w12.sh [n]` interleaved A/B).
Start: suite 10881 checks, 0 failed, 1031 tests. Base unit turn 36.5-38.1 ms (n=2 x 3), end_turn 55.7-58.5.

## Profile (tip; 24K reads, ~130 us each warm in `S/bench_w12.gd`)
Reads are ~55% of a turn (29K `Battle.read`, 0.18 ms each wrapped). 1.3M `stat` calls but a warm stat is ~1 us: not the lever.
- `restless()` (Battle.read's `dead_eye`, 29K a fight) ran `has_tag(&"undead")` first: 22 us (lambdas over items and slots, `equipped()` per passive slot); in a stretch the held `disturbed` stat is a lookup.
- `_seem` asked every ally of t for `brood`: 11 stat calls a read and a held-effects BUILD (25 us: `_on_passives` + gather) per ally per epoch; 27K builds of 159K a fight (the biggest single source).

## Done
1. `has_tag`: loops, tag asked before the bar (`equipped()` last), `emblems()` once; `emblems()` loop, no array/lambda; `restless()` in a stretch asks `disturbed()` first (outside one keeps the tag first: there the stat is a 25 us gather).
2. `Unit.lends(s)` (new, per stretch while the unit stands where it did): any effect of stat s on any skill it has (on or off the bar), status, ground, item, property. False = stat(s) is its bare 0 for a non-core stat. `Perception._seem` skips an ally that doesn't lend brood (no build).
Test: `ai_tactics_test.test_warm_read_answers_as_before` (has_tag vs the old long form over item tag, skills, form; emblems; restless in and out of a stretch with a living disturbed unit and a sleeping undead; lends vs the stat held and vs a fresh scan; a fresh stretch finds a status put on). Mutation spot-checks, all caught: lends false for brood (3 fail), lends ignoring timed (3), no epoch check in lends (3), has_tag skipping items (2), restless in a stretch dropping undead (1; needed a disturbed living unit).

## Calls
- Brood skip via `lends()`, not a held stat: a held build is what costs. The scan is a superset of what `_gather_effects` draws on (Modifiers.effect keeps the stat), so false is exact; `s` not in CORE (brood isn't) so base is 0.
- `lends` is kept per stretch with the key `_held_fx` uses (epoch, cell, footing, steadied), no hp: it doesn't read hp.
- `candid()` (lambda walk of the bar, 8 us, ally reads only) rewritten with `lends(conspire)` gate: bench 94 -> 84 us a read but ~0.8% of a turn (10K calls): under noise in the sim, dropped.

## Tried, dropped (no measurable gain, measured A/B x3)
- Per-stretch memo of `stat(s)` (no tags/viewer/of/base) in `stat()` (held dict, hp in the key): 36.7-38.5 vs base 36.5-38.1; a held lookup costs as much as the stat loop.
- `_on_passives` as a loop (no `filter` lambda): 32.2 vs 32.3 before.
- `may_lend` gates on `trickery`, `concealment` (`_levels`), `nullify` (`_left`): bench 94 -> 90 us a read, sim 32.6 vs 32.3: noise.
- Read dedup within a stretch: 87 of 29K reads repeat (epoch, o, t, cells); nothing to cache.
- Not touched (under noise or no exact precondition): `_chain`, `actives` held, `can_afford` (0.19 ms x 1023 = 2%), `Read.new()` (5 us, 54 fields), `mod()` (4.7 us: scaling 2.2 + `reduced()` 2.4), `armor_defense` (17.8K builds a fight, Behaviours/armor.gd), `synergized` loop, `_dim`'s two mods.
