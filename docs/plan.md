# Plan: the unbuilt systems

How to build what's still open in `docs/todo/systems.md`, plus the systems the class, item and monster entries depend on. Each phase unlocks content that is already designed, so a phase ends with something playable, not just plumbing.

Each system lists:
- **Approach:** where it goes in the code.
- **Unlocks:** what content it enables.
- **Blocked by:** the open questions (`?N`) to answer before it's built. Systems with no questions can start at once.
- **Size:** S is under a session; M is about a session; L is several sessions.

Every system gets a test file in `Tests/` like the existing ones, and its entries move from `docs/todo/` to `docs/done/` when it's finished.

## The round of 2026-11-09: silhouettes, glow, downed units, command skills, exhaustion

Six pieces of work, each built in its own worktree and merged in turn. The first four share no design and run side by side; the last two wait on them. Each has a question number for the calls made on judgement (`todo.md`).

| # | Work | What it is | Waits on | Tests | ? |
| --- | --- | --- | --- | --- | --- |
| A | **Silhouettes and glow** | Black shapes only for what might be a "monster in the brush": a suspected hider, or a unit in darkness or fog. Never an ally in ordinary conditions; a unit in broad daylight the viewer can't identify looks like any other. The faction glow gets four strengths, used by every skill and by commanding: barely (can't be reached), somewhat (reachable after a move that isn't certain), mostly (a certain move brings it in range; clicking makes the move and acts), fully (in range now). Allies out of command range keep their colour with a weaker glow. | — | `hud_test.gd` | 84 |
| B | **Downed** | One Downed condition (down but not out): HP runs below 0 while downed, to a limit of 20% max HP x rank; past it the unit dies. *Tenacity* (Adventurer, Fighter; passive): at 0 HP it lingers downed for rank rounds. *Grudge* (Berserker, low tier): downed, it keeps acting for rank rounds; more than rank actions, or a round ended without a melee attack, and it dies. Healed back above 0, a downed unit is saved (`Battle.rescued()` pays XP). | — | `downed_test.gd` | 85 |
| C | **Command skills and trinkets** | The limits stay at least 1 at low charisma; leadership skills and items stand in for talent. *Strategist*: rank more units a turn. *Tactician*: rank more orders per unit. Trinkets *Strategy Guide* and *Tactician's Playbook* do the same by rank. A Legendary rarity (4x the resources to rank up); *Grand Design*, legendary: +1 cha mod a rank when commanding. | — | `command_test.gd`, `items_test.gd` | 86 |
| D | **Exhaustion** | Each use of a skill in a round raises the next use's cost, AP and resource alike. Full weight on the skill used, half on the rest of its broad kind (physical, technical, mental). A channeled skill counts as one cast however long it's held. A unit recovers one use of each skill a turn; resting recovers its con mod more, or a fraction of a use at con mod 0 or less (at -3, one more every 4 turns rested). | — | `exhaustion_test.gd` | 87 |
| E | **Skill tooling, Kick, CLAUDE.md** | Once Downed is in: a tool (and an agent skill for using it) that takes the repeated, high-friction steps out of adding a skill. Tried on *Kick*: an attack at rank range whose effects depend on the tile between kicker and target. Then CLAUDE.md gets under four lines on how skills are composed. | B | `kick_test.gd` | 88 |
| F | **Clairvoyance** | An arcane and Cleric spell, channeled: it pings the silhouettes of unseen foes within the caster's wisdom + rank, building suspicion over the area but telling no more than where they are. Each turn end it's held it updates the places and gains a rank. | A | `clairvoyance_test.gd` | 89 |

**Status.** A to D are built (rows under "Built since"; the pieces' own notes in `docs/plans/`). E and F are built too (487 tests, 0 failed after the merge). The Battle UI v2 plan (`docs/ui-ux-v2.md`, ?90) is planned only; it builds on A's glow.

## Built since the plan was written

Answers to ?4, ?7, ?9, ?17, ?22, then ?23 to ?44 unblocked these. They're in `docs/done/`, each with its test file.

| Was | System | Tests |
| --- | --- | --- |
| 1.4 | Disabled skills (Brainfog) | `brainfog_test.gd` |
| 4.11 | Reserve generalisation: reserves from passives, whole-cost payment, refills, skills that need a reserve (Sweet Nothings) | `warlock_test.gd` |
| 4.12 | Energy damage (Smite) | `astral_test.gd` |
| 4.13 | Channeled skills (Metea) | `astral_test.gd` |
| 4.14 | Pillar skills | `brainfog_test.gd` |
| 5.15 | Item effects and a max HP effect | `items_test.gd` |
| 5.16 | Trinket slot (skills on items still to come) | `items_test.gd` |
| 5.17 | Equipping items, from the character sheet (equipping skills still to come) | `items_test.gd` |
| 5.18 | Drops, spoils and rewards | `items_test.gd` |
| 6.23 | Persona descriptors (intention, strategy) | `astral_test.gd` |
| 7.27 | Shared tier 1 row | `warlock_test.gd` |
| 7.29 | Warlock: Elmon's path (Hogel's is a stub) | `warlock_test.gd` |
| 8.33 | Hearts, revival, summoning | `hearts_test.gd` |
| 8.34 | Uncontrolled allies | `hearts_test.gd` |
| 8.35 | Astral Envoy: the Princess, Regeneration Probes, shades, the arena | `astral_test.gd`, `hearts_test.gd` |
| — | Coordinate's pooled reads (part of 6.26) | `coordinate_test.gd` |
| — | Effect arcs, damage dealt, either-side skills (wauaw) | `warlock_test.gd` |
| 13 | Starting items, item AP, potions | `kit_test.gd` |
| 20 | Vision through the player's unit (Synergy still to come) | `hud_test.gd` and the rest, unchanged |
| — | Skill attributes (range, rank, opening AP), level effects, sealed and cursed slots, pinned pillars | `kit_test.gd`, `slots_test.gd` |
| — | Sweet Nothings toggle, one patron, cha for wis | `warlock_test.gd` |
| — | Star lattice, Starmen and Starmotes, neutral sides | `stars_test.gd` |
| — | Last stands, Level Down, Death | `last_stand_test.gd` |
| — | Red Spinel Ring, the player down, Synergy | `revive_test.gd` |
| — | Smite by god, Level Up, levels taken back, tier gates | `smite_test.gd` |
| — | Allies and companions, Dagger initiative | `allies_test.gd` |
| 22 | Warlock, the rest: Chant, Hogel's path (Gasp, Breathtaking, Irradiate) | `hogel_test.gd` |
| — | Cleric (Luun, Sol), Synergy's range, Quartz Ring | `hogel_test.gd` |
| — | Humble, Hogel's rest, Sol's path, Igna and Aetha | `sol_test.gd` |
| 1.2 | Effect strength set when cast (Rejuvinate's decay, `Effect.by_mod`) | `paladin_test.gd` |
| 2.4, 2.5 | Pushes and teleports (Send Off) | `moves_test.gd`, `paladin_test.gd` |
| 5.15 | Investigating on contact | `moves_test.gd` |
| 6.23 | Fighter roots: Protector (Shields Up!, Obstruct, Interdict, Turtle Tactics), Slayer (Jugular); Interject, Snapping Turtle, Warcry, Inspire, Sundering, Silent Strike stubbed | `fighter_test.gd` |
| 6.24 | Paladin roots: Divinity: Eros (Rejuvinate, Send Off, Lovely Caster, Impassioned Fighter), Idealism, Prowess; Final Act and Gallantry stubbed | `paladin_test.gd` |
| — | Executes on any contest, bracing on investigations, hiding and last stands | `check_test.gd`, `bracing_test.gd` |
| — | Wizard and Mage trees laid out, their new skills stubs (?70); the tab row wraps | `casters_test.gd` |
| — | Skill icon boxes, ?? for AI designs, trees picked on the class tab, Wizard Dabblings (?71) | `casters_test.gd`, `paladin_test.gd`, `hud_test.gd` |
| 1.3, 2.7 | Water depth, Flood, grappling and drowning apart (?72) | `water_test.gd` |
| — | The Undine (?73) | `undine_test.gd` |
| 7.27 | Infernal Meadows: maps generated around the party, spawn formations, sight by wisdom, area difficulty, the battle camera; Gamut's Tower (?74) | `meadows_test.gd` |
| — | Key rebinds; Rift's domains and Emergency Exit's pockets (?75) | `keybinds_test.gd`, `pockets_test.gd` |
| — | Sight in every battle and hunting; borrowed trees; Rift unchanneled (?76) | `sight_test.gd`, `casters_test.gd`, `pockets_test.gd` |
| 7.27 | Gamut's Tower walkable, a floor per difficulty; dungeon menus (?77) | `tower_test.gd` |
| — | Eros for Clerics, caster trees from any class, class features (?76) | `hogel_test.gd`, `casters_test.gd` |
| — | Levels: XP from BST and level, n log n requirements (?78) | `level_test.gd` |
| — | Levels revised: (BST + level) / 7, shared near the fall, XP for revivals, once each, cap 20 (?79) | `level_test.gd` |
| — | Units in their own colours, drained by AP, grey once uncommandable; command limits by cha mod (?83) | `hud_test.gd`, `command_test.gd` |
| — | Discipline; the Ranger (Nature trees, Natural Talent); the Druid (biomes, guest trees, Beastshape); shared skills reached tree by tree (?80, ?81, ?82) | `nature_test.gd` |
| A | Silhouettes and the four strengths of glow (?84) | `hud_test.gd` |
| B | Downed; Tenacity and Grudge (?85) | `downed_test.gd` |
| C | Command skills and trinkets: Strategist, Tactician, Strategy Guide, Tactician's Playbook, Grand Design, Legendary rarity (?86) | `command_test.gd`, `items_test.gd` |
| D | Exhaustion (?87) | `exhaustion_test.gd` |
| E | Skill tooling (`Util/skill.py`, the behaviour seam), Kick, CLAUDE.md (?88) | `skills_test.gd`, `kick_test.gd` |
| F | Clairvoyance (?89) | `clairvoyance_test.gd` |

## Questions to answer first

| Question | Blocks |
| --- | --- |
| ?13 Fighter (Interject trigger, Sundering threshold, Silent Strike scope) | Reactions, Silent Strike, Sunder |
| ?12 Paladin (Final Act, Send Off, Rejuvinate's decay) | Effect strength, Teleport, Reactions |
| ?45, ?46 Humble's duration, Sol's gaps | Small fixes to built skills |
| ?2, ?11 Stat caps, Trade Skills and Grind | Adventurer core passives |

## Phase 1: Foundations

1. **Checks and contests** (M)
   - Approach:
     - Make one `Battle.check(a, stat, b, against, opts)` helper that returns totals and the winner.
     - It takes advantage or disadvantage (the same rule `doubt()` uses), per-tile range penalties, the caster winning ties, and `offensive` / `defensive` tags for Turtle Tactics.
     - Move Drown's contest, Sing's `resisted`, the `save` skills (Haluca, Brainfog) and `doubt()` onto it.
     - A skill declares its check with a small `Check` resource (stat, opposing stat, edge, range penalty) in place of today's separate `save`, `resisted` and `drags_to` contest fields.
   - Unlocks: Jugular, Interdict, Gallantry, Turtle Tactics, Snapping Turtle, the Siren's Charm.
   - Blocked by: ?14, for Charm only.
2. **Effect strength set when cast** (S)
   - Approach: `Unit.Applied.scale` exists and multiplies an effect's amount; set it at cast time from the distance.
   - Unlocks: Rejuvinate's distance decay.
   - Blocked by: ?12.
3. **Tile marks** (M)
   - Approach:
     - Snares, zones, debris and earthworks are each their own per-tile dictionary in `Battle` today.
     - Give them a common `Mark` base: owner faction, turns left, what triggers it (entry, turn end, stepped on), and whether it's used up.
     - One tick in `end_turn()` and one entry hook in `travel()` would serve all of them.
   - Unlocks: one-use tile effects (Warcry's Charge! and Routed!), damage for moving.

## Phase 2: Moving units around

4. **Pushes** (S): the reverse of `pull()`, stopping at blockers and holes. A pushed unit that hits something might take damage; that's a design choice to settle when Shove is designed.
5. **Teleport** (S): `Battle.place(u, c)`, which skips `walk()`. It springs traps but leaves no debris trail. Unlocks Send Off (?12: who picks the tile, and does it work on enemies).
6. **Fear, shove and entrance** (M): effects that make a unit move, or let go of a grapple. Fear is a forced move away, built on Pushes (and the AI's `_away()`); entrance is a forced move toward, reusing `pull()`. Each ends a grapple through the existing `_let_go()`.
7. **Damage for moving** (S): an effect hurts per tile walked, hooked into `travel()` through tile marks or a `per_tile` effect stat. Meander's top rank wards it off (`passes_by()` already counts tiles).
8. **Facing** (M)
   - Approach: `Unit.heading` exists but is only used by Eyes Forward. Add `Unit.facing`, set by moves and by Shields Up!, and a cone test in `Unit.hit()`.
   - Unlocks: Shields Up!.

## Phase 3: Reactions

9. **Reactions and interrupts** (L)
   - Approach:
     - Before `cast()` resolves a hit on a target, collect reactions from units whose passives listen: Interject (an ally is hit), Gallantry (an adjacent ally is attacked), Final Act (it reaches 0 HP; the hearts code's `downed` hook is the place).
     - Each reaction can swap the target or take an action, resolved in a fixed order, at most once each per trigger.
     - Final Act needs an "interrupt" turn: `_acting()` must allow a unit outside its side's turn, as it already does for posing traitors.
   - Unlocks: Interject, Gallantry, Final Act, Snapping Turtle.
   - Blocked by: ?12 (Final Act after its action), ?13 (Interject trigger and frequency).

## Phase 4: Resources and items, the rest

10. **More resources** (S each): Stamina, Rage, Focus, Hype, Clout, Gold, as `Reserve`s with the fields Sweet Nothings added. Unlocks Field Experience and Everyman. To be designed.
11. **Skills on items** (M): `Item.skills`, granted while equipped (added to the unit's slots, flagged so they can't be ranked); Urlo's enchantment then covers trinkets and item skills.
12. **Equipping skills** (L): learned vs equipped; the hotbar becomes the equipped set, passives filling from the bottom (Brainfog's order already assumes it); auto-equip and a Settings toggle; drag-to-slot on the skills screen. Blocked by ?3.
13. **Starting items** (S): built.
14. **Saving** (M): the stash, the starter's outfit and hearts to a save file.

## Phase 5: Perception follow-ups

15. **Investigating on contact** (S): moving next to a hidden unit triggers `investigate()` against its stored roll. Hook it in `travel()`, beside the debris cleanup.
16. **More contextual clues** (S): last-seen positions, where attacks came from (`_expose`), and the tiles a hidden unit could reach since it was last seen, in `AI._search()`.
17. **Dissonance by how far the lie is** (M): a distance between the persona's claimed words and tags and the unit's own, from a small similarity table.
18. **Hard to read, by debuffs** (S): more effects like Haluca's `scrambled`, through `Perception._dim()`.
19. **Commitment to the bit** (S): a passive that lets a posing traitor really attack its own allies; `cast()`'s whiff branch checks for it.
20. **Synergy**: built, within command range.

## Phase 6: Trees and classes

21. **Divinity trees** (M): one tab per god, with Pray on a shared row (`Role.shared`). Eros gets Renew and Rejuvinate. Other skills are to be designed.
22. **Warlock, the rest** (S): more Elmon and Hogel skills.
23. **Fighter roots** (L): Protector needs Checks, Facing and Reactions; Vanguard needs Tile marks; Slayer needs Checks and Silent Strike (Disabled skills are built; ?13).
24. **Paladin roots** (M): Send Off needs Teleport; Final Act needs Reactions; Smite could join its list (?29).
25. **Rangers** (M): a new class with Observe and Eyes Forward on its tree. To be designed.

## Phase 7: Encounters

26. **Astral Envoy tuning** (S, later): balance waits until more of the game exists; Sunder once Sundering exists (?13).
27. **Unbounded maps, camera and spawning** (L): a map that streams chunks, a camera that pans and follows units, and spawning out of view (`Battle.summon()` is the start). Unlocks Infernal Meadows (30 kills open the escape portal).

## Suggested order

1. Phase 1, Checks first: it touches the most code, and five Fighter skills and the Siren's Charm wait on it.
2. Phases 2 and 3 next, so the Fighter and Paladin roots can be built (with ?12 and ?13 answered).
3. Phase 5's small items (15 to 19) fit between larger pieces.
4. Phase 4's equipping skills once ?3 is settled.
