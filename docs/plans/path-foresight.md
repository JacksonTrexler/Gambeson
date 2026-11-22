# Path foresight: Meander and at_end in the estimate, the AI's approach on route()'s price (branch `z-pathfore`)

Card "Path foresight" (docs/queue.md; ?137 follow-ups of `path.md`, `tile-marks.md`). Tests: `Tests/path_test.gd` (4 new tests);
`facing_test.test_ai` and `marks_test.test_helpful_marks_draw_the_approach` restaged (see below).

## Readings

- `Battle.hazard(u, c, r, nth)` was the one estimate behind the HUD forecast and `route()`. It ignored that standing still
  (Meander: `Unit.passes_by()`) walks over a trap and ground's `afflicts` without touching them (`travel()`'s `touched`), and it
  never counted `at_end` (put on whoever ends its turn on the tile; `end_turn()`). `route()` passed nth 0, so a trap near the start
  of a Meander walk still bent the route.
- `AI._approach` scored each cell beside the foe by its own count of bad tiles on `line()` (10 a tile, `known_bad()` or a hint)
  plus euclidean distance; `route()`/`stride()` had the real price (ground drag, units in the way, Peel, marks).

## Calls (each open for review)

1. **Meander in `hazard()`**: for the nth tile of a walk, `passes_by(terrain, nth)` leaves out the trap and the ground's afflicts (as
   `travel()` does). Fire, marks and tolls (per_tile has its own `wards()`) are untouched. `route()` now knows how far along each
   tile is: the line's index, and a depth for each search node (a `[tile, nth]` key in its dread cache, only when the unit has any
   Meander). `dread()` takes `passed`: a passed-by trap isn't "at least a tile" either. The per_tile toll stays out of routing
   (`hazard(..., tolls = false)`), as before.
2. **at_end counted on the walk's last tile** (`ends`): `hazard(u, c, r, nth, ends)`. HUD.drain() passes it for the last tile of
   the previewed path; `route()` for `dest`. It is "if it ends its turn there": the walk may not be the unit's last act, but the walk's end
   is the best guess. A destination can't be bent round, so this matters to the price, not the route (the AI's approach cells).
3. **`route(u, dest, ln, price)`**: a Dictionary asked for fills `{cost}`: movement (`stride()`, with `pass_cost()` for units in the
   way) plus dread, less what marks draw it, of the route returned (the line's, if it kept it). The walk is unchanged.
4. **`AI._approach` weighs a cell by that price** (plus euclid minus chebyshev distance as the old tie-break,
   +0.5 diagonal, - FLANKING x opening, WARY as before). The old risk count and lure sum are gone. Real tile counts now show: a
   cell on the diagonal costs ceil(distance) tiles, so a straight approach beats a diagonal one by up to a tile, where it
   was 0.16. Units in the way price in `pass_cost()`.
5. **Blind units (negative foresight allowance) still price the line with dread**: they don't *search* round it (their walk is
   optimistic, unchanged) but the AI, choosing where to head, still avoids cells whose line crosses what it knows. Without this
   the sim sprang twice as many known traps (the old AI avoided them regardless of int).
6. **Suspicion**: the old AI counted a tile with a hint ("disturbed earth?") as a bad tile. A walk steering by hints would break "a walk goes
   only by what it knows" (path_test), so it's an AI-only weight: `price.wary = true` makes `dread()` count a hinted tile at
   least `SUSPECT_TILES` (3.0, a guess), in the price and in the search.
7. **Tuned: `HAZARD_TILES` 0.5 -> 2.0, `STEER_MARGIN` stays 2, `SUSPECT_TILES` 3.0 (a guess, not swept).** A 1d6 trap now weighs 7 tiles
   (+1), a fire about 9: dearer than the old 10-a-tile risk count for a trap, cheaper for bigger ones. See the table.
8. **Tests changed**: `facing_test.test_ai` staged its unit off the map (y 9; the price of an off-map line is infinite): moved all up 2
   tiles. `marks_test.test_helpful_marks_draw_the_approach`: the old premise (a nearer straight cell, lure 0.75 tipping it) is gone
   now that real tile counts decide: restaged so two cells cost the same (the straight way blocked by a unit). `path_test.test_a_long_way_round_isnt_worth_it`:
   mud on every way round within the margin, as the trap weighs more.

## Sims (tuning)

A scratch test (not committed) fights museum battles, 8 seeds, plain and with N known spike traps and Magic Stew scattered over the field
(a third of them stew; N = 12, 30). "sprung" counts traps sprung over the battles, "known" those the walker already knew of. Most known
ones are blind units (int mod -1, a negative foresight allowance: their walk goes straight on purpose) and units with nowhere cheaper to go.

| build | plain | 12 scattered | 30 scattered |
|---|---|---|---|
| AI unchanged (commit 104a095, old 10-a-tile risk count) | 4 sprung, 6/2 wins | 16 sprung (12 known) | 27 sprung (24 known) |
| route() price, HAZARD 0.5 | 8 | 19 (15) | 41 (36) |
| HAZARD 1.0 | 8 | 18 (14) | 35 (31) |
| **HAZARD 2.0** | 8 | 16 (12) | 27 (22) |
| HAZARD 3.0 | 8 | 16 (12) | 24 (19), turns 280 (units dither) |
| HAZARD 5.0 | 8 | 16 (12) | 23 (18), turns 282 |
| HAZARD 2.0, STEER 1 | 8 | 15 (11) | 29 (24) |
| HAZARD 2.0, STEER 3 | identical to STEER 2 (the map is small) | | |

The plain battles' extra springs (4 -> 8) are mostly hidden traps with a hint (5 of 8); the old AI counted such a tile 10, now
`SUSPECT_TILES` 3 only for the approach. Left. Two to three more weights than 2.0 buy little and stall fights; margin 1 vs 2 is within noise
(15/29 vs 16/27), so the existing 2 stays (room round fire on a bigger map). Soak (30 seeds, combat_test): Lancin 28, Nemes 2, turns 10-17,
all invariants held. STEER_MARGIN 4 was cut short (slow, no change expected).

## As built

- `Scripts/Battle.gd`: `hazard(u, c, r, nth, ends, tolls)`, `dread(..., passed, wary)`, `route(u, dest, ln, price)`, `SUSPECT_TILES`, `HAZARD_TILES`.
- `Scripts/HUD.gd`: `hazard(u, c, nth, ends)`, drain() marks the walk's last tile.
- `Scripts/AI.gd`: `_approach` only.
- Tests: `Tests/path_test.gd` (Meander passes a trap by; at_end where it ends; the approach pays the walk's price; the AI heads for the cheaper cell),
  `facing_test`, `marks_test`. Mutation spot-checks (each failed its test, reverted): `passed` out of hazard's trap; at_end
  counted off the last tile; `dread()`'s passed clause; hint counted without `wary`; units dropped from the price (pass_cost); HAZARD_TILES back to 0.5.
- Suite: 8564 checks, 0 failed (912 tests) before tuning; 8565, 0 failed (913 tests) final.

## Not done

- The walk's real line is drawn from the rng later than the AI's `line()` call (equal ties settled by luck), so the approach's line can differ
  from the walk's on a tie.
- Other AI walks (flee, kite, retreat) pick cells without this price (z-aitune's area).
- `SUSPECT_TILES` isn't tuned.
