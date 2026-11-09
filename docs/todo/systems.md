# Todo: systems

`[ ]` to do · `(?N)` waits on open question N (numbered across all todo files) · *Now:* what the game does today. Done items and decided rules: `docs/done/`. Index: `todo.md`.

Build roughly in this order; the content below depends on them.

- [x] **Levels** (2026-11-09): a basic level system. XP comes from a unit's BST (base stat total) and the stats behind it, with its level in the reckoning; the XP each level requires scales n log n. Built (`docs/done/systems.md`). (?78)
    - Answered (78): level is just a regular stat in the reckoning, and XP should be quite small at low level: a unit is worth (BST + level) / the stats counted (7). Any unit nearby gets a share and the one that felled it two. Bringing a unit back (a resurrection, or saving a downed unit by healing it up) pays XP too. A unit pays out once on death and once on revival. The level cap is 20 for now.
- [ ] **Saving the downed**: XP for bringing a unit back is built (`Battle.rescued()`), but nothing calls it yet: hearts and a Red Spinel Ring get a unit up on their own, there's no resurrection skill, and a downed unit can't be healed. Waits on how a downed unit (a Berserker) recovers once healed enough. (?79)

79. **Levels, revised - built on judgement, open for review (2026-11-09).**
    - What a unit is worth: (BST + level) / 7, rounded, at least 1 - the mean of the seven, level the seventh stat, its own and not what Level Down leaves it. A level 1 villager 9 XP (65 / 7), a level 4 Siren 12 (82 / 7). The level requirements stay 20 x n log2 n (20, 40, 100, ... 680 at level 10, 1,620 at 19); since stats don't grow with level, worth hardly does, so later levels take many more kills. The x20 is the number to tune.
    - "Nearby": within 3 tiles (straight-line) of the unit as it falls, standing (not down), and not on its side; third sides count. The killer (whoever struck it last, if standing and not its ally) takes two shares wherever it stands. The worth splits into the shares, each rounded, at least 1 XP (a villager felled with two more of its foes near: 9 in 4 shares, the killer 5, the other two 2 each). Units at the cap still take up their share. Felled with no blow and nobody near, it pays nothing.
    - Brought back: the same split among its own side within 3 tiles, two shares to whoever brought it back (`Battle.rescued(u, by)`). Getting up on a heart doesn't count as being saved.
    - Once: a unit pays out for falling once a battle and for being brought back once (`Unit.paid_fall`, `paid_rise`). Going down on a heart isn't falling: only its last fall pays.
    - The cap: level 20 (`Unit.MAX_LEVEL`). XP past it is lost; a starter never starts above it; the debug level-up stops there; the character sheet shows "max level". Level Up can still lift a unit's level now above 20 for a while.
    - The log groups a fall's XP in one line for the player's side: "XP for felling Villager3: Brick +4, Villager1 +2".

