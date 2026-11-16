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

- [x] **Checks and contests.** Built 2026-11-15 (?141): `Battle.check()`, `SkillCheck` (`docs/done/systems.md`). Was: skill-defined checks with `offensive` / `defensive` tags, advantage/disadvantage, per-skill range penalties. Needed by Interject, Gallantry, Snapping Turtle, the Siren's Charm. *Now:* the Check resolver carries advantage and disadvantage, offensive and defensive kinds (`Unit.check_mod()`, the `check` effect) and executes (`Check.cut()`); Jugular, Interdict and Turtle Tactics are built on it. Still separate fields: Drown's `drags_to`, Sing's `resisted`, Haluca's and Brainfog's `save`. Per-skill range penalties are still to do.
- [x] **Equipping skills**: `Unit.equipped()`, the hotbar is the equipped set (actives too), auto-equip with a Settings toggle, losing slots by source, drag-to-slot, saved. Built 2026-11-15 (?163) (`docs/done/systems.md`).
- [x] **Real trees for Fighter and Paladin** (`docs/done/classes.md`). (?67)
- [ ] **Real trees for the Wizard and the Mage**: laid out, every new skill a stub (`docs/todo/classes.md`). (?70)
- [x] **Bracing in more checks**: investigations, inspecting tiles and doubting are offensive, hiding and deceiving rolls defensive, and a last stand takes its best defensive bonus (`docs/done/systems.md`). (?68)
- [ ] **More resources**: Stamina, Rage, Focus, Hype, Clout, Gold. *Now:* Mana, Sweet Nothings and Power exist, so Field Experience and Everyman still have nothing to work with.
- [x] **Reactions and interrupts**: Interject, Gallantry, Final Act, Snapping Turtle. Built 2026-11-14 (?140): `Behaviour.react`, `Battle.react`, `grant_interrupt` (`docs/done/systems.md`).
- [x] **Facing and direction**: `Unit.facing`, Rear ?? and Flank ??. Built 2026-11-15 (?142) (`docs/done/systems.md`).
- [x] **Effect strength set when cast**: `Unit.Applied.scale`, from Rejuvinate's distance (`Skill.decays`) and the caster's mod (`Effect.by_mod`: Interdict, Rejuvinate) (`docs/done/systems.md`).
- [x] **One-use tile effects laid by skills** (Warcry). Built 2026-11-14 (?139): `Battle.Mark`, `lay_mark()` (`docs/done/systems.md`).
- [x] **Teleport** (Send Off) and **pushes** (`Battle.place()`, `send()`, `push()`, `Skill.push`; nothing pushes yet) (`docs/done/systems.md`). (?68)
- [x] **Investigating on contact** (`docs/done/systems.md`). (?68)
- [x] **Damage for moving**: the `per_tile` Effect stat, Footsore ??, warded by Meander. Built 2026-11-14 (?139) (`docs/done/systems.md`).
- [ ] **Hard to read, by debuffs**: Haluca exists; others to come. *Now:* negative cha.
- [x] **Fear, shove and entrance effects**: three Effect stats driven by `Battle.drive()`. Built 2026-11-15 (?146) (`docs/done/systems.md`). Was: ways to make a grappler let go (or move) besides breaking free.
- [ ] **Commitment to the bit**: skills that let a traitor follow through on attacking its real allies rather than whiff (a Cultist, Oath or Devotee tree).
- [ ] **More ways suspicion wears off.** *Now:* a Siren's Sing and Pray to Eros, a stack at a time. No decay for now.
- [ ] **Divinity trees**: one per god, each with Pray at tier 1: Ramut (war, power), Eros (love, healing), Sol (light, fire), Urlo (magic, energy), Luun (dark, jovial), Drael (water, air), Vetruvis (earth, music). *Now:* the Paladin's Divinity root is Eros's (Rejuvinate, Pray, Renew, Smite, Send Off, Lovely Caster, Impassioned Fighter); the Paladin worships Eros. Clerics have a tab per god. The shared tier 1 row (`Role.shared`) is built, for a tab per god.
- [x] **Urlo's enchantments, the rest**: trinkets and item skills (else +1 rank), skipping items that can't be scaled (Heart +1). Built 2026-11-15 (?143) (`docs/done/systems.md`).
- [x] **Skills on items**: `Item.skills`, lent while worn. Built 2026-11-15 (?143) (`docs/done/systems.md`).
- [ ] **Last stands elsewhere**: the general defensive check (`Battle.last_stand()`) is meant to come up again; only Level Down and Death use it now.
- [x] **Execute, more**: any skill tagged `execute` cuts the foe's side of its contests by how hurt it is (`docs/done/systems.md`). *Now:* only Death carries the tag. (?68)
- [ ] **Shops** (later): another way to get items.
- [x] **Saving**: `Save.gd`, JSON at `user://save.json`. Built 2026-11-15 (?145) (`docs/done/systems.md`). Was: the stash, the starter's outfit and hearts last only until the game closes.
- [x] **More contextual clues for searching**: `AI.clues()` weighs last seen, reach, where a blow came from, marks and debris. Built 2026-11-15 (?159) (`docs/done/systems.md`).
- [ ] **Rangers**: Observe belongs on their tree too, once they exist.
- [x] **Dissonance by how far the lie is**: `Perception.lie()` over a natures table. Built 2026-11-15 (?152) (`docs/done/systems.md`). Was: a tally of what the persona puts forward.
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
    - **Built (2026-11-14, ?120):** a bump into a concealed unit gives the walker 1 recon on it (`docs/plans/small-notes.md`).
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

## Exhaustion (2026-11-09)

Plan and rules: `docs/plans/exhaustion.md`.
- [x] **Exhaustion** (`Scripts/Exhaustion.gd`, `Unit.exhaustion`): built (`docs/done/rules.md`, `docs/done/systems.md`). (?87)
- [x] **Stamina** (2026-11-10): built (`docs/done/systems.md`, `docs/done/classes.md`, `docs/plans/stamina.md`), `Tests/stamina_test.gd`. (?87, ?98)
- [x] **Universal channel rule** (2026-11-10): built (`docs/done/rules.md`, `docs/plans/channels-jam.md`). (?85, ?89, ?97)
- [x] **Stamina recovers in battle** (2026-11-11): answered "stamina recovers alongside energy, rank bonus if resting"; built (`docs/plans/stamina.md`, "Amended"). (?98, ?100)
- [x] **The HUD shows only a unit's largest reserve**: a Ranger with Energy, Stamina and Focus sees one bar. Built 2026-11-14: the map draws a sliver bar for each reserve beyond two (?128). (?100)
- [x] **A save-Stamina toggle**: Stamina and Mana are now toggles on the hotbar (2026-11-11, ?116); switching is a channel. (?98, ?116)
- [ ] **The AI has no idea of a `stamina` skill's extra effect** (Move ??). (?98)
- [x] **`tapped` and `helpless`** (2026-11-12, built 2026-11-14, ?119): `tapped` is a utility effect other effects may apply; a tapped unit can't act or take orders. It is not a debuff and can't be cleansed, but its sources can be addressed (healing off a stun, a wound), which removes it, and the unit is free to use AP and reactions on its turn. Tapped when: out of AP; it has received cha mod orders this turn (until the commander ends the command phase; afterward it may use remaining AP on autopilot); downed or stunned with no effect or skill letting it act (see Mindless Fury). `helpless` is for stun and other full action-disabling spells. (?65, ?90)
- [x] **Tapped saturation** (2026-11-12, built 2026-11-14, ?119): a unit acting in a reduced capacity is drawn at 50% saturation, instead of 0% for tapped or 75% for low AP / command limit.
- [x] **Stun** (2026-11-12, built 2026-11-14, ?119): a wound-type cause of `tapped`/`helpless`; healing it off removes the tap.
- [x] **Mindless Fury** (2026-11-12, built 2026-11-14, ?119): Berserker passive, tier 5. A unit may take rank actions in a reduced capacity when it would otherwise be interrupted or incapacitated; its effective mental stats are 1 while acting this way. It can't power through `tapped` to take unlimited actions in a turn, and needs blanket mitigation of unit-inflicted disabling effects.
- [x] **Drone** (2026-11-12, built 2026-11-14, ?119): tier 4, Mage general / Specialist Merchant. The unit does not tap when the command limit is exceeded; its mental stat mods are capped at +rank when acting this way.
- [ ] **Rebalance the museum** (Nemes leans on Hex), or teach the AI to weigh a raised cost and vary. Now Lancin 27 / Nemes 3 with exhaustion on (13 / 17 off); Stamina and Move ?? change none of it. (?87)
- [x] **Nothing on the hotbar shows a worn skill until hovered.** Built 2026-11-14: a small gold diamond on the slot when the unit's worn emblem modifies that skill (`SkillSlot.modded`; `docs/plans/ui-small.md`, ?136).
- [x] **Static skill descriptions** (skills screen, spellbook) show base costs only. Built 2026-11-14 (?134): the hotbar tooltip, spellbook and its detail read what the holder pays (`Skill.markup(rank, with_spec, u)`); the skills screen stays base on purpose, with a "Base values" note when modifiers change them.

87. **Exhaustion - answered (2026-11-10), built (`v-stamina`, ?98).** A task from a caster, martial or specialist tree inherits that as a tag; truly general skills apply less exhaustion on everything. Stamina, above, is new. The rest stands as built:
    - **Broad kinds** (your physical / technical / mental, for the half share) are read as the existing martial / specialist / magical category tags. **Twenty of the 65 active skills carry none** (Smite, Solar, Renew, Sing, Drown, Rake, Energy Missile, Flamecharm...) and wear on themselves only. A skill with two kinds shares with both, half once.
    - **Con mod 0 rests like +1** (one extra use), as Energy recovery does; read literally ("adds con mod") it would add nothing. Below 1, 1 / (1 - mod) of a use: -1 half, -3 a quarter. Fractions are continuous.
    - **The museum sims flip** (now, with the museum changed since: Lancin 27 / Nemes 3, against 13 / 17 with exhaustion off) from Lancin 8 / Nemes 22 (3-14 turns) to Lancin 29 / Nemes 1 (8-20 turns); Nemes won by casting Hex over and over (437 casts to 293), and at a step of 0.25 it is still 25 to 5.
    - **The AI is unchanged** and doesn't weigh exhaustion: it picks by score and stops when `can_afford()` says no.
    - Step 0.5 of base cost per use, linear (AP stays fractional, resource rounds up, 0 stays 0), tunable in three constants (`STEP`, `KIND` 0.5, `RECOVERY` 1). The half share is derived from the other skills' own counts, so it recovers as they do. Counts fall at the end of the unit's own side's turn (one use a turn is free for ever, two build up). A channeled skill is one use, paid at the rate the channel was. Strike III's three hits are one use; free recasts and toggles are none. Light activity gets no resting bonus. A reserve that pays whole costs still pays its 1 point. Staged tests run with exhaustion off (`Test.calm()`).

98. **Exhaustion kinds by tree, Stamina, Move ?? - answered (2026-11-11), built (`w-focus`, ?100).** "Stamina recovers alongside energy, rank bonus if resting": built, so "never refilled in battle" below is replaced (`docs/plans/stamina.md`, "Amended"). Still open: Strike counting as general; mana paying for skills magical only by tree; the name "Move ??". Built on judgement before that, my calls: Your ruling on 87, built on `v-stamina` (`docs/plans/stamina.md`). My calls:
    - **Tree beats tag**: a skill's kind comes from the trees it sits on, so Strike (tagged martial, on the base General tree) is now general. A skill on trees of two kinds gets both.
    - **The general share is 0.25**: a general skill's use counts a quarter against every other skill, one way.
    - **Mana now pays for skills magical only by their tree** (Stonegift, the Sol and Eros skills a Wizard holds), since the rules read `tagged()`.
    - **Stamina is on Blade, Scout, Fury and Slayer**: the Rogue, the Ranger, the Berserker, and the Paladin's Fury and Slayer Prowesses (the agile ones); a Fighter can learn it through Slayer. An Adventurer can't (none of its trees offers it).
    - **Reserve (con mod + 2) x rank**, ~~never refilled in battle~~ (now recovers with Energy, ?100). It pays automatically, before Energy; there is no way to save it.
    - **Waterstrike is the only magical skill Stamina covers** (physical and magical by its tree).
    - **Move ?? was added** since walking had no skill to carry the `stamina` tag: 2 AP, 1 cost, rank tiles, 2 x rank if paid with Stamina. **Move ?? is an AI-made name for you to review.**
    - **Adventurers' Field Experience and Everyman let Energy count as Stamina** for a `stamina` skill's bonus (a general skill counts as the kind they name); the exhaustion cut stays the passive's alone.
    - **Sims**: base now Lancin 27 / Nemes 3 with exhaustion on, and 13 / 17 with it off; unchanged by this (Hex casts 314 to 293).

