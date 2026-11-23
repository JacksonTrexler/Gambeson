# w15-tilesus: the AI weighs tile suspicion (?261 card 4)
Goal: a unit that suspects a tile avoids walking onto / ending a walk there, by how much. Base 13916cf.

## Reading
Suspicion of a tile (`Unit.suspicion[Vector2i]`, w14-detective) already lowers the tile's concealment per stack, so a trap seen through is priced as a known trap, and a hint tile (net -2/-3) is priced SUSPECT_TILES by `dread(wary)`. Gap: a suspected tile still unseen with no hint (net -1, or -4: told by word, or a hidden unit's tile) cost 0. All AI walks (`_approach`, `_retreat`, `_line_up`) price ends through `route(price {wary})` -> `dread()`, so one change covers them.

## As built
- `Battle.dread(..., wary, doubt)`: `doubt` = `u.suspects(c)` (wary walks only); if wary, doubt > 0, r.net < 0: cost >= SUSPECT_TILES x min(doubt, SUSPECT_STACKS). No new Skill.gd field, no per-skill branch, no AI.gd change. Non-suspecting units: unchanged (term 0).
- Test `path_test.test_suspected_tile_costs_more` (route price + dread inequalities). Mutation (term off) fails it; reverted.
- busy_fight 15 a side rounds=10: OUTCOME ok both; n=253 both; unit turn mean 24.3/23.8 base vs 24.2/25.1 here (noise).

## Calls
1. Scale: SUSPECT_TILES (3) per stack, cap SUSPECT_STACKS 3 (9 tiles); guess. Stack 1 equals a hint's price (max, not sum).
2. Applies only while net < 0: once it makes the tile out, the real hazard/known-trap price takes over (so no double-count).
3. Wary walks only (AI choosing where to go), like the hint rule; a real walk goes by what it knows.
4. Priced on every tile of the route (as hints are), not only the walk's end.
5. Tile-keyed suspicion only; suspicion of a unit already works via its read.

## Undone
No visual check; `_flee`/`_hunt` paths use route() unchanged (get it free where wary).
