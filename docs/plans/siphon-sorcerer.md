# Siphon, Overcharge, Energy Transfer, Powerful and the Sorcerer

The user's design (verbatim, the parts built here):

> Energy is ubiquitous, but it's only upside to Power is Power may be easier to siphon / make unit eligible for degenerate bonus effects.
> Caster Active: Energy Transfer: low damage `energy` attack attacking a target's resource instead of their health (`siphon`). Unit recovers Energy in same amount, or at rank * 20% efficiency if they don't have an energy bar or it's full as overcharge energy. Overcharge decays over rank turns.
> `Overcharge` is an effect that functions as an added resource buffer.
> Energize:
> ^these are ways for Mana users to get regular energy without toggling.
> Starmen, Sorcerers
> Power transfer:
> Sorcerers:
> Stellar Soul: Beings with a heart that originated from and yearns for the Astral.
> Root: Powerful: use power instead of energy. Power *is* energy, effects that grant energy will grant power to unit instead.
> Borrows many spells astral creatures like starmen and motes use.

## Readings and calls (written before building)

What exists: Power is `Unit.powered()` (the `powered` Effect stat, from `Skills/powerful.tres`): the unit's
`energy` field *is* its Power - its bar pulses (`POWER_COLOR`), and `recover()` never brings it back. Energy
damage (`&"energy"`, `Unit.drain()`) already takes Energy first and carries a share to HP. Starsap
(`Battle._sap()`) drains Energy into Power. "Energized" is a unit property (`Properties/energized.tres`:
resists energy), not a skill. Neither Energize nor Power Transfer exists anywhere.

1. **Siphon** (tag, `--human`): a siphon attack's damage, after mitigation and luck as `drain()` has it,
   comes off the target's resources and never its HP - its Overcharge first (the outer buffer), then what it
   currently spends: the fund its last skill was paid from (Energy or a reserve it still spends) if that
   holds any, then Energy, then its other reserves it spends, fullest first. It spills from one to the next
   until the damage is used up or the unit is empty. Siphon takes precedence over the energy rule (no carry
   to HP). *Call - several reserves:* "currently spends" read as its last payment (`Unit.paid_with`), so a
   Mage casting on Mana loses Mana, a Fighter swinging on Stamina loses Stamina.
   - *Call - Power is easier to siphon:* a powered target loses x1.5 (`Unit.POWER_SIPHON`, rounded). Why
     1.5: Power never comes back on its own, so each point siphoned is lost for the battle; doubling
     would let two Energy Transfers empty a Starmote (whose max HP *is* its max Power), while x1.5 is
     enough to make Power the obvious target the user describes.
2. **Overcharge** (status, `--human`; `Effects/overcharge.tres`, Effect stat `overcharge` marks it): an
   extra buffer, `Unit.overcharge` points, spent before any fund on a point-for-point cost (not a reserve
   that pays whole costs: Sweet Nothings) - and it counts toward what the unit can afford (`funding()`,
   `can_strike()`): the only change to payment code. It decays to nothing over the granting skill's rank in
   the holder's turns, the turn it's put on not counting (as every status put on in one's own turn):
   each turn's end takes (what's left / turns left), rounded up, so 10 over 3 turns goes 10, 6, 3, 0.
   Granted again while it lasts: the points add, the timer restarts at the new rank. Spent to 0, the status
   ends. *Call - HUD:* an `OC` row in the unit card right under its reserve and Energy rows, only while it
   holds any; the status's own icon shows with the other effects. No overhead bar.
3. **Energy Transfer** (`--human`, active): `energy`, `siphon`, `magical`, `offensive`, `int`; 3 AP, 1
   Energy, range 4 (Energy Missile's), 1d4 at rank I, 1d6 from III, no mod - low damage. The caster then
   gets what it drained: as Energy, up to its max; what doesn't fit (its bar full, or no bar: max Energy 0)
   comes as Overcharge at rank x 20%, rounded down, for rank turns. *Call - tree:* the general Caster tree
   (`Trees/general_caster.tres`), which every Mana user (Mage, Wizard, a Druid's Astral) reaches: the user
   calls it a "Caster Active", and it is a way "for Mana users to get regular energy without toggling". At
   tier 2 there, the rank of a Caster tier 2 like its neighbours.
4. **Powerful / grant routing:** every effect that gives Energy goes through `Unit.grant_energy(n)` -
   Starblade's refill, an Energy potion, starlight on the lattice, Starsap, Energy Transfer - which adds to
   `energy`, that is to Power on a powered unit, and returns what it got. Regen (`recover()`) is not a grant
   and stays as it is (Power never regenerates). Powerful's description says that its grants arrive as
   Power. Powered units are already identifiable to future effects by `powered()`; nothing more is added -
   no "degenerate bonus effects" invented.
5. **The Sorcerer** (`--human`): caster focus, noun Caster, tree "Stellar Soul" (described as the user put
   it), root skill Powerful (the existing `Skills/powerful.tres`, first on the tree), borrowing the astral
   creatures' spells as they are (the same resources): Energy Missile (the Starmote's attack), Starsap
   (the Starman's); Energy Transfer it reaches on the general Caster tree, as a caster. Strike and Starkind (inherent, what a star creature *is*) are not
   borrowed. *Calls:* stats by analogy with the Mage and Wizard (the caster defaults) with int and cha
   swapped - int 10, cha 15 - since Energy Missile is a cha spell; no Mana (it runs on Power: no Mana
   reserve, no Mana skill); a robe and a staff like the Mage and Wizard, an Energy Potion for their Mana
   Potion; god Urlo (magic, energy); its tab colour a pale starlight blue.
6. **Open:** Energize and Power Transfer, named but not defined - not built (see below).
