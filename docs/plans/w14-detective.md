# w14-detective: Detective observes the unconcealed; word of suspicion carries tiles

## Reading
w13 left: Detective only noted what it saw through; orig (4fe2c05 Investigation.lead) also investigated units at net 0..2 and tiles at net 0 not yet marked. spread() was units-only (orig shared tile suspicion too).

## As built
- a) `Battle._observe(o, center, reach)` called at the end of `survey()` (turn-end look, Observe etc.): if stat `detective` > 0, each foe it `read()`s at net 0..2 (located) and each empty tile within reach at net 0 gets `note(o, k, rank)` recon; self-limiting (stops once net rises). Goes through read(), so lent reads (Coordinate/Study) count. No Skill.gd field, no per-skill branch.
- b) `spread(o, t: Variant)`: `suspect()` now spreads suspicion of a tile too (any tile, not told_of); `lets_word` holders = whoever stands on the tile (none: word passes). Signal `told(..., of: Variant, ...)`.
- Tests (Tests/suspicion_test.gd): `test_detective_observes`, `test_tile_word`. Mutations (each fails): units loop off; tiles loop off; tile spread off.

## Calls
1. Detective observation runs inside survey() (turn-end look), not at turn start or on every read; orig: when investigating as a lead. Reach = survey's reach (wis mod + rested).
2. Thresholds as orig: foe net 0..2, tile net 0 (units < 3 is where skills/effects appear).
3. Recon amount = detective rank per survey, per target (orig: rank per success).
4. Tile word reaches same radius/rules as unit word (WORD + cha mod); Bandwagon on a unit standing on the tile can stop it.
5. Signal `told` `of` widened to Variant (tests' lambdas unaffected).

## Undone
- No AI weighing; no visual check.