## Skill tooling, Kick and CLAUDE.md (2026-11-09)

Plan and what was built: `docs/plans/skill-tooling.md`. Built (`docs/done/systems.md`, `docs/done/classes.md`). Suite after the merge: 487 tests, 0 failed.
- [x] `Util/skill.py new` and `check`, the behaviour seam (`Scripts/Behaviour.gd`, `Skill.behaviours`), Kick, the agent skill `.claude/skills/new-skill/SKILL.md` and `CLAUDE.md`. (?88)
- [x] **Behaviours don't run on the early-return paths in `Battle.cast()`** (Strike's chain, contests, saves). Built 2026-11-14 (?134): `Battle._land()` runs them on every path that lands; a lost save or contest runs none, as a missed roll runs none.
- [x] **The HUD forecast and the AI don't know Kick's tile effects.** Built 2026-11-14 (?138): `Kick.outcome()`, `Behaviour.foresee`.
- [ ] **No map has a hole tile yet**, so Kick's hole push is only tested.
- [x] **The stale-count check**: `hud_test.test_every_tab_draws_its_skills` covers every tab. Built 2026-11-15 (?156).
- [x] **`skills_test.test_wiring` skips without python3.** Built 2026-11-14: `Test.tool_check` fails, naming the problem (?127).
- [x] **Waterstrike's tag `bludgeon` probably should be `blunt`.** Built 2026-11-14: `blunt`, so it breaks a starpane (?127).
- [x] **Shrink `UNSAID`**: 11 existing `Skill` fields that no description mentions are exempted in `skills_test`. Built 2026-11-14: `UNSAID` is empty (?133, ?134).
- [x] **Lift `pings` into a behaviour and lower `FLAG_CEILING`** (raised from 124 to 125 because Clairvoyance's `pings` flag was built in parallel, beside the seam). Built 2026-11-14: `Behaviours/clairvoyance.gd`; `FLAG_CEILING` is now 128 (?133, ?134).

88. **Skill tooling, Kick, CLAUDE.md - settled (2026-11-10):** "that's fine for now"; the calls stand.
    - **"g-action skill/ tool"** was read as a Claude Code agent skill (`.claude/skills/new-skill`) plus a script (`Util/skill.py`). Say if you meant something else.
    - It paid: Kick took 9 files with no hand wiring, against 17 files and about 12 hand-edited .tres for Tenacity and Grudge.
    - **Kick:** General Martial tier 1, 4 AP, 1 Energy, 1d4 + str, range = rank, effects last rank turns. "The tile between" is the tile at the kicker's feet toward the target. Checks run trap, water, loose ground, hole/edge, bare; the first match wins. A trap springs on the target but stays where it is, revealed. Water leaves **Soaked** (movement -rank), loose ground (leaves, sand, debris) **Blinded** (offensive checks -rank), a hole, edge or off-map tile pushes rank tiles, bare ground is plain damage; adjacent targets take a 1-tile push. Soaked and Blinded are new reusable effects (`Effects/soaked.tres`, `blinded.tres`).
    - **CLAUDE.md** is four lines: two on skills (data first, behaviours in `Behaviours/*.gd`, never a new `Skill.gd` flag; use `skill.py new` and `check`), one on reading the big files by range, one on running the tests.
    - New skills use behaviours; old flags move over only when touched. `check` runs as `skills_test.test_wiring`; `skills_test.test_flags_described` fails when a field a skill sets doesn't change its description.

## Unit bios (2026-11-10)

- [ ] More tempers as they're wanted (cowardly, vengeful...): each is a word in `Bio.BEHAVIOURS` and a branch in `AI.act()`. (?91)
- [x] Bio text on the character sheet and the Guide. Built 2026-11-15 (?154). Appearance words beyond the Bio tables are flavour only. (?91)
- [ ] Clout earned in play (helping a side, lying to it) rather than set by hand. (?93)

100. **Focus, and Stamina's recovery - built on judgement, open for review (2026-11-11).** Your rulings on 97 and 98, built on `w-focus` (`docs/plans/focus.md`). Suite after both merged: 38408 checks, 535 tests, 0 failed. My calls:
    - **Who:** the Ranger's Bounty root and the Mage's Commitment root. Commitment's earlier AI stub "Focus ??" is renamed **Fixation ??** (an AI-made name, for review).
    - **Size** (wis mod + 2) x rank; starts each battle empty; builds half its max (rounded up) on each turn spent resting, none when light or busy, none while channeling.
    - **Payment:** it pays first for a ranged attack (reach > 1.5), otherwise only once Energy can't. A ranged attack that leaves Focus at 0 gets + rank to its roll (the forecast counts it). Violet.
    - **Jam drains Focus** by the HP the target lost.
    - **Stamina recovers** on Energy's tick and rate (full resting, half light, none busy) plus its rank on a resting turn; it recovers even with Energy full, and Power doesn't stop it; an idle channeler gets half and no bonus.
    - Open: the HUD shows only a unit's largest reserve (a Ranger with Energy, Stamina and Focus sees one bar); the AI doesn't rest to build Focus. (Both built 2026-11-14: ?128, ?130.)

## Resources: Mana, Stamina, the toggle (2026-11-11)

Plan, readings and what was built: `docs/plans/resources.md`; done in `docs/done/systems.md`. `Tests/resources_test.gd`.

116. **Resource rules: Mana and Stamina as toggles - built on judgement, answered (2026-11-12) for the recovery rules, built (2026-11-14, ?121).** Your design (Mana and Stamina as toggle passives, on when learned; who pays what; Mana's even-keel regen, Stamina's rest bonus; switching as a channel that carries over up to 10% of max per rank per turn; two bars). Suite after both merged: 41663 checks, 565 tests, 0 failed. My calls, each for you to confirm or change:
    - **Answered (2026-11-12), built (2026-11-14, ?121):** Energize and Recovery Endurance (RE) below, with burnout. See ?117 in `docs/todo/classes.md` for the text of both.
    - **General mechanic, burnout:** a unit recovering Energy by means other than waiting or resting eventually burns out. Con mod worth of recoveries are deferred; that deferral is **Recovery Endurance (RE)**, and it only comes back mid-combat if the unit rests at full resource. Reenergizing always consumes RE.
    - A unit that recovers Energy or health with no RE left, and fails a con check, loses max HP / resource: 10% x (1 + abs(RE)) x the amount recovered (for HP, the amount over the RE threshold; RE goes negative). A unit that abuses recovery without the con to bear it gradually loses maximum HP / resource.
    - **Single heals:** a unit healed above con mod x 20% of its health by one skill use makes a con check against the difference; -1 RE on a failure.
    - **Replacement is literal:** a unit running on Mana or Stamina has its own Energy emptied as the battle starts and doesn't get it back. That is the lock-out from Energy-cost actives. Confirm?
    - **Wizards and Mages now start every battle with no Energy** (they run on Mana). Strike costs nothing so still works; their non-magical costed skills need Energy Transfer, Overcharge or a switch. This is the intended result of the design; say if it bites.
    - **Energy from Energy Transfer, a potion or Overcharge pays for anything**, non-caster skills included: the rule reads the toggle, not which reserves are held. Confirm?
    - **Stamina also pays general skills**, and `physical` is dropped from its list (it pays martial, specialist, general), or a Stamina user couldn't pay for Move ??. Confirm?
    - **Running on Stamina, no spell that costs anything can be paid** (Focus and Overcharge included); a free spell (Waterstrike) is still allowed. Confirm?
    - **Focus** keeps its rules and sits beside either toggle, except for that spell ban.
    - **Regen:** Mana as Energy does (full resting, half light, none busy) plus its rank on a resting turn and half that on any other turn, busy included; Stamina's resting bonus is 2 x rank. A reserve switched off doesn't recover. Confirm?
    - **A unit with both toggles learned** keeps the first on its bar on, the other off. Confirm?
    - **The switch is a channel** (`Unit.toggle()`): it takes effect at the channel's end, the unit running on the old resource meanwhile. Each turn held counts one; when it ends (toggled again, broken by acting, interrupted by Jam) the old reserve goes to 0 and floor(10% of its max x the toggle's rank x turns held), no more than it had, goes into the new one. Holding another channel, a unit can't switch. Confirm?
    - **Learning a toggle mid-battle** makes the unit run on it at once, but the Energy it had stays until spent. Confirm?
    - **The AI never toggles**; a Wizard or Mage under the AI just runs on Mana. (Built 2026-11-14, ?130: it switches when it can strike and pay for nothing.)
    - **Bars:** a unit shows what it runs on first, then its other reserves (a second 2px bar on demand); the Energy bar only when it holds Energy; the unit card lists each held reserve. Mana and Stamina sit on the hotbar as toggles.
    - Open: the hotbar marks no switch in progress, only the log line ("switching to Energy, channeled"); a Druid holds Mana from its Astral tab before learning the skill (with no toggle, both pay as before). (The switch mark is built, 2026-11-14, ?128.)

## Vanishing, preparation, tooling (2026-11-11)

