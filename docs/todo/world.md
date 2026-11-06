# Todo: scenes, items and monsters

`[ ]` to do · `(?N)` waits on open question N (numbered across all todo files) · *Now:* what the game does today. Done items and decided rules: `docs/done/`. Index: `todo.md`.

## Scenes

- [ ] **Infernal Meadows**: an overworld or challenge area for now. An endless plane of grass (grass is the default empty tile); demons spawn out of view over time, just Sirens for now. Once 30 enemies are slain, an escape portal opens, and a unit stepping onto it wins the battle at once.
- [ ] **Astral Envoy**: tuning. (?29) Balance waits: there's a lot of ground to cover first. *Now:* built, with the star lattice and two Starmen (`docs/done/world.md`).

## Items

- [ ] Item sprites and icons. *Now:* items are names and descriptions on the character sheet.
- [ ] **Saving** the stash and outfit: later.
- [ ] Sources for Habergeon, Brigandine, Aethendine and Ignauldron (drops, rewards, shops).

47. Armor weights, as built (my numbers): light the higher of 10 and level / 2, + dex mod; medium the higher of 12 and level × 0.75, + dex mod / 2; heavy the higher of 14 and level, + dex mod / 4. Aethendine and Ignauldron lift their drag at mod 2+. Robe counts as light (it used to be the higher of 8 and level / 4), and Plate now matches Brigandine exactly (it was a flat 20) - should Plate differ, or go? Half Plate is medium now, so your "10 or level / 2 + dex / 4" for it gave way to Habergeon's scaling.

## Monsters

### Siren

- [ ] **Charm**: the Siren's cha check against the target's wis check. A target that beats it gets a standard investigation pass and a stack of suspicion of the Siren. (?14)

14. Siren:
    - Does "2+: Rank −1 mitigation to tile roll penalty" mean each rank past 1 takes 1 off the per-tile penalty? (Built that way.)
    - What does a charm that lands do to the target? (Beating it is settled.)

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