- [ ] **Checks and contests.** Skill-defined checks with `offensive` / `defensive` tags, advantage/disadvantage, per-skill range penalties. Needed by Interject, Gallantry, Snapping Turtle, the Siren's Charm. *Now:* the Check resolver carries advantage and disadvantage, offensive and defensive kinds (`Unit.check_mod()`, the `check` effect) and executes (`Check.cut()`); Jugular, Interdict and Turtle Tactics are built on it. Still separate fields: Drown's `drags_to`, Sing's `resisted`, Haluca's and Brainfog's `save`. Per-skill range penalties are still to do.
- [ ] **Equipping skills.** Learned vs equipped; slots shared by actives and passives, passives filling from the bottom of the hotbar; auto-equip (on by default); losing slots. *Now:* the hotbar has 4 + level / 4 slots (+ `extra_slots`), then slots skills grant, then the clover slot (filled on its unit's turn; hidden while it's unlucky, remembering its skill). Only actives and switched passives go on it, and every learned passive works. Disabling (Brainfog) treats always-on passives as filling the bar from the bottom. Unequipping a slot-granting skill should make its slots disappear.
- [x] **Real trees for Fighter and Paladin** (`docs/done/classes.md`). (?67)
- [ ] **Real trees for the Wizard and the Mage**: laid out, every new skill a stub (`docs/todo/classes.md`). (?70)
- [x] **Bracing in more checks**: investigations, inspecting tiles and doubting are offensive, hiding and deceiving rolls defensive, and a last stand takes its best defensive bonus (`docs/done/systems.md`). (?68)
- [ ] **More resources**: Stamina, Rage, Focus, Hype, Clout, Gold. *Now:* Mana, Sweet Nothings and Power exist, so Field Experience and Everyman still have nothing to work with.
- [ ] **Reactions and interrupts.** Units acting outside their turn: Interject, Gallantry, Final Act. *Now:* only the side whose turn it is acts (and traitors posing in its party).
- [ ] **Facing and direction**. *Now:* only Shields Up!'s `Unit.guard`, set by the skill; moves don't turn a unit.
- [x] **Effect strength set when cast**: `Unit.Applied.scale`, from Rejuvinate's distance (`Skill.decays`) and the caster's mod (`Effect.by_mod`: Interdict, Rejuvinate) (`docs/done/systems.md`).
- [ ] **One-use tile effects laid by skills**, triggered on entry (Warcry). *Now:* traps, zones, debris and earthworks, each its own kind.
- [x] **Teleport** (Send Off) and **pushes** (`Battle.place()`, `send()`, `push()`, `Skill.push`; nothing pushes yet) (`docs/done/systems.md`). (?68)
- [x] **Investigating on contact** (`docs/done/systems.md`). (?68)
- [ ] **Damage for moving**: effects that hurt a unit when it moves, which Meander can ward off at a higher rank.
- [ ] **Hard to read, by debuffs**: Haluca exists; others to come. *Now:* negative cha.
- [ ] **Fear, shove and entrance effects**: ways to make a grappler let go (or move) besides breaking free.
- [ ] **Commitment to the bit**: skills that let a traitor follow through on attacking its real allies rather than whiff (a Cultist, Oath or Devotee tree).
- [ ] **More ways suspicion wears off.** *Now:* a Siren's Sing and Pray to Eros, a stack at a time. No decay for now.
- [ ] **Divinity trees**: one per god, each with Pray at tier 1: Ramut (war, power), Eros (love, healing), Sol (light, fire), Urlo (magic, energy), Luun (dark, jovial), Drael (water, air), Vetruvis (earth, music). *Now:* the Paladin's Divinity root is Eros's (Rejuvinate, Pray, Renew, Smite, Send Off, Lovely Caster, Impassioned Fighter); the Paladin worships Eros. Clerics have a tab per god. The shared tier 1 row (`Role.shared`) is built, for a tab per god.
- [ ] **Urlo's enchantments, the rest**: trinkets, skills on items (their own enchantment effect, else +1 rank), and skipping items that can't be scaled (Heart +1). *Now:* weapon and armor, +1 or the item's own enchanted form; the trinket slot exists but Urlo skips it.
- [ ] **Skills on items**: an item carrying a skill its wearer can use while it's equipped. *Now:* items carry effects, hearts and their own fields (Starblade's refill), not skills.
- [ ] **Last stands elsewhere**: the general defensive check (`Battle.last_stand()`) is meant to come up again; only Level Down and Death use it now.
- [x] **Execute, more**: any skill tagged `execute` cuts the foe's side of its contests by how hurt it is (`docs/done/systems.md`). *Now:* only Death carries the tag. (?68)
- [ ] **Shops** (later): another way to get items.
- [ ] **Saving**: the stash, the starter's outfit and hearts last only until the game closes.
- [ ] **More contextual clues for searching**. *Now:* the AI weighs what it finds suspicious and enemies' debris.
- [ ] **Rangers**: Observe belongs on their tree too, once they exist.
- [ ] **Dissonance by how far the lie is**: harder to pretend to be something you very much aren't (a wolf in sheep's clothing, not a scary dog). *Now:* a tally of what the persona puts forward.
- [ ] **Unbounded maps, camera control, spawning mid-battle**, for Infernal Meadows. *Now:* units can be summoned onto a fixed map (`Battle.summon()`: Regeneration Probes).
  - [x] **Procedural maps** generated around the party: grass, light brush, ponds, thin streams (`Meadows.gd`).
  - [x] **Spawn formations** (`Formation`, `Formations/`): prefab groups (units and offsets) that scale and are reused, placed beside features (ponds) beyond the party's perception.
  - [x] **Area difficulty** (`Battle.difficulty`, `Difficulty.area()`): an area attribute (0.5, 1, 1.5) for dungeons and scenarios, built off the roll difficulties; it caps live spawns at ally faction count x difficulty and slows the escape portal.
  - [x] **Perception range** (`Battle.sight`, `Battle.in_range()`, `Perception._range()`): in every battle, units perceive within their wisdom total, and make out appearances within half that, the range shared across their side. Your answer (2026-11-09). Sides remember where they last made out foes and go looking there (`Battle.sightings`, `AI._hunt()`). (?77)
  - [x] **Area conditions** (`Battle.conditions`): Fog halves perception distances.
  - [x] **Camera** (`BattleCamera`, the Meadows): centred on the player's unit (its commander if it's down), or on the commanded unit while commanding, once it's far enough away. Home refocuses on the selected unit; Home again returns to the player's unit.
  - [x] **Key rebinds** in Settings: a dropdown of bindable actions and a press-a-key panel (`KeyBinds`, saved to `user://keybinds.cfg`).
- [x] **Water tiles**: flowing water, ponds, and shallows (their rank is their depth). Built (`docs/done/systems.md`). (?72)
- [x] **Flood**: a tile layer that slows movement and douses, often laid by effects or tile reactions. Its rank is its depth; deeper than a unit's size and the unit is submerged, so Sirens drown smaller creatures more easily. Laid Flood holds its depth for rank rounds, then dissipates. Built (`docs/done/systems.md`). (?72)
- [x] **Grappling and drowning as mechanics of their own**: drowning needs the Grappled effect on its target. Built (`docs/done/systems.md`). (?72)

