# Tile marks, Warcry and damage for moving (branch `s-marks`)

`docs/plan.md` Phase 2 items 3 (tile marks) and 7 (damage for moving), and Warcry (`docs/todo/classes.md`), which
needed both. Tests: `Tests/marks_test.gd`, `warcry_test.gd`, `per_tile_test.gd`, `regain_test.gd` (new);
`fighter_test`, `gods_test`, `pockets_test` changed. Frames: `scratchpad/shot_s-marks/` (`warcry/`, `hover/`, `walk/`).

## Readings

- Snares (`snares`) are ground: the trap *is* the tile's terrain and is known by `Snare.known` plus recon. Zones are
  concealment, debris is evidence, flames roll fresh damage on two triggers, earthworks were `{faction, turns}` and a
  wading multiplier. Only the earthwork is the shape of a mark (a side, a lifetime, a price on entering).
- A trap is known through `Perception.tile`: concealment levels against the observer's recon, bypassed by `Snare.known`.
  Fire is "plainly visible to everyone" (`forecast.md`). Marks should sit between the two: a `concealment` of 0 is fire,
  more is a trap.
- `travel()` computes the whole walk first, then moves, then runs its effects over `passed` (fire, debris...). `walked()`
  adds `steps` *before* those run, so anything wanting "which tile of the turn is this" must read `steps` first (`touched`
  does; `_toll()` takes `began`).
- Routes (`route()`) only search when `dread()` of some tile on the straight line is above 0; `stride()` is the one price.

## Calls (each open for review)

