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
- 69 Paladin Prowess (2026-11-07): which gods each prowess tree suits (Eros: Protector, Vanguard; Ramut: all but Protector; every god at least two); one choice, permanent; unaligned tabs hidden.
- 66 Shackles: every pick or pry try costs their rank in AP, like taking them off; off, they fall away (not to the stash) and the stowed trinket goes back on; AI units work at them first thing.

**Answered (2026-11-06):** 61 (HP: 5 HP and up is fine - class units start from a base of 5), 62 (power read as fullness % / 20; glass's check is now against the unit's inertia).

**Confirmed as built (2026-11-06), per "confirm where the mechanics make sense":** 45 (Humble: rank x 4 x (1 - share cut) turns), 46 (Sol's path), 48 (Bracing caps at rank), 50 (Strike's upgrades), 51 (Journeyman + two-tier specialist edge), 52 (Perfect does not overheal). 47 (armor): Robe is unique (no dex, wis as magical Defense); Plate kept matching Brigandine; the weight numbers stand. 53, 54 answered (T1 capitalised; tab colours fine).

**Kept as built unless you say otherwise:** 42, 1, 2, 3, 5, 6, 8, 10, 11, 12, 13, 14, 15, 16, 18, 19, 20, 21, 29. Each is a call I made that you haven't reviewed; they stay listed in their files, but I won't keep asking.

| File | What's in it | Open questions |
| --- | --- | --- |
| [docs/todo/rules.md](docs/todo/rules.md) | Rules still to settle: damage floor, stat caps, attack rolls, the clover slot | 1, 2, 5, 6 |
| [docs/todo/systems.md](docs/todo/systems.md) | Systems to build: the composability seams (Check resolver, tile stacks, behaviour spine, context tags, derived-stat pipeline), then checks, a tree for the Wizard, equipping, resources, reactions, Divinity, items... | 21, 68 |
| [docs/todo/ui.md](docs/todo/ui.md) | The log, targeting, lore keeper, a stats block; UX: gray-out commanded units, raise commandable prominence, default orders, tile-panel walker icon, suspicious-tile overlay, accessibility | 8, 56, 60 |
| [docs/todo/classes.md](docs/todo/classes.md) | Adventurer (Actualization), Wizard, Warlock, Cleric, general trees and Strike, Rogue/Bard, Paladin, Fighter, Berserker (Affinity) | 3, 10, 11, 12, 13, 15, 16, 18, 19, 20, 42, 57, 58, 64, 65, 67, 69 |
| [docs/todo/world.md](docs/todo/world.md) | Scenes (Infernal Meadows, Astral Envoy), items and armor, monsters (Siren, Sunder) | 14, 29, 47, 63, 66 |

The plan for building the unbuilt systems is [docs/plan.md](docs/plan.md). How to make skills, rolls, tiles and attributes composable as that content grows is [docs/plan-composability.md](docs/plan-composability.md).

Tests: `godot --headless --path . -s Tests/run.gd` runs them all (about 25 s); add `-- quick` for the fast tier (about 13 s), or `-- <words>` to target tests by file or name.
