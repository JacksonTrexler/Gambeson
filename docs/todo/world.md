# Todo: scenes, items and monsters

`[ ]` to do · `(?N)` waits on open question N (numbered across all todo files) · *Now:* what the game does today. Done items and decided rules: `docs/done/`. Index: `todo.md`.

## Scenes

- [ ] **Infernal Meadows**: an overworld or challenge area for now. An endless plane of grass (grass is the default empty tile); demons spawn out of view over time, just Sirens for now. Once 30 enemies are slain, an escape portal opens, and a unit stepping onto it wins the battle at once.
- [ ] **Astral Envoy** (stub): an open meadow arena with sparse rocks and tall grass. The player's side has its villagers, its commander and uncontrolled allied shades. The boss is the **Astral Princess**, with **Regeneration Probes** (see Monsters). (?22)

22. Astral Envoy and the Astral Princess:
    - Hearts, as I read it: any unit can carry them, its side's max lives are the hearts its units have between them, and each revive brings one probe. Right?
    - Probes: "avoids enemies" means keeping away from the player's units? Who does Regeneration Pulse heal: the princess, every ally in range, all of them? It pulses more often as lives run out; once none are left (max − consumed = 0), does it pulse every turn?
    - Allied uncontrolled shades: what are they (stats, skills, how they act)? "Faction villagers, commander": the player's side's villagers and its leader?
    - Power: its max is max Energy, and it starts full? Which tools, items, skills and tiles give it back?
    - Metea II: is the casting point the tile chosen on the first cast? Struck the turn it's cast, it reaches 0 tiles from there: only that tile? Can it strike more than once per channel, and what breaks a channel (taking damage, moving)? Damage d12 × rank?
    - Smite: dice for "extreme" damage? It hits Energy (or Power), then carries over to HP from rank 2.
    - Physical Intelligence, as built: the same cap as Arcanist Perspective. Below rank V, int must be at least (100% − 20% × rank) of the str standing in for it; from V, no cap. Right reading of "max mod difference of 20% × rank"?
    - Pillar: "furthermost permanent skill slot" means the bottom of the hotbar, among the sure slots (not granted or clover ones)?
    - Sunder: the Fighter's Sundering passive, or a separate active?
    - Starblade: (damage / target BST)% × rank, of max Power or as points?
    - Heart Up-Link sets Defense (level + the higher of con mod and consumed hearts) in place of the armor's own? Heart Up's "Defense is con mod + consumed hearts": added to Defense, or replacing it? Is the trinket a third equipment slot?
    - Reviving at the end of the current side's turn: does the body stay on its tile meanwhile, and can it be hit or moved?
    - Rewards: what's a **Heart** (a consumable that gives a unit a life)? Who gets drops?
    - Her persona: rank, trickery and dissonance? Intention and strategy (closest, strongest) drive her AI: are they also what insight reads?

## Items

- [ ] **Burning Blade** (enchanted weapon): attacks use the highest of cha, wis or int. The wielder adds its str mod to max HP, even if negative. Needs item effects and a max HP effect. (?9)
- [ ] **Starblade** (weapon): on a melee hit (a damaging skill on an adjacent unit), the wielder recovers Power equal to (gross damage dealt / target BST)% × rank. (?22)
- [ ] **Heart Up-Link** (armor; needs positive con): con mod lives (hearts). Defense: level + the higher of con mod and consumed hearts. (?22)
- [ ] **Heart Up** (trinket): a heart, an extra life. Defense is con mod + consumed hearts. (?22)
- [ ] **Heart**: a drop (see Astral Princess). (?22)

9. Equipment: where do items come from (loot, shops, quests), and is the character sheet (the dock's character icon) where they're equipped? Until then, should anyone in the museum start armored (say, the player's unit in a Gambeson)? Nobody does now.

## Monsters

### Siren

- [ ] **Charm**: the Siren's cha check against the target's wis check. A target that beats it gets a standard investigation pass and a stack of suspicion of the Siren. (?14)

14. Siren:
    - Does "2+: Rank −1 mitigation to tile roll penalty" mean each rank past 1 takes 1 off the per-tile penalty? (Built that way.)
    - What does a charm that lands do to the target? (Beating it is settled.)

### Regeneration Probe

Enemy, Astral Envoy. Low stats, low movement; avoids enemies. One spawns per lost heart, every time a revive is used. A comeback mechanic: it scales with how dire things have become. Hearts and probes are mainly the boss's for now, but any unit that comes to summon probes or use several hearts should work the same way. (?22)
- [ ] **Regeneration Pulse I**: heals (1d4 + 5% max HP) per rank. A probe uses it once every (its side's max lives − consumed lives) turns. (?22)

### Astral Princess (boss)

Level 18. Str 18, dex 18, con 12, int 14, cha 14, wis 8. (?22)

Persona: adjectives Glittering, Shining, Gleaming, Glimmering; nouns Princess, Heroine, Vindicator. Intention: purge evil (evil resides in the living). Strategy: "Efficient. Does not shy away from a challenge" (closest, strongest).

Skills (?22)
- [ ] **Powerful**: her Energy is Power (see Systems).
- [ ] **Metea II** (tier 3 magical spell, `earth`, `fire`): cast on any tile in range and in line of sight, paying AP and cost, and channel. Cast again for a small AP and cost to strike: a high-damage explosion (d12) on a tile within (turns since the cast began) tiles of the casting point, radius rank.
- [ ] **Sunder** (see Fighter: Sundering).
- [ ] **Smite** (Paladin; `Astella`, `energy`) V: channeling Astella, deal extreme `energy` damage to an adjacent unit. Rank 2+: once the target's Energy is gone, (rank − 1) × 20% of the energy damage dealt carries over to HP.

Equipment: Starblade, Heart Up-Link, Heart Up (see Items). Physical Intelligence is built (`docs/done/classes.md`).

Rewards: one drop, Heart Up (25%) or a Heart (75%).
