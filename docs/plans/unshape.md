# Forced unshape (branch y-unshape)

Reading: `Battle.neutralize(u, how)` (docs/plans/slayer.md) tells downed, down, killed; slayer.md:26,136 left
"a forced unshape calls it with `unshaped`". Shapes a unit can be in: `Unit.form` (Beastshape) and the mist
(Vaporize, a toggled passive whose effect has stat `mist`). No polymorph exists in the code, so none is handled.

## Calls
1. **One hook, `Battle.unshape(u, by) -> bool`**: ends the form (emits `shaped(u, "", "")` like the voluntary
   path, so the HUD follows) and switches off any on toggle whose effects carry `mist`; if anything ended,
   `neutralize(u, &"unshaped")`; false and silent when u was in no shape. `by` is unused for now (reserved
   for reactions); `neutralized`'s own `by` is still `last_hit_by`.
2. **Effect stat `unshape ??`** (via `mechanic.py stat`), the data-ready seam: any skill, item, mark or tile
   effect carrying it forces the unshape as it is put on, through the existing `Battle.drive()` call all three
   application sites already make (cast, behaviour `put`, timed effects). It is erased at once: nothing stays
   on the unit. Name is AI-made, so ` ??`.
3. **Voluntary unshape stays quiet**: Beastshape used shaped still calls `Unit.unshape()` directly, no
   neutralize. A mist turning itself off is a plain toggle.
4. **No new skill.** Open question for the user (?126): should skills that force unshape exist (a Dispel,
   a Hex of the beast), and should unshaping be a Slayer/anti-druid tool or a general one? Also: does a mist
   forced out count as "neutralized" for Poach-like regains? Built as yes (it is taken out of its role).
5. Poach hears it for free: its `felled` fires for the cast's own target, so a blow whose effect unshapes
   its target regains (tested through a duplicated Poach with the stat on it).

## As built
- `Scripts/Battle.gd`: `unshape()`, a 4-line guard at the top of `drive()`.
- `Scripts/Effect.gd`: stat `unshape`, name, description (by `mechanic.py`).
- Tests (lean: no new file): `Tests/slayer_test.gd` `test_unshaped` (form, mist, stat, voluntary quiet),
  `test_unshaped_poach` (regain). Mutation spot-checks, each failed then reverted: dropping
  `neutralize(u, &"unshaped")` (4 fail), skipping the mist branch (1), routing Beastshape's voluntary turn
  back through `unshape()` (1).
