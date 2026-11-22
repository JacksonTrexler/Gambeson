# Focus, and Stamina's recovery

The user's rulings (verbatim):

> stamina recovers alongside energy, rank bonus if resting

> focus is a resource that rangers and mages can access. Focus: builds up quickly, only while resting.
> can be used in place of energy. if fully used to cast ranged attack skill, rank bonus to accuracy

> (Jam) Deals damage to focus as well, same as physical damage received.

Builds on `docs/plans/stamina.md` and `docs/plans/channels-jam.md`.

## Readings and calls (written before building)

1. **Stamina's recovery.** "Alongside energy" is read as: on the same turn-end tick and by the same rule
   as Energy (`Unit.recover()`): (con mod + wis mod) / 2 a turn resting (at least 1, a part of a point
   below 0), half that with light activity, none busy. A resting turn adds the Stamina passive's rank.
   - *Call:* Stamina keeps its own running fraction (`Unit.reserve_rest`). It comes back even when
     Energy is full, and when its Energy is Power (which never comes back by itself): Power is a rule for
     the Energy bar, not for the unit.
   - *Call:* the rank bonus comes only from resting (`activity() == &"rest"`). An idle channeler has
     light activity, so it gets half the rate and no bonus, as the channel rule already gives it for
     Energy.
2. **Focus, the reserve** (`Reserves/focus.tres`): `base` 2 and `reserve_mod` wisdom, like Stamina's
   constitution. Max is (wis mod + 2) x rank. *Call:* wisdom, because Focus is attention and both
   classes are wisdom-leaning watchers or casters. It pays point for point for any skill (no `only`).
   - *Starts empty* each battle (`Reserve.empty`). Nothing fills it at battle start.
   - *Builds quickly, only resting* (`Reserve.builds` 0.5): half its max, rounded up, on each turn that
     counts as rest. *Call:* two rests fill it. Energy needs about five turns from empty at a typical
     rate of 2, so this is "quickly" without being free. A channeler isn't resting and builds none.
     Light or busy turns build none. It doesn't recover alongside Energy.
3. **Who** (the Focus passive, `Skills/focus.tres`, `--human`, tagged specialist and magical so it fits
   either typed slot):
   - The Ranger's **Bounty** root (Observe, Snare, Special Eyes): the hunter who watches and waits, the
     root a bow-ranger takes. Scout already holds Stamina, and a Ranger with both is the case the payment
     order is built for.
   - The Mage's **Commitment** root ("the extra mile", "Mages reward sticking to one"): holding still
     to build Focus, then spending all of it on one shot, is commitment.
   - *Call - a name clash:* that root's first stub was an AI-named passive also called Focus (`ai`,
     "Focus ??", stub ?70: own-element spells +rank damage). The user's Focus takes the name. The stub
     is renamed **Fixation ??** (`Skills/fixation.tres`). Its plan, position and Resonance's prerequisite
     are unchanged. Piercing Focus keeps its name.
4. **Payment order** (`Unit.funding()`, `Reserve.aims`):
   - For a ranged attack (`Unit.ranged()`: an attack roll, reach past the adjacent tiles, span > 1.5),
     Focus pays first (after a skill's own `needs`). That is the use it's built for.
   - For anything else, Focus pays only once Energy can't (the existing last step).
   - *Call:* this way a Ranger with Stamina and Focus pays Stamina for a melee swing, a Move ?? or a
     Snare, and Energy for the rest. Its Focus is never spent by accident on something that can't gain
     from it, and the player still has no payment choice to manage (none exists in the HUD).
     "In place of Energy" holds both ways: it replaces Energy on a shot, and it backs Energy up.
   - *Call:* a ranged attack goes to Focus even when Focus won't be emptied. It's spent where it counts,
     and emptying it is what earns the bonus.
5. **The accuracy rule.** When paying for a ranged attack spends the last of the reserve that paid it
   (Focus), the attack roll gets + the holder's `focus` Effect stat: 1 a rank on the passive (a new stat,
   `mechanic.py stat focus --human`). Read by `Unit.focus_bonus()` in `Battle.cast()`'s attack bonus.
   The hit forecast (`Battle.hit_chance()`) counts it through `Unit.focus_forecast()`. *Call:* "fully
   used" means the store is 0 after paying. Focus 3 on a 1-cost shot gives no bonus, and the third such
   shot does.
6. **Jam drains Focus.** Behaviours run before damage, so a new Behaviour hook `dealt(c, n)` runs after
   a cast's damage, with the HP the target lost. Jam's takes as much off the target's Focus. *Call:* HP
   actually lost ("damage received"), after mitigation.
7. **Colour.** Focus is violet, `Color(0.66, 0.42, 0.95)`: hue about 270 degrees. Energy is yellow
   (#e8c547), Stamina yellow-green, HP green, mana blue (about 220) and Sweet Nothings pink. Violet sits
   apart from all of them, and from Power's orange.

## As built

As planned. Details:

- `Reserve.gd`: `with_energy` (Stamina), `empty`, `builds` (Focus 0.5), `aims` (Focus).
- `Unit.gd`: `recover()` calls `_recover_reserves(activity, rate)` before its Power check. Reserves that
  start `empty` start at 0 in `_ready()` and `pick()`. `giver_rank(r)`. `funding()` has the `aims` step
  for `ranged()` skills. `pay_for()` sets `emptied`. `focus_bonus()`, `focus_forecast()`.
- `Battle.gd`: the attack bonus adds `focus_bonus()` and `hit_chance()` takes off `focus_forecast()`.
  `_behave()` returns its Cast, and each behaviour's `dealt()` runs after the damage tiers.
  `Behaviour.gd` has the `dealt` hook. `Behaviours/jam.gd` drains Focus and says so.
- `Skill.gd`: a reserve-giving passive's description adds "empty/full as each battle starts", "comes
  back as Energy does, rank more on a turn it rests", "builds 50%... only resting", and "pays first for
  a ranged attack".
- Tests: `Tests/focus_test.gd` (reserve, who, building, not busy or channeling, payment order, accuracy,
  Jam), `Tests/stamina_test.gd` (`test_recovers`, `test_recovers_light`).

## Left open

- The AI doesn't rest to build Focus or save it for a shot. Focus only pays if a unit happens to rest.
- No museum unit holds Focus, so the sims are unchanged by it. Stamina now recovers, which changes them
  only for units holding Stamina (none in the museum).
- The HUD bar shows only a unit's largest reserve (`main_reserve()`). A Ranger with Stamina and Focus
  shows whichever max is bigger.
- The todo docs aren't updated (out of bounds here). The calls above (Fixation ?? for the stub, wisdom,
  half a rest, the order, Power not blocking Stamina, HP lost for Jam) want a question number when
  merged.
