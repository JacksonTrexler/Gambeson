# Done: scenes, items and monsters

`[x]` done · `(?N)` an open question in `docs/todo/` that may still change it · *Now:* what the game does today. Index: `completed.md`.

## Scenes

- [x] **Astral Envoy** (`Scenes/astral_envoy.tscn`, played from `Scenes/envoy_play.tscn`; on the entry screen): a 14 × 10 open meadow, sparse rocks (Rough) and tall grass (`Terrain/tall_grass.tres`: concealment 1 to whoever stands in it). Your side: four villagers and two shades (uncontrolled), joining whichever side you pick, and your starter. The **Stellar Order** (`Factions/astral.tres`): the Astral Princess, and the Regeneration Probes her revives bring. Two **Starmen** (`Factions/starmen.tres`, neutral) at the far edge. The **Wayfarers** (`Factions/wayfarers.tres`): a starter of each other class on the entry screen (the Cleric among them), at level 1 in its starting items, a side of their own allied with yours; your leader can't order them (`Battle.companions`). Reward: the Starblade. (?29)
  - **The star lattice** (`Battle.starpanes`, `Battle.starpower`): a broken grid of starpanes, with starpower sources at two intersections, (8, 2) half full and (11, 7) empty. Standing on a source or a pane joined to one side-on, Power comes back each turn at x2 (a source with any Power in it) to x5 (full) its resting rate, whatever the unit did; an empty source gives nothing. Plain Energy gets 30% of what the boost adds (where Power would get +10, Energy gets +3). A bludgeoning blow (a `blunt` skill: Strike bare-handed, or with a Staff) on a pane with no one there breaks it, cutting the panes beyond off. Drawn as faint panes and links, sources as stars that brighten as they fill; the tile pane says what each tile gives.

## Items

Every item has a **rank** (1 for all so far): its effects scale by it. In battle, putting on or using a trinket (or a consumable) costs 1 AP, a weapon 2 (3 if heavy), armor 10 − dex mod: hardly worth it mid-fight (`Item.ap_cost()`; free once the battle is over). Taking things off is free.

**Starting items** (`Role.items`; a new starter from the entry screen wears them: `Game.outfit`):

| Class | Armor | Weapon | Trinket |
| --- | --- | --- | --- |
| Fighter, Paladin | Half Plate | Broadsword | Health Potion |
| Rogue, Bard, Adventurer | Gambeson | Dagger | Energy Potion |
| Wizard | Robe | Staff | Mana Potion |
| Warlock | Robe | Staff | Sweet Something |

Armor, by weight (`Item.WEIGHTS`; the tag light, medium or heavy). Each weight shares its basic piece's scaling; dex shares round by luck, and a negative one rounds down. (?47)
- **Light**: Defense the higher of 10 and level / 2, + dex mod. **Gambeson** (basic), **Robe**.
- **Medium**: the higher of 12 and level × 0.75, + dex mod / 2. **Habergeon** (basic), **Half Plate**.
- **Heavy**: the higher of 14 and level, + dex mod / 4. Each turn it takes 3 − con mod dex AP and 3 − str mod wis AP, at least 1 each (`Unit.armor_drag()`). **Brigandine** (basic), **Plate**, and:
  - [x] **Aethendine**: its wearer's full dex mod; rank more dex AP a turn; no dex AP drag with con mod 2 or more.
  - [x] **Ignauldron**: rank more skill AP a turn; burns its wearer for rank fire as each turn starts; no wis AP drag with str mod 2 or more.
- Habergeon, Brigandine, Aethendine and Ignauldron have no source yet (no drops, rewards or shops).

Weapons
- [x] **Rapier**: strength attacks may use dex instead.
- [x] **Broadsword** (martial): damage skills +0.5 range per rank (Strike reaches a diagonal at rank 1); Strike +rank.
- [x] **Dagger** (specialist): strength attacks may use dex; +20% × rank on its wielder's initiative d20, and +20% × rank general AP on its first turn of a battle.
- [x] **Staff** (casters): magical (caster) skills +rank range.

Weapons carry a damage tag for skills that take their wielder's (Strike): Broadsword, Burning Blade and Starblade slash; Dagger and Rapier pierce; Staff blunt; bare hands blunt.

