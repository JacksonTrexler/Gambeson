# Tapped, helpless, Stun, Mindless Fury, Drone

Branch `a-tap`. Baseline suite: 41775 checks, 0 failed (594 tests).

## Readings

- **Tapped** is derived, never stored, never cleansed: it's what its sources say right now. Sources:
  out of AP; ordered to its cap this turn (until the command phase wraps, then autopilot may spend the
  rest); helpless (Downed without `acts`, asleep, or any effect with the `helpless` stat) without a
  permit. Lift the source (heal the wound, cleanse Stunned, heal above 0 HP) and it is free at once.
- Two queries, split by who knows what (Unit can't see Command):
  - `Unit.tapped()`: out of AP, or `Unit.stopped()` (helpless and no permit left). Battle and the AI
    use `stopped()` (an action's own cost already needs the AP).
  - `Command.tapped(u)`: `u.tapped()`, or at its order cap without a Drone permit. `could_order()` and
    the HUD read this one.
- **helpless**: an Effect stat (`helpless`, a harmful one so it's a debuff) plus the Glossary term;
  `Unit.helpless()` is the source query (the stat, sleep, Downed without `acts`).
- **Reduced capacity**: one state, `Unit.reduced()`: acting under a permit. Mindless Fury: helpless
  but with fury actions left (mental stats count as 1). Drone: ordered past the caps this turn
  (mental mods capped at + its rank).
- Saturation (`HUD.command_sat`): tapped 0, reduced 0.5, low AP or orders given toward the cap drain
  to 0.75 (SAT_LOW was 0.55).

## Calls

- Free actions (0 AP) still go at 0 AP: "out of AP" taps for orders and the map, but a 0-cost action
  isn't blocked by it (its pay check would pass anyway).
- Sleep counts as helpless (a full action disabling effect), so Mindless Fury acts through it too.
- Autopilot after the command phase: allies ordered up to their cap (tapped by orders) with AP left
  act on their own when the turn ends (`Command.idle()`). Allies given fewer orders than the cap
  don't (unchanged); locked allies (a wasted intent order) don't.
- Mindless Fury actions: rank skill uses per own turn while helpless, counted as Grudge counts them
  (each skill use paid for). Past that it's disabled (tapped) for the turn: no infinite actions.
- Drone: a drone ignores both caps (orders per ally, allies a turn); an order past either makes it
  reduced for the turn. Its tap from AP running out still holds.
- Stun on **Brawn** (the blunt, strength Prowess tree: Paladin, Berserker), after Crushing Blow,
  its deepest skill. Prowess trees have no tiers (Branch.tier is for general trees), so depth stands
  in for "high tier". Very difficult attack = -5 to hit; difficult con check at its rank
  (`Difficulty.dc(&"difficult", r)`); Stunned for rank turns.
- Stunned: `Effects/stunned.tres`, stat `helpless`, `wound = true` (a heal clearing its rank takes it
  off), `ease = 2` (cleansing halves its rank).
- Mindless Fury on **Fury** (Berserker's own tree), after Grudge and Frenzy, needing 3 of the root's
  others: its capstone, standing in for tier 5. `classes = [berserker]` like Grudge.
- Drone on the general Caster tree at tier 4. **No Merchant tree exists** (nor a Specialist
  "Merchant" anything): left for when one is made.
- Jam's Jammed ?? stays: a short Stunned would make the low-tier Jam a full lockout, stepping on
  Stun; Jam's "instant stun" is the interrupt plus lost reactions.
- Check tag seam: `Unit.check_mod(s, kind, tags)` passes the check's tags to `check_bonus`, where a
  `check` effect with `tags` counts only for checks carrying one. Stun's con check carries `taps`;
  execute checks already carry the skill's `execute` tag (reused instead of a new `executes`).
  A later Intervention: `check` effect, `tags = [taps, execute]`, per_rank; "executes assume full
  HP" would be one line in `Battle.executed()` reading a stat (not built).

## As built

- `Unit.helpless()` (source: helpless stat, sleep, Downed without `acts`), `Unit.stopped()` (helpless,
  no Mindless Fury uses left; named so because `Unit.disabled` is Brainfog's skill table),
  `Unit.tapped()` (out of AP or stopped), `Unit.reduced()`, `Unit.fury_acts`, `Unit.overdriven`;
  `Unit.mod()` applies the reduced-capacity mental cost (`FURY_MOD` -5, a stat of 1; Drone `mini(mod,
  rank)`). Both reset in `refresh()`.
- `Command.tapped(u)`, `within_caps()`; `under_caps()` lets a Drone past; `order()` marks
  `overdriven`; `could_order()` reads `tapped()`; `idle()` adds capped allies (autopilot).
- Hold (`HUD.hold`) now locks the held ally (`Command.lock`), so it neither takes orders nor goes on
  autopilot when the turn ends - otherwise a hold at a 1-order cap would autopilot.
- Gates: `Battle._acting`, `AI.act`, the AI's craven fear read `stopped()`; the AI's finish-last
  scoring stays on Downed foes only (a Stunned or sleeping foe isn't deprioritised). `Downed.changed`
  drops a channel only if stopped (Mindless Fury keeps it).
- HUD: `command_state` gains `&"reduced"` (glows as ready); `command_sat` 0 tapped, 0.5 reduced
  (`SAT_REDUCED`), else drains to `SAT_LOW` 0.75 by the larger of AP spent squared and orders given
  of the cap. Reasons: `_why_tapped()` (Mindless Fury spent, asleep, Downed, "Stunned: helpless till
  healed or cleansed", out of AP).
- Check seam: `check_bonus(s, kind, tags)`; Stun carries `taps` as a skill tag, so its save does.
- Mechanics: stats `helpless` (harmful), `mindless`, `drone`; terms `tapped`, `helpless`, `taps`
  (`--human`), `reduced` ("Reduced capacity ??"); `Effects/stunned.tres` (wound, ease 2).
- Skills (`--human`): `stun` (4 AP, 2 Energy, reach 1, 1d6 + str, -5 to hit; on a failed difficult con
  save, Stunned rank turns, and an interrupt if that stops it), `mindless_fury` (Fury, after Grudge
  and Frenzy, needs 3, Berserker only), `drone` (Caster tier 4, magical tag).
- Tests: `stun_test`, `mindless_fury_test`, `drone_test` (new). Changed to the new rule:
  `command_test.test_idle` (a capped ally goes back on the autopilot list; a locked one doesn't),
  `hud_test.test_command_colour` (last tenth of AP now below 0.8, SAT_LOW 0.75).
- Suite: 41819 checks, 0 failed (602 tests).
- Not done: no screenshot of the new saturation; 0-AP free actions still go (see calls); the
  Intervention skill and "executes assume full HP"; a Merchant tree.
