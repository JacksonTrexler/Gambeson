# Todo: scenes, items and monsters

`[ ]` to do · `(?N)` waits on open question N (numbered across all todo files) · *Now:* what the game does today. Done items and decided rules: `docs/done/`. Index: `todo.md`.

## Scenes

- [x] **Infernal Meadows**: a standalone challenge for now, reached later through a dungeon gate on the overworld. Ordinary grass with a "Paradise" feel. Your answers (2026-11-08):
  - The map is generated around the party as it moves: a procedural generation test map. Light brush, a few ponds and thin streams.
  - Demons spawn in small groups: 1-2 Sirens near water, or near an Undine. Spawn formations are prefabs that are easy to tweak, scale and reuse, and they spawn beside features such as ponds. Out of view means beyond the whole party's perception.
  - At most (ally faction count x difficulty) demons alive at once. Difficulty is an area attribute (0.5, 1, 1.5), built off the roll difficulties.
  - The player gets the commanders and soldiers of both sides.
  - Kills are counted in total; in-fighting is assumed to come from outside influence in most scenarios.
  - Once 30 are slain, the escape portal forms where the last one died. It takes longer to open the higher the difficulty, and spawning ramps up hard meanwhile. The portal shows its turns remaining. A unit stepping onto it once it's open wins the battle at once.
  - No leaving early yet, except by the Wizard's Emergency Exit.
  - Built (`Scenes/meadows.tscn`, `Meadows.gd`; `docs/done/world.md`). (?74)
