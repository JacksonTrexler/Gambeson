# Rescue and interrupt: Resuscitate, Intervention, Borrowed Time, friendly fire

Branch `b-rescue`. Baseline suite: 41838 checks, 0 failed (607 tests). The user's texts are in todo.md
under 84 and 85.

## Resuscitate

Readings and calls:
- "adjacent downed unit immediately recovers with rank * 5% hp": it comes back *up* with rank x 5% of
  its max HP, not a heal of that much - a heal is what its HP is below 0 plus the share, so a unit deep
  in the negatives is still saved. One heal, through `Battle.mend()` -> `Unit.heal()` (the
  `being_healed` path every recovery takes, so Molothrus and a-recover's Recovery Endurance join).
- Only on a Downed ally (`hostile = false`: no reviving foes); used on anything else it's refused
  before it's paid for. That needed a target filter: a generic `Behaviour.fits(b, caster, target)`
  hook that `Battle.cast()` asks (every behaviour must allow it), rather than a Skill flag.
- General Specialist tree, tier 4 (its tiers run 1-7; Drone, also "mid", sits at 4 on Caster).
  3 AP, 2 Energy, reach 1, tags physical + specialist (like First Aid).
- The caster gets the rescue XP (`healed_by`, `Battle.rescued()`).
- Not done: the AI doesn't use it (it isn't a `heals()` skill), and the HUD still offers it on any ally
  in reach (the cast is refused).

## Intervention

Readings and calls:
- Placed on **Divinity: Eros** (`Trees/eros.tres`), after Renew - the one divine tree both Cleric and
  Paladin have today. a-gods is restructuring these trees into a god system: move the branch there.
- 3 AP, 2 Energy, an ally (or itself) within rank tiles; Bless lasts rank turns (duration not given).
  Tags magical, wis, bless.
- `bless` is a Glossary term (condition, `--human`) and a tag on the skill; the buff is three of the
  skill's effects, each named "Bless" (shown as one), all data:
  - `regen` 5% x rank tagged `downed`: heals as its side's turn starts only while Downed. `_mend()` now
    asks regen with `Unit.state_tags()` (`downed` while Downed), so any regen tagged downed works so.
    From below 0 it climbs back and is saved once above 0.
  - `hale` (new Effect stat, "Hale ??"): every execute reads `Unit.execute_share()` - HP left / max,
    or 1 while hale. Readers: `Battle.executed()` (the cut on an execute-tagged skill's defensive
    check), `Battle.last_stand()` (Death), Luun's Smite threshold (r x 5% HP: a hale unit is never
    under it - "much less likely" becomes "can't", since it isn't a check).
  - `check` +rank, defensive, tagged `taps`, `execute` (the seam Stun built).
- The seam made sturdier: `last_stand()` against an execute now adds check effects tagged execute;
  the `save` contest (Haluca's kind) now passes the skill's tags to the target's check (it didn't).
- "Any check added later, whether or not the developer is aware": `skill.py check` now fails a skill
  that puts on a helpless/sleep effect (inline, an Effects/ file, or preloaded by its behaviour) without
  the `taps` tag, or that `kills` without `execute`.
- Test proves it with a throwaway `Skill.new()` tagged taps/execute (`intervention_test.test_seam`).