Trinkets and consumables
- [x] **Quartz Ring** (trinket; the Museum's reward): the wearer's command range has no limit (and with it, Synergy's).
- [x] **Red Spinel Ring** (trinket; every new starter finds one in the stash, to swap in mid-battle for 1 AP): once a battle, falling with no heart left, its wearer gets up as the turn ends at rank × 10% of its max HP (past rank 10, more than full), with **Resurrection Sickness** for rank turns: −10% of max HP as each of its turns starts, never the last HP; a turn starting at full HP cures it.
- [x] **Health / Energy / Mana Potion** (trinkets): used from the trinket slot, they give back 15% × rank of max HP / Energy / Mana + con mod, and are emptied: still worn, and full again as the battle ends.
- [x] **Sweet Something** (trinket; a dubious treat): used, a Sweet Nothing; emptied the same way.
- [x] **Heart Up** (trinket): an extra life while worn; +1 Defense for each heart its wearer has spent. (?29)
- [x] **Heart** (consumable): used from the character sheet, an extra life for good. (?29)

More weapons and armor
- [x] **Burning Blade** (enchanted weapon; Icor drops it): strength attacks use the best of cha, wis or int; its wielder adds its str mod to max HP, even if negative.
- [x] **Starblade** (weapon; the Astral Envoy's reward): a melee hit gives back Power (Energy): (gross damage / the target's base stat total) × (1 + enchantment) of its max. (?29)
- [x] **Heart Up-Link** (armor; needs a positive con mod): con mod lives while worn. It sets no Defense: its wearer's is as if unarmored (dex mod + con mod). (?29)

- [x] **Enchanting** (`Item.enchant`, Pray to Urlo): an item is enchanted once: armor +1 Defense, weapons +1 damage on strength attacks, shown in the item's description; or it becomes its own enchanted form (`Item.enchanted_as`).

## Monsters

### Siren

Acts serene and stands still until unmasked. It tries to get units close by enrapturing them, with trickery and singing; once they're adjacent, it at once tries to Drown or Rake them, by its AP and access to water. Sirens come pre-configured: they know what they're about. *Now:* `behaviour` lure: Drown first, then Rake, without moving.

- [x] **Alluring** (passive, rank IV): rank persona, carrying a look: Friendly; Harmless, Beautiful, Serene, Safe; holy; named Beautiful/Radiant/Serene/Harmless Beauty/Lady/Songstress. Its persona is its nature, so it doesn't personify. Its rank comes off its dissonance penalty.
- [x] **Persona names.** A persona that claims an identity (rank 3) goes by a random fake name instead of "Something": an adjective from its persona's pool and a general noun from its noun pool ("Beautiful Beauty", "Radiant Lady", "Serene Songstress"). Later, adjectives can carry effects and nouns their own sprites. For now, each noun shows a text stand-in for its sprite (":D", ";)", ":3"). *Now:* each unit picks its name as the battle sets up (Unit → Persona: `shows_adjectives`, `shows_nouns`). Whoever it fools sees that name in the log, tooltips and its card, and the noun's face in place of its sprite on the map and the card.
- [x] **Sing** (active · 3 AP · 2 cost · range rank + cha mod · `sound`, `cha`): a song, used at once, landing on the closest units in range, no more than rank. On an ally: +1 movement per rank, for 2 turns. On a foe: drawn up to rank tiles toward the singer. The enraptured (convinced it's an ally) take it for support and walk in; one that isn't convinced won't, and a suspicious one won't either, but cha against its wis takes a stack of suspicion off.
- [x] **Drown**: a grapple, str contest against a unit. On a win, the Siren drags it to the nearest water tile, submerging both of them. Water must be within the Siren's movement range: it can't drag a unit past where it could move itself. −1 to its roll for every tile it must travel to the water; rank 2+: rank − 1 off that per-tile penalty. Submerged, the unit takes 1d12 + str mod at the end of each turn it doesn't escape the grapple; it escapes by moving away (see Grapples). *Now:* 5 AP, 2 cost. (?14)
- [x] **Rake** (once called Claw): its attack when no water is in range for the target. *Now:* 1d4 + str mod, `physical` `slash`, 3 AP, adjacent.

### Astral Princess (boss)

`Scenes/astral_princess.tscn`, `Units/AstralPrincess.png` (a placeholder). Level 18; str 18, dex 18, con 12, int 14, cha 14, wis 8; 60 HP, 20 Power. Starblade, Heart Up-Link and Heart Up: two lives; Defense 5 (dex + con mods), +1 for each heart spent. Worships Urlo. Persona: Personify III, going by Glittering / Shining / Gleaming / Glimmering Princess / Heroine / Vindicator. Intention "Purge evil: evil resides in the living"; strategy closest, strongest. Each revive brings a Regeneration Probe. Drops Heart Up (25%) or a Heart (75%). (?29)
- [x] **Powerful** (`pillar`): her Energy is Power.
- [x] **Physical Intelligence** V (`magical`, `pillar`): str mod can stand in for int mod on magical skills, with a max mod difference of 20% × rank. *Now:* `Skills/physical_intelligence.tres`, capped like Arcanist Perspective; she has it at rank III.
- [x] **Metea II** (tier 3 magical spell, `earth`, `fire`; channeled): cast on a tile in range, then strike a tile within (turns since) tiles of it: rank d12 + int mod to everyone within rank tiles but her.
- [x] **Smite V** (Paladin; `divine`): extreme damage to an adjacent unit (4d12 + cha mod at V), carrying her god's tag: Urlo's energy, so it drains Energy first, 80% of what's left once it's gone carrying to HP, and takes five enchantments off (enchanting her own items with what's left over).

### Regeneration Probe

`Scenes/probe.tscn`, `Units/Probe.png` (a placeholder). Enemy, Astral Envoy: level 3, 6 HP, movement 3, skittish (keeps away from its foes). One comes with each heart its side spends.
- [x] **Regeneration Pulse I**: heals allies within 3 tiles (1d4 + 5% of their max HP) × rank, once every (its side's lives left) turns. (?29)

### Shade

`Scenes/shade.tscn`, `Units/Shade.png` (a placeholder). An uncontrolled ally of the Astral Envoy's: level 2, 8 HP, Strike.

### Starman

`Scenes/starman.tscn`, `Units/Starman.png` (a stick figure, placeholder). Neutral (the Starmen), `dangerous`, `astral`, `beast`; aggressive AI, hunting the Stellar Order first (`Unit.hunts`). Level 6, 24 HP, 20 Power; str 14, dex 12, con 12. Strike, Powerful.
- [x] **Starsap** (passive): as its side's turn ends, it drains 2 Energy (Power) from each unit of another side a tile away side-on (larger units reach and are reached on diagonals: `Battle.sap_reach()`), HP once theirs is gone, into its own Power; what it can't hold fills the starpower sources, emptiest first. With every source full, it stops.
- [x] Falling, it reverts to a **Starmote** on its tile, keeping its Power (`Unit.reverts_to`).

### Starmote

`Scenes/starmote.tscn`, `Units/Starmote.png` (placeholder). Level 3, 12 Power. Recovering AI: it heads for the nearest free lattice tile and holds there, firing only when a foe is beside it and it has nowhere further to go (or it's holding the lattice).
- [x] **Starkind III** (inherent: it can't be disabled or removed, and takes no slot): its max HP is its max Power. Ending its turn off the lattice, it loses (100% − rank × 20%) of its max HP. On the lattice at full Power, it grows a **Reforming** stack as each of its turns starts and ends; otherwise it loses one. At its level in stacks, it reforms into a Starman (`Unit.reforms_into`).
- [x] **Energy Missile**: 1d4 energy damage, range 4, 3 AP, 1 Power.

## Lore: Center and Jimhe Deyn's gangs

Jimhe Deyn runs competing gangs out of Center, each a mix of species shoehorned into a single class and build. He puts each through its own cryptic exercise, which tangentially explains why its members invariably have particular armor skills (the Bracing passives).
- **The Rollers** (Agility Bracing): timely courier runs for protected businesses, in full kit, vaulting, folding and rolling over fences, through crowded outdoor seating and the city's hodgepodge elevations. Turf: **the Joint**, certainly the classiest of Center's outer districts, though class can't mask a definitive and enigmatic odor that permeates its otherwise glamorous shops and restaurants.
- **The Ratz** (Balanced Bracing): general calisthenics, fully equipped. They spend more time at **the Jym** than in their own territory: Center's premier combination training ground and derelict sewer system. Nobody but a few unpleasant kinds of monster and the Ratz hang out there, and the latter are usually pretty exhausted from training: an attractive place for fledgling adventurers to get stronger.
- **The Greasejons** (Vanguard Bracing): bulking while fully equipped; known to tear up Center's night markets for protein and calories. **Central Night Markets**: the shopkeeps keep the lights on and their guards heavily armed when nightfall comes and conflict breaks out in Central streets. You never know who'll be selling what when you find yourself cornered, for better or worse.
- **The Doozers** (Combat Bracing): deadlifting their peers in full plate; all a bit top-heavy for it. They run **the Central Lift**: a circular wooden platform from the depths of the Jym to the Center proper, started only at full capacity, its riders carefully curated for a high likelihood of friction with one another. Watching fights on the Lift is one of Center's premier entertainments, despite bloodsports not being permitted within city walls.
- **The Heaflers** (Meditative Bracing): casters made to sprint the city's circular paths in full armor. They look damn haggard.
- **The Teufers** (Invigorating Bracing): casters who cinch their robes two belt notches tight to stay lively. They don't look pretty.
- [ ] The gangs as encounters, and these places as scenes.