- [x] **Gamut's Tower**: a new scene with a selection of portals, just the Meadows for now. Revised (2026-11-09): a walkable hall of dungeon instances on a stone floor, with a staircase up and one down and portals in a ring between them. Each level is a difficulty. The Meadows is the only portal open; stepping onto it opens a menu with the dungeon's enemies and potential rewards. Built (`Scenes/gamuts_tower.tscn`, `GamutsTower.gd`, `Dungeon`; on the class selection screen's scenarios). (?77)
- [x] **A Rift's domain**: the Wizard's Rift opens a portal to a pared-down Meadows, an 8x8 grass diamond with an escape portal at its centre, its difficulty scaled on the Rift's rank and its level shared with the Wizard's. Built (`Battle.open_rift()`; `docs/done/classes.md`). (?75)
- [ ] **Astral Envoy**: tuning. (?29) Balance waits: there's a lot of ground to cover first. *Now:* built, with the star lattice and two Starmen (`docs/done/world.md`).

77. **Sight everywhere and Gamut's Tower - built on judgement, open for review (2026-11-09).**
    - Sight: a foe within any one of a side's ranges is in sight for the whole side, but how well each unit reads it (recon, concealment, disguises) stays its own; pooling reads is still Coordinate's. Each side starts knowing where the others drew up in the open, remembers where it last made out a foe (or something it can't tell the side of), and its units head there when nothing's in sight; reaching the spot and finding no one, they forget it. Spawned demons arrive knowing where the party is. The museum's tests turn sight off unless they test it.
    - The tower: three floors, Gentle at the bottom, Standard, then Harsh at the top; you arrive on the ground floor, in the middle. Down from the ground floor leads out (back to the class selection screen); up from the top says the way is shut. The ring holds six portals between the stairs, the Meadows east and five sealed. Arrow keys or WASD step a tile; a click walks there.
    - The menu: the dungeon's blurb, how it's won (with the portal's turns at that floor), its enemies (name, look, HP, skills, read off their scenes) and what winning brings on that floor. Rewards are my picks: a Health Potion and a Mana Potion on every floor, a Heart from Standard, a Heart Up on Harsh (`Dungeon.rewards`, `reward_floors`; the battle's `rewards`).
    - The battle's menu button still goes to the class selection screen, not back to the tower: the starter is used up by the battle.

## Items

- [ ] Item sprites and icons. *Now:* items are names and descriptions on the character sheet.
- [ ] **Saving** the stash and outfit: later.
- [ ] Sources for Habergeon, Brigandine, Aethendine and Ignauldron (drops, rewards, shops).

47. **Confirmed (2026-11-06).** Robe is unique (`no_dex`, `mind_stat = wisdom`: no dex to Defense, wis mod as magical Defense). Plate kept matching Brigandine; weight numbers stand. Encounter-end drops: mundane armor common, armor with added effects rare (`Item.rarity`; `Loot` weights by it; Aethendine and Ignauldron marked rare). Boss commanders wear heavy armor where it fits - Alabaster is a stone golem whose Stoneskin already makes it the heavy unit, so it's left unarmored by design; the rule applies to humanoid commanders as they're authored. *Original, for the record:* Armor weights, as built (my numbers): light the higher of 10 and level / 2, + dex mod; medium the higher of 12 and level × 0.75, + dex mod / 2; heavy the higher of 14 and level, + dex mod / 4. Aethendine and Ignauldron lift their drag at mod 2+. Robe counts as light (it used to be the higher of 8 and level / 4), and Plate now matches Brigandine exactly (it was a flat 20) - should Plate differ, or go? Half Plate is medium now, so your "10 or level / 2 + dex / 4" for it gave way to Habergeon's scaling.

## Monsters

### Siren

- [x] **Closing in**: a Siren too far away to lure moves toward units aggressively. True of all Sirens. Built (`AI._out_of_song()`). (?72)
- [ ] **Charm**: the Siren's cha check against the target's wis check. A target that beats it gets a standard investigation pass and a stack of suspicion of the Siren. (?14)

14. Siren:
    - Does "2+: Rank −1 mitigation to tile roll penalty" mean each rank past 1 takes 1 off the per-tile penalty? (Built that way.)
    - What does a charm that lands do to the target? (Beating it is settled.)

### Undine

- [x] **Undine**: an elemental, here a demon variant. Built (`Scenes/undine.tscn`, `docs/done/world.md`). (?73) Meadows Undines' natures are Malevolent and Abyssal. Their appearance is Murky instead of Clear; all Undines are Aquatic.
  - **Waterstrike**.
  - **Waltz of Vapors**: a circle of fog within rank + dex or cha total. Channeled: it must be used every turn to keep it up, and only at the start of a turn.
  - **Vaporize**: the Undine turns into a mist cloud: major physical resistance, respectable magic resistance, weak to wind. It can share tiles with other units and can't attack, but by **Coalescing** (its only active) on an occupied tile it can try to grapple and drown a unit there as a Siren can, until it's physically moved off the shared tile or the unit moves off.
  - **Well Up**: floods a tile within rank range with rank Flood; adjacent tiles flood at rank - range.

73. **The Undine - built on judgement, open for review (2026-11-08).**
    - Natures and appearance have no system of their own, so they're tags and words: tags monster, elemental, demon, undine, aquatic, malevolent, abyssal; its vibe "Murky"; an ominous aura. It borrows the Siren's sprite, tinted blue.
    - Numbers: 18 HP, dex and cha 14. Waterstrike 1d6 + dex mod at range 1 (rank II). Waltz of Vapors I, Well Up III, Coalescing I.
    - Waltz of Vapors: fog conceals (a new concealment kind) at its rank, out to rank + the better of its dex and cha mods. It lasts through its next turn, so using it as each turn opens keeps it up. That's how "channeled, must be used every turn" reads here; the game's Channel (Metea) means something else.
    - Vaporize is switched on and off like Mage Armor, at no cost: 75% off physical damage, 50% off magical, wind 50% harder (+100% against wind, so magical wind nets +50%). As a mist it can use Coalescing and nothing else.
    - Coalescing: a str contest, as Drown's. Won, it moves into the foe's tile and shares it (the tile stays the foe's; the Undine still takes its turns but can't be picked out while inside), grappling it; the foe drowns there each turn (1d12 + str), engulfed. It ends when the foe breaks free and moves off, or either is moved; the Undine then has the tile.
    - Well Up floods the tile rank deep and the 8 tiles around it rank - 1, for rank of its side's turns.
    - Its AI keeps the fog up, turns to mist under half HP, Coalesces into its best target as a mist, and otherwise floods the tile of a foe not yet under, then strikes.

### Astral Princess

- [ ] **Sunder** (see Fighter: Sundering). Waits on Sundering. (?13)

29. Astral Envoy, my calls on question 22 (each can change):
    - Hearts: any unit can carry them (its own, Heart Up, Heart Up-Link's con mod); its side's lives are its units' hearts together. Down with a heart left, a unit holds its tile, can't be hit or moved, loses its effects and channel, and gets up at full HP as the current side's turn ends. Each revive brings one Regeneration Probe, on the nearest free tile.
    - Probes: level 3, 6 HP, movement 3, no attacks; they keep away from your units. Regeneration Pulse heals every ally within 3 tiles, the probe too, once every (its side's lives left) turns, every turn once none are left.
    - Shades: level 2, 8 HP, Strike; on your side, acting on their own. The villagers and shades join whichever side you pick.
    - Power: max Energy (20), starting full; only Starblade gives it back.
    - Metea II: the casting point is the tile picked on the first cast (range 5 + rank, no line of sight yet: the game has none). Struck the turn it's cast, only that tile. One strike per channel; it ends only on striking, or when she goes down or falls. Damage rank × d12 + int mod (Physical Intelligence: str can stand in), everyone within rank tiles but her, her allies included. 6 AP and cost 5 to begin, 2 AP and 1 to strike.
    - Smite: 2d12 / 3d12 / 4d12 + cha mod at ranks I / III / V, adjacent, with an attack roll; 5 AP, cost 4. She worships Urlo: energy damage, and it disenchants.
    - Starblade: (gross damage / the target's base stat total) × (1 + enchantment) of max Power, as a share.
    - A Heart is a consumable: +1 life for good.
    - Her persona: Personify III (a name from her pools, "Gleaming Heroine"), no stance or trickery. Insight reads her intention and strategy at net 2. "Strongest" weighs each level it reads as half a tile of distance.
    - Physical Intelligence: kept as built (the Arcanist Perspective cap).

63. **Magnitudes - built on judgement.** Your "extreme fire damage" and "intense rank cone range" read as tags that scale a number by rank: faint 0.5, mild 1, moderate 1.5, strong 2, intense 2.5, extreme 3, overwhelming 4 x rank, rounded up (`Difficulty.MAGNITUDE`). Open for review.
66. **Shackles - built on judgement.** *Choices:* each pick (approachable, dex) or pry (unfair, str) try costs the shackles' rank in AP, the same as taking them off unlocked; once off they fall away rather than going to the stash, and the stowed trinket goes back on; an AI unit works at them before anything else. Open for review.
