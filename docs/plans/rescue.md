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
