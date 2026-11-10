# Gambeson todo

Open work and questions, split by scope so each can be read on its own. What's done, and the decided design rules, are indexed in `completed.md`.

`[ ]` to do · `(?N)` waits on open question N · *Now:* what the game does today. Questions are numbered across all the files.

## Questions

**Built on judgement, open for your review (2026-11-06)** - you asked me to make the calls and annotate them; each is listed in its file with the choice made:
- 57 Actualization: the respec reaches no further than the unit knew itself *before* the Meditation (so Self-reflection opens the first one); self-knowledge and respecs last the battle (class units are made fresh each battle).
- 58 Berserker / Affinity: the even curve keeps today's 1 + r^2 steps (about n^2) so nothing shifts; +1 is n log2 n floored at n; a skill's Affinity sums the postures it serves (a dual skill pulled both ways nets out); a posture tag decides outright; ranks never drop below I; per-posture ranks deferred. Its three Prowess tabs' skills are mine.
- 60 Default orders: either low cha *or* low wisdom gives intents (not exclusive or).
- 63 Magnitudes: tags scaling a number by rank - intense 2.5 x rank, extreme 3 x rank, rounded up (faint .5, mild 1, moderate 1.5, strong 2, overwhelming 4).
- 64 Wildfire: Sol's tab, after Solar; a fixed 60 degree cone; (3 x rank)d6 + wis; spares the caster; an earth unit dodges at the impossible *rung* (beatable at low rank), not automatically failing.
- 65 Judgement: lawful domains are Sol among the Cleric's gods (Ramut too, once a Cleric can follow him); 1d4 + wis; open from the start of the tab.
- 67 Fighter and Protector: the trees' shape, Shields Up!'s range and DEFEND aim, Obstruct's size penalty and +25% a rank as a multiplier, Interdict's str check as a save, attack rolls as offensive checks for Turtle Tactics, Jugular's numbers. Also my calls on 12 (Rejuvinate's spelling, decay fixed when cast, Send Off on either side landing straight away, `<3` as the `love` tag), noted under 12.
- 68 Moving units and checks: pushes do no damage on impact; teleports spring traps and leave no trail; contact investigates each time until seen through, hiding only; executes cut saves and drags, not Defense; bracing kinds for investigating, hiding and last stands.
- 80 Discipline (2026-11-09): a toggle burning up to rank AP left into an attack; +2 to hit, +25% damage, a crit face lower a point; the initiative half deferred.
- 81 Ranger (2026-11-09): Bounty, Scout and Forester roots of borrowed skills; Specialist and Martial; one Nature tree at -1 until 4 magical skills are learned; Natural Talent +1 stacking.
- 82 Druid (2026-11-09): what each biome borrows, four ?? stubs, the kin table, one guest tree, beasts by biome, shaping rank + 1 turns; Thalassic has no beast yet.
- 83 Colours and command limits (2026-11-09): the dark sprites were a shader bug; unidentified units now in colour with a grey glow instead of black; drain 1 - 0.45 x spent^2, grey for any reason it can't take an order (out of reach too); limits at least 1, effects don't raise them, a charge is one order.
- 84 Silhouettes and glow (2026-11-09): a black shape only when the viewer has placed a unit, can't tell its side and something stands between; suspicion alone is enough, even in daylight; four glow strengths (barely, somewhat, mostly, fully); clicking a "somewhat" target walks nowhere; glow strength on a black shape is unreadable.
- 85 Downed, Tenacity, Grudge (2026-11-09): one Downed condition any skill sets by data; a round is one of its side's turns; Grudge's action is a skill use; helpless means no acting but still hit, healed and targeted; hearts spent first; XP on the death, rescue XP once.
- 86 Command skills and trinkets (2026-11-09): caps are max(cha mod, 1) + bonus; Strategist and Tactician on the Specialist general tree at tier 3; Strategy Guide and Tactician's Playbook uncommon trinkets; Grand Design the first legendary, a trinket; the Astral Princess's table reads Heart Up 21%, Heart 62%, the two books 8% each, Grand Design 1%.
- 87 Exhaustion (2026-11-09): +0.5 of base cost per use, half-weight on the rest of a broad kind (martial, specialist, magical), counts fall by 1 a side-turn, resting adds con mod, con mod 0 rests like +1; twenty active skills carry no kind; the museum sims turn from Lancin 8 / Nemes 22 to Lancin 29 / Nemes 1.
- 88 Skill tooling, Kick, CLAUDE.md (2026-11-09, **planned, not built**): `Util/skill.py new` and `check`, a behaviour seam, an agent skill, Kick's tile effects, CLAUDE.md under four lines; "g-action skill/ tool" read as a Claude Code agent skill plus a script.
- 89 Clairvoyance (2026-11-09, **planned, not built**): four assumptions: pings see through walls, no rank cap while held, the cast's cost once, allies share the pings.
- 90 Battle UI v2 (2026-11-09, **planned only**): four open points in `docs/ui-ux-v2.md`; nothing built.
- 79 Levels, revised (2026-11-09): (BST + level) / 7 with the requirements still 20 x n log2 n; "nearby" is 3 tiles, standing, not on the fallen unit's side; shares rounded, at least 1; revival XP built but nothing yet brings a unit back (hearts don't count); going down on a heart isn't a fall; the cap at 20 loses XP past it.
- 77 Sight everywhere and Gamut's Tower (2026-11-09): sight's range shared across a side but reads still each unit's own; sides remember foes and hunt where they were last seen; three floors bottom-up from Gentle, six portals, out down the ground floor's stairs; the menu's contents and the rewards per floor.
- 76 Borrowed trees and Rift's count (2026-11-09): Dabblings borrow caster trees by kind from any class; schools carry no penalty; Eros back by way of the Cleric, its Paladin features locked for others (Skill.classes: Smite, Lovely Caster, Impassioned Fighter); the Bard's Song a Genre tab; borrowed trees bring their class's shared row; Rift unchanneled by Alt-click, its count 3 x difficulty with the doors open, started by any end of the channel.
- 73 The Undine: natures as tags, Murky as its vibe, the Siren's sprite tinted; its numbers; Waltz kept up by using it as each turn opens; Vaporize a free toggle (75% / 50% off, wind +50%); Coalescing shares the foe's tile (it can't be picked out while inside); Well Up rank deep, rank - 1 around.
- 72 Water: depth in unit sizes (Water and Pond 5, Flowing 2, Shallows 1; submerged when deeper than the unit's size); a Flood adds its rank, +0.5 movement a rank, lasts its setter's turns; drowning only held and submerged (or engulfed); Sirens out of song range close in.
- 70 Wizard and Mage trees (stubs): Wizards reward switching spells and elements, Mages sticking to one; the Wizard's liability in a Transgression root; one pact and one affiliation (both allowed); schools are elements paired as the gods pair them, colleges are postures; both on the Red Mage sprite, neither on the entry screen.
- 69 Paladin Prowess (2026-11-07): which gods each prowess tree suits (Eros: Protector, Vanguard; Ramut: all but Protector; every god at least two); one choice, permanent; unaligned tabs hidden.
- 66 Shackles: every pick or pry try costs their rank in AP, like taking them off; off, they fall away (not to the stash) and the stowed trinket goes back on; AI units work at them first thing.

**Answered (2026-11-09):** 78 (level is a plain stat in XP's reckoning, (BST + level) / 7; shared nearby, two shares to the killer; revivals pay; once each; level cap 20), 71 (the Wizard's borrowed trees found, not listed), 74 (sight in every battle, shared across the side; the cap counts living allies, nobody despawned; Gamut's Tower walkable), 75 (Rift can be cast unchanneled; two-way doors are right). The rest of each stands as built.

**Answered (2026-11-06):** 61 (HP: 5 HP and up is fine - class units start from a base of 5), 62 (power read as fullness % / 20; glass's check is now against the unit's inertia).

**Confirmed as built (2026-11-06), per "confirm where the mechanics make sense":** 45 (Humble: rank x 4 x (1 - share cut) turns), 46 (Sol's path), 48 (Bracing caps at rank), 50 (Strike's upgrades), 51 (Journeyman + two-tier specialist edge), 52 (Perfect does not overheal). 47 (armor): Robe is unique (no dex, wis as magical Defense); Plate kept matching Brigandine; the weight numbers stand. 53, 54 answered (T1 capitalised; tab colours fine).

**Kept as built unless you say otherwise:** 42, 1, 2, 3, 5, 6, 8, 10, 11, 12, 13, 14, 15, 16, 18, 19, 20, 21, 29. Each is a call I made that you haven't reviewed; they stay listed in their files, but I won't keep asking.

| File | What's in it | Open questions |
| --- | --- | --- |
| [docs/todo/rules.md](docs/todo/rules.md) | Rules still to settle: damage floor, stat caps, attack rolls, the clover slot | 1, 2, 5, 6 |
| [docs/todo/systems.md](docs/todo/systems.md) | Systems to build: the composability seams (Check resolver, tile stacks, behaviour spine, context tags, derived-stat pipeline), then checks, trees for the Wizard and Mage, equipping, resources, reactions, Divinity, items, water, the Meadows' maps... | 21, 68, 72, 79, 87, 88 |
| [docs/todo/ui.md](docs/todo/ui.md) | The log, targeting, lore keeper, a stats block; UX: gray-out commanded units, raise commandable prominence, default orders, tile-panel walker icon, suspicious-tile overlay, accessibility | 8, 56, 60, 83, 84, 90 |
| [docs/todo/classes.md](docs/todo/classes.md) | Adventurer (Actualization), Wizard, Warlock, Cleric, general trees and Strike, Rogue/Bard, Paladin, Fighter, Berserker (Affinity), Mage, Ranger, Druid | 3, 10, 11, 12, 13, 15, 16, 18, 19, 20, 42, 57, 58, 64, 65, 67, 69, 70, 76, 80, 81, 82, 85, 89 |
| [docs/todo/world.md](docs/todo/world.md) | Scenes (Infernal Meadows, Gamut's Tower, Astral Envoy), items and armor, monsters (Siren, Undine, Sunder) | 14, 29, 47, 63, 66, 73, 77, 86 |

The plan for building the unbuilt systems is [docs/plan.md](docs/plan.md). How to make skills, rolls, tiles and attributes composable as that content grows is [docs/plan-composability.md](docs/plan-composability.md).

Tests: `godot --headless --path . -s Tests/run.gd` runs them all (about 25 s); add `-- quick` for the fast tier (about 13 s), or `-- <words>` to target tests by file or name.
