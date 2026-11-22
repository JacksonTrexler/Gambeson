# AI support: restoring skills, Intervention, switching, Focus, Clairvoyance

Branch `n-ai`. Baseline suite: 42616 checks, 0 failed (648 tests). Items from the todo lists in
`recovery.md`, `rescue.md`, `resources.md`, `focus.md`, `clairvoyance.md`. All in `Scripts/AI.gd` plus a
hook on `Behaviour`. Tests: `Tests/ai_support_test.gd`.

## Readings and calls

1. **Heal, Megaheal, Energize, Resuscitate: one generic "what does this restore".**
   - `Behaviour.restores(c: Cast) -> Dictionary` (pool -> expected amount; pool is `&"hp"`, `&"energy"`
     or a Reserve). Default `{}`. Heal declares its mean (dice average + mod + rank), Energize the Energy
     it can give now (its pair, further pairs, within `room()`), Resuscitate what it is below 0 plus its
     share. A later healing behaviour declares its own and the AI picks it up.
   - *Call:* a hook on the behaviour taking the same `Cast` that `apply()` takes, not a Skill field and
     not a change to `Skill.heals()`. `heals()` is read by `Battle.cast()` (`mend(..., skill.healing())`),
     so making it true for Heal would heal twice. `Skill.gd` is untouched.
   - `AI._restores(b, u, s, t)` sums what behaviours declare, plus the HP of the old `heal_mods` /
     `heal_bonus` skills; `AI._mends()` is "not hostile and restores HP". `_heal()` and `_tend()` use it.
   - *Call:* `_heal()` now picks the best (skill, ally) over all its healing skills by `want()` (the first
     skill on a tie), not the first skill with any target, so Resuscitate wins on a Downed ally when its
     want is higher; it checks `Behaviour.fits()` for each target (Resuscitate: only the Downed).
   - `want()`'s pragmatic "heal would be wasted" test reads the declared HP restore instead of
     `Skill.healing()`.
   - *Call:* non-HP pools (Energize) are not healed on demand: `_replenish()` runs last in a self-directed
     turn, after the strikes, casting a restorer on itself once the pool is at half or less (Energy only
     if it runs on Energy, a reserve only if it spends from it). So it never costs a blow, and a Mana
     user (no Energy) never wastes Energize.
2. **Intervention.** `_support()` was for `grants` skills only. *Call:* it now also takes any
   non-hostile, not self_only, not dual/either skill with effects of its own (Intervention, Rally,
   Rejuvinate, Level Up, Blur, Invisibility, Embellish), on an ally in reach, or itself (last), that
   lacks the first effect, and each target must pass `Behaviour.fits()`. Self-only buffs are still left
   alone (Bulwark, Hide...): casting them every turn would reshape every sim.
3. **Switching Mana/Stamina.** `_switch()`, on a self-directed turn, when it holds no channel, can't
   strike anything from where it stands (`_could_strike()`) and can pay for none of its skills worth
   something (price over 0, a blow or a restore): it toggles to the other pool if that pool could pay for
   one (`_pays()`: `Reserve.only`, `bars`, `covers()` of the cost). The switch is a channel, so it ends
   the turn idle; next turn `_finish_switch()` toggles again to complete it (carry-over after one turn
   held) and the turn goes on. *Call:* finishing next turn, not waiting for the carry to fill: the
   switch destroys what it leaves anyway, so one idle turn is the price.
4. **Focus.** `_steady()`: holding an `aims` reserve below full, a ranged attack it would pay from it,
   nothing it can strike from here, and an idle turn so far: it rests, building Focus (50% of max a
   rest). Bounded: a rest or two fills it, then it walks up. *Call:* "save it for a shot" is mostly
   already true (Focus pays first for ranged only); the AI adds `FOCUS` (1.0) x `Unit.focus_forecast()`
   to a strike's score, so a shot that would empty Focus (+rank to hit) outranks an equal one. No
   deliberate holding back of a shot to build more (that needs a planner).
5. **Clairvoyance.** `_scry()`: no foe in sight, no clue to search (`_search()`), nowhere its side last
   saw a foe (`last_seen`), no channel held: it casts a `pings` skill, then hunts/searches on the pings'
   suspicion in the same turn. *Call:* `act()` no longer holds still for a `pings` channel (the Metea
   rule "holding a channel, hold still"): it acts on what it sensed, which ends the channel at the turn
   end. Otherwise a scryer would stand scrying forever, even with a foe in reach.

## As built

See the commit; the notes above are what was built. Details to know:

- `Behaviour.gd`: `restores()`. `Behaviours/heal.gd`, `energize.gd`, `resuscitate.gd`: one override each.
- `Scripts/AI.gd`: `_restores`, `_mends`, `_replenish`, `_low`, `_finish_switch`, `_switch`, `_pays`,
  `_could_strike`, `_steady`, `_scry`; `_heal`, `_support`, `_tend` reworked; `act()` calls them.
- Tests: new `Tests/ai_support_test.gd` (11 tests). No existing test changed except as the suite's
  combat_test count notes.

## Not done

- HUD "help" orders (`Skill.serves(&"supportive")`) still don't count Heal: that is `Skill.heals()`,
  which a sibling branch is reworking. The AI's own `_heal()` is what the HUD order runs, so a Helpful
  order does heal now.
- The AI doesn't hold a shot back to build Focus, and doesn't prefer Resuscitate over Heal on a Downed
  ally except by list order on a tie.
- Switching is to the other pool that *currently holds* enough: a unit with one toggle and no Energy
  has nowhere to switch to.
