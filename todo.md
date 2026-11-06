# Gambeson todo

Open work and questions, split by scope so each can be read on its own. What's done, and the decided design rules, are indexed in `completed.md`.

`[ ]` to do · `(?N)` waits on open question N · *Now:* what the game does today. Questions are numbered across all the files.

## Questions

**Asking now:** 51 (Journeyman; the specialist edge), 52 (Perfect overhealing), 50 (Strike upgrade gaps); still open from before: 45 (Humble), 46 (Sol gaps), 47 (armor numbers; Plate), 48 (Bracing caps).

**Kept as built unless you say otherwise:** 42, 1, 2, 3, 5, 6, 8, 10, 11, 12, 13, 14, 15, 16, 18, 19, 20, 21, 29. Each is a call I made that you haven't reviewed; they stay listed in their files, but I won't keep asking.

| File | What's in it | Open questions |
| --- | --- | --- |
| [docs/todo/rules.md](docs/todo/rules.md) | Rules still to settle: damage floor, stat caps, attack rolls, the clover slot | 1, 2, 5, 6 |
| [docs/todo/systems.md](docs/todo/systems.md) | Systems to build, roughly in order: checks, trees for Fighter, Paladin and Wizard, equipping skills, resources, reactions, Divinity trees, last stands and executes, items, evidence follow-ups... | 21 |
| [docs/todo/ui.md](docs/todo/ui.md) | The log, settings, targeting, the lore keeper | 8 |
| [docs/todo/classes.md](docs/todo/classes.md) | Adventurer, Wizard, Warlock, Cleric (Sol's gaps), the general trees and Strike, Rogue and Bard, Paladin, Fighter | 3, 10, 11, 12, 13, 15, 16, 18, 19, 20, 42, 45, 46, 48, 50, 51, 52 |
| [docs/todo/world.md](docs/todo/world.md) | Scenes (Infernal Meadows, Astral Envoy), items and armor, monsters (Siren, Sunder) | 14, 29, 47 |

The plan for building the unbuilt systems is [docs/plan.md](docs/plan.md).

Tests: `godot --headless --path . -s Tests/run.gd` runs them all (about 25 s); add `-- quick` for the fast tier (about 13 s), or `-- <words>` to target tests by file or name.