74. **Infernal Meadows - answered (2026-11-09):** sight in every battle, shared across the side; the cap counts living allies, and demons over it after deaths stay; Gamut's Tower a walkable hall (`docs/todo/world.md`, ?77). The rest stands as built:
    - "Ally faction count" is the party's living units: the cap is that x difficulty, rounded up (7 x 1 = 7 at the start), doubled while the portal forms. Demons over the cap when the party loses units aren't despawned; none join until they're under it. One formation joins as each demons' turn opens (two while the portal forms).
    - Formations: a Siren by the water; two Sirens by the water; an Undine and two Sirens (anywhere, since the Undine brings its own water). Each scales with difficulty (x0.5, x1.5, rounded).
    - The portal opens 3 x difficulty turns (rounded up) after the 30th kill: 2 gentle, 3 standard, 5 harsh, counted on the party's turns. It shows its turns left, then OPEN. Every kill counts, whoever made it.
    - Perception range: on in every battle now (?77). Allies always see each other.
    - The party: your starter, both commanders (Alabaster, Icor) and the four villagers, all on your side. Ramut's Ire is off here (demons stay out of sight by design).
    - The plane: 12-tile chunks, kept one chunk around each of the party; nothing is forgotten behind it. Grass is tinted brighter for the Paradise look; brush is Tall grass (cover).
    - Gamut's Tower: a walkable hall now, a floor per difficulty (?77).
    - Camera: it glides to the player's unit (its side's commander once it's down), or to the selected unit once that's over 110 pixels off centre. Home keeps to the selected unit; Home again goes back to the player's.

72. **Water, Flood, drowning - built on judgement, open for review (2026-11-08).**
    - Depth is in unit sizes (Medium 3): Water and Pond 5, Flowing Water 2, Shallows 1. A unit is submerged when the water is deeper than its size, so a Medium unit keeps its head up in 3. A Flood's rank adds to the depth beneath it (a Flood on a pond deepens it). Only one Shallows depth exists yet; deeper shallows can be more tiles.
    - A Flood costs half a movement point per rank to cross. It puts out fire on its tile; there's no burning state on units to douse yet. "Rank rounds" counts its setter's side's turns, as fire does.
    - Drowning needs the target held and submerged; a holder engulfing it on its own tile (a mist Undine) counts as submerged. Drown no longer hurts a unit held on dry ground.
    - A Siren too far away to sing to anyone walks toward its best target, then tries its ambush (Drown, Rake) from there.

21. Evidence:  "14 is mid": I made 10–14 the middle band (2–3 debris, 1–3 tiles off) and 9 or less poor. Right floor for "mid"? Debris from hiding and from moving despawn by the same rule (placement range + dex mod). Right?

68. **Moving units and checks - built on judgement, open for review (2026-11-06).**
    - Pushes go straight away from the pusher and stop short of the first blocked tile; hitting something does no damage. Nothing pushes yet (a Shove, when designed).
    - Teleports (Send Off) spring a trap where they land and leave no debris trail; they don't count as moving.
    - On contact: a unit walking past a hidden foe (any tile of its walk beside it), or a hider ending its walk beside a foe, has the foe investigate against the hider's own roll, each time they come into contact, until it's seen through. Only hiding (concealment) is felt this way, not disguises.
    - Executes cut the foe's side of a save or a drag contest (x HP left / max HP / rank); Defense isn't a check, so attacks aren't cut.
    - Bracing kinds: investigating, inspecting tiles and doubting are offensive; hiding and deceiving rolls defensive; a last stand takes the best defensive bonus over its stats.

## Composability seams (see `docs/plan-composability.md`)

- [x] **`Check` resolver** - done; see `docs/done/systems.md`. Next on it: Affinity and context tags hook in here.
- [x] **Tile stacks** - done; see `docs/done/systems.md`. Leaves let effects through (a shrine under leaves still heals) and only hide them from sight, which settles 59. *Still to do:* lay leaves and glass in a scene (the museum is left bare so its seeded battles stay as they were), a wind skill for windswept, and folding snares, zones, flames and disturbed earth into layers.
- [ ] **Behaviour spine for skills**: grow `Skill.behaviours` (compose verbs that read a shared `Cast` bag) beside the flags; lift flags into behaviours on touch, densest clusters first (Strike chain, damage+riders, heals). Describe-where-you-execute. Answers ?55.
- [ ] **Context tags**: tag each cast offensive / defensive / supportive by use, feeding `Check` and the Affinity rank-cost. Enables Berserker and "invest under circumstances".
- [x] **Derived-stat pipeline** - done (`Unit.refit()`, `level_hp()`, `respec_by()`); see `docs/done/systems.md`. As built, HP = authored base (10 for class units) + `((con mod · (1 + Hardy)) + vigor) · level` - your formula as the *level scaling* on top of a base, not the whole of HP (alone it gives a level 1 Wizard 1 HP). (?61)
