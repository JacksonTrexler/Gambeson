# Item rarity rank costs, enchanted and honed

The ruling (user): equipment rarities multiply what a rank costs - common 1, uncommon 1.5, rare 2, epic 3,
legendary 4 (Grand Design), mythic 5. `enchanted` gives rank +1 (also for higher rarities); `honed` is
mutually exclusive with it, also rank +1, and triggers none of what `enchanted` does. Both may sit on skills
that need a capstone's weight.

## Readings and calls

- Nothing ranks items up in play yet; `Item.worth()` (rank x rank cost) stays the one place, now a float.
  `Item.RANK_COST` is the single table; `rank_cost()` reads it.
- Epic and mythic added to the rarity enum. Loot pull: epic 0.08 (between rare 0.15 and legendary 0.05),
  mythic 0.02. No item uses them yet.
- `enchanted` and `honed` are Glossary tags (`--human`: the user named them, kind "condition"). Each is rank
  +1 through `Tags.quality_rank()`: `Item.ranked()` for items, `Unit.rank()` for skills. Everything that
  scaled by an item's rank (effects, potions, heat, burning, revive, shackles, drag, Brutal) now reads
  `ranked()`; `rank` stays the bought rank (what `worth()` charges).
- Exclusivity: `Tags.exclusive()`, checked by `mechanic.py check` over Items/ and Skills/ and by
  `Tests/quality_test.gd`.
- `honed` never reads as `enchanted()`; Pray (`Unit.enchant()`) skips honed items too (call: honed is
  already perfect, and the two exclude each other).
- The tag, not Pray's numeric `Item.enchant` (+1 Defense / damage), gives rank +1. Making Pray's result
  also raise rank would change heavy-armor drag and existing tests: left alone (question for the user).
- Burning Blade carries `enchanted`, so it is now ranked 2; its only effect isn't per rank: no change.
- No skill is tagged: no capstone clearly needs it.

## As built

Scripts/Item.gd, Tags.gd, Unit.gd, Battle.gd, AI.gd, HUD.gd, CharacterSheet.gd, Glossary.gd,
Util/mechanic.py; Tests/quality_test.gd (new), Tests/items_test.gd (the rare-worth line: a rare rank is now
2, was 1).
