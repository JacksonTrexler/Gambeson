# w9-siren (queue card 6): Siren trait passive from 4fe2c05

Goal: ONE `trait` passive on the Siren carrying: +2 str/dex/con only on water, cheaper water move, Rake x2 vs trusting, `aquatic` tag, movement 2, shows_boon. Detective/Ambush/Opportunist: rebuild or record.

## Readings
- Main Siren (Scenes/siren.tscn): Alluring is its innate trait; Oceanic (user's) is a toggle DRAWBACK (-4 str/dex/con unless on water/wet/moist, `Effect.unless_on` already on main). Left untouched.
- aquatic tag: has_tag() counts a learned skill's tags, so the trait skill's `aquatic` tag gives it. Battle._cost(): aquatic -> water costs 1 to enter (already "cheaper movement in water"), and no drowning (_grip). So 4fe2c05's `move_cost -2 [water]` effect is redundant: not added.
- trusting: Battle._trusts(o,t) (read(o,t).faction null or attitude ally). 4fe2c05 used `crit_trusting` Skill flag + per-hit `power *= 2`. Alluring's Friendly stance makes foes read a Siren as ally -> Rake doubles.
- shows_*: Skill carries a look (Alluring), Unit._take_looks() copies it, Perception._lie() reads it into Read. boon rides the same path.
- Reactions on main have no "ran into" trigger; Investigation.gd/marks/watch gone.

## As built
- `Effect.only_on` (terrain tags it needs; generic twin of `unless_on`): Unit.stat() reads it; Effect.describe says "only on x". Util/tres.py NAME_LISTS knows it. Not Siren-specific.
- Effect stat `betrayal` (mechanic.py stat; +fraction damage to targets that trust the holder; tags-conditioned): read in Battle.cast() damage line via `_trusts(target, caster)`, foes only.
- `shows_boon`: Skill field + Unit field + Read.boon; Unit._take_looks() copies it from a skill, Perception._lie() puts it on the Read of the fooled. Nothing displays it yet (as in 4fe2c05).
- `Skills/seaborn.tres` (Seaborn ??, ai, trait, tags aquatic): +2 str/dex/con only_on water; betrayal 1.0 on slash; shows_boon "Something extremely beneficial". Innate on Scenes/siren.tscn (unit.py trait); `movement = 2` on the scene.
- Tests/aquatic_test.gd: test_seaborn (only_on on/off, wet vs water, aquatic cost, movement, boon), test_rake_trusting (same seed, fooled = 2x seen-through).
- Mutation spot-checks (each failed its check, reverted): only_on read -> `if false`; betrayal term dropped from damage; boon copy off.

## Calls (for questions)
1. Trait is a NEW skill "Seaborn ??", not Oceanic: Oceanic stays the user's toggle drawback (-4 unless water/wet/moist); on water they stack (str 14, as 4fe2c05).
2. Cheaper water movement = the `aquatic` tag (existing Battle._cost: water costs 1) rather than 4fe2c05's `move_cost -2 [water]`, which it makes redundant. Side effect (as 4fe2c05): Siren can't be drowned.
3. Rake double damage = generic stat `betrayal` tagged `slash` (every slash skill the Siren holds, not Rake alone; Rake is its only one), not 4fe2c05's `crit_trusting` Skill flag. "Trusting" = Battle._trusts(): reads the holder as ally or can't make out its side (Alluring's Friendly stance feeds it). Applied in Battle.cast()'s main damage line only (not Strike chains, cones, traps).
4. `shows_boon` on Skill (field 106, FLAG_CEILING 105 -> 106, question for the user: the shows_* look family a trait carries) and Unit.
5. movement 2 set on the scene (a unit stat), not an Effect on the trait.
6. Name "Seaborn ??" and stat id `betrayal` AI-made.

## Questions: not rebuilt
- Detective (stat `detective`, marks recon on units/tiles): needs Investigation.gd (investigate/watchers, Unit.marks), removed from main; rebuild means a whole investigation system. Missing: that system.
- Ambush (`watch` flag: set a watch with another skill of the same hostility, with Coordinate): needs the Battle watch/trigger machinery and Skill.watch flag (creep); `ambush` tag is only a dictionary term now. Missing: a watch hook (a Behaviour on a `moved`/`seen` trigger).
- Opportunist (`reaction` flag: uses its first active on enemies that run into it): Reaction triggers on main are attacked/hit/crit/fallen only, no "moved beside it"; needs a new trigger fired from Battle's move path plus a Behaviour.react (chaser.gd pattern). Smallest of the three: best next.
