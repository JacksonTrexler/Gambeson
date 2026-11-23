# w18-starmen
Goal: astral void impassable but jumpable; starmen traits Floaty, Hop; behaviours Flippant, Vindictive, Power Hungry (names --human).
Files: Terrain/astral_void.tres, Scripts/{Battle,Unit,AI,Bio,Effect,Skill,Behaviour,Glossary}.gd, Behaviours/jump.gd, Skills/{floaty,hop}.tres, Scenes/starman.tscn, Util/unit.py, Tests.

## Readings (follow-up.md best guesses, no Answer filled)
- F5: a jump must land on a tile its jumper can stand on (not void unless aloft); `floating` / `flight` tag ignores void; walkers keep enter 99 (?267) as "impassable" in paths and the Path overlay.
- F8: one rule. Starman Bio vindictive (as a further temper), `grudges = ["astral"]` = standing grudge on the tag (HUNT) on any foe tagged astral; blows add GRUDGE each as before.
- F9: 25% of max HP lost this fight (any source, Unit.harmed) -> aggressive for the rest of the fight; aimless = random safe tile, no scoring.
- F10: not hostile beyond what Energy Transfer already is; starman gets Energy Transfer; "high" = largest share of its max (Power, else Energy, else reserves); skips targets below 25%. Targets foes and neutrals alike (any unit not its friend).
- F17: Floaty's own rank (starman 1): Jump x2, movement /2 (left fractional, not rounded); Hop 1 AP, 1 cost (Power), base 2 tiles -> 4.

## Calls
- Several tempers: `Bio.also` (further behaviours beside `behaviour`), `Unit.tempered(t)`. temper() stays the lead one.
- New Effect ops `scale` (x(1 + amount·rank)) and `divide` (/(1 + amount·rank)); Skill.span passes its range as stat base so range mul/scale effects scale the whole range.
- Tag `floating` (user's word) on Floaty; `jump` tag on Hop; Floaty's range effect is tagged `jump`, so any later jump skill scales.
- Behaviour hook `fits_at(b, caster, cell)` checked before payment in Battle._cast_at.

## Done / next
(see As built)
