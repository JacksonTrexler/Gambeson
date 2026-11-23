# w14-ambush: the AI weighs where to Ambush (2026-11-23)
Goal: AI casts Ambush by where foes will walk, not only via `_defend`. Base 7ec9686.

## As built
- `Behaviour.waylays(c, cell) -> {tiles, skill}` (generic hook, empty default): what a tile-cast would mark and the blow a trip strikes with. Ambush implements it from its own `footprint()`/`weapon()` (one source with `apply_at`).
- `AI._waylay` (in the full turn's advance branch, after `_rally`, self-directed only): each foe it makes out walks toward the nearest of caster/allies (`route` of its line, first `ceil(movement)` free tiles); the first tile a candidate footprint covers fires (each tile once), worth `score(u, weapon, read, b, foe)`. Candidates: walked tiles (cap 12). Casts the best if value - AP cost x AP > PUSH x RIDER, then holds (no advance: the weapon's reach is from where it stands). Skips if its own marks are up. No per-skill branch: any skill whose behaviour answers `waylays` joins.
- Test `ambush_test.test_ai_waylays`; mutation (`step in way.tiles` -> false) fails it.

## Calls
1. Foes' goal = nearest of caster and its allies; objective not modelled (no objective concept in AI).
2. Ambusher holds after laying (blow reach is from its tile); next turn the mark may be left behind.
3. Pricing: a weak blow (score 2 vs AP 2 x 1.5) is not worth it; a strong one is. Not tuned.
4. Seen-through discount not applied (foes are only guessed to walk blind).

## Seed-3 stall (hud_test.test_play_scene)
Plain AI bug: a luring Siren (behaviour `lure`) too far from any song (`_out_of_song`) closed in only on `_best_target`; Tess was read vaguely (net -2, not a `_foe`) so no target -> held at (7,6) forever with its side's last-seen cell (1,3) known. Fix: no target -> `_hunt` (toward last seen). Test back on seed 3 (was moved to 1 by w14-detective). Mutation (drop the else) = the seed-3 stall, fails.
