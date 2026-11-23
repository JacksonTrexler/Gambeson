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
- Hop is an innate active, not a `trait`-tagged skill: the tooling's traits are always-on passives (skill.py refuses an active one). Floaty is a trait (unit.py trait).
- Starman: `hunts` (Stellar Order) and Unit.behaviour aggressive dropped; the astral grudge replaces hunting. Default faction Starmen (neutral; battles set their own). appearance Beast.
- Grudge named in Bio.grudges now GRUDGED 5 (was HUNT 10), under 3 blows (6): a foe that keeps striking it outweighs the standing grudge ("otherwise aggressed").
- Flippant turn: feed if a rich target can be reached this turn, else skirt (4 random safe walk tiles tried, then a random safe hop, else _away()). Unit.harmed = HP lost this fight (any source), Bio.FLIPPANT 0.25.
- Power Hungry: _richest() ranks Power > Energy > reserves by share read (Read.energy / true max_energy); FEED 0.25 floor; any non-friend not ignored; also a pull in _hunted() (HUNGER 4 x share) once aggressive. Drains with any siphon-tagged skill (Energy Transfer added to the starman).
- Any unit with a jump skill jumps first on its main approach when that lands nearer the goal (_leap()).

## As built
- Battle: _cost floating over void = 1; footing(u, c); _cast_at asks fits_at; harmed cleared in _listen.
- Effect ops scale/divide (Unit.stat, Effect.value/helps); Skill.span: range effects multiply the whole range; Unit.skill_stat base.
- Tags floating, jump, void (Glossary, --human). Behaviours/jump.gd; Skills/hop.tres (1 AP, 1 cost, radius 2, lent), Skills/floaty.tres (trait).
- Bio: flippant, power_hungry, also, FLIPPANT; Unit.tempered(), temper() latch; unit.py --also/--grudges, check of also.
- AI: _feed/_richest/_fill/_hunger/_siphon/_jump/_leap/_skirt; _grudge/_fancies via tempered().
- Tests: hop_test (void + jump, Floaty scaling), stars_test.test_flippant, test_power_hungry, test_hunts (+ otherwise aggressed), test_sap (grudge not hunts); equip_test.test_traits list + floaty.
- Mutations (each failed its test): temper latch off; neutrals skipped; footing always true; divide as add; floating void clause off; GRUDGE 0; GRUDGED 20.
- busy_fight 30: unit turn target mean 111 / p95 275 ms (main 113 / 277): flat. Starmen sim (4 starmen v 4 villagers + Princess, 8 rounds): mean 30 ms / p95 41 ms here, first turn 245 ms cold (looks); drains, jumps, skirts all seen.
- Suite 11184 checks, 0 failed (1056 tests); start 11144 (1052; the baseline run raced my first edits, 1 failure from that). skill/unit/mechanic check ok; launch clean.

## Undone / hooks
- HUD shows Bio.behaviour only, not Bio.also chips. No visual frames (no UI change).
- Movement /(rank+1) stays fractional (2.5), not rounded up.
- For F (fog) / I (monster): Unit.tempered() and Bio.also take more tempers; any tile skill tagged jump uses Floaty and _leap(); footing() is the landing rule.
