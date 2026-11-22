# Path: routes steer round known hazards, the hazard estimate counts more (branch `q-path`)

Two open items from `forecast.md` (?132): the walk isn't steered round fire or traps; only a bleed's first tick
is counted and ordinary ground's `afflicts` not at all. Tests: `Tests/path_test.gd` (new), `hud_test.test_will_consume`
(one hover moved). Frames: `scratchpad/shot_q-path/`.

## Readings

- There was no pathfinder. `Battle.walk()` takes `line()` (a straight run of ceil(distance) tiles, equal ties
  settled by luck over the true map) and pays for it step by step. `HUD` previews it with `walk(u, c, true)`, the
  reach overlay walks every cell in range, and `AI.travel` is `Battle.travel()` = `walk()`. So steering belongs
  in `walk()`: one place all three go through.
- What a unit knows of a tile is `Battle.read(u, c)` (recon, sight): `trap`, `worth`, `afflicts`, `net`. `walk(expected)`
  already treats ground it can't read (`net < 0`) as plain. Fire (`Battle.flames`) is plainly visible, as `forecast.md` decided.
- Peel's `step_cost` hook runs inside the step price with a bag counting steps taken, so a searched route must price
  steps with the hook too.
- `hud_test.test_will_consume` walked to a tile beyond a known trap and expected the walk to go through it; now that
  route bends round, so the test hovers the trap tile itself. `command_test.test_expected_walk` needed no change: its
  trap-knowing unit has int mod -1, which is the "plans optimistically" case.

## Calls

1. **`Battle.route(u, dest, line)`** inside `walk()`. Only if the straight line crosses a tile with dread above 0 does it
   search (an 8-neighbour Dijkstra in the box of start and dest widened by `STEER_MARGIN` = 2 tiles); it keeps the line
   unless the route is strictly cheaper (movement + dread), so it only goes round "when one costs about the same".
   Costs of tiles the unit hasn't read (plain ground), units it can't locate (not in the way) are as `walk(expected)`.
   The same route is used for the real walk (the unit's knowledge, never the true map), so the preview is the walk.
2. **One price, `Battle.stride()`**: ground (entering and leaving), wading, obstruction, the passives' `step_cost` hooks (Peel;
   each search node carries its own bag), and `pass_cost` for a unit in the way. `walk()` pays it; `route()` weighs it.
   `Peel` still works (`peel_test` unchanged, passing).
3. **Dread**: `Battle.dread(hazard, read)` = HAZARD_TILES (0.5) movement per HP foreseen, 1 per AP, and any known trap or
   known-detrimental ground at least 1. So a 7-damage trap is worth a 3.5 tile detour; a 1d8 fire about 2.25.
   Weights are my guess; `HAZARD_TILES` is one constant to turn.
4. **Hazard moved to Battle**: `Battle.hazard(u, c, read)` is the estimate for any observer's read; `HUD.hazard(u, c)` is
   `battle.hazard(u, c, tile_view(c))` (the player's eyes, as before), steering reads `read(u, c)` (the walker's own).
   `foresight_allowance` moved the same way (`HUD.foresight_allowance` delegates). Whether HUD (eyes) and the walker
   differ is only for commanded units.
5. **Negative allowance doesn't steer**: the user's rule is "negative int mod plans optimistically"; I used the foresight
   allowance (int mod + `foresight` stat) so a bonus lifting it to 0 steers again, as for the "?".
6. **Steering is free**: it doesn't spend a foresight; allowance 0 still steers round what it can see (it only can't put a
   number on it: "?"). Only below 0 it doesn't.
7. **Fuller estimate**: wounds count each tick they take HP: bleed (dice average + setter's mod, at least 1) and poison
   (amount x max HP) times the wound's turns (`wound_turns` for a trap, `Effect.turns` or the ground's `turns` for
   afflicts); `winded` takes AP once (AP is this turn's pool; later turns' aren't on the bars). Poison and winded scale by
   level when `per_rank` (trap's level; afflicts go on at rank 1, `travel()`). Ground's afflicts come from the `Read`
   (so only ground read at net 0 or better counts) with the terrain's `turns`/`level`.
8. **Not done / kept**: Meander (`passes_by`) isn't foreseen; at_end effects aren't counted (no stepping); `AI._approach`
   still scores approach cells by its own line risk (r-route's area); unit-blocked routes use pass_cost only.

## As built

- `Scripts/Battle.gd` (`route`, `stride`, `known_ground`, `hazard`, `dread`, `foresight_allowance`, `walk`),
  `Scripts/HUD.gd` (`hazard`, `foresight_allowance` delegate), tests.
- Ties between equal-cost routes hug the straight line (a 0.00001 x deviation term in the search only).
- Suite: baseline 44831 checks, 0 failed (718 tests); now 44710, 0 failed (727 tests). The 9 new tests add 19 checks;
  `combat_test.test_battles` (simulated AI battles) counts 140 fewer (33858 to 33718) because the AIs now walk different
  routes round known traps and fire, so battles play out differently; it still passes.
- Frames: `scratchpad/shot_q-path/crop_bend.png` (a path bending round a known trap, same movement) and `crop_blind.png`
  (the same walk by a unit with a negative int mod: straight through, stopping on the trap).
