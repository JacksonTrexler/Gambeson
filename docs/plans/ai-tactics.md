# AI tactics: slayer conditions, Focus, Resuscitate, Kick's tiles, Grudge (q-ai, 2026-11-14)

Branch `q-ai`. Open items from `ai-support.md`, `slayer.md`, `downed.md` and `skill-tooling.md`, all in
`Scripts/AI.gd` plus three hooks on `Behaviour` and one forecast line in the HUD. Baseline suite: 45467
checks, 0 failed (741 tests); `combat_test` alone 38732 checks. Tests: `Tests/ai_tactics_test.gd`.

## Readings and calls

1. **The AI reads what the player sees.** `AI.score(u, s, r, b, t)` (the battle and target are optional, so
   the old two-argument callers still work) now takes the chance to hit from `Battle.hit_chance(..., b)`
   - the skill's edge, its behaviours' `edge()` and `guard()` (Gank's ambush, Poach's advantage, Spike's
   Defense), the target's Defense, Focus - the damage from `damage_range(u, s, t, b)`, and scales the
   blow's worth (damage, the KILL bonus, effects) by that chance.
   - *Call:* the chance uses the target's **true** Defense, though the HUD hides it when the player can't
     make it out (`_defense_shows`). The AI used to ignore Defense entirely, so this is not new cheating
     by kind; a read-based estimate would need a Defense on `Read`.
   - *Call:* `_strike` still adds `FOCUS * focus_forecast()`; `hit_chance` now carries that bonus too, so a
     last-Focus shot is counted twice. Left as a tie-break so the existing sims keep their shape.
2. **What those can't say: two more generic hooks** (`Behaviour.gd`, both pure, both added to
   `Util/skill.py`'s HOOKS so `check` accepts a behaviour that only has them):
   - `refunds(c, p) -> float`: the share of its AP price expected back, given the chance p it lands.
     Poach: 0.5 when `easy()`; Slam Jam: p/(rank + 2). The AI adds `share x AP cost x AP` (`AP` = 1.5 HP
     per AP) to the score. *Call:* AP only, not the Energy/Focus refund: Energy has no price in the score
     anywhere else. 1.5 HP per AP is a guess (a 3 AP, 1d6 + 2 strike is about 5 HP).
   - `unguarded(c) -> int`: the Defense the cast costs its caster. Sutemi: the tiles it would lunge. The
     AI subtracts `DEFENSE` (0.5) per point. *Call:* 0.5 HP per point, a guess: each point is about 5%
     more hits taken for a turn, and a blow is about 5 to 10 HP, over the foes in reach.
   - No per-skill branches in the AI: a later behaviour joins by overriding either.
3. **Focus.** `_steady()` already rested when nothing was in reach. It now also rests when what is in reach
   is only ranged attacks none of which is likelier than `SHOT` (0.5) to hit, **and** a rest would give
   Focus enough (`builds` x max) to pay for a ranged attack it can't pay for from Focus now, with a Focus
   stat to add. Melee in reach, or a decent shot, always wins; Focus already enough or full: it shoots.
   Bounded: after one rest it can pay, so the weak-shot test no longer holds.
   - *Call:* "worth shooting" is the hit chance (0.5), not the score: it is what Focus changes (+rank to hit),
     and it reads the same on any ranged skill.
4. **Resuscitate first.** New hook `Behaviour.revives(c) -> bool` (Resuscitate: a Downed target).
   `AI._heal()` adds `RESCUE` (1.0) to the want of a skill that revives its target. *Call:* a hook, not
   "fits() is narrower than Heal's", which can't be asked of a behaviour without a target to refuse; and a
   bonus, not a hard rule, so an unaffordable Resuscitate still falls back to Heal.
5. **Kick's tiles, one function.** `Behaviour.foresee(c) -> {lo, hi, notes}` (HP it takes off the target
   beyond the blow, and a line for each rider); `Battle.foresee(u, s, t)` sums a skill's behaviours.
   `Kick.outcome(b, from, to)` reads the ground once; `apply()` and `foresee()` both use it, so the forecast
   can't drift from the effect. The HUD (`_hurt`) adds the trap's dice to the HP span it draws and keeps
   the notes, which the unit's hover tooltip lists under its read ("Soaks it (2 turns)"). The AI adds the
   trap's mean and `RIDER` (1.0) per note.
   - *Call:* a trap's damage is its dice, before the target's mitigation and ignoring its blast (so a
     kicker standing in the blast, or an ally of the target, isn't counted).
   - *Call:* the line's tie-break on equally near tiles (`Battle.line`, `contest()`) may roll a coin, so on
     such a line the forecast can differ from the kick.
6. **Grudge, cheap halves.**
   - *Healing itself back up* (`_save_self`): Downed under Grudge, it casts a mending skill on itself
     when what it declares it restores (`_restores()`, mean) is more than it is below 0 - it is saved
     and standing rather than spent. Strongest such skill. A heal that might not lift it, it doesn't
     gamble on. It costs a skill use against its allowance, the use that saves it.
   - *Starving it of melee* (`_starve`, before `_steady`): a foe Downed under Grudge that owes a melee
     (`Downed.melee`, not yet made this round), when it is the **only** foe left standing that u can place:
     u doesn't give it the blow. Inside its reach (movement + 1) it walks away (`_away`); outside, it
     holds still rather than close, unless it can shoot from where it stands. One blow that ends it (its low
     roll past the Downed limit) is always taken. *Calls:* only when the Grudge unit is the last foe: with
     others around the retreat would give up real attacks for a maybe; it does not plan for allies in the
     Grudge unit's reach (they would take the blow), nor for a second round. Straight-line tiles, as
     `Command.tiles`, stand in for its walk.

## As built

- `Scripts/AI.gd`: `score`, `_strike` (passes the battle and target), `_steady`, `_heal` + `_revives`,
  `_save_self`, `_starving`, `_starve`; constants `AP`, `DEFENSE`, `RIDER`, `RESCUE`, `SHOT`.
- `Scripts/Behaviour.gd`: `refunds`, `unguarded`, `foresee`, `revives`. `Scripts/Battle.gd`: `foresee()`.
  `Scripts/HUD.gd`: `_hurt` (adds foresee), `_tip_text` (notes). `Util/skill.py`: HOOKS.
- Behaviours: `poach.gd`, `slam_jam.gd` (`refunds`), `sutemi.gd` (`unguarded`), `kick.gd` (`outcome`,
  `foresee`), `resuscitate.gd` (`revives`).
- Tests: new `Tests/ai_tactics_test.gd` (11 tests, 31 checks). No existing test changed. Counts: the suite
  45467 -> 45614 before the new file (combat_test alone 38732 -> 38879: its sim fights now weigh hit chance).

## Not done

- A Defense on `Read`, so the AI estimates a foe's Defense as the player does rather than knowing it.
- Starving Grudge with allies in its reach, or over more than one round.
- Poach's Energy / Focus refund, and its regain on a neutralizing blow, aren't priced; neither is Slam Jam's
  interrupt.
- Kick's trap blast on bystanders; Kick's push into a unit or edge (the forecast says "back", not how far
  it will really go).