102. **Vanishing before its eyes (!?) - built on judgement, open for review (2026-11-11).** "New effect for units vanishing / becoming harder to perceive before a unit's very eyes !?... a unit will assume a hostile / friendly unit that becomes obscured this way is on the same faction when concealed, sufficient trickery still applies." My calls:
    - **What counts:** a skill putting concealment on a unit (Hide, Vanishing Act, Blur, Invisibility) or a unit walking into cover, watched by an awake unit - ally or foe - that made out its side and place just before and still has it within half its sight range (close enough to see how it looks). Stepping out of sight range isn't vanishing.
    - **The assumption** (`Unit.assumed`) lasts the battle: while it can't make out the unit's side, it takes it for the side it seemed (the card and the AI read it so). A plain read shows the truth again. A lie that fools it still wins (Vanishing Act's own trickery does).
    - **Not yet:** darkness or fog laid over a unit (Darkstone, Waltz of Vapors) doesn't count, only the unit's own concealment and the ground it steps on.
105. **Preparation - built on judgement, open (2026-11-11).** "Before a fight starts, the player can review the map and may click on up to cha mod (min 0) friendly units to learn more about (one recon level); up to wis mod enemy units / tiles to scrutinize." My calls:
    - **Only battles started from the entry screen** prepare (`Battle.prep`, `Game.starter.prep`); tests and the tower's later floors don't.
    - **The leader's mods**; whether a unit counts as an ally is how it *seems* (a disguised foe that looks friendly is an ally study).
    - **What a study gives:** its whole side reads that unit or tile a recon level better for the battle. **Scrutinizing** a foe also looks harder at it if it fools the leader (`doubt()`); a tile is inspected (`inspect()`). A plain tile can be studied, to no effect beyond the recon.
    - **Begin** is the End Turn button (and Space) while preparing; the initiative roll comes after.
111. **Tooling (2026-11-11).** `role.py tree` (an empty root) and `role.py tab` (a tab beside a class's own, a new choice with `--by`/`--affinity`, or `--into` an existing one), in the new-class process; `icon.py effect` for a status icon; a new behaviour hook, `affinity`. Fixed: `icon.py` lettered a skill by its *effect's* name when that came first in the file: Coalescing, Drown, Interdict, Judgement, Reckless Abandon and Snare had wrong placeholder letters, now redrawn.

## Tapped, helpless, Stun, Mindless Fury, Drone (2026-11-14)

Plan, readings and what was built: `docs/plans/tapped.md`; done in `docs/done/systems.md` and `docs/done/classes.md`. Tests: `stun_test`, `mindless_fury_test`, `drone_test`; `command_test.test_idle` and `hud_test.test_command_colour` changed to the new rule.

119. **Tapped, helpless, Stun, Mindless Fury, Drone - built on judgement, open for review (2026-11-14).** Your answers of 2026-11-12, built on `a-tap`. Suite after all merged: 42616 checks, 0 failed (648 tests). My calls, each for you to confirm or change:
    - **Tapped is derived, never stored, never cleansed:** a unit is tapped while out of AP, or ordered to its cap this turn (until the command phase wraps; then autopilot may spend the rest), or helpless (the `helpless` stat, asleep, Downed without `acts`) with no permit. Lift the source (heal the wound, cleanse Stunned, heal above 0) and it is free at once. `Unit.tapped()` and `stopped()` serve Battle and the AI; `Command.tapped(u)` serves orders and the HUD. Confirm?
    - **Free (0 AP) actions still go** while out of AP: the AP pay check would pass anyway. Sleep counts as helpless, so Mindless Fury acts through it too. Confirm?
    - **Autopilot:** allies ordered up to their cap with AP left act on their own when the turn ends; allies given fewer orders don't (unchanged); a held ally (`Command.lock`) doesn't, so a hold at a 1-order cap stays a hold. Confirm?
    - **Reduced capacity** (Reduced capacity ??, a Glossary term): acting under a permit, drawn at 0.5 saturation. Tapped is 0; low AP or orders toward the cap drain to 0.75 (it was 0.55). Confirm?
    - **Stun** (Brawn, after Crushing Blow; Paladin and Berserker): prowess trees have no tiers, so depth stands in for high tier. 4 AP, 2 Energy, reach 1, 1d6 + str, -5 to hit ("very difficult"); a failed difficult con save at its rank leaves Stunned (`Effects/stunned.tres`, stat `helpless`, a `wound`, `ease` 2 so cleansing halves its rank) for rank turns, interrupting what it stops. The save carries a `taps` tag. Confirm?
    - **Mindless Fury** (Fury, after Grudge and Frenzy, needing 3 of the root's others, Berserker only; standing in for tier 5): rank skill uses per own turn while helpless, counted as Grudge counts them; mental mods count as 1. Past that it is tapped: no infinite actions. Confirm?
    - **Drone** (general Caster tier 4, magical): ignores both command caps (orders per ally, allies a turn); an order past either makes it reduced for the turn, mental mods capped at its rank. Its tap from running out of AP still holds. Confirm?
    - **Jam's Jammed ?? stays** (the interrupt plus lost reactions): a short Stunned would make the low-tier Jam a full lockout and step on Stun. Confirm?
    - **Check tag seam:** `check_bonus(s, kind, tags)`; a `check` effect with `tags` counts only for checks carrying one. After merging, the HUD grey-out reads each ally's own order cap. Confirm?
    - **New names to review:** Reduced capacity ?? (the term).
- [ ] **No Merchant tree exists for Drone**: it sits on the general Caster tree at tier 4; the Specialist "Merchant" half waits for the tree. (?119)
- [x] **No screenshot of the new saturation.** Taken 2026-11-14 (?136): 0% is clear grey, 50% plainly half faded, 75% only a faint dulling on a dark sprite. (?119)
- [ ] **0-AP free actions still go while tapped**; say if they should not. (?119)

## Recovery: burnout, Energize, Heal, Megaheal (2026-11-14)

Plan, readings and what was built: `docs/plans/recovery.md`; done in `docs/done/systems.md` and `docs/done/classes.md`. Tests: `burnout_test`, `energize_test`, `megaheal_test`; `champions_test.test_hex_iii` resets with `hp = 50`, not `heal(50)`.

121. **Burnout, Recovery Endurance, Energize, Heal, Megaheal - built on judgement, open for review (2026-11-14).** Your design under 116 and 117, built on `a-recover`. Suite after all merged: 42616 checks, 0 failed (648 tests). My calls, each for you to confirm or change:
    - **One place:** every non-regen recovery already passes `Unit.heal()` or `Unit.grant_energy()`; both report what actually came back through `Unit.recovered`, and `Scripts/Burnout.gd` is the rule's one home. Regen never reports; out of combat nothing listens. Confirm?
    - **RE** (`Unit.endurance`) starts each battle at max(con mod, 0): a con 10 unit has none to spare, and negative con doesn't start in debt. The card shows "RE n". Confirm?
    - **Energy grants spend 1 RE each**, even at 0 or below (it runs negative); a reserve restore (Mana potion) and Overcharge count as Energy; a grant that gives nothing spends nothing. Confirm?
    - **Depleted** (RE 0 or below as a recovery starts): a con save, d20 + con check mod against the standard DC 12 (my pick). A fail cuts that pool's max by 10% x (1 + |RE|) x the amount recovered, rounded, at least 1; an HP recovery also takes 1 RE. Your "(recovered hp over RE threshold)" is read loosely: HP loss reckons on all the HP recovered, as Energy's does, so small heals still burn a depleted unit. Confirm?
    - **Big single heal:** more than max(con mod, 0) x 20% of max HP in one heal asks a con save against the excess (the raw HP number, no 10 +); a fail is -1 RE. Confirm?
    - **Refill:** a resting turn ended with Energy (or the reserve it runs on) full resets RE to its starting value, all of it, not +1. Confirm?
    - **Lost max lasts** past the battle (`Unit.burnt`; cut in `refit()`, `max_energy` or `pools()`): "gradually lose maximum" read literally. The card shows "-n burnt". Nothing restores it yet. Confirm?
    - **Energize** (general tier 4, 0 Energy, 2 AP for one pair, then every further pair it can, up to rank pairs, only as many as there is room): 1 Energy a pair, past a full bar the rest is Overcharge up to 20% x rank of total resource, for rank turns. No amount picker. If it has no room at all, its 2 AP are still spent. Being tier 4, it needs 3 T4+ skills first. Confirm?
    - **Heal and Megaheal** (Cleric): there is no life tree, so both sit on Eros, gated by depth since `Branch.tier` only sets depth on a class tree and a Paladin could take them at once: Heal after Rejuvinate, Megaheal after Heal, each needing 4 other Eros skills. One behaviour (`heal.gd`, exported `magnitude`): the dice x magnitude + wis mod + rank. Heal 1d8 x moderate (1.5 x rank), 4 AP, 4 Energy; Megaheal 1d8 x severe (3 x rank), 6 AP, 9 Energy; range 3. Confirm?
    - **New names to review:** none. Burnout and Recovery Endurance are glossary terms from your text.
- [x] **The AI doesn't use Heal, Megaheal or Energize**: `Skill.heals()` reads `heal_mods`, which they don't carry. Built 2026-11-14: `Behaviour.restores()` (?130). (?121)
- [ ] **Other gains don't report**: Sweet Nothings on a kill, Focus building, Downed saves via `hp =`, post-battle refills. Which should count? (?121)
- [ ] **Burnt max has nothing to restore it.** (?121)
- [ ] **No burnout out of combat.** (?121)
- [ ] **A Life tree** to hold Heal and Megaheal as domain-general skills. (?121, ?122)

## Tag colours and trim (2026-11-14)

Plan, readings and what was built: `docs/plans/tag-colors.md`; done in `docs/done/systems.md`. Tests: `tag_colors_test` (new), `glossary_test` (reads fire's colour from Tags). Your request: "associate a color with each tag. Accessories associated with tag has trim color (eg banner with color insignia)".

125. **Tag colours and trim - built on judgement, open for review (2026-11-14).** Built on `m-colors`. My calls, each for you to confirm or change:
    - **One table in `Tags.gd`** (`Tags.COLOR`, keyed by word), not a field on `Glossary.TERMS` (most coloured words aren't terms). `Tags.color(word)`: its own entry, else its parent's, else neutral grey. `Glossary.ELEMENTS` and `SkillSlot.TINTS` are gone; `Glossary.KINDS` stays as the kind palette. Confirm?
    - **Every existing word has an explicit colour** (about 200), except the children that inherit. Elements keep the colours they had; disciplines take their slot hues brightened; resources match their bars; conditions take their identity (burning fire, soaked water); the difficulty ladder runs green to red; materials take their material's colour. All AI-picked, for you to retune. Confirm?
    - **`mechanic.py tag` requires `--color`** unless the tag has a `--parent`; `mechanic.py color <word> <hex>` sets or retunes any word; `check` fails a word with no colour of its own or through its parent. Not derived from the kind (grey mush). Confirm?
    - **Trim** is the first tag, parents expanded, with a colour not in `Tags.PLAIN` (materials, forms, weights, qualities, stats, generic categories); a new coloured tag trims items out of the box, a new plain word must join PLAIN. light, medium and heavy are weights, never the element (a Dagger isn't trimmed pale yellow). No override field. Confirm?
    - **Where it shows, with no new text:** term links, damage floaters (skipping the broad words: a fireball's number is orange, a sword's stays red), the hotbar stripe (now every skill: martial red, specialist green), a swatch on the character sheet rows, a pennant per trimmed item on the unit card (own units, and any unit whose Defense you can read), and a small banner on the sprite. Confirm?
    - **The sprite's banner is the trinket's alone**, on dark cloth rather than its side's colours so it can't give a disguise away; it is on the sprite node, so a silhouette blacks it out and a persona's face hides it. Confirm?
    - **For emblems** (see the skill modifiers section below): a Sigil, Insignia, Crest or Badge trims for free if its tag or symbol has a colour; its form word needs a colour and a place in PLAIN, or `check` fails it.
    - **New names to review:** none (colours aren't names; they carry no ??).
- [ ] **Retune the colours**: every entry in `Tags.COLOR` is mine; `mechanic.py color <word> "#rrggbb"` changes one. (?125)
- [ ] **Equipment isn't composed on the sprite** (one PNG per unit), so trim is a drawn banner, not a recoloured part; real trim waits on layered art. (?125)
- [x] **Emblem forms** (sigil, insignia, crest, badge) a colour and a PLAIN place. Built 2026-11-14 (?131). (?125)

## Fixes (2026-11-14)

Plan and what was built: `docs/plans/fixes-11-14.md`. Tests: `turn_test` (three sides, off-turn death, two sides), `helpless_test` (new); `watch_test`, `gods_test`, `god_slots_test` read `God` instead of `Unit.GODS`, none weakened.

127. **Fixes - built on judgement, open for review (2026-11-14).** Built on `n-fix`. My calls, each for you to confirm or change:
    - **`end_turn` passes the turn once:** it sets `Battle.ending_turn`, `_on_died` doesn't pass the turn while it's set, and `end_turn` passes it at the end to the first side after the ending one that still stands. A side dying outside `end_turn` still passes at once. Confirm?
    - **A leader that is `stopped()` (helpless, no permit) gives no orders and gathers no one.** Mindless Fury is a permit, so a berserker under it can still lead. Confirm?
    - **One query, `Unit.reacts()`** (not jammed, not stopped), read by dodging, guarding and obstructing. Obstruct wasn't asked for but is a reaction by Jam's own definition, so a sleeping or Stunned Vanguard no longer holds a zone. Confirm?
    - **The guard is suspended, not ended** by going helpless (`Unit.guard` stays), so a Stunned shield-bearer's stance returns with the Stun's cure; Jam still ends it. Confirm?
    - **A helpless unit still watches** (seeing isn't acting), not changed. Confirm?
    - **God constants:** `Unit.GODS` and `GOD_TAGS` live on `God` (`domains`, `tag`); patrons have neither; `role.py god` takes `--domains` and `--tag` and `check` fails a pantheon god without them. No behaviour change.
    - **Waterstrike's tag is `blunt`:** a visible consequence is that it breaks a starpane and brittle terrain it's aimed at. Unrelated to the Slayer's Bludgeon. Confirm?
    - **Wiring tests fail, not skip,** with no python (`Test.tool_check` tries python3, python, then the usual folders).
    - **New names to review:** none.
- [ ] **Should `Unit.guard` end (not just pause) on going helpless?** (?127)
- [x] **Other reactions** read `reacts()`. Built 2026-11-14 (?140): `Battle.react` gates every reaction on `Unit.reacts()`. (?127)

## AI support (2026-11-14)

Plan and what was built: `docs/plans/ai-support.md`. Tests: `Tests/ai_support_test.gd` (11); the combat_test count notes changed, nothing else.

130. **AI support - built on judgement, open for review (2026-11-14).** Built on `n-ai`. My calls, each for you to confirm or change:
    - **One hook for restoring:** `Behaviour.restores(c) -> Dictionary` (pool to expected amount), declared by Heal, Energize and Resuscitate; the AI sums it with the old `heal_mods` / `heal_bonus` HP. Not a `Skill` field and `Skill.heals()` untouched (Battle would heal twice). A later healing behaviour declares its own and the AI picks it up. Confirm?
    - **`_heal()` picks the best (skill, ally)** over all its healing skills by `want()` (the first on a tie), not the first skill with any target, and asks `fits()` per target. Confirm?
    - **Non-HP pools are not healed on demand:** Energize is cast last in a self-directed turn once the pool is at half or less (Energy only if it runs on Energy, a reserve only if it spends from it). It never costs a blow, and a Mana user never wastes it. Confirm?
    - **Support:** `_support()` also takes any non-hostile, not self-only, not dual skill with effects of its own (Intervention, Rally, Rejuvinate, Level Up, Blur, Invisibility, Embellish) on an ally in reach or itself last, that lacks the first effect. Self-only buffs (Bulwark, Hide) are still left alone: casting them every turn would reshape every sim. Confirm?
    - **Switching:** on a self-directed turn with no channel, nothing to strike from here and nothing it can pay for that is worth something, it toggles to the other pool if that could pay; the switch ends the turn idle and `_finish_switch()` completes it next turn rather than waiting for the carry to fill. Confirm?
    - **Focus:** holding an `aims` reserve below full, a ranged attack it would pay from it and nothing to strike from here, it rests (50% of max a rest); a strike's score gains `FOCUS` (1.0) x the Focus it would spend. It doesn't hold a shot back to build more (that needs a planner). Confirm?
    - **Clairvoyance:** with no foe in sight, no clue, no last-seen place and no channel, it casts a `pings` skill and hunts on the pings the same turn; `act()` no longer holds still for a `pings` channel (else a scryer scrys forever). Confirm?
    - **New names to review:** none.
- [ ] **HUD "help" orders** (`Skill.serves(&"supportive")`) still don't count Heal: that is `Skill.heals()`. A Helpful order does heal, through the AI's own `_heal()`. (?130)
- [x] **The AI doesn't hold a shot back to build Focus**, and prefers Resuscitate over Heal on a Downed ally only by want or list order. Built 2026-11-14 (?138).
- [ ] **Switching only goes to a pool that currently holds enough**: a unit with one toggle and no Energy has nowhere to switch to. (?130)

## Skill terms, cost and modifiers (2026-11-14)

Plan, readings and what was built: `docs/plans/skill-modifiers.md`; done in `docs/done/systems.md`. Built on `m-core`. Tests: `Tests/modifiers_test.gd` (10 tests); no existing test changed. Your request of 2026-11-14 (verbatim in the coordinator's `answers-2026-11-14.md`); the martial skills in it (Slayer) are built (?126) and the tag colours (?125). Two follow-ups are in progress: `r-route` and `r-param` (below).

131. **Skill terms, cost and modifiers - built on judgement, open for review (2026-11-14).** My calls, each for you to confirm or change:
    - **"claude-skill"** is `.claude/skills/new-skill/` and `Util/skill.py`, which it drives. Confirm?
    - **One place for what a skill does:** `SkillTerms` reads four channels from existing fields (rank to range, rank to impact, stat to range, stat to impact); `Modifiers` is the one reader every per-rank and per-stat value goes through; `Pricing` the cost calculator. Behaviours declare their own channels with `Behaviour.terms()`.
    - **Nullify = rank I or stat 0.** A nullified rank term reads as rank I (rank' = 1), not zero, so a skill whose whole effect is "x rank" still does its rank-I thing; a nullified stat term reads 0. Confirm?
    - **RSC reading:** a factor 1 + f(r), r the emblem's rank: f = (2 + r)/(3 + r) for one skill (Sigil), (1 + r)/(2 + r) for a subset (Crest, Badge), r/(1 + r) for all (Insignia). Your "rank *" prefix is read as dropped (with it the factor passes x2, against "approaches x2"). Several emblems on one skill multiply. Confirm?
    - **Lambda is p^(1+f), payoff x(1+f):** a requirement's permissive share p becomes p^(1+f) under lambda up (80% needed becomes 96% at f = 1; p to p squared) and p^(1/(1+f)) under lambda down (to its root). The contingent payoff is multiplied by 1 + f (lambda up) or divided by it (down), rounded, at least 1; a multiplying effect scales its distance from 1. Built as a multiplier, not your exponent or root, which misbehaves on shares like Stoneskin's 0.4 and on +1. Only beneficial contingencies; a penalty contingency makes a skill no more eligible. Confirm?
    - **Intensity mapping:** low / moderate low / moderate / high / extreme map onto `Difficulty.MAGNITUDE` faint / mild / moderate / strong / severe (intense and overwhelming lie between and past); an existing skill's intensity is derived from its tier's average at rank I. Confirm?
    - **Tag-kind eligibility:** a tag is a modifier by its Glossary kind: damage (and `DAMAGE_TAGS`) needs a damage tier, check needs a check, condition needs effects, ground needs a tile aim, target never; an unknown tag is ineligible. Added tags reach `has_tag`, `hit_tags`, executes, stun's check. Confirm?
    - **Symbol eligibility:** each needs the channel it boosts (rho up rank impact, rho down rank range, sigma down stat impact, sigma up stat range; lambda a beneficial contingency), so an emblem never only takes away.
    - **Emblems in the trinket slot:** one at a time, so they compete with Heart Up and rings; made by hand as `.tres` (no item tool), no icons yet, named "<Word> Sigil" etc. (so no ??). Scopes: Density and Diluted Sigils, Concentrated and Dispersed Crests, Restrictive Badge, Unrestrictive Insignia, Fire Insignia, Execute Sigil. Rarities uncommon to epic. Confirm?
    - **Emblems in Alabaster's loot** (Heart 4, each emblem 1); the Astral Princess's and Icor's tables are pinned by `items_test`, so left alone. Confirm?
    - **Five new declarative `Skill.gd` fields** (`intensity`, `impact`, `penalty`, `requires`, `priced`), raising `FLAG_CEILING` from 125 to 130. This is against CLAUDE.md's "never a new `Skill.gd` flag"; they are data every skill shares, and the task asked for it. **Please OK this, or say how else to carry them.**
    - **Pricing** (`Pricing.TABLE`): intensity points exponential, per-rank hit and damage, effect impact (tame 2, impactful 5) tapered by its requirement, flat penalties, adjacent -1, AP = 1 + 0.5 p, Energy = 0.5 p. Existing skills keep hand-set costs unless `priced = true`; modifiers scale a price by computed(modded) / computed(base). Only Poach is priced (its computed price is within 1 AP and 1 Energy of its hand one). **Should I tune the price table, or adopt the computed prices?** 71 of 89 hand-priced actives drift from the computed price at rank I (`skill.py drift`).
    - **Slayer skills, hand against computed (rank I):**

      | Skill | Hand AP/cost | Computed AP/cost | Points |
      |---|---|---|---|
      | Gank | 4/2 | 2/1 | 1.9 |
      | Peel | passive | - | - |
      | Poach | 3/2 | 4/3 (now priced) | 5.5 |
      | Sutemi | 5/2 | 5/4 | 8 |
      | Spike | 6/2 | 3/2 | 4 |
      | Hitch | 3/1 | 5/4 | 7 |
      | Bludgeon | 5/2 | 3/2 | 4 |
      | Slam Jam | 6/3 | 6/5 | 9 |

      The gaps: impactful effects outweigh low damage (Hitch); a gate on the whole skill (Gank) and the target's Defense (Spike) count as cheap; the Slayer plan's "high damage" is 1d10, which the bands read as moderate.
    - **A symbol can also be a tag:** a Fire Insignia puts fire on every eligible skill, trimmed fire. Emblem forms (sigil, insignia, crest, badge) are `Tags.PLAIN`; the six symbols are coloured through `mechanic.py color`.
    - **New names to review:** none (emblem names follow your pattern).
- [x] **Skill terms:** `SkillTerms`, `Modifiers`, `Skill.requires`, the Terms fields; any eligible tag or element applicable to any skill by a modifier, new eligible tags working out of the box (the five fields are a call, above). Built 2026-11-14. (?131)
- [x] **Cost calculator** (`Pricing`, `skill.py drift`), folding in the refunds of Poach and Slam Jam through their behaviours' contingencies. Built; the table is a first cut. (?126, ?131)
- [x] **Modifiers:** the symbol passives as data (`Modifiers`, symbol ids `rho_up` ... `lambda_down`). Built. (?131)
- [x] **rho, sigma and lambda**, up and down, as the scaling and restriction rules. Built. (?131)
- [x] **The Rank Scaling Calculation** (`Modifiers.rsc()`), once, shared by every emblem. Built. (?131)
- [x] **Sigil, Insignia, Crest and Badge** items, trimmed through ?125 (`Item.emblem`, `scope`, `trim_tag()`). Built. (?131)
- [x] **Authoring:** `skill.py new --intensity --impact --penalty --requires --hand-priced`, `terms`, `modifiers`, `drift`, with `check`. `.claude/skills/new-skill` not edited (house rule: skills aren't edited without you). (?131)
- [ ] **Tune the price table or adopt the computed prices**; 71 of 89 hand-priced actives drift. (?131)
- [ ] **Ineligible for every modifier** (`skill.py modifiers`): 54 skills became 27 after ?133 and ?134 (`docs/plans/param.md` has each call); the 27 are left concrete (flat, binary or build-time gates). (?131, ?133)
- [x] **Not routed through the reader yet:** saves, executes, DCs, reach, requirements on every outcome, descriptions, AI estimates, behaviour hooks and `Unit.mod()`. Built 2026-11-14 (?134).
- [x] **Behaviours on cast's early-return paths** now run. Built 2026-11-14 (?134). (?131)
- [x] **Lift `pings` into a behaviour, and shrink UNSAID**: built 2026-11-14, UNSAID empty (?133, ?134). (?131)
- [x] **Emblems have no icons** (items have none yet), and no item tool writes them. Icons built 2026-11-14 (`icon.py item`, ?135); still no item tool. (?131)

**Built, the two follow-ups to ?131:** `r-param` (?133) and `r-route` (?134), below.

## Parameterizing skills (2026-11-14)

Plan, readings and what was built: `docs/plans/param.md`; done in `docs/done/systems.md`. Built on `r-param`. Tests: `Tests/param_test.gd` (5 tests); `clairvoyance_test`, `water_test` and `skills_test` changed. Your request of 2026-11-14: a skill too concrete that could be compatible if tagged, polymorphized or parameterized should be.

133. **Parameterizing skills - built on judgement, open for review (2026-11-14).** `skill.py modifiers` went from 54 ineligible to 33, and to 27 once ?134 took the deferred six. My calls, each for you to confirm or change:
    - **"Parameterized"** means the skill declares its channels and every read of that rank or stat goes through its holder's modifiers; a channel is declared only where the read is routed, so no skill is eligible for a modifier that would do nothing. Confirm?
    - **"Add the missing tags"** read as the terms' kind flags and channels a skill failed to declare (Manifest's per-stat effect). No `Skill.tags` added: none of these skills' checks or damage would read a tag modifier. Confirm?
    - **Passive hooks** (affinity, lets_word, hurt, healing, command_mod, step_cost) get the holder and a rank, not a Cast: `Behaviour.mods_on(holder)` and `holder_rank()`. Peel uses it too.
    - **Rank as a quantity of effect is rank impact** (Move's tiles, Energize's pairs, Telepathy's commands); **as a distance, rank range** (Molothrus, Telepathy, Clairvoyance); wisdom score in Clairvoyance's reach is stat range.
    - **21 parameterized:** Efficiency's five (Acceptance, Bargaining, Quarry, Survivalist, Wildcaller), Bandwagon, Illusionist, Molothrus, Telepathy, Word to the Wise, Energize, Heal, Megaheal, Move, Resuscitate, Clairvoyance, Manifest, Sweet Nothings, Mana, Grudge and Tenacity (the Downed rule's rank).
    - **27 left concrete, with the reason in the plan's table:** binary or max-rank-I traits (Arcanist, Everyman, Powerful, the slot passives...), flat ones (Favour, Hazard Expert), Oceanic (a penalty contingency only), and **build-time gates** (Dabblings' `studies`, the general-tree `waives`, Divinity, Mastery, Symphony, Witchery, Generalist...): an emblem coming off would strand picks. Hand prices kept; no per-rank added to flat passives (Favour). Confirm?
    - **Clairvoyance's pings are a behaviour** (`Behaviours/clairvoyance.gd`), with three generic hooks, `recast_stops()`, `held(b, holder)` and `senses()` (the AI's scry); `Battle.ping(u, reach)` and `pinged()` stay as the perception side; reach is wisdom score + channel rank through the reader. `FLAG_CEILING` 130 to 129 (later 128).
    - **UNSAID:** Sweet Nothings' two were already said; Coalescing's and Drown's `grapples` were dead (`holds()` is true by `drowns`) and are removed from their .tres, `water_test` asserting `holds()`. The other seven's markup went to ?134.
    - **New names to review:** none.
- [ ] **The 27 left concrete**: confirm the reading, or say which should scale (Favour per rank would rebalance). (?133)
- [x] **Strike's and the elemental reads** have a `terms()` (`element` on a `chain` skill). Built 2026-11-15 (?160). (?133)

## Routing through the reader (2026-11-14)

Plan, readings and what was built: `docs/plans/route.md`; done in `docs/done/systems.md`. Built on `r-route`. Tests: new `Tests/route_test.gd` (10 tests); `modifiers_test.test_requirement` and `skills_test` changed.

134. **Routing through the modifier reader - built on judgement, open for review (2026-11-14).** Finishes what ?131 listed as not routed. My calls, each for you to confirm or change:
    - **Which channel each read is:** rank as a distance or how many it reaches is rank range (aura reach, Flamecharm's split, Flamewall's width, Solar's cone, Send Off, Sing's targets, Waltz's radius, Metea's blast); rank as what it does is rank impact (a save's + rank, an execute's `/ r`, hits per rank, DCs, turns, Beastshape's form rank, Pray, Smite's riders...); the full list is in the plan. Vetruvis's radius takes one rank in, a call. `skill.py modifiers` 51 to 27 with ?133.
    - **Requirements on every outcome path:** one payoff set (`hit`, `edge`, `damage`, and new `turns` and `strength`) read wherever the skill has that outcome; lambda pays turns like hit. A requirement is described (`Requirement.markup()`).
    - **Descriptions as held:** hotbar tooltip, spellbook and its detail read through `u.mods()` ("{o:1.75 x int mod}", AP and cost as the holder pays); **the skills screen stays base** (it is where ranks are bought) with a "Base values" note. Confirm?
    - **`Behaviour.describe_as(c)`** added for modified numbers in behaviour text; none override it yet.
    - **AI and HUD share `Battle.damage_range()`**; `hit_chance` counts the requirement's hit and edge and the hit's tags.
    - **Behaviours on every path** (`Battle._land()`): Beastshape, aura/retrieve/humble/fog/exit/boost/imbue, Eros's heal, Level Down, Death, Strike's chain (once). **A lost save or contest is a miss and runs none; a channel stopped by recasting lands nothing; tile skills have no Cast.** Confirm?
    - **UNSAID emptied** by markup lines for Beastshape, Coordinate's links, Alluring's adjectives and nouns, Personify's AP, Pray's range. **`Skill.cinders` was dead** (its Effect does the work) and is removed; `FLAG_CEILING` 129 to 128.
    - **New names to review:** none.
- [x] **Behaviours' `describe()` lines** show modified numbers: `describe_as` on the 22 behaviours with terms. Built 2026-11-15 (?148). (?134)
- [x] **Routed:** Rift turns and difficulty and Look's dissonance rank (`domain`, `practised look`). Built 2026-11-15 (?160). (?134)
- [ ] **Still not routed:** the text of reserves, opens and Downed rules, and the build-time gates (Dabblings, waives). (?134, ?160)
- [x] **A lost save or contest runs behaviours**: `Behaviour.missed()`, run by `Battle._miss()`. Built 2026-11-15 (?160); no skill uses it yet. (?134)

## AI tactics (2026-11-14)

Plan and readings: `docs/plans/ai-tactics.md`. Built on `q-ai`. Tests: new `Tests/ai_tactics_test.gd` (11 tests, 31 checks); no existing test changed.

138. **AI tactics - built on judgement, open for review (2026-11-14).** My calls, each for you to confirm or change:
    - **The AI reads what the player sees:** the chance to hit from `Battle.hit_chance` (edge, guard, Defense, Focus) scales a blow's worth. Uses the target's true Defense, though the HUD may hide it. Kept.
    - **Two more hooks, `refunds` and `unguarded`:** Poach and Slam Jam's refunds count at 1.5 HP per AP (AP only, not Energy or Focus); Sutemi's lost Defense costs 0.5 HP a point. Both guesses.
    - **Focus:** it rests rather than fire only weak shots (none likelier than 0.5) when a rest would pay for a ranged attack; melee or a decent shot always wins.
    - **Resuscitate first:** a `revives` hook and a bonus (1.0), not a rule, so an unaffordable one falls back to Heal.
    - **Kick's tiles:** `Behaviour.foresee` and `Battle.foresee`; the trap's dice before mitigation, ignoring its blast; the HUD adds them to the HP span and lists riders in the hover tooltip.
    - **Grudge, cheap halves:** a Downed Grudge unit mends itself when the skill restores more than it is below 0; a Downed Grudge foe that is the last foe standing isn't given its melee (the unit walks away, or holds still outside reach), unless one blow ends it.
    - **New names to review:** none.
- [x] **A Defense on `Read`**: the AI guesses 12 when none shows. Built 2026-11-15 (?162). (?138)
- [x] **Starving Grudge with allies in its reach, or over more than one round**: `AI.starve_worth()`. Built 2026-11-15 (?162). (?138)
- [x] **Poach's Energy / Focus refund and regain, and Slam Jam's interrupt**, are priced (`foresee` riders, cost points). Built 2026-11-15 (?162). (?138)
- [x] **Kick's trap blast on bystanders and its push distance** are priced (`Kick.driven()`, spill). Built 2026-11-15 (?162). (?138)

## Tile marks, Warcry and moving damage (2026-11-14)

Plan and readings: `docs/plans/tile-marks.md`. Built on `s-marks`. Tests: new `Tests/marks_test.gd`, `warcry_test.gd`, `per_tile_test.gd`, `regain_test.gd`; `fighter_test`, `gods_test`, `pockets_test` changed. Suite 45594 checks, 0 failed.

139. **Tile marks, Warcry, damage for moving - built on judgement, open for review (2026-11-14).** My calls, each for you to confirm or change:
    - **One `Battle.Mark`** (side, lifetime, uses, price on entering, who it touches, how it's drawn); only disturbed earth (Pray) folded in. Snares, zones, debris, flames and layers stay as they are. Kept.
    - **Triggers:** entry (every tile of a walk, and a teleport) and turn end; a mark on a tile you pass goes off, so no separate "stepped on".
    - **Who knows:** its side, units that know it, or everyone at concealment 0 (Warcry's); otherwise the tile read decides. Warcry's marks are all plain.
    - **Warcry:** a self-cast that marks toward the nearest rank foes it can read (no UI to choose), the first rank tiles of each line from the caster, the nearer half Charge! (allies, +10% x rank damage, rank AP back) and the rest Routed! (foes pay rank more movement); lasts 2 + rank of its side's turns, each tile one use.
    - **Regain ??:** a new instant Effect stat (AI-made name): it gives AP back to a pool by its tag, up to what the pool started the turn with.
    - **Footsore ??:** a reusable status (AI-made name), `per_tile` 1 a rank.
    - **`per_tile`** (your name): each tile walked costs HP, not for teleports, pulls or pushes. **Meander wards it** when its rank is at least the effect's (the skill's text says "higher", its ground rule "not greater": equal wards).
    - **The AI** casts Warcry just before it advances on a foe, with a new `marks` hook.
    - **New names to review:** Footsore ??, Regain ??.
- [x] **The hazard estimate foresees `per_tile`** and Meander's wards. Built 2026-11-15 (?150). (?139)
- [x] **Helpful marks (Charge!) pull the route and the AI's approach.** Built 2026-11-15 (?150). (?139)
- [ ] **Fire, zones, debris and snares aren't marks**: fire rolls fresh dice and spreads (`flame()`, about 15 sites); revisit if a second dice-rolling mark appears. (?150)
- [x] **The HUD draws a `?` for a hidden or suspected mark.** Built 2026-11-15 (?150). No content lays a hidden mark yet. (?139)
- [x] **You can choose which foes Warcry marks toward** (`Behaviour.picks()`, the HUD's pick aim). Built 2026-11-15 (?157). (?139)

## Reactions and interrupts (2026-11-14)

Plan and what was built: `docs/plans/reactions.md`. Built on `s-react`. Tests: new `Tests/reaction_test.gd`, `interject_test.gd`, `gallantry_test.gd`, `final_act_test.gd`, `snapping_turtle_test.gd`; `paladin_test`, `fighter_test` changed.

140. **Reactions and interrupts - built on judgement, open for review (2026-11-14).** My calls, each for you to confirm or change (?12 and ?13 had been left "as built", and nothing was):
    - **One hook, `Behaviour.react`,** and one seam, `Battle.react`; triggers attacked, hit, fallen and snap. Area skills cast on a tile and damage outside casts (flames, traps) trigger none but `fallen`.
    - **Order:** the attacker first, then its target, then the rest by distance; a unit's passives top to bottom; each at most once a moment.
    - **Reaction checks** are contests, the reactor winning ties, carrying their skill's tags (so Turtle Tactics helps).
    - **Tag `reaction`** (your word), on all four skills; `skill.py check` fails a reacting behaviour without it.
    - **Interrupt turn:** a free action is one skill use of any AP cost, no walking, Energy still paid; the player picks for the leader and party, the AI for others (`AI.interrupt()`).
    - **Interject (?13):** allies beside it, every hit; rank 5+ adds +25% x rank Defense as guard.
    - **Gallantry:** an adjacent ally, before the roll, cha contest; the attack then locks on the Paladin. Rank adds nothing yet.
    - **Final Act (?12):** holds at 0 HP, takes one free action, then falls as it would have unless it healed above 0; once a battle.
    - **Snapping Turtle:** on an offensive skill, snaps up to rank of its other defensive passives that have behaviours; Gallantry and Final Act have no snapped form.
    - **New names to review:** none.
- [ ] **Snapped forms for Gallantry and Final Act**; always-on defensive passives (Turtle Tactics) have nothing to snap. (?140)
- [x] **Reactions to area skills** (`Battle.area_blow()`), flames and traps (`hit` only). Built 2026-11-15 (?150). (?140)
- [x] **The AI weighs enemies' reactions** when picking targets (`Behaviour.foils`). Built 2026-11-15 (?150). (?140)
- [x] **The AI holds a Final Act unit back as such** (`Behaviour.reprisal()`). Built 2026-11-15 (?162). (?150)
- [x] **Battle runs the AI for interrupts** unless `Battle.directed` says a person picks. Built 2026-11-15 (?150). (?140)

## Checks and contests (2026-11-15)

Plan and what was built: `docs/plans/checks.md`. Built on `u-checks`. Tests: new `Tests/check_test.gd`; `hud_test`, `haluca_test`, `intervention_test` changed. FLAG_CEILING 128 to 126.

141. **Checks and contests - built on judgement, open for review (2026-11-15).** My calls, each for you to confirm or change:
    - **One helper:** `Battle.check(a, stat, b, against, o)` rolls, `Battle.odds()` gives the chance, both through `Battle.sides()`; `Check.odds()` sums the d20 faces, advantage included. No `beats()` call is left outside it. Kept.
    - **`SkillCheck` / `Skill.check`** (code names, no `??`): a skill declares its check; it replaces `save`, `resisted` and `drags_to`, so `FLAG_CEILING` goes 128 to 126 (three out, one in). The nine .tres were migrated by script.
    - **Range penalty:** per tile, less 1 a rank past I (Drown's rule made general); its distance is tiles dragged for a drag, else tiles between caster and target past the first.
    - **Ties and tags kept per site:** the actor wins except Hitch (the foe), a grip (the holder) and Flamewall (the wall); Sing's foe and a reaction's attacker roll without the actor's tags. Not made uniform: each is in its skill's text.
    - **`doubt()`:** the fooling unit now uses its defensive cha check mod, so bracing counts on a deceiving roll as ?68 says. The only number that moved.
    - **Uniform now:** a declared check's options come from `Battle.skill_opts()`, so Sing also takes zeal, a contingency, an execute's cut and the modifier tags. Death rolls its last stand through the helper (its caster's d20 now rolls first: rng order only).
    - **Forecast:** `hit_chance()` answers a declared check's odds (a drag's to its spot), so the HUD's brackets, Alt's "N% to win" and `AI.score()` now see a save skill's chance, which was always 1.0 before.
    - **New names to review:** none.
- [x] **Rolls against an earlier total** (investigating, the last-stand fall, Level Down's bar) go through `Battle.check()` with a fixed side. Built 2026-11-15 (?148). The DC rolls (Burnout, Stun, Bandwagon, dodges) stay on `resolve()`: see the ?148 items. (?141)
- [ ] **Hitch and Slam Jam pass their stats to the helper in code**, not as a `SkillCheck`, because their check follows a hit. (?141)

## Facing (2026-11-15)

Plan and what was built: `docs/plans/facing.md`. Built on `u-facing`. Tests: new `Tests/facing_test.gd`; `fighter_test`, `jam_test`, `helpless_test`, `watch_test`, `Tests/test.gd` changed to the new shape (not weakened).

142. **Facing - built on judgement, open for review (2026-11-15).** My calls, each for you to confirm or change:
    - **The shield turns with the unit (the main call).** `Unit.guard` is now a bool and its cone is the front of `facing`, so Shields Up! faces the tile it was aimed at on the cast turn, but when the unit later walks or attacks the shield turns with it, until its next turn is through. Alternative: pin the shield where it was aimed. Kept, because a shield you carry points where you point.
    - **One facing:** `Unit.facing`, precise rather than snapped to 8 ways, set by a walk (its last step), by any skill aimed at a unit or tile (as it is paid for, so a miss turns too) and by Shields Up!. `heading` is folded in (Eyes Forward reads `facing` gated by `striding`; a strip now follows the last step).
    - **The cone:** within 45 degrees of facing is front, within 45 of the opposite is rear, the two arcs between are flank; edges inclusive; no facing is front.
    - **Hit tags Rear ?? and Flank ??** (AI-made names): added in `Battle.hit_tags()` like `ambush`, so effects tagged for them need no new code. A rear attack needs 1 less (`REAR_EDGE`, +1 to hit); flank has a tag and no number of its own.
    - **Not turned by being hit,** healed or dodging. A unit that takes a blow in another's place (Interject, Gallantry) turns to the attacker after the blow's side is read.
    - **Opening facing:** each unit with none turns toward the nearest foe at set-up; summons start with none (front from every side).
    - **Draw and AI:** a faint chevron on the sprite; `AI._approach` prefers the tile whose aspect lowers the foe's Defense (0.4 tiles a point, ties and near-ties only).
    - **New names to review:** Rear ??, Flank ??.
- [x] **The hit forecast labels a rear or flank blow** (`HUD.aspect`). Built 2026-11-15 (?148). (?142)
- [ ] **A unit that is hit doesn't turn**, and forced moves (push, pull, send, teleport) don't turn anyone. (?142)
- [ ] **No skill carries a flank or rear rider yet** (Gank's ambush analogue). (?142)
- [ ] **The AI doesn't walk to a side for a better shot**; the pull only breaks ties. (?142)

## Skills on items (2026-11-15)

Plan and what was built: `docs/plans/item-skills.md`. Built on `u-itemskills`. Tests: new `Tests/item_skills_test.gd` (9 tests); no existing test changed.

143. **Skills on items - built on judgement, open for review (2026-11-15).** My calls, each for you to confirm or change:
    - **`Item.skills`** are lent on the hotbar while the item is worn (`Slot.from` marks them on loan); they are never ranked and never cost points. A skill both learned and lent takes the higher rank, a tie going to the learned one.
    - **Rank:** the item's `skill_rank()`: its rank, enchanted or honed, a trinket's Pray enchant, and +1 more for Pray's numeric enchant on a weapon or armor, capped at the skill's `max_rank`.
    - **On loan doesn't count as learned:** lending a capstone's prerequisite doesn't open the capstone. You can't buy a skill you are wearing.
    - **Hotbar:** a lent skill goes into the first free slot; if none, the spellbook. Losing the item takes it off and ends a channel of it. Pale-blue ring, "Lent by <item>".
    - **Urlo's enchantment** reaches the trinket, and skips items with nothing to scale (Heart Up, Heart Up-Link) without using up Pray's count.
    - **Hobnail Boots ??** (AI-made name): an uncommon trinket lending Kick, in Alabaster's loot, so it competes with emblems and Heart Up for the one slot.
    - **New names to review:** Hobnail Boots ??.
- [ ] **Should a weapon or armor enchant raise the item's rank?** As built, Pray's enchant on a weapon or armor raises its lent skills' rank, not its drag. Open question. (?143)
- [ ] **Should lent skills ever count toward prerequisites?** As built, never. (?143)
- [x] **Saving** of lent skills: they come back by being the item's. Built 2026-11-15 (?145). (?143)

## Test and logic consolidation (2026-11-15)

Plan, survey and what each part built: `docs/plans/consolidation.md` (survey, then "B1" to "B5 as built"). Built on `v-survey`, `c-runner`, `c-sweeps`, `c-tables`, `c-tiles`, `c-displace`.

144. **Test and logic consolidation - answered and built (2026-11-15).** Your request (2026-11-14): "assign delegates to consider consolidating tests 20/80 style, abstracting / apply DRY and KISS where it would do the most impact. there are a lot of tests for not a lot of game at present. any opportunity to make tests / logic less concrete may be an area of interest". The results:
    - **Time:** a full run went 150 s to about 60 s (the museum scene held for the whole run was most of it); `quick` is about 33 s.
    - **Check count** about 46k to about 8k. **That drop is cosmetic:** combat counts one check per invariant per battle, over 8 seeds by default and 30 under `soak`, where it used to count every evaluation. Same invariants, same AI, same battles.
    - **Runner:** new words `reverse` (files and tests reversed, to catch order dependence) and `soak`; a script error inside a test now fails it (`ScriptErrors` logger); `slow.txt` regenerated; each run has its own settings file.
    - **`reverse` found a real leak:** `champions_test.test_entry` left `Game.outfit`, `stash`, `hearts` and `starter` set. The runner now resets all of `Game`'s statics before every test.
    - **Tests:** a sweep (`sweep_test`) casts every active and weighs every passive, so per-skill effect tests went; 19 per-skill or pin files deleted (13 in the sweep, 5 capstones into one table, 2 unit pins out of 3, with `unit.py check` taking the wiring). Rule tests were kept. Each deletion was spot-checked by mutation.
    - **Logic:** `Skill.gd` fields 126 to 104 (`FLAG_CEILING` 104): seven tile skills moved onto a new `Behaviour.apply_at`, fifteen self and utility fields onto behaviours (`Displace`, `beastshape`, `waltz`, `aura`...), one `Battle.displace()` primitive. Battle.gd shrank by about 150 lines.
    - **My calls:** fewer seeds not fewer invariants; no extra roster battle (astral and meadows don't fit the invariants); pure queries (`tile_target()`, `whole()`, `impact()`) beside the hooks rather than a hook per skill; Sutemi's lunge, `channel`, Strike's chain, the Look and Terms groups left alone.
    - **Asked of you:** the per-item test file question at the top of `todo.md`.
    - **New names to review:** none.
- [ ] **Should `skill.py new`, `unit.py new` and `mechanic.py` keep writing one test file per item?** Option A (recommended): a table row for data-only skills, a file only with a behaviour. Option B: keep a file, a 3-line stub on the shared helpers. Either needs a `CLAUDE.md` and `.claude/skills/` change. (?144)
- [x] **`KeyBinds.SAVE`** is now a `static var` the runner points elsewhere. Built 2026-11-15 (?145). (?144)
- [x] **Behaviours that crash on a missing precondition**: `sweep_test.test_missing_preconditions` casts them with the thing nowhere. Built 2026-11-15 (?156). (?144)
- [x] **Rename `Battle._expose()`** to `_lose_cover()`; Glossary and Effect text fixed. Built 2026-11-15 (?156). (?144)
- [ ] **Not lifted, by design:** Sutemi's lunge, `channel`, Strike's `chain`, the Look and Terms groups, the heal fields. Lift on touch. (?144)

## Saving (2026-11-15)

Plan and what was built: `docs/plans/saving.md`. Built on `x-save`. Tests: new `Tests/save_test.gd` (5 tests, 30 checks); `Tests/run.gd` points the paths at per-process files; no existing test changed.

145. **Saving - built on judgement, open for review (2026-11-15).** My calls, each for you to confirm or change:
    - **Format:** JSON at `user://save.json` (`Save.gd`), not a ConfigFile: the data is nested and a version field makes a bad file easy to refuse. Settings stay in `Prefs` and `KeyBinds`.
    - **Saved:** level, xp, hearts, outfit, stash (in order) and the hero. Not the portal just taken or the difficulty, and not learned skills (a starter re-learns them each battle from its level's points).
    - **A new `Game.hero`** `{faction, role, name}`, because `Game.starter` is used up by `Battle` as it starts.
    - **Load and Continue:** Entry loads once per process; a Continue button ("Continue: Shrike, Adventurer, level 3") plays the saved starter at its saved level, outfit, hearts and stash. Play still starts a new starter (stash kept) and saves it at once.
    - **When:** Play, each equip, unequip and use of an item from the sheet, the battle's end and closing the window; through a temp file and a rename. `Save.save()` does nothing until a hero is picked, so a scene played from the editor can't blank a real save.
    - **Versioning:** `VERSION` 1; a file that isn't JSON, isn't a dictionary or has another version is moved to `save.json.bad` with a warning and counts as no save, so an older game never overwrites a newer one's. Within a good file, what is gone is dropped with a log line.
    - **Items by id** (`{item, rank, enchant}`): a copy (Pray's enchant) finds its file by name; the file's own item is used unless rank or enchant differ. Lent skills come back by being the item's.
    - **Hook for x-equip:** `Save._equipped_out()` and `_equipped_in()` are empty and marked; the `equipped` key is written and read.
    - **Tests never touch the real files:** `KeyBinds.SAVE` went from a `const` to a `static var`; tests that removed it had been deleting the player's real binds. Driver scripts outside `run.gd` use the real paths unless they set the same.
    - **New names to review:** none.
- [x] **The equipped-set hook**: `Save._equipped_out()` and `_equipped_in()` filled. Built 2026-11-15 (?163). (?145)
- [x] **A "New game" button** on the entry screen (`Save.erase()`, `Game.reset()`). Built 2026-11-15 (?158). (?145)
- [x] **Saves on quitting inside Gamut's Tower.** Built 2026-11-15 (?158). (?145)

## Fear, shove and entrance (2026-11-15)

Plan and what was built: `docs/plans/fear.md`. Built on `x-fear`. Tests: new `Tests/forced_test.gd` (5 tests, 25 checks); no existing test changed.

146. **Fear, shove and entrance - built on judgement, open for review (2026-11-15).** You named all three words, so no `??`. My calls, each for you to confirm or change:
    - **Three Effect stats** `shove`, `fear`, `entrance`, carried by any Effect (a skill's, a behaviour's `put()`, a mark's). `Battle.drive()` runs after the source is set and moves the holder `amount` tiles (times rank with `per_rank`, times strength) away from, or toward, whoever put it on, through `displace()`. An effect with no source moves no one.
    - **Shove is instant; fear and entrance are statuses** that last their `turns` and drive the holder again as each of its own turns starts (`_frighten()`, the shape of `_bleed()`).
    - **Tags** `shove`, `fear`, `entrance` ride on the move (a new `Battle.driven` signal) and on collision damage; a `Displace` behaviour tells `shove` going away and `entrance` toward, so Kick, Send Off and Sing already speak them.
    - **Collision damage, yes:** a push stopped short by a unit or the edge deals `Battle.SLAM` 2 blunt per tile unspent to the pushed unit and to the one it struck. First-guess number, one constant. **It changes Kick and Send Off near walls.**
    - **A grapple ends when either party actually moves** (`_break_grips()` in `displace()`). A push that goes nowhere keeps it.
    - **No skills:** none in the todo docs wants one; the effects are data-ready.
    - **The AI** neither seeks nor avoids them (its `_away()` spends the unit's own movement).
    - **New names to review:** none.
- [ ] **The AI doesn't read fear, shove or entrance**, nor foresee the move or slam in the forecast. (?146)
- [ ] **No skill carries fear, shove or entrance yet.** Needs a design. (?146)
- [ ] **Aura and Coordinate's effect loops don't call `drive()`** (neither carries one today). (?146)
- [ ] **The tags aren't on skills' own `tags`** (the cast's tag set), only on the move. (?146)

## Polish (2026-11-15)

Plan and what was built: `docs/plans/polish-11-15.md`. Built on `x-polish`. Tests: `sweep_test.test_describes_as`, `hud_test.test_forecast_side`, `check_test.test_check_against_a_total`, `last_stand_test`, `bracing_test`, `paladin_test.test_decay_reaches_behaviours`; no existing test changed.

148. **Polish - built on judgement, open for review (2026-11-15).** My calls, each for you to confirm or change:
    - **`describe_as`:** the 22 behaviours with rank or stat terms write their text once in `describe_as(c)`, each number reading the channel `apply()` reads. Numbers `apply()` reads raw (Kick's effect turns, Hitch's tow, Peel's step count, Slam Jam's share) stay at the base rank on purpose. Humble now says "N x 4"; Zone (Darkstone) now says its rank.
    - **Facing cue:** `HUD.aspect` from where the attacker would stand (a walk comes first); one word, `rear` or `flank`, over the foe in the tag's colour, nothing from the front, no number. The chevron is 9 px out, 3 px wide, alpha 0.8.
    - **Earlier totals:** `Check.fixed(n)` is a side that rolls no die; `Battle.check/odds/sides` take a number as `against`. Moved: `investigate()`, `inspect()`, `_borrowed()`, `_level_down()` (a roll must beat the bar). rng order unchanged.
    - **Decay generic:** `Cast.strength` is read by `Cast.put()` and by Aura, so every behaviour's effects decay with distance. It is computed against the original target; a reaction that swaps the target doesn't recompute it. Instant HP and damage don't decay.
    - **New names to review:** none.
- [ ] **Level Down and investigating have no forecast**: Level Down's bar is rolled per cast and declares no `SkillCheck`. The helper can answer them when one is wanted. (?148)
- [ ] **The DC rolls** (Burnout, Stun, Bandwagon, dodges) could use `check(.., against: dc)`; left. (?148)
- [ ] **Hitch and Slam Jam pass their stats to the helper in code**, not as a `SkillCheck`. (?141)
- [ ] **`_borrowed()`'s `bonus = r` is unproven by mutation**: its rank barely changes the outcome. (?148)
- [ ] **The facing word sits a little right of the foe's centre.** Cosmetic. (?148)

## Screenshot pass (2026-11-15)

Plan and findings: `docs/plans/shots-11-15.md`. Built on `y-shots`. No code changed.

149. **Screenshot pass - findings only (2026-11-15).** Clairvoyance pings read clearly and stay with the foes after End turn; the Specialist tree reads, with T3 holding four skills, not three (Ds, St, Ta, Ww); the facing chevron was low-contrast; the lent ring and emblem diamond read; Warcry marks read, but Routed!'s blue blended with movement outlines and water. Fixed since: the chevron (?148), the rear / flank label (?148), suspicion stacks and Routed!'s colour and glyphs (?150). Left:
- [x] **The Specialist tree opens at its lowest filled tier** (`SkillGrid.floor_y()`). Built 2026-11-15 (?163). (?149)
- [ ] **The lent ring sits a little lower than the rank pip**, so they don't share a baseline. Cosmetic (SkillSlot). (?149)
- [ ] **Re-check the Warcry marks on a busy board** now Routed! is magenta with glyphs, and a mark has no on-tile text. (?149, ?150)

## Reaction and marks gaps (2026-11-15)

Plan and what was built: `docs/plans/gaps-react-marks.md`. Built on `x-gaps`. Tests in `reaction_test`, `gallantry_test`, `per_tile_test`, `marks_test`; `final_act_test` and three `reaction_test` interrupt tests set `b.directed`.

150. **Reaction and marks gaps - built on judgement, open for review (2026-11-15).** My calls, each for you to confirm or change:
    - **Area moments:** `Battle.area_blow(cast, victim, strike, tries)` asks `attacked`, then `hit` (if the victim tries, as Wildfire's dodge), then strikes; used by the cone behaviour (Solar, Wildfire) and `_detonate` (Metea). **A reaction may swap the victim** (Interject, Gallantry take an area hit for an ally beside them); a swapped-in unit already in the cone is hit twice. Flames and trap blasts ask `hit` only.
    - **Interrupts in simulations:** `Battle.directed` is a Callable ("a person picks"); `_open_interrupt()` calls `AI.interrupt()` for every other unit. Unset (headless), every interrupt is the AI's. Battle now calls `AI`, which it never did.
    - **Enemy reactions in targeting:** `Behaviour.foils(r, holder, rank)` (0-1); `AI._foiled()` asks each passive of the target's side the AI can read, caps at `FOILED` 0.8 and scales a positive strike value. Gallantry = its cha contest odds, Interject = its dex odds, Final Act = `WORTH` 0.25 on a killing blow.
    - **`per_tile` in the estimate:** `hazard(u, c, r, nth)` adds the unit's own tolls, Meander's wards included; `route()` passes `nth` 0 (a toll every tile owes steers nowhere).
    - **Hidden marks:** `maybe_suspicious()` includes tiles with a mark hidden from the viewer; the HUD shows a `?` where a viewer has suspicion it can't read.
    - **Helpful marks:** `Mark.helps(u)` and `Battle.lure()` = `HELP_PULL` 0.75 movement off a step onto a known helpful mark; it tips choices only, the walk's real price is untouched.
    - **Fire as a mark: not done**, too tangled (see the item).
    - **From the screenshot pass:** Routed! is magenta `Color(0.62, 0.12, 0.5)`, with a glyph per mark (a cross for Routed!, a chevron up for Charge!); the tile card says "Suspicious of it: N" and the `?` gets a count when N is above 1.
    - **New names to review:** none.
- [ ] **No content lays a hidden mark** (Warcry's are plain). (?150)

## Dissonance by how far the lie is (2026-11-15)

Plan and what was built: `docs/plans/dissonance.md`. Built on `y-dissonance`. Tests: `persona_test.test_dissonance_distance` new; `test_insight` and `lure_test.test_stall_lifts` updated.

152. **Dissonance by distance - built on judgement, open for review (2026-11-15).** Your wolf in sheep's clothing, not a scary dog. My calls, each a first guess:
    - **Distance per claim** (`Perception.lie()`): true (one of its own words) 0; near (shares a nature with one) 0.5; far (opposed to one) 1.5; anything else, or a word the table lacks, 1, so unknown content behaves as the old tally. Near beats far when both apply. The sum is rounded up, so any lie reads at least 1.
    - **Natures ?? table** (`Perception.NATURES`, `OPPOSED`), internal keys: gentle ??, fell ??, fair ??, foul ??, bright ??, dead ??, holy ??, unholy ??, hot ??, cold ??, wet ??, folk ??, beast ??, made ??, small ??, big ??, calm ??. Opposed: gentle-fell, fair-foul, holy-unholy, holy-dead, bright-dead, hot-cold, folk-beast, folk-made, small-big.
    - **Aura joins the truth** ("ominous" below 0, "benevolent" above). **Stance** stays a flat 1; **claimed level** near within 1, far at 4 or more off; **alias** the worse of its words; Embellish and Brood stay 1 each.
    - **Glossary term "Dissonance"** (an existing in-game word); Alluring links it.
    - **Balance, asked of you:** the Siren goes from dissonance 7 to 9 and its penalty after Alluring IV from 3 to 5, so its lure is doubted more often. Left as built. If it is too much: `LIE_FAR` 1.25 (softens it), or a practised look cutting more. `lure_test.test_stall_lifts` pins the Siren's lie 2 easier so its seeded roll still tests stalls.
    - **New names to review:** the 17 natures above.
- [ ] **The Siren balance** (above, top of `todo.md`). (?152)
- [ ] **Stance has no nature to measure**, so a side claimed falsely is always 1. (?152)

## Bio text (2026-11-15)

Plan and what was built: `docs/plans/bio-text.md`. Built on `y-bio`. Tests: new `bio_test.test_sheet_line`.

154. **Bio text - built on judgement, open for review (2026-11-15).** My calls:
    - **`Bio.line(unit, read)`** builds the line; the sheet's `open(u, editable, r = null)` takes the viewer's Read (null: own, whole bio). HUD.gd not touched: the sheet opens for own units only, so the foe path waits for a caller (a shift-click look-over).
    - **Minimal words:** "Brave - Injured Knight - Rotting" (a dot between), tags coloured; no sentences, no new Glossary terms.
    - **Foe:** an unknown name shows nothing; fooled by a persona, only the persona's adjectives and noun (properties would leak at persona III); else the temper (for insightful viewers), the real adjectives and kind noun, and properties as read.
    - **Guide:** a Bio paragraph on the character page; `Bio.TEMPERS` gives each temper a few words, kept in size with `Bio.BEHAVIOURS` by a test.
    - **New names to review:** none.
- [x] **A foe's bio look-over**: middle-click or L on a tile (`HUD.look_over()`). Built 2026-11-15 (?161). (?154)

## Test tidy and the `_lose_cover` rename (2026-11-15)

Plan and what was built: `docs/plans/tidy-11-15.md`. Built on `z-tidy`. Tests: `hud_test.test_every_tab_draws_its_skills`, `sweep_test.test_missing_preconditions` new.

156. **Test tidy - built on judgement, open for review (2026-11-15).** My calls:
    - **"Stale count" read as "each tab draws exactly the skills it lays out":** the new test opens every role's skills screen and checks every tab against the view's `skills()`, both ways (only the Adventurer tab is a wheel).
    - **Missing preconditions:** Burning Bag cast with the bag nowhere, in the stash and on an ally; Emergency Exit with no Meadows. The portal and pocket cases stay in `meadows_test` and `pockets_test`.
    - **`Battle._expose()` is now `_lose_cover()`** (it only costs a hidden unit a level of concealment); `Behaviours/cone.gd` follows. A plain function name, not an AI-made game name, so no " ??". Glossary "held" and the Effect text now say a holder's grip only drowns a submerged unit.
    - **`KeyBinds.SAVE`** was already a static var that `run.gd` redirects; nothing to finish.
    - **No test file deleted:** `trickster_test` and `slam_jam`'s `test_tree` restate tree wiring, and removing a skill from a tree passes `skill.py check`, so they stay as the only guard.
    - **New names to review:** none.
- [ ] **`skill.py check` doesn't catch a skill dropped from its tree**, so two tests are the only guard of that wiring. (?156)

## Warcry's foe picker (2026-11-15)

Plan and what was built: `docs/plans/warcry-picker.md`. Built on `z-warcry`. Tests extend `warcry_test.gd`.

157. **Warcry picker - built on judgement, open for review (2026-11-15).** My calls:
    - **A generic seam, `Behaviour.picks(c) -> int`** (default 0): how many targets the caster may pick by hand. `Cast.picked` carries them, `Battle.cast(..., picked)` passes them, `Battle.picks_of()` sums for the HUD. A later multi-target skill overrides `picks()`.
    - **No picks means the behaviour chooses** (Warcry: the nearest rank), so a quick cast and the AI are unchanged. Picks are validated in `Warcry.chosen` (alive, foe, still located, capped at rank, duplicates dropped; none left, the nearest).
    - **HUD:** the key of a skill with `picks > 0` sets `aim` as a tile skill does; `intent()` is `&"pick"` on a visible foe (toggle, capped), Ctrl-click still strikes; cast on the second press or a click on the unit. Cancel, select, slot change and a cast clear the picks.
    - **Only picked foes are drawn** (red brackets and a number; the hint "Warcry: 2 of 3 picked"); the default is not, the hint says "the nearest N". Pickable is what the caster `read()`s as located, the filter Warcry uses.
    - **Warcry's static `picks(b, caster, n)` renamed `nearest`**; `Skill.describe` says "you choose them, else the nearest first".
    - **New names to review:** none.
- [ ] **The default "nearest N" isn't previewed** before picking; only picked foes are drawn. (?157)
- [ ] **No other skill overrides `picks()` yet.** (?157)

## Save follow-ups (2026-11-15)

Plan and what was built: `docs/plans/save-followups.md`. Built on `z-savefu`. Tests: `save_test` (`test_new_game`, `test_tower_quit_saves`).

158. **Save follow-ups - built on judgement, open for review (2026-11-15).** My calls:
    - **"New game" button** on the entry screen (`%Delete`), shown when a hero or save file exists. Confirm is a second press (the text turns to "Sure? Press again to delete the save"), not a dialog. `Save.erase()` removes the save, `.bad` and `.tmp` and calls the new `Game.reset()`, which lives in Game so a later static is added beside its declaration.
    - **Tower quit:** `GamutsTower._notification` saves on `NOTIFICATION_WM_CLOSE_REQUEST`, as Entry and HUD do.
    - **Allied glow picker:** already in `Prefs`; nothing to do.
    - **Driver save path:** a code guard in `Save.PATH` (a `-s` script gets `user://save_driver.json`) over a memory note; `Prefs` and `KeyBinds` are not guarded.
    - **New names to review:** none.
- [ ] **`Prefs` and `KeyBinds` paths aren't guarded for driver scripts**, only `Save.PATH`. (?158)

## More contextual clues for searching (2026-11-15)

Plan and what was built: `docs/plans/search-clues.md`. Built on `z-search`. Tests: `evidence_test.gd` (4 new tests; suite 8269 to 8287 checks).

159. **AI search clues - built on judgement, open for review (2026-11-15).** My calls (all weights guesses):
    - **One scoring function, `AI.clues(b, u) -> {tile: weight}`;** 1 is a foe's worth. `_search()` sums the weights inside an Observe's look for every tile in reach and casts at the best, if it holds at least `WORTH` 0.5. A later clue calls `AI._clue()`. Constants at the top of AI.gd: `SUSPICIOUS` 1, `DEBRIS` 1, `MARKED` 0.5, `LAST_SEEN` 0.5, `REACH` 0.5, `HIT` 1.
    - **Signs and guesses:** suspicious tiles, debris and foe marks stay until dealt with; last seen, reach and blows are guesses, dropped for a tile the side searched lately (`Battle.swept`, `SWEEP_TURNS` 4) or where it now sees a placeable unit.
    - **Reach:** `Battle.reckon_reach()`, a Dijkstra over ground the viewer makes out, each step priced by `stride()`, budget movement x rounds since (capped at `REACH_TURNS` 3), shared evenly (a foe's total is 1). Rounds = ceil(side turns / sides); a tile must also lie within the budget as the crow flies; marks are priced as the walker knows them (a small residue of its knowledge).
    - **Where a blow came from:** only blows inside a cast by a foe the victim can't place; its side keeps every tile on the side the blow landed (hit tags, else front) within the skill's reach for `HIT_TURNS` 6. The attacker's real tile is never used (a test checks it). Bleeds, traps and area casts without a Cast are not counted.
    - **After searching it still hunts** where its side last saw a foe (it used to hunt only if it hadn't searched).
    - **Combat sims shift:** an Observe user with old sightings and no clue now searches at battle start.
    - **New names to review:** none.
- [ ] **Tune the clue weights and turn caps by the sims** (all guesses). (?159)

## Param tail (2026-11-15)

Plan and what was built: `docs/plans/param-tail.md`. Built on `z-param`. Tests extend `route_test.gd` (`test_missed`, `test_rift_look`, `test_strike_element`).

160. **Param tail - built on judgement, open for review (2026-11-15).** The six deferred skills and the UNSAID markup were already built (r-route; `describe_as`, ?148), so nothing was done there. My calls:
    - **`skill.py modifiers` stays 28 before and after:** the eligible were already eligible; what changes is which modifier acts. Rift gains rho_up, Strike's chain reads a stat-impact `element` term, Alluring's rank-impact list gains `practised look`. The 28 left are the concrete ones of ?133.
    - **Strike's element bonus** (imbued, or Elemental Mastery's highest mental mod) goes through Strike's modifiers as stat impact; the bonus is Strike's, not Elemental Strike's, which stays rho-only (a sigma read would need a stored mental bonus on the unit, a bespoke counter). Strike passives' per-hit extras stay Effect stats.
    - **Rift's difficulty and turns, and Look's dissonance rank and text,** read rank through the caster's modifiers as rank_impact (SkillTerms: `domain`, `practised look`). The "over walls from rank III" gate and the reach stay on real rank; the 1.5 difficulty clamp still caps what a modifier buys.
    - **`Behaviour.missed(c)`**, a generic hook, the counterpart of `apply()`: `Battle._miss(c)` runs it (and sets `c.hit` false) before `used` on every failing path: a lost drag, engulf or contest, a passed save, a missed attack roll, a Strike chain with no hit, Level Down taking no level, Death not killing, and in `area_blow` a victim that dodged. Not run on a cast refused before it is tried, nor on tile skills with no victim. **No skill uses it yet** (no content invented).
    - **New names to review:** none.
- [ ] **No skill uses `Behaviour.missed()` yet**; a refund or rider on a miss is the first. (?160)
- [ ] **Elemental Strike has no sigma read**; it would need a stored mental bonus on the unit. (?160)

## Foe look-over and the sheet's leak (2026-11-15)

Plan and what was built: `docs/plans/lookover.md`. Built on `z-lookover`. Tests: `bio_test.test_look_over`.

161. **Look-over - built on judgement, open for review (2026-11-15).** My calls:
    - **Middle-click on a tile, or a new rebindable action `look_over` (default L, "Look over" in `KeyBinds.NAMES`) on the hovered tile.** Shift-click is taken: `intent(inspect)` selects a foe rather than attacking it. Middle-click itself is not rebindable.
    - **`HUD.look_over(c)`:** the unit `unit_seen(c)` makes out there (the unit card's gate); the sheet opens read-only with `null` (whole bio) for the player's own side, else with `view(u)`. Nothing leaks beyond `Bio.line()`'s own gates. No new text.
    - **The sheet itself leaked** (real name, XP, hearts, kit): with a Read it now shows only the Read's name (else looks, else "Something"), level (or ?), and the bio line; no equipment or stash.
    - **New names to review:** none.
- [ ] **Middle-click isn't rebindable** (KeyBinds binds keys only). (?161)

## AI prices what it ignores (2026-11-15)

Plan and what was built: `docs/plans/ai-prices.md`. Built on `z-aiprice`. Tests in `ai_tactics_test.gd` (5 new; suite 8289 checks, 0 failed; combat_test's numbers moved with the weights).

162. **AI prices - built on judgement, open for review (2026-11-15).** My calls, each a first guess:
    - **Defense from Read:** `Read.defense` (null unless its armor shows, the HUD's own rule, now `HUD._defense_shows`); `Battle.hit_chance(..., guess)`; the AI guesses `GUESS_DEFENSE` 12 (a medium armor's floor) when the read has none.
    - **Cost, not only AP:** `saved` is `share x (AP cost x AP + cost points x POINT)`, `POINT` 0.5 HP per Energy or Focus point.
    - **`Behaviour.foresee` gains `riders` and `spill`**, summed by `Battle.foresee()`; the AI adds `RIDER` (1.0) x riders + spill to a blow's value. Poach: a felling blow is one rider (regain). Jam: the interrupt is one rider. Slam Jam: a rider at its contest's odds. The interrupt and the regain are worth a flat RIDER whatever the target or the amount.
    - **Kick:** `Kick.driven()` reads a push to where it stops; tiles are riders at `PUSH` 0.5, a stop short adds the slam as spill (negative for an ally); a trap's blast counts each other unit within `blast` (foes +, own -). No mitigation, boost or reactions counted.
    - **Grudge:** `_starve` no longer needs the Grudge unit to be the last foe; `starve_worth` = `STARVE` 5.0 (a kill) / the units of its side in the foe's reach; 0 once it dies of its rounds anyway; it starves when that beats `_best_strike()`. Judged afresh each round; allies don't coordinate.
    - **Final Act:** a second generic hook `Behaviour.reprisal(r, holder, rank)`: HP the holder's reaction costs the blow's author. `_strike` takes it off the blow's worth but never below `1 - FOILED`, so a lone Final Act unit is left for last. Replaces Final Act's `foils` share.
    - **New names to review:** none.
- [ ] **Defense through a lie** (`_lie`/`twist`) isn't read, by the AI or the HUD. (?162)
- [ ] **A Grudge unit plans no retreat tile** so as not to be cornered next round. (?162)
- [ ] **Tune `GUESS_DEFENSE`, `POINT`, `RIDER`, `PUSH`, `STARVE` by the sims.** (?162)

## Equipping skills (2026-11-15)

Plan and what was built: `docs/plans/equipping.md`. Built on `x-equip`. Tests: new `equip_test.gd` (3 tests); `sweep_test.test_passives` unequips every non-pillar passive; `save_test` round-trips the set; `Test.roomy(u, n)` added; several tests rewritten to the new rule (listed in the plan).

163. **Equipping skills - built on judgement, open for review (2026-11-15).** Closes Phase 4 item 12. **The main call to review: actives must be equipped to work too, AI included** (before, the AI could use any active it had; the hotbar is the equipped set). My other calls:
    - **One query, `Unit.equipped(s)`:** inherent skills (Starkind, Reckless Abandon) always; anything else only on the hotbar in a slot a level curse hasn't sealed. `passives` and `actives` filter through it, and readers of what a passive does (`efficiency`, `candid`, `has_tag`, `pools`, `spends`, `giver_rank`, waivers, the AI's toggles, Sigil) were moved onto it. Learning-side readers still read every learned skill.
    - **Always-on passives go on the bar** (`Skill.fits_bar()` is "not inherent") but **can't sit in the clover slot**; toggles still can.
    - **Default bar** (`_fill_bar`, every unit): pillars in the last sure slots, actives and toggles from the left, always-on passives from the right; actives win a shortage. **NPCs carry `extra_slots` for the rest:** `unit.py check` flags a unit whose learned skills outnumber its slots; Siren `extra_slots = 2`, Undine 1.
    - **Auto-equip** (`Unit.auto_equip`; Settings "Auto-equip new skills", on by default, Prefs `auto_equip`): a new skill goes where it would by default if there's room; new slots fill with learned skills left off; a full bar leaves it off; a slot emptied by hand is never refilled. **The toggle is global**, NPCs included; passives fill sure slots first, typed granted slots after.
    - **Losing slots:** granted slots keyed by source (items pooled as `item`); unequipping a granting skill re-sorts the bar (cascading); skills that come off are announced on `Unit.lost_skills`.
    - **Growing the bar:** new sure slots go in above the passives and pillars; a clover slot turning plain keeps its skill. **Pillars** still can't be moved or unequipped.
    - **Brainfog's order:** pillars, then the hotbar right to left.
    - **Skills screen:** drag a skill from the wheel or grid onto the hotbar (the screen steps aside for the drag); "Equipped" or "Not equipped: drag it onto the hotbar"; an unequipped rank numeral dulled. Grid tabs open at their lowest filled tier. Settings' options row wraps. The Guide's Hotbar page says all this.
    - **Save:** the starter's bar is written as skill ids (`Save._equipped_out()`, `_equipped_in()`, `Unit.set_equipped()`); learned skills themselves aren't saved yet, so this mostly keeps the class's arrangement.
    - **New names to review:** none.
- [ ] **Always-on passives on the bar show the green "on" dot** toggles use. Left as is; should they? (?163)
- [ ] **Skill Slot +1 (?3) is still a stub.** (?163)
- [ ] **The auto-equip toggle is global**, not player-only. (?163)
- [ ] **NPC-side equipping choices** beyond `extra_slots`. (?163)
