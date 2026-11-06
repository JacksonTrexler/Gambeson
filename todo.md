# Gambeson todo

Open work and questions, split by scope so each can be read on its own. What's done, and the decided design rules, are indexed in `completed.md`.

`[ ]` to do · `(?N)` waits on open question N · *Now:* what the game does today. Questions are numbered across all the files.

## Questions

**Asking now (new systems, specs to confirm before building):** 57 (Actualization: the cut-off Self-reflection clause, and whether Meditate's respec is combat-only), 58 (Berserker Affinity: rounding of `n·log n`, and whether re-costing live can strand a skill below rank I), 59 (tile stacks: does Leaves mask a *beneficial* tile too, or only hazards?). The composability plan these ride on: `docs/plan-composability.md`.

**Confirmed as built (2026-11-06), per "confirm where the mechanics make sense":** 45 (Humble: rank x 4 x (1 - share cut) turns), 46 (Sol's path), 48 (Bracing caps at rank), 50 (Strike's upgrades), 51 (Journeyman + two-tier specialist edge), 52 (Perfect does not overheal). 47 (armor): Robe is unique (no dex, wis as magical Defense); Plate kept matching Brigandine; the weight numbers stand. 53, 54 answered (T1 capitalised; tab colours fine).

**Kept as built unless you say otherwise:** 42, 1, 2, 3, 5, 6, 8, 10, 11, 12, 13, 14, 15, 16, 18, 19, 20, 21, 29. Each is a call I made that you haven't reviewed; they stay listed in their files, but I won't keep asking.

| File | What's in it | Open questions |
| --- | --- | --- |
| [docs/todo/rules.md](docs/todo/rules.md) | Rules still to settle: damage floor, stat caps, attack rolls, the clover slot | 1, 2, 5, 6 |
| [docs/todo/systems.md](docs/todo/systems.md) | Systems to build: the composability seams (Check resolver, tile stacks, behaviour spine, context tags, derived-stat pipeline), then checks, trees for Fighter/Paladin/Wizard, equipping, resources, reactions, Divinity, last stands, items... | 21, 59 |
| [docs/todo/ui.md](docs/todo/ui.md) | The log, targeting, lore keeper, a stats block; UX: gray-out commanded units, raise commandable prominence, default orders, tile-panel walker icon, suspicious-tile overlay, accessibility | 8, 56 |
| [docs/todo/classes.md](docs/todo/classes.md) | Adventurer (Actualization), Wizard, Warlock, Cleric, general trees and Strike, Rogue/Bard, Paladin, Fighter, Berserker (Affinity) | 3, 10, 11, 12, 13, 15, 16, 18, 19, 20, 42, 57, 58 |
| [docs/todo/world.md](docs/todo/world.md) | Scenes (Infernal Meadows, Astral Envoy), items and armor, monsters (Siren, Sunder) | 14, 29, 47 |

The plan for building the unbuilt systems is [docs/plan.md](docs/plan.md). How to make skills, rolls, tiles and attributes composable as that content grows is [docs/plan-composability.md](docs/plan-composability.md).

Tests: `godot --headless --path . -s Tests/run.gd` runs them all (about 25 s); add `-- quick` for the fast tier (about 13 s), or `-- <words>` to target tests by file or name.