1. **One `Battle.Mark`**: `kind`, `by`, `faction`, `effects`, `rank`, `who` (allies / foes / any, from its side's view),
   `on` (enter / end), `turns` (its side's turns), `uses` (0: stays), `effect_turns`, `cost` (movement more to enter),
   `wade` (times as much), `concealment`, `known`, and `tint`/`swell` (how it's drawn). `marks: Dictionary[cell, Array]`,
   `lay_mark()`. Laid again by the same side with the same `kind`, it renews rather than stacks.
2. **Folded in: disturbed earth only** (Pray, to Vetruvis; `earthwork()` is a Mark with `who = foes`, `wade = 1.5`,
   `uses = 0`). Left alone: snares (they are the ground), zones (area concealment), debris (evidence), flames (damage rolled
   each time; two triggers; would need dice on a mark), layers. `Battle.Earthwork` and `earthworks` are gone; `gods_test`
   and `pockets_test` use `marks`.
3. **Triggers**: entry (every tile of a walk, as fire is: `travel()`; `place()` too, as it springs traps) and turn end
   (`end_turn()`). Plan.md's third, "stepped on" (stopping there), isn't separate: a mark on a tile you pass through goes off.
4. **Who knows**: `Mark.told(o)`: its side, units in `known`, or everyone when `concealment` is 0. Otherwise the tile's read
   decides (`Perception.tile`: mark concealment joins the levels as plain-sight, less the viewer's suspicion of the tile;
   `Read.marks` is what the observer may use). `inspect()` finds one like a trap. Warcry's marks are concealment 0.
5. **Hazard and steering through the same functions**: `hazard()` runs a known mark's effects through `_owe_wound` (bleed,
   poison, winded); `stride()`/`step()` add `mark_cost()` and `wading()` (with `expected`, only the marks the walker knows);
   `route()` searches when a known mark would harm the walker (`Mark.harms()`, at least a tile of dread, like a known trap).
   The real walk pays the true marks, the preview the known ones (as obstruction does).
6. **Effect lifetime**: `effect_turns` 1 means "until its turn ends": no extra turn for entering on its own turn (unlike
   `Cast.put`), one extra for an end-of-turn trigger (that tick doesn't count).
7. **Warcry** is a self-cast (`self_only`, no damage, no roll): it picks the nearest *rank* foes it can read as located (no
   UI for choosing), and for each marks the first *rank* tiles of the line **from the caster** toward it (short of the foe),
   the nearer `ceil(rank / 2)` Charge!, the rest Routed! (rank 1 lays one Charge!). A tile an earlier line marked isn't
   marked again. Lifetime `turns = 2 + rank` of its side's turns ("a few"; skill data). Each is one use.
   - Charge!: `who = allies` (the caster too): effects `Effects/charge.tres` (`damage` +10% x rank) and `charge_ap.tres`
     (the new `regain` stat, dex tag, rank AP back), until its turn ends. Two Charge! tiles don't stack (same effect: the
     higher rank stays).
   - Routed!: `who = foes`, `cost = rank`: the extra movement is part of the step's price (so paid in movement and the
     same AP, steered round, forecast), used up by the first to enter.
8. **New Effect stats**: `per_tile` (named by the user) and `regain` (mine; its title shows as "Regain ??"). `regain` is
   instant: `Unit.afflict()` hands the AP to `Unit.regain(n, pool)` and keeps nothing; its tag picks the pool (`dex` is dex
   AP, `wis` wis AP, none general), up to what the pool started the turn with. A reusable status, **Footsore ??**
   (`Effects/footsore.tres`: `per_tile` 1 a rank), for later skills and marks to put on.
9. **`per_tile`**: each tile walked by `travel()` costs `amount` (x rank if `per_rank`) HP through `Unit.hit`, tagged as the
   effect's tags (environmental if none), by whoever put it on. Not paid for `place()` (a teleport), pulls or pushes.
   **Meander wards it with the ground's own test**: `Unit.wards(level, extra)` = still, and the effect's rank (its level) no
   higher than Meander's rank; `passes_by()` is now that. The skill's doc says "if its rank is higher than the effect's"
   where its ground rule says "not greater": I kept one rule (equal wards).
10. **AI**: new Behaviour hook `marks(b, u)` (it would lay marks that matter now); `AI._rally()` casts such a skill just
    before a unit advances on a foe, so the walk passes over them. Warcry's: a foe in sight and none of its own marks up.
11. **UI**: `Overlay._mark()` draws a translucent square in the mark's tint, swelling (Charge!, hot orange) or collapsing
    (Routed!, dark blue) inside a faint outline; the tile card says what it does and for how long (`HUD._mark_note()`);
    the log and a float text say it went off; `toll_paid` floats the HP a walk cost.
12. **Tests changed**: `fighter_test.test_tree` used Warcry as the example of a stub "waiting on a system"; it now builds a
    stub for the sentence and checks Warcry is no stub. `gods_test.test_vetruvis` and `pockets_test` read `marks`.

## As built

- `Scripts/Battle.gd` (`Mark`, `lay_mark`, `_trigger`, `_toll`, `earthwork`, `wading`, `mark_cost`, `known_marks`, `hazard`,
  `dread`, `route`, `stride`), `Scripts/Unit.gd` (`wards`, `regain`, `afflict`), `Scripts/Effect.gd`, `Scripts/Read.gd`,
  `Scripts/Perception.gd`, `Scripts/Behaviour.gd`, `Scripts/AI.gd`, `Scripts/HUD.gd`, `Scripts/Overlay.gd`,
  `Skills/warcry.tres`, `Behaviours/warcry.gd`, `Effects/charge.tres`, `charge_ap.tres`, `footsore.tres`.
- Suite: baseline 45524 checks, 0 failed (761 tests); now 45594, 0 failed (785 tests).

## Not done

- The hazard estimate doesn't foresee `per_tile` (a flat toll a tile; Meander's partial ward isn't foreseen either, as before).
- Fire isn't a mark; zones, debris and snares aren't either. Helpful marks (Charge!) don't attract the AI or the route.
- Hidden marks have the read plumbing but no content uses concealment yet, and the HUD doesn't draw a "?" for a suspected one.
- You can't choose which foes Warcry marks toward.
