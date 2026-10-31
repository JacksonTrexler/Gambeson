# Done: items and monsters

`[x]` done · `(?N)` an open question in `docs/todo/` that may still change it · *Now:* what the game does today. Index: `completed.md`.

## Items

Armor (see the Defense rule)
- [x] **Gambeson**: Defense the higher of 10 and level / 2, + dex mod.
- [x] **Plate**: Defense the higher of 20 and level.
- [x] **Robe** (`cloth`): Defense the higher of 8 and level / 4.

Weapons
- [x] **Rapier**: strength attacks may use dex instead.

- [x] **Enchanting** (`Item.enchant`, Pray to Urlo): an item is enchanted once: armor +1 Defense, weapons +1 damage on strength attacks, shown in the item's description; or it becomes its own enchanted form (`Item.enchanted_as`).

## Monsters

### Siren

Acts serene and stands still until unmasked. It tries to get units close by enrapturing them, with trickery and singing; once they're adjacent, it at once tries to Drown or Rake them, by its AP and access to water. Sirens come pre-configured: they know what they're about. *Now:* `behaviour` lure: Drown first, then Rake, without moving.

- [x] **Alluring** (passive, rank IV): rank persona, carrying a look: Friendly; Harmless, Beautiful, Serene, Safe; holy; named Beautiful/Radiant/Serene/Harmless Beauty/Lady/Songstress. Its persona is its nature, so it doesn't personify. Its rank comes off its dissonance penalty.
- [x] **Persona names.** A persona that claims an identity (rank 3) goes by a random fake name instead of "Something": an adjective from its persona's pool and a general noun from its noun pool ("Beautiful Beauty", "Radiant Lady", "Serene Songstress"). Later, adjectives can carry effects and nouns their own sprites. For now, each noun shows a text stand-in for its sprite (":D", ";)", ":3"). *Now:* each unit picks its name as the battle sets up (Unit → Persona: `shows_adjectives`, `shows_nouns`). Whoever it fools sees that name in the log, tooltips and its card, and the noun's face in place of its sprite on the map and the card.
- [x] **Sing** (active · 3 AP · 2 cost · range rank + cha mod · `sound`, `cha`): a song, used at once, landing on the closest units in range, no more than rank. On an ally: +1 movement per rank, for 2 turns. On a foe: drawn up to rank tiles toward the singer. The enraptured (convinced it's an ally) take it for support and walk in; one that isn't convinced won't, and a suspicious one won't either, but cha against its wis takes a stack of suspicion off.
- [x] **Drown**: a grapple, str contest against a unit. On a win, the Siren drags it to the nearest water tile, submerging both of them. Water must be within the Siren's movement range: it can't drag a unit past where it could move itself. −1 to its roll for every tile it must travel to the water; rank 2+: rank − 1 off that per-tile penalty. Submerged, the unit takes 1d12 + str mod at the end of each turn it doesn't escape the grapple; it escapes by moving away (see Grapples). *Now:* 5 AP, 2 cost. (?14)
- [x] **Rake** (once called Claw): its attack when no water is in range for the target. *Now:* 1d4 + str mod, `physical` `slash`, 3 AP, adjacent.

### Astral Princess

- [x] **Physical Intelligence** V (`magical`, `pillar`): str mod can stand in for int mod on magical skills, with a max mod difference of 20% × rank. *Now:* `Skills/physical_intelligence.tres`, capped like Arcanist Perspective. Nobody has it until she exists, and `pillar` does nothing until Disabled skills and Pillar skills are built. (?22)
