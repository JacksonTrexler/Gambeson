# AI walks: wear for heals and supports, shove positioning, one price (q2-aiwalks, 2026-11-16)

Branch `q2-aiwalks`. Cards "Exhaustion wear for heals and supports" and "AI positioning for forced moves, and the other walks on route()'s price" (docs/queue.md). Baseline 8592 checks, 0 failed (916 tests). No names made up, so no ` ??`.

## Calls (each open for review)

1. **Wear for heals and supports.** `AI._wear` is HP (AP and cost points), taken off a blow's HP worth. A heal's worth is a share of an ally's HP and a support has no worth to take it off, so these weigh by a share: `AI._fresh(u, s) = max(1/rate, 1 - WORN)`, 1 fresh, down to 0.2. `_heal` multiplies a heal's want by it (a lone worn heal is still cast: it only orders skills); `_support` tries its skills least worn first (its own order on a tie). *Call:* a share, not `_wear()`'s subtraction, because the two aren't in the same unit; WORN's floor is reused, not a new constant.
2. **Shove positioning, both ways, through the forecast.** New `Battle.standing(u, c, f)` runs f with u standing on c instead (a planning question: `move()` there and back, nothing felt), so `Battle.foresee()` / `course()` / `foresee_drive()` are read from a tile it could walk to, no new maths.
   - `AI._line_up` (before `_strike`, not for the stoic, rooted or craven-and-held-back): for each tile it can reach, the most any affordable skill with a behaviour or a drive effect adds beyond its damage (`_driven()`: riders x RIDER + slam + spill, `score()`'s own terms) on a foe in range from there. It walks to the best tile if that beats where it stands (or, with nothing in reach from here, the poorest tile in reach: what every tile gives alike cancels out) by **PUSH x RIDER** (one tile of shove; no new constant), at the price `route()` puts on it (no more than its movement left: not through dreaded ground) and with AP left to pay the blow. Generic: any behaviour whose `foresee()` tells more from one side (Kick's ground, Displace) joins; no per-skill branch.
   - `AI._shoved(u, c, reads)`: what the foes it reads could do at c by driving it (slam HP, and the unit driven into if it is u's side's), worst blow of the ones it has read (`Read.skills`, so only with recon) from a foe that could walk up beside c on the side it comes from. *Call:* the foe is put **squarely** beside c, on the dominant axis, not diagonal: Kick's `between()` reads a diagonal's tile in the middle as the ground it kicks, so a diagonal "beside" isn't a push. `_retreat` takes it as its first key (rounded to whole HP), before distance.
3. **One price for the other walks.** `_retreat` (flee, kite, starve: `_flee`, `_keep_away`, `_recover`, `_starve` all go through `_away`) prices each tile it could end on by `route()` with `wary`, as `_approach` does, and keys `gap - extra`, extra = price less the movement the walk spent (dread of ground it knows or suspects, a detour; not below 0). So a trap on the furthest tile costs it a tile of distance per ~1 of dread. Callers now pass `reads`. *Call:* a retreat doesn't weigh the plain movement (moving far is the point); `_recover`'s walk to the lattice and `_escape` are untouched (they pick no cell by cost). `_retreat`/`_line_up` restore the rng (pricing a line draws on it, as `_approach` knew).
4. **Grudge and retreats.** The Grudge unit's own approach: `_last_blows` picks its target among the foes it can walk up to this round (`_reachable()`: beside it, or with an `_approach` cell its expected walk ends on), else as before. It makes its blow this round or dies of it, so the strongest foe far off no longer draws it past the near one. Allies coordinating a retreat: **not done.** The one rule I tried (don't end beside an ally that still has to back off) couldn't be told apart from what `_room()` already does (an ally occupies a tile, so it counts against the room of the tiles beside it): the mutation survived the test, so it came out.
5. **`SUSPECT_TILES` stays 3.0.** Sim (scratch test, not kept): the museum battle, 8 seeds, with 12 or 30 of its hinted spike trap scattered over the field (same cells per seed for each value), counting `sprung` emissions over all 8 battles:

   | SUSPECT_TILES | 12 traps: sprung (turns) | 30 traps: sprung (turns) |
   |---|---|---|
   | 0 (hint ignored) | 29 (98) | 59 (97) |
   | 1 | 27 (102) | 55 (97) |
   | 2 | 25 (103) | 58 (97) |
   | **3** | 24 (103) | 51 (101) |
   | 5 | 24 (103) | 52 (98) |
   | 8 | 24 (103) | 51 (94) |

   Springs fall to 3 and no further; the 30-trap column at 2 is noise (58 against 55 at 1). Winners: Lancin 6-8 of 8 throughout, no stall. 3.0 is at the knee, so it stays; no other AI constant touched.

## Tests (by seam)
`ai_tactics_test`: `test_wear_weighs_heals_and_supports` (item 1), `test_lines_up_a_shove`, `test_retreat_weighs_shoves_and_price` (shoved + route price), `test_grudge_goes_for_what_it_reaches`. No existing test changed. Mutations (rule broken, test fails, reverted): `_fresh` out of `_heal`; `_support` unsorted; `_shoved` out of the retreat key; the route extra dropped; `_driven`'s spill dropped (line-up into its own side); `_reachable` returning all reads. *Survived:* the line-up's gain threshold (PUSH x RIDER): no test stages a gain between 0 and a tile's drive; it is a one-line choice left as is. The ally-room rule (call 4) was dropped for failing this check.

## As built
`Scripts/AI.gd` (`_fresh`, `_heal`, `_support`, `_driven`, `_line_up`, `_shoved`, `_retreat`/`_away` with `reads`, `_later`, `_reachable`, `_last_blows`), `Scripts/Battle.gd` (`standing()`), `Tests/ai_tactics_test.gd`. Suite: 8609 checks, 0 failed (920 tests).
