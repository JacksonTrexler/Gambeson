# Gaps left by reactions and tile marks (branch `x-gaps`)

The "Not done" lists of `docs/plans/reactions.md` and `docs/plans/tile-marks.md`. Baseline suite: 8070 checks, 0 failed (838 tests).

## Readings

- Reactions: `Battle.react()` asks every switched-on passive about a moment (`attacked`, `hit`, `fallen`) with a Cast whose
  target a reaction may swap. Only `cast()` made the first two; a cone, a blast or a flame never did.
- Interrupts: `grant_interrupt()` opened one and waited; only the HUD (`_on_interrupt`) called `AI.interrupt()`.
- Marks: `hazard()` is the one estimate behind the HUD forecast and `route()`; `stride()`/`route()` the one price.

## Calls (each open for review)

1. **Area moments: one helper, `Battle.area_blow(cast, victim, strike, tries)`.** For a foe of a hostile area skill's
   caster it asks `attacked`, then (if `tries(victim)` > 0: Wildfire's dodge) `hit`, with a Cast of its own under way
   (`resolving()`, so Interject's cut reads it), then `strike(victim, share)`. Used by the cone behaviour (Solar, Wildfire)
   and `_detonate` (Metea). Allies, the caster and non-hostile skills get no moment (as `cast()`: only a foe is a target).
   A reaction may **swap the victim** (Interject, Gallantry take an area hit for the ally beside them): I allowed it,
   since the seam does; the swapped-in unit tries (dodges) and takes it, even if it was in the cone too (then hit twice).
   Flames (`flame()`) and trap blasts (`spring()`) have no attacker's cast to swap: they ask `hit` only, `cast` null, `by`
   the setter if it's still there. No `attacked` for them (no roll to come before). Existing reactions ignore a null cast.
2. **Interrupts in simulations.** `Battle.directed` is a Callable (unit -> bool, "a person picks"); `_open_interrupt()`
   calls `AI.interrupt()` itself for every other unit. Unset (headless), every interrupt is the AI's, so combat_test and the
   game agree. The HUD sets it to "the player's own unit, not on autopilot". Cost: Battle now calls `AI` (it never did);
   the AI's pick at the HUD no longer waits `pace` (it acts as the interrupt opens); the "acts out of turn" log line is a
   non-deferred connection so it still comes first. Tests that need a person to pick (`final_act_test`, the interrupt tests
   in `reaction_test`) set `directed`.
3. **Enemy reactions in targeting.** A new hook, `Behaviour.foils(r, holder, rank) -> float` (0-1: the share of a planned
   blow the holder's reaction would likely take; default 0), asked about the same `Reaction` moment the seam builds
   (`Reaction.odds()` is `contest()` without the roll). `AI._foiled()` asks each passive of the target's side that the AI
   *reads* (Read.skills / Read.kit: an unread passive can't be weighed), per moment (attacked, hit, fallen when the blow's
   average kills), multiplies what each leaves standing, caps at **FOILED = 0.8**, and scales a positive `_strike` value by
   `1 - foiled`. Numbers: Gallantry = its cha contest odds on `attacked`; Interject = its dex contest odds on `hit` (both
   only with the eligibility `react()` has, beside the target); Final Act = **WORTH 0.25** on a killing blow while unspent.
   Not done: holding a Final Act unit back as such (the discount only lowers the kill's pull).
4. **per_tile in the estimate.** `hazard(u, c, r, nth)`: with `nth` (the tile's number in the walk, 1 on) it adds u's own
   per_tile tolls, **Meander's wards included** (same `wards(rank, nth)` as `_toll()`; so Meander is now foreseen for per_tile).
   `nth = 0` (route()) adds none: a toll every tile owes alike steers nowhere and would only trigger a pointless search.
   `HUD.drain()` passes `i + 1`.
5. **Hidden marks.** `maybe_suspicious(o)` now includes tiles with a mark hidden from o, so the HUD reads them; the HUD's
   `suspect` ("?" on the map, tile card) also takes a tile the viewer has suspicion stacks on and still can't read
   (`net < 0`), as `Battle.suspicious()` already counted. This is the foresight idiom (a muted "?" where it can't tell).
   No content lays a hidden mark yet; unchanged.
6. **Helpful marks.** `Mark.helps(u)` (enter, hits u, harms it nowhere, some effect helps) and `Battle.lure(u, c)` =
   **HELP_PULL 0.75** movement off a step onto a tile with a known helpful mark. `route()` searches when one lies in its box
   even with no danger, step cost `max(stride + dread - lure, 0)` (non-negative: the search stays valid); `AI._approach()`
   subtracts the line's lure. Less than a tile: it only tips choices between ways as long as each other. The walk's real
   price is untouched. A unit with negative foresight still walks the straight line (as for hazards).
7. **Fire as a mark: not done.** A mark puts timed effects; fire rolls fresh 1d8 + the setter's wis mod each trigger (walk,
   end of turn, wall), burns layers and spreads (`Battle.gd` ~15 sites), wards (Flamedance) and `burned` signal hang off
   `flame()`, and a dozen tests set `b.flames` directly. Folding it needs an instant-damage effect with dice on a mark plus
   a rewrite of those paths: not cheap or safe. Revisit if a second dice-rolling mark appears.

### From the screenshot pass (`docs/plans/shots-11-15.md`)

8. **Routed! colour** dark blue -> dark magenta `Color(0.62, 0.12, 0.5)`, and a glyph on every mark by `swell`: a cross for
   Routed!, a chevron up for Charge!, so they read without colour.
9. **Suspicion stacks**: the tile card says "Suspicious of it: N" and the "?" gets a small count when N > 1 (Clairvoyance adds one
   a turn). It shows the viewer's own stacks on any tile it marks.

## Tests (by seam)

- `reaction_test`: `test_area_moments`, `test_area_interject` (item 1), `test_ai_interrupts` (2); interrupt tests set `directed`.
- `gallantry_test.test_ai_weighs_it` (3). `per_tile_test`: `test_hazard_foresees_it`, `test_forecast_sums_it` (4).
- `marks_test`: `test_hud_suspects_a_hidden_mark` (5, 9), `test_helpful_marks_pull`, `test_helpful_marks_draw_the_approach` (6).
- Changed to the new rule: `final_act_test.scene` and three `reaction_test` interrupt tests set `b.directed` (a person picks).
- Mutation spot-checks (rule broken, test fails, reverted): `area_blow` skips reactions (3 fail); the AI call in
  `_open_interrupt` removed (2); `_foiled` returns 0 (2); the `nth` toll block off (4); the hidden-mark loop in
  `maybe_suspicious` off (1); `lure` returns 0 (3).

## As built

`Scripts/Battle.gd` (`area_blow`, `directed`, `_open_interrupt`, `flame`, `spring`, `_detonate`, `hazard`, `maybe_suspicious`,
`Mark.helps`, `lure`, `route`), `Scripts/AI.gd` (`_foiled`, `_approach`), `Scripts/Behaviour.gd` (`foils`, `Reaction.odds`),
`Behaviours/cone.gd`, `interject.gd`, `gallantry.gd`, `final_act.gd`, `warcry.gd`, `Scripts/HUD.gd`, `Scripts/Overlay.gd`.
