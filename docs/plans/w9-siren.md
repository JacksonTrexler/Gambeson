# w9-siren (queue card 6): Siren trait passive from 4fe2c05

Goal: ONE `trait` passive on the Siren carrying: +2 str/dex/con only on water, cheaper water move, Rake x2 vs trusting, `aquatic` tag, movement 2, shows_boon. Detective/Ambush/Opportunist: rebuild or record.

## Readings
- Main Siren (Scenes/siren.tscn): Alluring is its innate trait; Oceanic (user's) is a toggle DRAWBACK (-4 str/dex/con unless on water/wet/moist, `Effect.unless_on` already on main). Left untouched.
- aquatic tag: has_tag() counts a learned skill's tags, so the trait skill's `aquatic` tag gives it. Battle._cost(): aquatic -> water costs 1 to enter (already "cheaper movement in water"), and no drowning (_grip). So 4fe2c05's `move_cost -2 [water]` effect is redundant: not added.
- trusting: Battle._trusts(o,t) (read(o,t).faction null or attitude ally). 4fe2c05 used `crit_trusting` Skill flag + per-hit `power *= 2`. Alluring's Friendly stance makes foes read a Siren as ally -> Rake doubles.
- shows_*: Skill carries a look (Alluring), Unit._take_looks() copies it, Perception._lie() reads it into Read. boon rides the same path.
- Reactions on main have no "ran into" trigger; Investigation.gd/marks/watch gone.

## Calls
(see "As built")

## Done
(none yet)

## Next
1 Effect.only_on + Unit.stat read; 2 Effect stat `betrayal` (+ Battle read); 3 shows_boon (Skill/Unit/Perception/Read); 4 trait skill + scene; 5 test; 6 checks, suite.
