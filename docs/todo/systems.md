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
- [x] **Unbounded maps, camera control, spawning mid-battle**, for Infernal Meadows. Built 2026-11-16 (?175): bounded work, a panning camera, spawns checked by the real sight rules; the 30-kill portal battle stays later (`[ ]` under ?175). *Was:* units could be summoned onto a fixed map (`Battle.summon()`: Regeneration Probes).
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
- [x] **The AI has no idea of a `stamina` skill's extra effect** (Move ??). Built 2026-11-15 (?167): `Behaviour.strides()` and `AI._stretch()`. (?98)
- [x] **`tapped` and `helpless`** (2026-11-12, built 2026-11-14, ?119): `tapped` is a utility effect other effects may apply; a tapped unit can't act or take orders. It is not a debuff and can't be cleansed, but its sources can be addressed (healing off a stun, a wound), which removes it, and the unit is free to use AP and reactions on its turn. Tapped when: out of AP; it has received cha mod orders this turn (until the commander ends the command phase; afterward it may use remaining AP on autopilot); downed or stunned with no effect or skill letting it act (see Mindless Fury). `helpless` is for stun and other full action-disabling spells. (?65, ?90)
- [x] **Tapped saturation** (2026-11-12, built 2026-11-14, ?119): a unit acting in a reduced capacity is drawn at 50% saturation, instead of 0% for tapped or 75% for low AP / command limit.
- [x] **Stun** (2026-11-12, built 2026-11-14, ?119): a wound-type cause of `tapped`/`helpless`; healing it off removes the tap.
- [x] **Mindless Fury** (2026-11-12, built 2026-11-14, ?119): Berserker passive, tier 5. A unit may take rank actions in a reduced capacity when it would otherwise be interrupted or incapacitated; its effective mental stats are 1 while acting this way. It can't power through `tapped` to take unlimited actions in a turn, and needs blanket mitigation of unit-inflicted disabling effects.
- [x] **Drone** (2026-11-12, built 2026-11-14, ?119): tier 4, Mage general / Specialist Merchant. The unit does not tap when the command limit is exceeded; its mental stat mods are capped at +rank when acting this way.
- [ ] **Rebalance the museum** (kept as built, 2026-11-18: you said no balancing now) (Nemes leans on Hex), or teach the AI to weigh a raised cost and vary. Now Lancin 27 / Nemes 3 with exhaustion on (13 / 17 off); Stamina and Move ?? change none of it. After ?167's wear weighing: Lancin 26 / Nemes 4 (scratch sim); Hex still outscores Strike, so the AI alone does not fix it: cost tuning is the user's call. (?87, ?167)
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
- [x] **Tune the price table or adopt the computed prices**: you answered (2026-11-18) that cost is part of a skill's identity; the computed price is the baseline and a skill declares a cost profile in words ("high mana, low ap"). Built 2026-11-18 (?190); no balancing.
- [ ] **Ineligible for every modifier** (`skill.py modifiers`): 54 skills became 27 after ?133 and ?134 (`docs/plans/param.md`), 29 once Final Act and Striking Intellect were added, 22 after ?191 (`docs/plans/w2-param.md` has each reason: switches, drawbacks, build-time gates). (?131, ?133, ?191)
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
- [x] **The 27 left concrete**: you answered (2026-11-18) that an over-concrete skill should be parameterized on rank, stats and check difficulty, where it can be. Built 2026-11-18 (?191): 7 of 29 parameterized, 22 stay. (?133)
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
- [x] **The text of reserves, opens and Downed rules** now reads the modifiers; built 2026-11-15 (?169). (?134, ?160)
- [ ] **Still concrete on purpose:** the build-time gates (Dabblings' picks, `waives`, the guest-tree rank caps), since they gate what is learned. (?169)
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
- [x] **Hitch and Slam Jam pass their stats to the helper in code**, not as a `SkillCheck`, because their check follows a hit. Decided 2026-11-15 (?164): kept, each with one static options function the roll and the forecast share. (?141)

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
- [ ] **A unit that is hit doesn't turn** (kept: under your rule only a move or an aim turns it). Forced moves no longer turn the unit either (?192, reversing ?188). (?142)
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
- [x] **Should a weapon or armor enchant raise the item's rank?** Answered 2026-11-18: the item is enchanted, so its lent skills are (+1 rank unless a lent skill has its own enchant effect); armor drag stays. Built 2026-11-19 (?196). (?143)
- [x] **Should lent skills ever count toward prerequisites?** Answered 2026-11-18: yes, and a skill that depends on one lapses when it is lost. Built 2026-11-19 (?196). (?143)
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
- [x] **Should `skill.py new`, `unit.py new` and `mechanic.py` keep writing one test file per item?** You answered Option A (2026-11-18, `docs/agents/answers-2026-11-18.md`). Built 2026-11-18 (?187). (?144)
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
- [x] **The AI doesn't read fear, shove or entrance**, nor foresee the move or slam in the forecast. Built 2026-11-15 (?170): `Battle.course()`, `foresee_drive()`; the AI reads it through `foresee()`. (?146)
- [x] **No skill carries fear, shove or entrance yet.** Kick and Send Off carry `shove`, Sing `cc` (entrance); no skill carries fear. Built 2026-11-19 (?192). (?146)
- [x] **Aura and Coordinate's effect loops call `drive()`.** Built 2026-11-15 (?170). (?146)
- [x] **The tags aren't on skills' own `tags`**: answered 2026-11-18, `shove` goes on skills that apply force to a unit (Kick, Send Off), `cc` on skills that impair acting. Built 2026-11-19 (?192). (?146, ?170)

## Polish (2026-11-15)

Plan and what was built: `docs/plans/polish-11-15.md`. Built on `x-polish`. Tests: `sweep_test.test_describes_as`, `hud_test.test_forecast_side`, `check_test.test_check_against_a_total`, `last_stand_test`, `bracing_test`, `paladin_test.test_decay_reaches_behaviours`; no existing test changed.

148. **Polish - built on judgement, open for review (2026-11-15).** My calls, each for you to confirm or change:
    - **`describe_as`:** the 22 behaviours with rank or stat terms write their text once in `describe_as(c)`, each number reading the channel `apply()` reads. Numbers `apply()` reads raw (Kick's effect turns, Hitch's tow, Peel's step count, Slam Jam's share) stay at the base rank on purpose. Humble now says "N x 4"; Zone (Darkstone) now says its rank.
    - **Facing cue:** `HUD.aspect` from where the attacker would stand (a walk comes first); one word, `rear` or `flank`, over the foe in the tag's colour, nothing from the front, no number. The chevron is 9 px out, 3 px wide, alpha 0.8.
    - **Earlier totals:** `Check.fixed(n)` is a side that rolls no die; `Battle.check/odds/sides` take a number as `against`. Moved: `investigate()`, `inspect()`, `_borrowed()`, `_level_down()` (a roll must beat the bar). rng order unchanged.
    - **Decay generic:** `Cast.strength` is read by `Cast.put()` and by Aura, so every behaviour's effects decay with distance. It is computed against the original target; a reaction that swaps the target doesn't recompute it. Instant HP and damage don't decay.
    - **New names to review:** none.
- [x] **Level Down and investigating have no forecast.** Built 2026-11-15 (?164): `Battle.level_odds()`, `seen_odds()`. (?148)
- [x] **The DC rolls** (Burnout, Stun, Bandwagon, dodges) use `check(.., against: dc)`. Built 2026-11-15 (?164). (?148)
- [x] **Hitch and Slam Jam pass their stats to the helper in code**, not as a `SkillCheck`. Decided 2026-11-15 (?164). (?141)
- [ ] **`_borrowed()`'s `bonus = r` is unproven by mutation**: its rank barely changes the outcome. (?148)
- [ ] **The facing word sits a little right of the foe's centre.** Cosmetic. (?148)

## Screenshot pass (2026-11-15)

Plan and findings: `docs/plans/shots-11-15.md`. Built on `y-shots`. No code changed.

149. **Screenshot pass - findings only (2026-11-15).** Clairvoyance pings read clearly and stay with the foes after End turn; the Specialist tree reads, with T3 holding four skills, not three (Ds, St, Ta, Ww); the facing chevron was low-contrast; the lent ring and emblem diamond read; Warcry marks read, but Routed!'s blue blended with movement outlines and water. Fixed since: the chevron (?148), the rear / flank label (?148), suspicion stacks and Routed!'s colour and glyphs (?150). Left:
- [x] **The Specialist tree opens at its lowest filled tier** (`SkillGrid.floor_y()`). Built 2026-11-15 (?163). (?149)
- [x] **The lent ring sits a little lower than the rank pip.** Built 2026-11-15 (?165): drawn on the numeral's baseline. (?149)
- [x] **Re-check the Warcry marks on a busy board.** Checked by screenshot 2026-11-15 (?168): they read over the glow, rings and cone. (?149, ?150)

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
- [ ] **The Siren balance** (kept as built, 2026-11-18: no balancing now; tune by check difficulty if ever). (?152)
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
- [x] **`skill.py check` doesn't catch a skill dropped from its tree.** It does (`check_reachable`, verified by mutation); the two tree tests are folded (?166). (?156)

## Warcry's foe picker (2026-11-15)

Plan and what was built: `docs/plans/warcry-picker.md`. Built on `z-warcry`. Tests extend `warcry_test.gd`.

157. **Warcry picker - built on judgement, open for review (2026-11-15).** My calls:
    - **A generic seam, `Behaviour.picks(c) -> int`** (default 0): how many targets the caster may pick by hand. `Cast.picked` carries them, `Battle.cast(..., picked)` passes them, `Battle.picks_of()` sums for the HUD. A later multi-target skill overrides `picks()`.
    - **No picks means the behaviour chooses** (Warcry: the nearest rank), so a quick cast and the AI are unchanged. Picks are validated in `Warcry.chosen` (alive, foe, still located, capped at rank, duplicates dropped; none left, the nearest).
    - **HUD:** the key of a skill with `picks > 0` sets `aim` as a tile skill does; `intent()` is `&"pick"` on a visible foe (toggle, capped), Ctrl-click still strikes; cast on the second press or a click on the unit. Cancel, select, slot change and a cast clear the picks.
    - **Only picked foes are drawn** (red brackets and a number; the hint "Warcry: 2 of 3 picked"); the default is not, the hint says "the nearest N". Pickable is what the caster `read()`s as located, the filter Warcry uses.
    - **Warcry's static `picks(b, caster, n)` renamed `nearest`**; `Skill.describe` says "you choose them, else the nearest first".
    - **New names to review:** none.
- [x] **The default "nearest N" isn't previewed** before picking. Built 2026-11-15 (?171): `Behaviour.defaults()`. (?157)
- [ ] **No other skill overrides `picks()` yet.** (?157)

## Save follow-ups (2026-11-15)

Plan and what was built: `docs/plans/save-followups.md`. Built on `z-savefu`. Tests: `save_test` (`test_new_game`, `test_tower_quit_saves`).

158. **Save follow-ups - built on judgement, open for review (2026-11-15).** My calls:
    - **"New game" button** on the entry screen (`%Delete`), shown when a hero or save file exists. Confirm is a second press (the text turns to "Sure? Press again to delete the save"), not a dialog. `Save.erase()` removes the save, `.bad` and `.tmp` and calls the new `Game.reset()`, which lives in Game so a later static is added beside its declaration.
    - **Tower quit:** `GamutsTower._notification` saves on `NOTIFICATION_WM_CLOSE_REQUEST`, as Entry and HUD do.
    - **Allied glow picker:** already in `Prefs`; nothing to do.
    - **Driver save path:** a code guard in `Save.PATH` (a `-s` script gets `user://save_driver.json`) over a memory note; `Prefs` and `KeyBinds` are not guarded.
    - **New names to review:** none.
- [x] **`Prefs` and `KeyBinds` paths aren't guarded for driver scripts.** Built 2026-11-15 (?166): `*_driver.cfg`. (?158)

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
- [x] **Tune the clue weights and turn caps by the sims** (all guesses). Tried in ?173 on the museum: every value gave identical fights, so none changed; needs a purpose-built sim (an Observe user hunting a hider, over the seeds). (?159, ?173) Tuned in ?177 with the sim: `DEBRIS` 1 -> 3, the rest unmoved. (?177)

## Param tail (2026-11-15)

Plan and what was built: `docs/plans/param-tail.md`. Built on `z-param`. Tests extend `route_test.gd` (`test_missed`, `test_rift_look`, `test_strike_element`).

160. **Param tail - built on judgement, open for review (2026-11-15).** The six deferred skills and the UNSAID markup were already built (r-route; `describe_as`, ?148), so nothing was done there. My calls:
    - **`skill.py modifiers` stays 28 before and after:** the eligible were already eligible; what changes is which modifier acts. Rift gains rho_up, Strike's chain reads a stat-impact `element` term, Alluring's rank-impact list gains `practised look`. The 28 left are the concrete ones of ?133.
    - **Strike's element bonus** (imbued, or Elemental Mastery's highest mental mod) goes through Strike's modifiers as stat impact; the bonus is Strike's, not Elemental Strike's, which stays rho-only (a sigma read would need a stored mental bonus on the unit, a bespoke counter). Strike passives' per-hit extras stay Effect stats.
    - **Rift's difficulty and turns, and Look's dissonance rank and text,** read rank through the caster's modifiers as rank_impact (SkillTerms: `domain`, `practised look`). The "over walls from rank III" gate and the reach stay on real rank; the 1.5 difficulty clamp still caps what a modifier buys.
    - **`Behaviour.missed(c)`**, a generic hook, the counterpart of `apply()`: `Battle._miss(c)` runs it (and sets `c.hit` false) before `used` on every failing path: a lost drag, engulf or contest, a passed save, a missed attack roll, a Strike chain with no hit, Level Down taking no level, Death not killing, and in `area_blow` a victim that dodged. Not run on a cast refused before it is tried, nor on tile skills with no victim. **No skill uses it yet** (no content invented).
    - **New names to review:** none.
- [ ] **No skill uses `Behaviour.missed()` yet**; a refund or rider on a miss is the first. Grepped again in ?169: no recorded skill design wants one. (?160)
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
- [x] **Defense through a lie** (`_lie`/`twist`) is read, by the AI and the HUD. Built 2026-11-16 (?173): `Read.believed()`. (?162)
- [x] **A Grudge unit plans a retreat tile** so as not to be cornered next round. Built 2026-11-16 (?173): `AI._retreat()`, `_room()`. (?162)
- [x] **Tune `GUESS_DEFENSE`, `POINT`, `RIDER`, `PUSH`, `STARVE` by the sims.** Tried in ?173: no change on the museum (it never uses STARVE or PUSH); needs a purpose-built sim (a Kick against a wall; a Grudge unit in a corner). (?162, ?173) Tuned in ?177: all five unmoved (table in `docs/plans/ai-sim.md`). (?177)

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
- [x] **Always-on passives on the bar show the green "on" dot** toggles use. Built 2026-11-15 (?165): the dot shows only for toggles. (?163)
- [x] **Skill Slot +1 (?3)**: answered 2026-11-18 (the hotbar, far right, a trait). Built 2026-11-19 (?194). (?163)
- [ ] **The auto-equip toggle is global**, not player-only. (?163)
- [ ] **NPC-side equipping choices** beyond `extra_slots`. (?163)

## Checks tail and rebate affordability (2026-11-15)

Plan and what was built: `docs/plans/checks-tail.md`. Built on `z-checkstail`. Suite 8391 to 8744 checks, 0 failed. Tests: `poach_test.test_afford_the_cut`, `last_stand_test.test_level_down_odds`, `bracing_test.test_seen_odds`, `check_test.test_dc_and_rider_forecasts`.

164. **Checks tail and rebate affordability - built on judgement, open for review (2026-11-15).** My calls:
    - **Forecast through one helper:** `Check.totals(c)`; `Battle.level_odds()` weighs each last-stand total (rolled once per cast, shared by all `rank` rolls) then `1 - (1-p)^rank`; `hit_chance()` answers it, so brackets, Alt's "N% to win" and `AI.score()` read it. `Battle.seen_odds()` does the same over the hider's guise totals (`Battle.guise()`, what `cast()` rolls) and each watcher's odds. HUD: Alt tooltip "N% to be seen through". **The AI rule is mine, change if unwanted:** `_support` skips an investigated skill foes see through at least `AI.SEEN` 0.9 of the time. Death's chance is not forecast (not asked).
    - **Fixed-DC rolls** go through `check(.., against = dc)` (Burnout's con save, Stun, Bandwagon, glass's dex check, `evade`, pick/pry, the held-fire wis check); the rng order is unchanged. Stun says its chance as a rider.
    - **Hitch and Slam Jam are not a declared `SkillCheck`** (`Skill.check` stands in place of the attack roll in five readers; "after a hit" would be a flag each must branch on): each keeps one static options function (`HITCH.grapple()`, `SLAM_JAM.contest()`) that `apply()` rolls and `foresee()` weighs, with `riders = p`.
    - **Affordability pays the rebate:** `Unit.can_afford(s, cut)`, `can_afford_after`, `funding`; `Battle.price_cut()` is the smallest sure share across the targets (a price paid once for a spread must be granted by all); used by the HUD (`why_not`, reach, readiness, drain's fund) and the AI (`_strike`, `_could_strike`, `_steady`, `_starve`, which no longer prefilter with `foe_actives(true)`). Slot-press checks with no target keep the full price.
    - **New names to review:** none.
- [ ] **No forecast for Death's chance**, and the initiative d20 and the two last-stand rolls have no DC. (?164)
- [x] **Unproven by mutation:** Hitch's `apply()` options and `hit_chance`'s Level Down branch. Built 2026-11-15 (?172): four mutations each fail `check_test`. (?164)
- [x] **Tune `AI.SEEN` (0.9)** by the sims; it is a guess. Tried in ?173 (0.8 / 0.95): no change on the museum; needs the purpose-built sim. (?164, ?173) Swept in ?177: kept 0.9. (?177)

## Equip follow-ups (2026-11-15)

Plan and what was built: `docs/plans/equip-followups.md`. Built on `z-equipfu`. Test: `equip_test.test_slot_switch_dot`.

165. **Equip follow-ups - built on judgement, open for review (2026-11-15).** The Save hooks, the Settings toggle, losing slots and the Specialist tab's scroll were already built by ?163. My calls:
    - **Lent ring** drawn on the numeral's baseline, just left of the rank numeral; the toggle dot and name shift left.
    - **The on/off dot shows only for toggles** (`SkillSlot.shows_switch()`); always-on passives have none. This answers ?163's open question as "no dot"; say if you want it back.
    - **An unequipped learned skill** (wheel and grid) has a dashed rim and a darker fill beside the dulled numeral (stubs share the dashes but are muted grey and unlearned).
    - **Skill Slot +1 (?3) not built:** the design is unresolved ("the hotbar's center or the tree's?"); see "Needs the user". The slot-granting path (`slots`, `Unit._grants`) already makes an untyped slot once decided.
    - **New names to review:** none.

## Tooling guards (2026-11-15)

Plan and what was built: `docs/plans/guards.md`. Built on `z-guards`.

166. **Tooling guards - built on judgement, open for review (2026-11-15).** My calls:
    - **Tree wiring:** `skill.py check_reachable` already fails a skill nothing offers (tree, role, item, another's grant); mutation (Switcheroo off `Trees/legerdemain.tres`) failed `check`. No new check.
    - **Folded tests:** `trickster_test` (a name and order snapshot of the Rogue tab) deleted; `slam_jam_test.test_tree` folded to **one check, Slam Jam placed uptree from Jam** (the coordinator's call, so the one prerequisite edge that shapes the tree is kept). The exact layout snapshots are no longer guarded.
    - **Driver paths:** `Prefs.SAVE` and `KeyBinds.SAVE` get `*_driver.cfg` when the main loop has a script (or none yet), the same expression as `Save.PATH`; `run.gd` still overrides all three. Verified by a `-s` script printing the paths.
    - **New names to review:** none.

## AI support 2 (2026-11-15)

Plan and what was built: `docs/plans/ai-support-2.md`. Built on `z-aisupport`. Suite 8416 to 8644 checks, 0 failed. Tests: `ai_tactics_test.test_wear_varies_the_blow`, `move_test.test_ai_stretches`, `ai_support_test.test_restorers_serve_help`.

167. **AI support 2 - built on judgement, open for review (2026-11-15).** My calls:
    - **Move ??'s extra effect:** a generic hook `Behaviour.strides(c)` (in `Util/skill.py` HOOKS); `Move.strides` reads `pays_as`, so Stamina doubles it in the forecast as in `apply()`. `AI._stretch()` casts the cheapest self-only `strides` skill only to bring a blow in reach this turn, with AP left to walk and pay (straight-line gap, AP priced; not for hunting, fleeing or reaching a heal).
    - **Exhaustion:** `AI._wear(u, s)`, the part of the cost exhaustion added, taken off a strike's worth, never below `1 - WORN` (**WORN 0.8**, as FOILED). Strikes only. Heals and supports are not weighed.
    - **Help orders:** `Skill.serves(posture, u)`: "supportive" also holds for a skill whose behaviour `restores()` (new `Skill.restoring(u)`). So Energize is supportive despite `self_only`, serves both HELP and DEFEND, a Berserker's Affinity for it nets -2, and Heal and Resuscitate now get Unsupportive -1 like Second Wind. `HUD.intent_skill` and `AI.restoring` are gone.
    - **?87 is not fixed by the AI alone:** 30 museum seeds, Lancin 27 / Nemes 3 became 26 / 4; Icor Hex 126 to 125, Strike 95 to 92. Hex still outscores Strike enough that Nemes leans on it; WORN was not tuned to hit a quota. Cost tuning is the user's call (Needs the user).
    - **New names to review:** none.
- [x] **Tune `AI.WORN` (0.8)** by the sims; weigh heals and supports for wear too. Tried in ?173 (0.6 / 0.9): no change; heals and supports still not weighed for wear (`_wear` prices strikes only). (?167, ?173) Swept in ?177: kept 0.8; heals and supports now weigh wear (?176). (?176, ?177)
- [ ] **Hex outscores Strike in the museum** (?87): kept as built, 2026-11-18 (no balancing now). (?167)

## Param rest (2026-11-15)

Plan and what was built: `docs/plans/param-rest.md`. Built on `z-paramrest`. Test: `route_test.test_reserve_text`.

169. **Param rest - built on judgement, open for review (2026-11-15).** My calls:
    - **Text now reads the modifiers:** `Unit.pools()`, `opened()` and `Downed.takes()` were already routed; `Skill.markup()` showed raw rank and the raw reserve mod. It now reads rank impact and `_mod(reserve_mod, stat_impact, m)` for a reserve's size, the tier a skill opens ("up to T3") and the Downed rule. Focus is the same path.
    - **The rates are routed too (my call):** `Unit.giver_rank()` (Stamina's and Mana's resting rate) and `Unit.carry()` (a switch's held carry) read the modifiers' rank; before, a Density emblem on Stamina grew the pool but not its rate, so the text would have lied one way or the other.
    - **Stays concrete:** the build-time gates (`waives`, Dabblings' `studies`, the guest-tree rank caps), which gate what is learned; an emblem coming off would strand picks.
    - **`missed()` still has no first user:** no recorded skill design wants a rider on a miss (Poach's and Slam Jam's refunds are on a hit, Grudge counts hit or miss as any use, "Commitment to the bit" is the posing whiff `missed()` doesn't run on); no skill was invented to exercise it.
    - **New names to review:** none.

## Forced moves: forecast and AI (2026-11-15)

Plan and what was built: `docs/plans/forced-forecast.md`. Built on `z-forced`. Tests: `Tests/forced_test.gd` (4 new), `ai_tactics_test.test_forced_moves_are_priced`; two Kick notes in `ai_tactics_test` now end "to (6, 3)" / "to (5, 3)".

170. **Forced moves: forecast and AI - built on judgement, open for review (2026-11-15).** My calls:
    - **One reader, `Battle.course()`**, the read-only twin of `displace()` (`{went, left, into, end}`); `Battle.foresee_drive()` makes a `foresee` dict: a line ("Shoves it 2 tiles back to (6, 3), then slams X (N each)"), `lo`/`hi` the slam, `riders` = `PUSH` (0.5, moved from Kick) a tile, `spill` the slam on the unit struck (an ally of the pusher counts against). Kick's own `driven()` is gone.
    - **Who foresees:** `Battle.foresee()` reads a skill's own `shove`/`fear`/`entrance` effects as `cast()` would put them on (not on a foe for a `dual` skill); `Displace.foresee()` (Sing, Send Off, any carrier) uses `moves()`, the test `apply()` makes. A behaviour's own `Cast.put()` effects are its to foresee. The HUD needed no change.
    - **Fear and entrance foresee the first move only**, not each repeat; flat mitigation, boosts and reactions on the slam aren't counted.
    - **The AI gets no new scoring:** `foresee()`'s riders and spill reach `AI.score()` (a tile is worth `PUSH x RIDER`; a slam into an ally nets against the foe's damage). `_support` skips a support skill whose effects harm, so a fear-carrying "buff" never goes on an ally.
    - **`drive()` in Aura's and Coordinate's (`Battle._link`) loops**, after `a.by` is set; an aura's shove drives each ally from its caster.
    - **Tags on skills' own `tags`: not added** (a skill's tags are the whole cast's; a `shove` tag on Send Off would make its blow, cost and effects read as a shove). Asked of you, at the top of `todo.md`.
    - **New names to review:** none.
- [x] **The AI doesn't walk to a tile to line up a shove against a wall**, nor weigh being shoved by foes in its own positioning (`_away` etc.). (?170) Built 2026-11-16 (?176): `AI._line_up`, `_shoved`. (?176)
- [ ] **Fear and entrance's repeat moves aren't foreseen**; neither are mitigation, boosts or reactions on a slam. (?170)
- [x] **No skill carries fear, shove or entrance yet.** See ?192. (?146)
- [x] **Turning**: ~~a unit moved by force now faces along the move~~ (?188) reversed 2026-11-19 (?192): only a unit's own intentional moves (fear and entrance included) and aims turn it. A unit that is hit still doesn't turn. (?142)

## Warcry's default-pick preview (2026-11-15)

Plan and what was built: `docs/plans/warcry-preview.md`. Built on `z-wcpreview`. Test: `warcry_test.test_the_hud_toggles_picks` extended.

171. **Warcry preview - built on judgement, open for review (2026-11-15).** My calls:
    - **A hook `Behaviour.defaults(c) -> Array[Unit]`** (default empty), the counterpart of `picks()`: what the skill takes when nothing is picked. `Battle.defaults_of()` unions the answers; `HUD.preview()` is that while `picking()` with nothing picked. Warcry's `chosen()` falls back to the same `defaults_of(c)`, so preview and cast cannot drift.
    - **Not drawn through `Behaviour.footprint()`:** that answers for a hovered cell; the default is units with no cell to hover.
    - **Look:** the picked foes' red brackets, thin and faint (alpha 0.25 plus a pulse) and no number; the first pick clears it.
    - **New names to review:** none.
- [ ] **No other skill overrides `picks()` or `defaults()` yet.** (?157, ?171)

## AI tuning and the last prices (2026-11-16)

Plan and what was built: `docs/plans/ai-tuning.md`. Built on `z-aitune`. Tests: `hud_test.test_a_lied_defense_is_believed`, `ai_tactics_test.test_starving_keeps_room_to_retreat`.

173. **AI tuning - built on judgement, open for review (2026-11-16).** My calls:
    - **Defense through a lie:** `Perception._lie` mirrors `Read.defense` about `MIRROR` 20 with chance `twist` (plate reads as cloth); 20 is a guess. The armor's name and trims stay true. One reader, `Read.believed(unknown)`, feeds `Battle.hit_chance()`'s guess for `AI._chance` and `HUD.odds`; the DF card row and the log's roll show the lie. `HUD.odds` itself has no test (a liar whose faction flips is read as an ally).
    - **Grudge retreat:** `_starve` backs off through `AI._retreat()`: with `safe` (movement + 2 of the Grudge unit) every tile past it counts the same, and the one with the most `_room()` (free tiles in its own movement further from the Grudge unit) wins. Other `_away` callers are unchanged. Not done: the Grudge unit's own approach; allies don't coordinate; next turn's position isn't foreseen.
    - **No constant tuned:** a scratch sim ran each of 15 constants low and high over the museum's 8 seeds, all identical to base (extremes moved only the turn count); 30 seeds before and after: Lancin 26 / Nemes 4, 413 turns. The museum has no Observe user, hider, Kick, Grudge or rider skill, so it cannot tell them apart. All stay at their guesses; the sim is not in the suite.
    - **Not done:** weighing heals and supports for exhaustion wear (`_wear` prices strikes only).
    - **New names to review:** none.
- [x] **A purpose-built AI sim** (an Observe user hunting a hider; a Kick against a wall; a Grudge unit in a corner) to tune the clue weights, `STARVE`, `PUSH`, `SEEN`, `WORN`. (?173) Built 2026-11-16 (?177): `Tests/sims/ai_sim.gd`, `sweep.sh`. (?177)
- [x] **Heals and supports weigh exhaustion wear** (`AI._wear` prices strikes only). (?167, ?173) Built 2026-11-16 (?176): `AI._fresh`. (?176)
- [x] **Other Grudge retreat parts**: the Grudge unit's approach, allies coordinating, foreseeing its next position. (?173) The Grudge unit's approach built (?176); allies coordinating a retreat is not, see ?176. (?176)

## Unbounded maps, camera and spawning (2026-11-16)

Plan and what was built: `docs/plans/unbounded-maps.md`. Built on `z-maps`. Tests: `Tests/meadows_test.gd` (`test_streaming`, `test_camera`, `test_spawning`, each mutation-checked).

175. **Unbounded maps - built on judgement, open for review (2026-11-16).** Phase 7 item 27. My calls:
    - **Streaming stays the Meadows'** (`Meadows.ensure_around()`); no generic streamer lifted out, as only one map streams. It now triggers on any party move and on a forced move (`driven`), so a shove off the known plane grows it.
    - **Bounded work:** `Battle.cells_near(c, r)` walks only the box round c; every "all cells within r" loop goes through it (prayers, explosions, `strike_tiles()`, `free_near()`, `drag_spot()`, `_scatter()`, the AI's Observe and channel candidates). A source test keeps new `get_used_cells()` loops out of Battle, AI, HUD and Overlay.
    - **Rule change: where sight is limited (the Meadows), a tile beyond a unit's perception can't look suspicious to it.** `maybe_suspicious()` reads only its sight's box; a hidden trap 20 tiles off gives no "disturbed earth?" hint to a unit that perceives 12. Where sight isn't limited, nothing changes.
    - **Camera:** arrow keys pan (new rebindable actions `camera_left/right/up/down`); a pan lets go of the unit, and the view keeps to the active unit again on an action, a new turn, a selection change or Home. The active unit is the selected one or the last to act that the player's side makes out, so an unseen demon doesn't pull the view. No edge-pan or drag (the HUD's panels sit on the edges, the mouse buttons are taken).
    - **Spawning unseen:** `summon(scene, f, c, unseen_by := null)` lands on the nearest free tile where no unit of that side would make it out by the real read (`Battle.read()`), or returns null. The Meadows pass the party's side; its distance check stays as the cheap first guess. Where sight isn't limited the check is skipped.
    - **Timings (seed 7, three rounds of every AI):** a round on the starting plane (2,304 tiles) 342 / 513 / 1,049 ms (was 345 / 788 / 1,178); on the grown plane (76,176 tiles) 1,021 / 743 / 960 ms (was 2,883 / 2,253 / 6,135). `free_near` 17.6 ms to 0.01 ms. An unseen `summon()` starting inside sight 164-176 ms; a formation spawn 9-10 ms; the HUD's `_mark()` 0.002 ms.
    - **A UI bug seen in passing, not fixed:** the turn clock's number draws over the end of the Meadows' "Demons slain" tally at the top centre.
    - **New names to review:** none.
- [ ] **The 30-kill escape-portal battle** stays as it is, a later battle. (?175)
- [x] **Edge-pan and drag for the camera** (the HUD's edge panels and the mouse buttons are taken). (?175) Edge-pan built 2026-11-16 (?179): `BattleCamera.edge_dir()`, a Setting. (?179)
- [ ] **Drag to pan the camera** (the mouse buttons are taken). (?175, ?179)
- [x] **A cheaper first guess for an unseen `summon()` starting inside sight** (~170 ms), if something summons often near the party. (?175) Built 2026-11-16 (?179): `beyond_sight()`, ~125 -> ~14 ms. (?179)
- [x] **The turn clock's number overlaps the "Demons slain" tally** at the top centre of the Meadows. (?175) Built 2026-11-16 (?179): the tally is right-aligned and ends left of the clock. (?179)

## AI walks (2026-11-16)

Plan and what was built: `docs/plans/ai-walks.md`. Built on `q2-aiwalks`. Tests: `ai_tactics_test` (`test_wear_weighs_heals_and_supports`, `test_lines_up_a_shove`, `test_retreat_weighs_shoves_and_price`, `test_grudge_goes_for_what_it_reaches`), each mutation-checked; suite 8609 checks, 0 failed (920 tests).

176. **AI walks - built on judgement, open for review (2026-11-16).** My calls:
    - **Wear for heals and supports as a share:** `AI._fresh(u, s) = max(1/rate, 1 - WORN)`; `_heal` multiplies a heal's want by it (a lone worn heal still gets cast), `_support` tries skills least worn first. A share, not `_wear()`'s subtraction, because a heal's worth and a support's none aren't in HP; `WORN`'s floor is reused.
    - **Shove positioning through the forecast:** `Battle.standing(u, c, f)` reads `foresee()` as if u stood on c. `AI._line_up` walks to the tile where a skill's drive adds most beyond its damage, if that beats where it stands by `PUSH x RIDER` (no new constant). `AI._shoved` prices being driven by foes it reads (the foe placed squarely beside the tile, since Kick's `between()` reads a diagonal as no push) and is `_retreat`'s first key.
    - **One price for the other walks:** `_retreat` (flee, kite, recover, starve) prices each end tile by `route()` with `wary`, keying `gap - extra`. `_recover`'s lattice walk and `_escape` untouched. `_retreat` and `_line_up` restore the rng.
    - **Grudge approach:** `_last_blows` picks among the foes it can walk up to this round (`_reachable()`), so a far strong foe doesn't draw it past a near one.
    - **Allies coordinating a retreat: not done.** The one rule tried (don't end beside an ally still to back off) was indistinguishable from what `_room()` already does; the mutation survived its test, so it came out.
    - **`SUSPECT_TILES` stays 3.0:** 8 museum seeds, 12 or 30 hinted traps: springs 29 / 27 / 25 / 24 / 24 / 24 at 0 / 1 / 2 / 3 / 5 / 8 (12 traps); 59 / 55 / 58 / 51 / 52 / 51 (30 traps). The knee is 3.
    - **Survived mutation:** the line-up's gain threshold (`PUSH x RIDER`), left as a one-line choice.
    - **New names to review:** none.
- [x] **Allies coordinate a retreat** (don't crowd the one tile out; back off in turn). (?176) Built 2026-11-16 (?178) as a tie-break only: `AI._claimed()`; no crowded battle shows a gain yet. (?178)
- [x] **A test for the line-up's gain threshold** (`PUSH x RIDER`: no test stages a gain between 0 and one tile's drive). (?176) Built 2026-11-16 (?178): `test_line_up_gain_threshold`, three mutants fail it. (?178)

## AI sim and tuning (2026-11-16)

Plan, scenarios and the full table: `docs/plans/ai-sim.md`. Built on `q2-sim`. Outside the suite: `Tests/sims/ai_sim.gd` and `Tests/sims/sweep.sh`.

177. **AI sim and tuning - built on judgement, open for review (2026-11-16).** My calls:
    - **The sim lives outside the suite:** `godot --headless --path . -s Tests/sims/ai_sim.gd -- [scenario words] [n=8] [debug]`, about 6 s at n=10, one `SIM <scenario> k=v` line each. Scenarios: hunt-still, hunt-moving, ambush, clash, kick-margin, kick-fight, grudge, rider, armor, worn, hide. `sweep.sh CONSTANT "v1 v2 v3"` edits one `const` in AI.gd or Battle.gd, runs it, and restores the file. The AI is deterministic, so seeds vary dice and start tiles; the choice scenarios read the AI's prices directly.
    - **`DEBRIS` 1 -> 3:** clash-debris 4.93 / 4.70 / 4.30 / 4.08 rounds to find the hider at 1 / 2 / 3 / 4 (n = 60); a sign outweighs a guess, and a decoy debris costs nothing. 4 gains little more.
    - **Left unmoved, with results recorded** (`docs/plans/ai-sim.md`): `SUSPICIOUS`, `MARKED`, `REACH`, `HIT`, `REACH_TURNS` (nothing moved); `LAST_SEEN` .5 (a plateau above .25); `SWEEP_TURNS` 4 (monotone but inside the noise, and 1 would break `evidence_test`); `GUESS_DEFENSE` 12; `POINT` .5; `RIDER` 1; `PUSH` .5; `STARVE` 5 (flips between 10 and 20); `AI.SEEN` .9; `AI.WORN` .8.
    - **Findings, not constants:** an Observe user that has swept its last clue stands beside a hider and never looks again; Poach is never chosen over Strike or Slam Jam in the rider set; Kick beats Strike on price even in the open, so `PUSH` and `RIDER` can't be tuned without a rival at par; after ?176 the Grudge set's Lancin HP lost fell 3.75 to 2.00.
    - **New names to review:** none.
- [x] **An Observe user that has swept its last clue stands next to a hider and never looks again** (hunt-still, seed 1: adjacent for 8 rounds). (?177) Built 2026-11-16 (?178): `AI.LOST`, a clue at the hunter's own tile. (?178)
- [x] **Poach is never chosen** over Strike or Slam Jam in the rider set; look at its price. (?177) Read 2026-11-16 (?178): the sim's foe was never bloodied; the price was right. (?178)
- [ ] **`PUSH` and `RIDER` can't be tuned until Kick has a rival at par on price.** (?177)

## AI findings, Meadows tails, dictionary, Deathlust, big sims (2026-11-16)

Plans: `docs/plans/ai-findings.md`, `meadows-tails.md`, `r-docs.md`, `r-deathlust.md`, `r-sims.md`. Built on `q3-ai`, `q3-meadows`, `r-docs`, `r-deathlust`, `r-sims` (Skeleton is under the Wizard / Mage notes in `docs/todo/classes.md`, ?181). Names to review in all of these: none.

178. **AI findings from the sim - built on judgement, open for review (2026-11-16).** Cards from ?176, ?177. My calls:
    - **Hunt-still fixed with one more clue:** `_hunt` forgets a sighting within a tile of it, so a hider seen once and missed leaves `clues()` empty and the hunter stands beside it forever. Now a living foe its side once made out (`sighted_when`), placed by no sighting, is a clue at the hunter's own tile, worth `AI.LOST` 0.5 (= WORTH, not tuned): a look there rules it out for `SWEEP_TURNS`, then it looks again. hunt-still 5.07 -> 4.67 rounds to find; about one more Observe a battle.
    - **Poach was never mispriced:** its condition is a foe at half HP that the caster never aimed a skill at; the sim's foe started at three quarters HP. The sim now starts it bloodied; Poach is used once a run, as the opener, never again on that foe (the card's text). No AI change.
    - **Line-up threshold tested:** `test_line_up_gain_threshold` stages the least real gain (0.5) and none; `<` to `<=`, `< 0` and `< 2 x PUSH x RIDER` each fail it.
    - **Allies and a retreat: a tie-break, not a reservation.** `_claimed()` runs `_retreat()` for each able ally that hasn't moved and is within reach, and a claimed tile loses a tie on shove, gap and room (a fourth key element, only on the starve walk). No state kept between units; "yet to move" is `move_left() >= movement`. The `grudge` sim is identical before and after (the two Lancin start apart); kept because a seam test can tell it from `_room()` and it is never worse on the first three keys. Drop it (`_claimed`, the key, the test) if no crowded battle shows a gain.
- [ ] **Does the ally tie-break pay in a crowded battle?** `_claimed()` costs one `_retreat` per ally in reach on a starve turn; drop it if a busy-fight sim shows nothing. (?178)
- [x] **A hunter's `LOST` clue after the line-up** is a guess at 0.5; tune it with a hunt sim where hiders start in range. (?178) The near variant is built (?217); no retune yet (queue).

179. **Meadows tails - built on judgement, open for review (2026-11-16).** Three cards from ?175. My calls:
    - **Tally vs clock:** the "Demons slain" tally is a right-aligned label x 80..226 (`Meadows.TALLY_LEFT/RIGHT`), growing leftward and ending clear of the clock (the HUD's clock is untouched; other tests pin it). Test: `meadows_test.test_plane`.
    - **Edge-pan:** `BattleCamera.edge_dir(pointer, view, clear)`, pure: a pointer within 3 design pixels of an edge pans that way (corners diagonal), unless over `Root/Left` or `Root/Right` (the panels fill the side edges, so in practice top and bottom pan). Arrow keys win when held; none while a panel (Settings, skills) is open, with the pointer out of the window, the app unfocused, or before the pointer first moved. Speed is the arrow keys' (`PAN`); it lets go of the unit as the keys do. The Setting `BattleCamera.edge_pan` (static), default on, "Edge-pan the camera" in Settings, Prefs `edge_pan`.
    - **Summon search:** the first guess is the nearest free tile past every watcher's perception range (`beyond_sight()`, a distance, no read), confirmed by one read; only if none reads unseen does the old nearest-unseen search run. A call: a nearer concealed tile (brush, fog) used to win; now a tile past sight does. Five Siren summons 111-145 ms -> 13-14 ms (M3).
- [x] **Edge-pan reaches only the top and bottom edges** while the HUD's side panels fill the left and right; a way to pan sideways by the mouse. (?179) Built 2026-11-20 (?217): middle-drag pans.

180. **Dictionary and glossary - built on judgement, open for review (2026-11-16).** Docs only. My calls:
    - **`g-dictionary.md`**: preferred terms for stubbing and naming, 20 rows, read from `Glossary.gd`, `Reserve.gd`, `Battle.gd` (`neutralized`), `Exhaustion.gd` and the plans; "use instead of" filled only where the code or you draw the line. The "Arcalís" rows are your rule (no ` ??`).
    - **`g-glossary.md`**: the Center entry verbatim; **the builder added its own one-line readings of Lancin, Lancela and Lancin Proper** under it, outside the verbatim paragraph. Delete them if wrong.
    - **CLAUDE.md** gained one naming line.
- [x] **Lancin and Lancela get their own headings in `g-glossary.md`**, light formatting only (answers 2026-11-18b item 11). Built 2026-11-19 (?180). The builder's one-line readings stay under the headings, marked as such; the user may still correct them.

182. **Deathlust and its hooks - built on judgement, open for review (2026-11-16).** Your words: "Units dying in rank range remove a small amount of exhaustion. Prevents specific skill exhaustion on skills used to kill (not down) a unit." The name is yours. My calls:
    - **Where:** Eros (after Impassioned Fighter, so it is not a Paladin's free first skill; free at the root it changed `progress_test.test_unlock`), Slayer and Vanguard (roots, open from the start), General Martial (tier 5 with the bracings; "Fighter martial" read as this tree). Tags `martial`.
    - **Reach:** 2 tiles a rank (2 / 4 / 6), through `rank_range`. "Rank range" as "rank tiles" was too tight (1 tile at rank I).
    - **Amount:** "small" is 0.25 of a use a rank (0.25 / 0.5 / 0.75), off every skill's count; a turn's end takes 1, and several deaths stack.
    - **Either side:** any unit killed in reach counts, ally, foe or the holder's victim; the holder's own death gets nothing. Downed never counts, nor unshaping.
    - **"Used to kill":** the unit's last hit came from the caster during that cast, or the cast was aimed at it (so executes count); a cast that kills one and downs another is a kill skill. A bleed's kill is no skill's. A channel's later strike (Metea) is not (its use was paid at the start). The kill skill's own use gains nothing, flat at every rank; other skills' share is derived from the count.
    - **Settled at the outermost cast's end**, so reactions inside it settle too.
    - **Generic pieces:** `Exhaustion.relieve(n, skill = null)` (turn-end `recover()` uses it), `Exhaustion.Wear`, `Unit.paid` signal, `Battle._settle_wear()`; Behaviour hooks `neutralized(b, holder, rank, u, by, how)` and `wearing(b, holder, rank, wear)` (`Util/skill.py` `HOOKS`). No HUD float or log line.
    - **Tests:** `Tests/deathlust_test.gd` (two tests, 11 checks); five mutations fail them.
- [x] **The AI doesn't seek kills for Deathlust's discount:** the relief is priced by a dry run of the `neutralized` hooks (`AI._relief()`, ?231); allies' Deathlust is not weighed. (?182)
- [x] **Deathlust gives no HUD float or log line** when it eases a count: it signs through `Battle.passive()` (?231); a log line is not built. (?182)
- [ ] **A channel's later strike (Metea) and an area skill's kills** don't count as a skill's kill (only `last_hit_by` and the cast's aim do). (?182)

183. **Big sims and AI cost - built on judgement, open for review (2026-11-16).** Your brief: M3 test box, a target 4x stronger, larger zoomed-out hunts, busy fights. My calls (full tables in `docs/plans/r-sims.md`):
    - **Outside the suite:** `Tests/sims/hunt_10v10.gd`, `busy_fight.gd` and the shared `field.gd` (an open grass field of any size); one smoke test in the suite, `Tests/sims_test.gd` (3v3, 557 ms), so a break in the field builder shows there.
    - **Hunt, 10 Rangers vs 10 hiders (60 x 40, n = 8, 20 rounds):** still 0.56 found, moving 0.39; the first find never before round 11 (the Rangers walk ten rounds to the last sighting). Not tuned.
    - **Busy fights, 15v15 and 20v20 (level 1, four skills each):** a unit's AI turn 84 / 103 ms mean, p95 268 / 318 on the M3.
    - **Budgets are mine:** 100 ms a unit's AI turn (a visible hitch), 1000 ms a side's `end_turn` (a freeze), at M3 x 4. Both are **over today**: a mean turn 3-4x the budget, p95 ten times; 15v15 `end_turn` mean 731 ms but p95 2.5 s; 20v20 mean 1.4 s. Constants at the top of `busy_fight.gd`.
    - **One change in Scripts:** `Perception._seem` asks only t's own side for Brood, same result, about 16% off a unit turn and 20% off `end_turn` (`persona_test.test_brood` catches it).
    - **Profile:** `Battle.read()` is about 215 calls a unit turn (0.33 ms each); `_line_up` 137 x 28 ms; `travel`, `_approach`, `suspicious` and `_watch` follow.
    - **Level 1 with four skills leans low** against a real party's turn.
    - **Load order:** a sim script must name `Test` before `Role`, `Branch` or `Effect` or the scripts hang in a cycle; `field.gd` has no `class_name`.
- [x] **AI turn cost over budget** (100 ms a unit turn, 1000 ms an `end_turn` on M3 x 4): a per-act read cache, `suspicious()` reusing the act's reads and skipping units beyond every viewer's range, `_line_up`'s foresee over every tile, a Brood-free fast path in `Unit.stat`, `travel`/`_approach`. Halved by `r-aiperf` (?184); w9 cut the unit turn 68 to 59 ms and `end_turn` 235 to 100 (?243); still over at the unit turn at M3 x 4. (?183)
- [ ] **Frame times unmeasured:** `busy_fight.gd`'s windowed path is written, not run. (?183)
- [x] **A hunt where hiders are in range from round 1**, to measure the search apart from the walk. (?183) Built 2026-11-20 (?217): `hunt_10v10` `near`.

184. **AI turn cost and the floater's tools - built on judgement, open for review (2026-11-16).** Calls (numbers in `docs/plans/r-aiperf.md`):
- A cache only inside a "stretch" (`Unit.begin_read()/end_read()`) where nothing mutates: `suspicious`, `_sightings`, `route`, `_check_stall`, the AI's reads and the weighing in `_strike`, `_line_up`, `_approach`, `_steady`, `_could_strike`, `_best_target`; dropped on a cell, footing or steadied change. A whole-act cache and a distance bound on `_line_up` were rejected as not strict.
- Proof of no decision change: `ai_sim` identical on 8 seeds; a `digest=` of every act's log in `busy_fight` equal before and after; 0 mismatches in 1.16 M cache hits.
- M3 mean / p95 ms: 15v15 unit turn 80/217 -> 38/75, `end_turn` 200/651 -> 122/347; 20v20 unit turn 100/260 -> 44/82, `end_turn` 425/1406 -> 233/679.
- Tools: `land.sh <branch>...` (merge main and the others in, union the appended docs, verify, ff, push, remove); `metrics.sh` and `docs/agents/metrics.csv`; `floater.md`, a brief to hand a whole prompt to one delegate. The haiku-timer idea: not used, since notifications carry tokens, tool uses and time.
- [x] **Unit turn still over budget** (151 ms at target vs 100): `suspicious()` reads every unit (~5 ms a call); `_look_harder` unscoped (`doubt` emits signals); `Perception.unit`, `skill_range`. (?184)
- [ ] **land.sh on a failed push** stops after the fast-forward, leaving the worktrees: push again by hand, then remove them. (?184)

185. **Traits - built on judgement, open for review (2026-11-18).** Your answer to ?163: traits are always on the hotbar, take no slot, can't be disabled the way skills are, don't order the hotbar, sit furthest right; suppression stays open. Plan: `docs/plans/w2-traits.md`. Calls for you to confirm or change:
    - **`trait` is a tag and replaced the `inherent` flag** (your word, no ??; made with `mechanic.py tag trait --human`, colour `#d6c8a0`, in `Tags.PLAIN`). `Skill.is_trait()` reads it; `Skill.inherent` is gone. Most of the rule was already built as `inherent` (?163); what was new is the word, the HUD column, suppression and the set of traits.
    - **Traits are always-on passives**, never actives or toggles; `skill.py check` (`check_traits`) fails one that isn't.
    - **Suppression:** one Effect stat `no_traits` (id has no ??) read by `Unit.traits_suppressed()`; the reusable status `Effects/traits_suppressed.tres` ("Traits Suppressed ??", harmful), used by nothing yet. It is read from timed statuses only (as `shackled()` is), so an item or passive can't suppress traits, only a status. Suppressed means as if unequipped: effects, hooks, reactions, tags and looks all stop until it ends.
    - **Which skills are traits:** Starkind and Reckless Abandon (were `inherent`), and **Alluring**, the Siren's alone; **Alluring now takes no slot, so the Siren's `extra_slots` goes 2 to 1** (`command_test.test_default_bar` updated). Left alone on purpose: Powerful and Physical Intelligence (pillars the curse should reach), Oceanic, Regeneration Pulse, Stoneskin, Hardy, Starsap (also on player trees), the Druid's FORMS (data of a shape, not skills; "aquatic" is a Property), species options (choices, not innates).
    - **Open: items' `insignia` and `badge` scopes can still modify a trait** (they don't order the hotbar; only the Sigil does, and it can't see a trait). Built as yes; say if a trait should be out of their reach.
    - **HUD:** a read-only `Traits` column under the hotbar (the hotbar is vertical here, so "far right" is its far end): a diamond where the number would be, trait-colour frame, no drag, drop, clear or key, dimmed with "Suppressed" while suppressed.
    - **Unequipped does nothing, audited for passives too:** one leak found and fixed (`Unit.skill_name()` renamed Strike for a learned but unequipped upgrade). Auto-equip and manual equip left as built.
    - **Spec text** reads "Trait" (was "Inherent").
    - **`FLAG_CEILING` in `Util/skill.py` should drop by one** (the `inherent` field went away); the host will do it.
    - **New names to review:** Traits Suppressed ??.
- [ ] **Which more skills are traits** (Oceanic, Regeneration Pulse, Stoneskin, Hardy, Starsap, the Powerful pair, the FORMS): confirm the reading above. (?185)
- [x] **Should `insignia` and `badge` reach a trait?** OK 2026-11-19: an item emblem can still modify a trait. (?185)
- [ ] **No skill applies Traits Suppressed ??** yet (a utility effect for later). (?185)
- [ ] **Lower `FLAG_CEILING` by one** in `Util/skill.py`. Host to do. (?185)

187. **Test stubs, Option A - built on judgement, open for review (2026-11-18).** Your answer to ?144: "A, 20/80 it", with tests of the core skills and mechanics where skills are functionally identical. Plan: `docs/plans/w2-teststubs.md`. Calls:
    - **Stub rule:** `skill.py new` writes a test only when it also stubs a NEW `Behaviours/<b>.gd` (a skill that reuses heal, boost, etc. is data-only); `--test` forces one. `unit.py` and `mechanic.py`: opt-in `--test` (replacing mechanic.py's `--no-test`); a mechanic's rule still gets a test beside the system that reads it.
    - **`item.py`, `role.py`, `tile.py` untouched** (item.py stubs nothing; role.py and tile.py only print a hint).
    - **Data pins that restate your placement stay** (tree tiers, `after`/`needs`: megaheal `test_gated`, slam_jam `test_uptree_from_jam`, persona `test_trees`); rule tests that only use a skill as vehicle stay (coordinate, drone, mindless_fury, stamina, focus, brainfog, haluca, smite, borrowed_time, prestidigitation).
    - **Folded or deleted** (each proved by a mutation): `double_bluff_test.gd` deleted (persona's `test_embellish` pins the rule); `megaheal_test` heal and megaheal merged into one table `test_dice`; `intervention_test.test_intervention` deleted (the sweep, `skill.py check` and `tag_colors_test` cover its data).
    - **Authorised edits:** CLAUDE.md's test line and `.claude/skills/new-skill`, `new-unit`, `new-mechanic` say the rule.
    - **Suite:** 8663 checks / 927 tests before, 8655 / 924 after (all 0 failed).
    - **New names to review:** none.
- [ ] **A wider sweep for per-skill data pins** (tree tiers, describe strings) moved into one table: left, since they encode your placement. (?187)

188. **Facing, wave 2 - built on judgement, open for review (2026-11-18).** Your answer to ?142: "a unit faces whichever direction they last moved (draw a vector from start to finish) or last targeted with a skill (draw a vector from position to targeted tile)". Plan: `docs/plans/w2-facing.md`. Calls:
    - **Whichever is latest** is the lead's reading of your "or": each event overwrites. One recorder, `Unit.turn(v)`; `face(c)` is `turn(c - cell)`; a zero vector changes nothing.
    - **A walk faces start to finish of the whole walk**, not its last step; a walk ending where it began changes nothing.
    - **Forced moves count as moves** (push, pull, send, teleport, effect shoves; the lead's reading): `displace()` turns the unit along the move; a push stopped at once changes nothing.
    - **Removed: the Interject/Gallantry stand-in turning toward the attacker** (`_swapped`): neither a move nor its own aim, so under the rule it doesn't turn.
    - **Kept:** `AI._line_up`, the opening line-up toward the nearest foe, Shields Up! and aimed-at-tile skills facing the tile.
    - **Tests changed to the new rule:** `facing_test.test_moves`, the Interject test (now `test_interjector_stays`), `displace_test.test_any_skill_knocks_back`; new `facing_test.test_latest_wins`. Mutation: dropping the turn in `displace()` fails two.
    - **New names to review:** none.

190. **Cost profiles - built on judgement, open for review (2026-11-18).** Your words (?131): "skill cost is part of its identity (ap heavy / resource heavy / specific resource needed or preferred). Skills *should* have an algorithm ... looking at which tags are included, which parameters are scaled how far (rank may scale cost, potentially a lot) as a baseline. Consider expanding how skill costs can be configured. a natural language description: "high mana cost, low ap cost" should be trivial for a sonnet or haiku model to implement via skill". Plan: `docs/plans/w2-cost.md`. Calls, those marked (lead) are the lead's readings of your words:
    - **Baseline = Pricing's points** (tags, terms, rank and stat scaling, contingencies); no TABLE number changes. A profile only skews how that budget is spent: AP against the resource cost, which resource, how steeply rank grows it.
    - **`Skill.priced: bool` is replaced by `Skill.costs: String`**, the profile as written ("high mana, low ap"); "" is hand-priced as `priced = false` was. Field count unchanged; **`FLAG_CEILING` 104 to 103** (the true count; the `inherent` field already went, ?185). Poach, Skeleton and Warcry become `costs = "even"`, priced as before.
    - **Vocabulary** (Pricing's TABLE, mirrored in `skill.py`): clauses split on commas, ";" and "and"; `[level] [only|needs|prefers] <dimension>`, `<flat|scaled|steep> rank`, or `even`. Levels: none 0, low 0.5, moderate or none stated 1, high 1.5, very high 2. Dimensions: `ap`, the resource cost (`cost` / `energy` / `resource`), or a reserve by id (`mana`, `stamina`, `focus`, `sweet nothings`). "cost" after a dimension is ignored.
    - **Absolute words, unstated = moderate** (lead): "high mana" alone is dearer overall; "high mana, low ap" spends the same budget differently. So a model writes what it reads.
    - **A plainly named reserve is a preference with teeth** (lead): `Unit._funding()` pays from it first (after a needed one) when it can; `only` / `needs` compile to the existing `Skill.needs`, one source at run time.
    - **One resource per skill**; **health costs are refused** (`health`, `hp`, `life`): no HP costs exist yet, so a mechanic for `new-mechanic` first.
    - **Weights to costs:** with q = p(1) + g x (p(r) - p(1)) (g: flat 0, scaled 1, steep 2), AP = clamp(round(ap_base + q x ap_per x w_ap), 1, ap_max), cost = round(q x energy_per x w_cost). "even" reproduces the old priced rule exactly.
    - **Rank word on the whole price** (flat, scaled, steep), not per dimension (lead). `steep rank` doubles growth past rank I; `flat rank` prices every rank as rank I.
    - **Migration is mechanical:** `Util/terms.gd infer` keeps a profile only where it reproduces the hand AP and cost exactly at every rank 1..max (5 if uncapped); `skill.py migrate` wrote **48 hand prices**; **38 stay hand-set** (no profile fits; listed in the plan, incl. the seven cost-x-rank starter spells). **26 of the 48 carry "flat rank"** (their terms grow with rank, their hand price did not); you may want those to scale, which would be balancing, so not done. With emblems on, a migrated skill now prices by its profile under modifiers rather than hand x points ratio: small differences, accepted as rounding.
    - **Tool:** `skill.py new --cost "high mana, low ap"` (default "even"; `--hand-priced --ap N --cost N` still hand), `skill.py cost <id> "<profile>"` or `cost <id> hand --ap --points`, `migrate`; `check` parses every profile and checks `only X` against `needs`; `skill.py cost` refuses to drop an existing `needs` silently. `.claude/skills/new-skill` documents it.
    - **Tests:** new `Tests/costs_test.gd` (profile table, every profile, funding preference); changed to the new rule: `modifiers_test.test_priced`, `energize_test`, `route_test.test_missed`, `route_test.test_requirement_paths`. Four mutation spot-checks. Suite 9522 / 931 tests to 9702 / 934, 0 failed.
    - **New names to review:** none (the profile words are yours or plain English).
- [x] **The 26 "flat rank" profiles**: OK as built (the user, 2026-11-19, ?185 to ?191). (?190)
- [ ] **The 38 hand-priced actives** stay hand-set; give one a profile with `skill.py cost` once its terms are parameterized. (?190)
- [ ] **Health costs** (`high health`) are refused: no HP cost mechanic exists. (?190)
- [ ] **Emblem pricing of migrated skills** differs slightly from the old hand x ratio: confirm rounding is fine. (?190)

191. **Parameterizing the concrete skills - built on judgement, open for review (2026-11-18).** Your words: "if in doubt for a skill that isn't properly parameterized with difficulty, scaling / it's overly concrete, that's a signal that it needs to be parameterized or scaled better on rank and stats"; "any underpowered skill should be easy to tweak using check difficulty"; "don't focus on balance at present". Plan: `docs/plans/w2-param.md`. Calls, those marked (lead) are the lead's readings of your words:
    - **Count:** 29 ineligible before (the 27 of ?133 plus Final Act and Striking Intellect), **22 after**; tags-only 5 to 4. No AP, cost or profile touched.
    - **Rule for "can be parameterized"** (lead): it holds a number (a count, bonus, duration, size) that can read rank through the declared channels with rank I exactly as before. Rank II and up is new scaling, which is what you asked for, not a rebalance of rank I. A max-rank-I passive still scales: a Density emblem reads rank I as II.
    - **Favour** (luck +1, mitigation 1%) goes `per_rank`: **reverses ?133's call** that this would rebalance; your later words say concrete is the signal. **Hazard Expert** (trap word x(1 + rank)) and **Move +1** (movement + rank): `per_rank`, data only.
    - **Basic Martial / Magic / Specialist Skill Slot +1:** `per_rank`; slots now read rank through the holder's modifiers (`Unit._grants()`), so **a Density emblem doubles a slot passive's count** (2 slots at rank I).
    - **Final Act:** its free actions are its rank (1 at rank I); the AI's `reprisal()` weighs that many.
    - **Gallantry:** its cha check gets +1 a rank past I (`CHECK_PER_RANK`). **The check's difficulty is a behaviour constant**, not a `Skill.check` on a passive (`ranked` would add +1 at rank I; a `Skill.check` on a passive would make the AI and HUD read it as a cast). To carry it, `Reaction.contest()` / `odds()` take an optional `bonus` (default 0), a generic hook any reaction's check can use.
    - **Stonegift:** `turns = 2, turns_per_rank = 1` (3 turns at rank I as before, +1 a rank); hand price untouched.
    - **Stays concrete (22), reasons in the plan:** binary switches (Arcanist, Physical Intelligence, Everyman, Field Experience, Working Knowledge, Decisive Strike and Mastery, Powerful, Synergy, **Striking Intellect**: a stat selector, and the roll code was off limits that round); Elemental Mastery (already scales through Strike's `element` term); penalties and traits (Oceanic, Reckless Abandon, Vaporize); the eight build-time gates (Generalist, Journeyman, Martialist, Thaumaturgist, Divinity, Mastery, Symphony, Witchery: an emblem coming off would strand picks); tags-only Coalescing, Energy Missile, Stoneskin (rank would need new content).
    - **Check difficulty:** none of the 29 had a `SkillCheck` to tune; the numbers are now data (`per_rank`, `turns_per_rank`) or one named constant. **Interject's and Snapping Turtle's checks do not use `bonus` yet**; queued.
    - **Tests:** `Tests/param_test.gd` (PARAMETERIZED gains nine; `test_concrete_scaled` one table: rank I as it was, rank II more, Density reads I as II; plus Favour's mitigation, Reaction bonus, Gallantry's text). Four mutation spot-checks. `skill.py check`: ok.
    - **New names to review:** none.
- [x] **Wire Interject's and Snapping Turtle's checks to `Reaction` `bonus`.** Queued (`docs/queue.md`). (?191) Found already built (?217).
- [ ] **The 22 left concrete** (see ?191): confirm which should stay; tags-only Coalescing, Energy Missile and Stoneskin would need new tiers. (?191, ?133)
- [ ] **Gallantry's check difficulty** is a behaviour constant; confirm, or say where a passive's check should live. (?191)

## Wave 3 (2026-11-19): facing, traits, exhaustion, lent skills

The user's second batch of 2026-11-18 (`docs/agents/answers-2026-11-18b.md`) built on `w3-facing`, `w3-traits`, `w3-exhaust`, `w3-lent` (plans `docs/plans/w3-*.md`). Baseline suite 9756 checks, 0 failed (936 tests).

192. **Facing, forced moves, shove and cc - built on judgement, open for review (2026-11-19).** Your words: "intentional unit actions only: pushes / warps etc don't count"; "`shove` should only apply to skills that apply the force to a unit itself. fear would technically be the unit itself deciding to act ... it *would* face the direction it is moving, and it should probably spend movement AP accordingly. tag it `cc` if needed ..., any skill or effect that infers penalties on a unit's ability to act needs to be tagged as such." Plan: `docs/plans/w3-facing.md`. Calls:
    - **Reverts ?188's forced turn:** push, pull, send and every other move by another's force leave facing alone.
    - **Self-driven moves are named by tag** (`Battle.SELF_DRIVEN = [fear, entrance]`), not a flag: `displace()` with such a tag turns the unit along the move and charges the tiles (real step cost, `stride()`) to movement and move AP (`Unit.walked(.., compelled)`). A later effect carrying the tag joins. Alternative: a boolean on the move.
    - **Compelled pays what it has and goes anyway:** fear on a foe's turn, or with less AP than the walk costs, still flees, paying `min(cost, AP left)` (`moved` goes up by the full cost; at its own turn start `_frighten()` takes it off the fresh pool). Alternative: a unit out of AP ignores fear (made fear useless on units that had spent their turn).
    - **Entrance counts as self-driven** (Sing's draw: the enraptured walks to the singer, faces it, pays move AP): only fear was named, entrance is its sibling (my reading). Alternative: entrance a plain pull.
    - **Slam unchanged:** a flee or draw stopped short still slams (the code did; `Effect.describe` says only shove hurts). Not touched; for you to say.
    - **`shove` on skills:** Kick (push) and Send Off (teleport away); Kick's pushes carry the `shove` move tag and credit the kicker. Not tagged: Sing (a draw: entrance, cc), Switcheroo (a trade of places), Drown, Hitch and Coalescing (grapples: held, not driven).
    - **`cc`** declared `mechanic.py tag cc --human` (term "CC", kind condition, colour `#a5a1c9`, a placeholder). New `mechanic.py carry <tag> --skills --effects --inline skill:stat` tags what exists; `Effect.bears` and `Unit.afflicted(tag)`. No rule reads cc yet.
    - **The cc audit** (255 skills, 15 reusable statuses, inline statuses). Tagged: Stun, Jam, Slam Jam, Hitch, Drown, Coalescing, Brainfog, Interdict, Bludgeon (Winded), Sing, Mindless Fury (the user is helpless: self-inflicted, tagged all the same; say if not); statuses Stunned, Jammed, Winded, Traits Suppressed, Hitched; inline Grappled, Interdicted's base AP, Mindless. Considered, not tagged: Level Down, Haluca, Humble, Hex, Showstopper, Phantasm, Breathtaking, Soaked, Blinded (a penalty, not a stop), Judgement and its Shackles, the Stew tile's sleep, and the fear, shove and entrance effect stats themselves.
    - **Tests:** `facing_test.test_latest_wins`, `displace_test.test_any_skill_knocks_back` and `test_draw_in`, `forced_test.test_the_three_effects` changed; new `forced_test.test_cc_and_shove_are_tagged` (one table over every skill and status). Mutations (each failed, reverted): turning on every displace; cc stripped from Stun.
    - **New names to review:** none (`cc` and `shove` are yours).
- [ ] **Confirm the cc audit's edge cases:** Mindless Fury tagged (self-inflicted); Level Down, Humble, Breathtaking, Soaked, Blinded left out. (?192)
- [ ] **Should the slam apply to a flee or draw stopped short?** Unchanged: it does; `Effect.describe` says only shove hurts. (?192)
- [ ] **No rule reads `cc` yet** ("certain equipment or skills may make them easier to deal with"): a resistance would read `Unit.afflicted()`. (?192)
- [ ] **No skill carries fear**; one that does should bear `cc`. (?192)

194. **Traits by tooling, Skill Slot +1, always-on passives - built on judgement, open for review (2026-11-19).** Your words: "Traits are best explicitly specified by builder skill / script tooling"; "skill slot +1 adds it to the unit's *hotbar*, and it sits on the far right ... it is a *trait* when learned ... it still costs points to learn for the first time ... If it's applied as an *item*, it can be disabled the same way other equipment effects can be disabled"; "always on passives should have no indication they are 'on' or 'off' whatsoever". Plan: `docs/plans/w3-traits.md`. Calls:
    - **The declaration is the tag, written by tools, checked:** `skill.py new --trait` (implies `--passive`, needs no tree), `skill.py trait <id> [--off]`, `unit.py trait <unit> <skill>[:rank] [--off]` (moves a skill onto a scene's `innate`, refuses a non-trait), `unit.py new --trait`; `--skill` naming a trait dies pointing at `--trait`. No `Skill.gd` field. Nothing was inferred at run time before; the loose part was authoring.
    - **Checks** (`check_traits`): a trait must be a plain always-on passive, not a pillar or foundation; a scene listing a trait under `learned` fails with the fix. Not made: "an innate always-on passive must be a trait" (Powerful and Starsap on Starmote and Starman are innate and slotted on purpose).
    - **Migration:** Siren's Alluring from `learned` to `innate` (rank 4 kept).
    - **Skill Slot +1** is a trait with one untyped `slots` Effect, `max_rank` 1, on the Adventurer's centre, tier 1; one point to learn (so "costs points the first time" holds). Mastery gating ("used to reward mastery") is left to where it is offered; a prerequisite on the centre needs machinery that doesn't exist. Alternative: gate it behind filled slots.
    - **Item version:** an item lists it in `Item.skills`; the slot goes when the trait is suppressed or the item taken off. No real item written (`item.py new ... --skills skill_slot` makes one).
    - **`Unit.bar_size()`** (sure slots + granted + clover) is the hotbar's one read; `clover()` and `burning_slots()` keep their own sums on purpose.
    - **(?165)** `SkillSlot.brightness()`: an always-on passive is bright whatever its unit can do now; a toggle dims when off or unusable, an active when unusable, a trait while suppressed. The tooltip's "Always on" spec word stays (kind, not state).
    - **Tests:** `equip_test.test_skill_slot` (new), `test_slot_switch_dot`, `adventurer_test`, `hud_test.test_adventurer_skills_screen` changed; mutations failed and reverted (brightness ignoring always-on, amount 0, trait under `learned`). Suite 9769 checks, 0 failed (937 tests).
    - **New names to review:** none.
- [ ] **A slightly darker untyped granted slot** (ui.md): needs a slot kind; Cram's card (?198) built a dashed rim for bonus slots instead and left this. (?194, ?3)
- [ ] **Skill Slot +1's mastery gating**: offered on the centre, learnable at once; say if it should wait on something. (?194)
- [ ] **A real Skill Slot +1 item** (none exists; the test builds one). (?194)
- [ ] **To do for the floater:** `.claude/skills/new-skill`, `new-unit` and `new-mechanic` should mention `--trait`, `unit.py trait` and `mechanic.py carry` (`.claude/` is out of bounds for builders and keepers). (?192, ?194)

195. **Exhaustion retune, Burnout, Recovery Endurance, Deathlust - built on judgement, open for review (2026-11-19).** Your words: bad things "should really only start happening on the second cast of the same regular ability, third caster skill cast in a row, or fourth skill use on the same turn"; "`Burnout` child of exhaustion. All `int` skills use `Burnout` ... with increased penalties for `int` skills and harsher exhaust effect on `mana` costs"; ?182 "1 tile per rank + 1 ... effect itself will be curved so consider a percentage". Plan: `docs/plans/w3-exhaust.md`. Calls:
    - **One pressure** (`Exhaustion.of()`): each prior use weighs `1/SAME` against the skill itself, `1/IN_KIND` against its broad kind, `1/ANY` against every other skill; `SAME 1`, `IN_KIND 2`, `ANY 3`. Mixed patterns add. Below 1 the rate rises `MILD` 0.1 a unit; from 1, `STEP` 0.5. The jump at 1 is deliberate. Alternative: a smooth ramp.
    - **"In a row" and "in a turn"** read as uses not yet recovered (counts fall 1 a side-turn), not a streak reset by an off-kind skill: no new counter. Alternative: a real streak counter.
    - **General skills are no longer special:** every skill weighs 1/3 on every other (was 0.25 and only general ones).
    - **Added cost rounds to nearest** (`Exhaustion.raise()`), the base still rounds up, so a mild wear under half a point adds nothing.
    - **Burnout** (`Burnout.of()`, `int`-tagged skills, 26): same thresholds; wear times `Burnout.PENALTY` 1.25; on a cost paid from a reserve that burns, times `Reserve.burns` again (Mana 1.5): a 3rd caster spell in a row costs 1.94x Mana, 1.63x Energy. AP is not harsher on Mana (you said costs); Energy standing in for Mana isn't. Burnout is a rule term, not a tag; `mechanic.py` can't edit a rule's Glossary term, so `Glossary.gd` was edited by hand.
    - **The old Burnout rule (?121) is renamed Recovery Endurance** (your own term): `Scripts/RecoveryEndurance.gd`, `recovery_endurance_test`; its Glossary text folded into `recovery_endurance`. Alternative: fold it into the new Burnout. HUD chip "Burnt -3 HP", `Unit.burnt` and `burn()` kept.
    - **Tooltip and pips:** "burnout x1.5" for an int skill, "exhausted x1.5" otherwise; slot pips show pressure (a whole pip bites).
    - **Deathlust:** radius = rank (rank I: adjacent, diagonals too, plus self), my reading of "1 tile per rank + 1"; relief `1 - 0.75^rank` of every skill's count (25%, 44%, 58%, 68%) through `rank_impact`, `Exhaustion.relieve_share()`; hooks `neutralized` and `wearing` kept.
    - **Tests:** `exhaustion_test.test_counts` (rewritten), `test_burnout` (new), `test_costs`, `test_channel_is_one_use`, `stamina_test.test_eases_exhaustion`, `deathlust_test.test_deaths_in_range`; `burnout_test` renamed `recovery_endurance_test`. Seven mutations failed and reverted. Suite 9807 checks, 0 failed (942 tests) after the merge.
    - **New names to review:** `Reserve.burns` ?? (a Reserve field).
- [x] **Cram's multiplier on the Burnout penalty**: built 2026-11-19, `Unit.slot_penalty()` in `Burnout.penalty()` (?198). (?195)
- [x] **No museum-sim retune check after the retune** (the AI reads `rate()` unchanged). (?195) Built 2026-11-19 (?207): Hex does not outscore Strike in uses (Strike 12, Hex 5 after; Hex 3 before).
- [ ] **Confirm the numbers:** `PENALTY` 1.25, Mana `burns` 1.5, `MILD` 0.1, the 1 - 0.75^rank curve. (?195)

196. **Lent skills: enchantment, armor as equipment, prerequisites - built on judgement, open for review (2026-11-19).** Your words (answer 8, ?143): the item is enchanted, so its lent skills are too, "+1 to rank" unless a skill has its own enchantment effect; "the armor effect itself should be implemented as an `equipment` skill, generally one that grants +armor"; lent skills can be prerequisites, and "if the unit loses the skill for any reason ... any dependent prerequisite skills would disable as well". Plan: `docs/plans/w3-lent.md`. Calls:
    - **Enchanted lends:** already +1 rank (`Item.skill_rank()`); new is the exemption, a generic hook `Behaviour.owns_enchant()` (`Skill.enchants()`), not a flag or Effect field; armor is its first user. Pray never raised an armor's own rank, so drag stays. Alternative: an `Effect` field.
    - **`equipment` tag** (yours) declared `mechanic.py tag equipment --human --kind target`, colour `#a7a79a` (my pick).
    - **Armor is a skill:** `Skills/armor.tres` ("Armor", passive, `equipment`, `ai = true`) with `Behaviours/armor.gd` (hook `Behaviour.armor(holder, rank, item)`); the formula moved out of `Unit.armor_defense()` unchanged; `armor_defense()` sums what the worn armor's equipment skills set (`Unit.armor_skills()`), unarmored (dex + con mod) with none working. Armor owns its enchantment: +1 Defense when the item is `enchanted()`; so an armor authored with the tag `enchanted` now also gets +1 Defense (none in Items/). The item keeps its table (weight tag, `no_dex`, `full_dex`, `mind_stat`, `eases`); the skill is the carrier.
    - **Equipment behaves as a trait** (`Skill.is_trait()` true: no slot, not disabled by skill-disabling), so traits suppressed takes armor's Defense away; not listed in `Unit.traits()` (the HUD strip would show every unit's Armor); `Skill.is_equipment()` says which. Alternative: list it.
    - **Migration:** `item.py lend armor --slot armor` (new) lent it to all nine armors; `item.py check` fails an armor lending none; `skill.py new --lent` for a skill only items lend. No fallback for an armor with none: test armor gets it (`bulwark()`). Defense of all nine armors at levels 1/9/30 x dex 6/10/14/20, plain and Pray-enchanted, and Robe's magical Defense matched the old tip (28ae12a).
    - **Prerequisites:** one read, `Unit.counts(x)` (learned, or lent and working); `reached()`, root `needs`, tier and category needs read it. A skill learned on a lent one is marked (`Unit.leaned`) and `lapsed()` when the prerequisites no longer hold; dependents lapse too; it all comes back with the lent skill. Calls: a lapsed skill keeps rank and slot and is switched off; authored units never lean (only `unlock()` marks); `lapsed()` reads no effects, so Reckless Abandon's skipped steps aren't given while judging; `Unit.leaned` isn't saved; Pray's enchant on a lent prerequisite doesn't matter; no respec exists so `leaned` has no removal.
    - **Tests:** `lent_test.gd` (new, 3 tests, 72 checks), `test.gd`, `equip_test`, `sweep_test.test_item_skills`; five mutations failed and reverted.
    - **New names to review:** Armor.
- [x] **`Unit.leaned` is not saved**: a loaded unit that learned on a lent skill won't lapse when it loses it. (?196) Plumbed 2026-11-19 (?207): `Unit.lapses_out/in`, `Game.lapses`, a Save `lapses` key; nothing fills it until learned skills are saved (next line).
- [ ] **`counts()` doesn't ask `equipped()` of a lent non-trait**: a lent skill left off the bar still counts. (?196)
- [x] **Power Armor and Scrap Plating** read `armor_skills()` and the `armor()` hook: built 2026-11-19 (?200). (?196)
- [ ] **Should Armor show in the HUD trait strip?** Not listed now. (?196)

## Wave 3 and 4 tail (2026-11-19): the Coyote set, Density eligibility

201. **Coyote Charm and Coyote Scepter - built on judgement, open for review (2026-11-19).** Your words (answer 8 of 2026-11-18b, the Coyote paragraphs): an epic trinket and an epic weapon with the Curse of the Coyote (`curse`), generic "disable" and "instant death" hooks, Borrowed Time when enchanted. Plan: `docs/plans/w4-coyote.md`. Calls:
    - **Readings:** "skills are disabled" = `Unit.disable()` (Brainfog's slot disabling); stuns, sleep and Traits Suppressed are cc statuses, so the Charm ignores them. "Instant death" = dying with HP left (Death and Luun's Smite set `hp = 0`); Borrowed Time (the `defer` stat) is reused.
    - **Two generic hooks, no item flags:** `Unit.disable(s, turns, curse, by)` emits `disabling(u, d)` (mutable `d`: skills, turns, curse, by); `Unit.slay()` is the one place an instant death happens and emits `slaying(u, d)` (`d.defer` puts the victim on borrowed time). Battle asks the disabler's then the target's passives (`Behaviour.disabling()`, `Behaviour.slain()`); Death and Luun's Smite call `slay()`; both added to `skill.py` `HOOKS`.
    - **Defer-disable is a status, not the item:** new Effect stat `postpone` ("Disablings postponed ??"): disablings go to `Unit.postponed` (not counting down) and curse debuffs (statuses bearing `curse`) don't tick, any curse, not only the Coyote's (cuts both ways). When the last postpone goes (tick or dispel), what was held lands for its full turns (`Unit.release()`). Held disablings aren't shown on the hotbar. Alternative: the item holds them.
    - **"Must be overcome" is a stat `overcome`** ("To be overcome ??", harmful): cleansing takes its ranks before any other debuff's; a heal (`Battle.mend()`) only wears max(power, 1) of its ranks away and does nothing else; plain `heal()` (potions) and dispels aren't stopped. A Downed unit's Resuscitate can be eaten by it (harsh, as the rule says).
    - **Duration:** the Charm buff and the Curse last rank turns (+1 on the unit's own turn), at the lending skill's rank; the curse goes on last (rightmost). A buff already up isn't renewed, so repeated disablings can't stall forever; later ones join the held pile.
    - **Enchanted Charm:** its behaviour owns the enchantment (not ranked up): an instant death on its last life (no hearts, not Downed) puts it on Borrowed Time for rank rounds; any enchantment counts (the tag or Pray's).
    - **Scepter:** disablings its wielder causes get + rank turns, and the target the buff and curse at its rank. Net: the disable waits rank turns, then lasts rank longer.
    - **Items:** Coyote Charm (epic trinket, magical, lends the skill Coyote Charm) and Coyote Scepter (epic blunt weapon, magical); lent skills tagged magical, curse. No loot table yet.
    - **After the merge the floater edited both Coyote skills with a `no_density` reason** (Density can't trade on them), as ?203's check demanded.
    - **Tests:** `coyote_charm_test.gd` (postpone, overcome, scepter, instant death); six mutations failed and reverted.
    - **New names to review:** Disablings postponed ??, To be overcome ?? (Effect stats `postpone`, `overcome`). (Coyote Charm, Coyote Scepter, Curse of the Coyote, `curse` are yours.)
- [x] **Coyote items are in no loot table**, and the AI doesn't weigh the postpone or the curse. (?201) Built 2026-11-19 (?213): `Loot/astral_princess.tres`, and the AI weighs a postponed disable (`DELAY`).
- [ ] **Postponing stops any curse ticking and holds any disabling** (not only the Coyote's); say if it should be Coyote-only. (?201)
- [ ] **A Downed unit's Resuscitate can be eaten by `overcome`.** (?201)

203. **Density eligibility and its bargain - built on judgement, open for review (2026-11-19).** Your words (answers of 2026-11-19, the 185-191 block): eligible if a skill has a scaling component and a penalty component that can be boosted or tamped down; dense skills "scale harder with vastly reduced range, have dramatically more difficult checks to pass / easier to overcome for enemies", diluted the reverse; "if this cannot be accomplished in a relatively balanced / faustian bargain manner, the skill is ineligible ... make as few of them ineligible as possible". Plan: `docs/plans/w4-density.md`. Calls:
    - **Checks read from the caster's side:** a dense skill is harder for its user to land (attack rolls, the saves and contests it imposes) and easier for foes to resist; Diluted the reverse. One number, a shift on the caster's side of every check the skill makes.
    - **"Scaling ... and a penalty" read as AND, both ways** (Density and Diluted share the rule): rank impact to boost or tamp down, and something that makes the skill harder or easier to land. A skill with no rank impact is ineligible for Diluted too (Clairvoyance, Solar, Peel, Send Off no longer fit through rank range alone).
    - **Range:** Diluted's "range scaling buff" literally, rank range x (1 + f); Density's "vastly reduced range" nullifies rank range *and* divides the whole range by (1 + f), never below the neighbouring tiles.
    - **The penalty component** (`SkillTerms.trades()`): a range, a check (attack roll, save, contest or a behaviour's declared check), **a slot a foe can disable** (every skill but a trait: dense skills are easier to disable, `Unit.slot_weight()`), or a penalty (the Terms group's: Cram's wear). The disable trade is my reading of "easier to overcome for enemies" for passives; without it ~95 more passives were ineligible. It makes the rule mostly "has rank impact, isn't a trait". Alternative: demand a stronger cost of passives.
    - **Knobs:** `Modifiers.DENSE_CHECK = 5`, `DILUTE_CHECK = 3`, times f (a rank I Sigil: -4 / +2): first cut, untuned ("tune by check difficulty").
    - **One read for the shift:** `Battle.requirement()`'s + hit carries it (attack rolls, Strike's chain, saves, contests, engulfs, Level Down, Last Stand, the forecast's `hit_chance`); behaviour checks via `Cast.check_shift()` (Hitch, Slam Jam, Stun's DC, Wildfire's dodge DC) and Gallantry's bonus.
    - **Declared reasons:** new `Skill.no_density` ("`no_density` ??", Terms group): **FLAG_CEILING went up 103 to 104 (`Util/skill.py`), against the rule that the ceiling only goes down** (CLAUDE.md: a field every skill shares was the stated exception, and this is one, but it is a field on a data resource). `skill.py check` runs `Util/terms.gd density-check` (a skill the rule finds ineligible must say why; one that says why but fits is flagged); `skill.py density`, `skill.py terms <id>`, `new --set no_density=...`. **Alternative:** no field: a `no_density` tag (shared and visible, the composability way) or a declared reason in the Terms group's data, so the ceiling stays 103. Which?
    - **Parameterized (rank I unchanged), 10:** Stun (DC rank and turns), Power Armor, Scrap Plating, and seven single-tier blows given `dice_per_rank` (Crushing Blow ??, Rake, Savage Swing ??, Waterstrike, Energy Missile, Gank, Sutemi): rank II+ is new scaling (2 dice at II), not a balance pass.
    - **Wildfire's reach_scale range** is not cut by Density's reach (only its rank range). Small; left. **Cram** unchanged, eligible; a Cram row in `param_test`.
    - **Ineligible: 140 under the bare rule, 45 with the disable trade, 35 now**, each with a declared reason: alluring, starkind, skill_slot (traits: no cost to trade); arcanist, physical_intelligence, everyman, field_experience, working_knowledge, decisive_strike, decisive_mastery, powerful, synergy, striking_intellect, elemental_mastery (a switch, selector or gate); generalist, journeyman, martialist, thaumaturgist, divinity, mastery, symphony, witchery (a build gate: an emblem off would strand picks); clairvoyance, peel, send_off, solar (rank buys only reach); mage_armor, manifest, relay (stat impact only: rank adds nothing yet); coalescing, stoneskin (a fixed roll or share: rank would need new tiers); armor (Defense by the item); oceanic, reckless_abandon, vaporize (a drawback only, an inherent trait, a toggled form); and the two Coyote skills (the floater's reasons).
    - **Tests:** new `param_test.test_density` (range, attack, forecast, slot weight both ways; Stun's DC; trait vs slotted; Clairvoyance); updated `modifiers_test.test_symbols`, `route_test.test_save_rank` / `test_area` / `test_aura` / `test_rift_look`, `param_test.test_move` / `test_clairvoyance` / `test_concrete_scaled`, `skills_test` QUIET; five mutations failed and `skill.py check` caught a dropped and a stale reason.
    - **New names to review:** `no_density` ?? (a Skill field).
- [x] **FLAG_CEILING raised for `no_density`:** keep the field, or replace it with a tag or a Terms-field entry (ceiling back to 103)? (?203) Answered 2026-11-19 (?210): the no-new-flags rule is relaxed, the field stays; listed as a flag to confirm (?203).
- [ ] **Passives' only trade is the disable weight:** is that a fair bargain? (?203)
- [ ] **Give the 35 a rank-impact term where the user's "as few as possible" asks:** Solar's damage, Send Off's turns, Clairvoyance, Peel (reach only); mage_armor, manifest, relay (`per_rank` on the effect); coalescing, stoneskin (new tiers). Queued. (?203)
- [ ] **The check-shift numbers** (`DENSE_CHECK` 5, `DILUTE_CHECK` 3) and the blows' new rank scaling are untuned. (?203)
- [ ] **The AI does not read the check shift or the disable weight** beyond the forecast. (?203)

## Wave 4 card C (2026-11-19): balance knobs

204. **Balance knobs - built on judgement, open for review (2026-11-19).** Your words (answers of 2026-11-19): "consider optional base/symbol scaling coefficient properties on tags like Impact, Range, Modified ... keep em in our back pocket and test on a few obvious ones"; a "β +-(beta) tag, for outliers it tweaks scaling to be stronger or weaker", visible only to units with `very high` int; a `d` (Cohen) tag (early ranks stronger or weaker, smoothing out with rank); "apply it to an obvious skill to test the feature itself and leave it alone for now". Plan: `docs/plans/w4-knobs.md`. Calls:
    - **Readings:** "Impact, Range, Modified" are the scaling channels (rank impact, rank range, and the stat channels). `Skill.scaling` is one coefficient per word (default 1), a factor on the channel's k, so it stacks with a symbol (x2 and Density x1.5 read x3); under 1 a rank never reads below rank I (Kick at rank I would otherwise reach half a tile).
    - **β:** tags `beta_up` ("β+") and `beta_down` ("β-"), k x1.25 or / 1.25 on all four channels (`Modifiers.BETA`). **d:** tags `cohen_up` ("d+") and `cohen_down` ("d-"), rank impact reads `1.5 / rank` more or less than the rank itself (impact only; `Modifiers.COHEN`). **The dial values 1.25 and 1.5 are first cuts, untuned.** Alternative: other values, or d on every channel.
    - **FLAG_CEILING 104 to 105 for `scaling`** (the coefficients need a number, a tag can't carry one), against the ceiling-only-down rule, as `no_density` was. Alternative: no field; one tag per coefficient value, or a Terms-field entry.
    - **"Very high" int is 16, and the holder is the viewer.** No int-gated visibility existed, so `Modifiers.sees_knobs(u)` = int score >= `VERY_HIGH_INT` 16 (the adventurer's 16 in every stat qualifies; a Fighter at 8 does not). Only the tag is hidden (`Skill.markup(rank, with_spec, u)`); the numbers a knob changes show to all, being true. Alternative: another threshold, or the viewing player's best int (`HUD.eyes()`), which needs a viewer argument on `markup`.
    - **Price unchanged by a knob** (`Modifiers.priced()` drops them): a nerf should not also make a priced skill cheaper. A knob is no emblem and is never labelled.
    - **Tools:** `skill.py knob <id> [--impact|--range|--modified X] [--beta +|-|off] [--cohen +|-|off] [--clear]`, `skill.py knobs`; `skill.py check` runs `terms.gd knobs-check` (a coefficient on a channel the skill lacks, 1 or negative, both + and -, β on a skill that scales by nothing, d on one with no rank impact). The four tags were declared with `mechanic.py tag --human`.
    - **One skill each, to test the feature:** Kick `scaling range = 0.5` (docs/plans/ai-sim.md: "Kick dominates Strike on price even in the open"; reach now 1, 1, 1.5, 2, 2.5 tiles); Gank `beta_up` (weakest of the Slayer set, never chosen by the sim); Spike `cohen_up` (dear and weak early: rank I reads as III). `modified` has no skill. Alternative: other skills.
    - **Tests:** new `param_test.test_knobs`; `Test.untuned(id)`; `kick_test` and `ai_tactics_test` read an untuned Kick; five mutations failed and reverted.
    - **New names to review:** none (`scaling` is a Skill field, plain code name).
- [ ] **Is the holder's int the viewer, is 16 "very high", are the dials (BETA 1.25, COHEN 1.5) right?** (?204) Answered in part (?211): 16 is the `very high` entry (`Modifiers.KNOB_SIGHT`); the viewer and the dials stay for review.
- [x] **FLAG_CEILING raised for `scaling`:** keep the field, or replace it with tags or a Terms-field entry (ceiling back to 104)? (?204) Answered 2026-11-19 (?210): the field stays; listed as a flag to confirm (?204).
- [ ] **The Guide does not list β and d** (the knob terms are kind `target`, which no Guide page lists); decide whether it should. (?204)
- [ ] **No skill uses `modified`;** the AI does not read a knob beyond the numbers it changes. (?204)

## Wave 4 card D (2026-11-19): aggressive tagging

205. **Tag and parameterize the rest - built on judgement, open for review (2026-11-19).** Your words (answers of 2026-11-19, last line): "*do* aggressively tag and parameterize skills to make them easier to scale and tweak in the long run". Plan: `docs/plans/w4-tags.md`. Calls:
    - **What "cheap" meant:** a skill whose number can read rank (impact or range) through an existing mechanism (`per_rank`, `dice_per_rank`, `Cast.impact_rank()`, `holder_rank()`) and one `terms()` line, with rank I exactly as before; no AP, cost or price edited. Alternative: also allow rebalances (tiers, new costs) for the harder ones.
    - **Drown rank II+ is new untuned scaling** (`dice_per_rank` now also multiplies a grip's `drowns` dice: 2d12 a turn at II); Peel, Solar, Energy Transfer, Kick's riders and Slam Jam likewise. Alternative: tune by the knob or a d tag, or leave rank II+ flat.
    - **Coyote Charm and Scepter channel reads are inert until slotted:** item-lent, so `mods_on()` is `NONE` today; live when a tree teaches them. Alternative: leave them concrete.
    - **Fifteen skills got existing tags via `mechanic.py carry`, inert** (no rule reads a skill's condition tag yet): entrance, evadable, aura, concealment, held, disabled, channeled, wound. No new words. Alternative: no tags until a rule reads them.
    - **Gale and Judgement left untagged:** `forced_test.test_cc_and_shove_are_tagged` audits `cc` and `shove` by what a skill does (Gale is a stub with no displace; Judgement's shackles hold movement, not action). Discipline and role tags untouched, since the AI reads `offensive` and friends as intent. Alternative: tag them and change the audit.
    - **Still concrete, with reasons:** Clairvoyance (rank is only reach), Send Off (a teleport), Stoneskin (`per_rank` would double 40% to 80%: a rebalance, needs tiers), Elemental Mastery (scales through Strike's `element`). Alternative: give them rank-impact terms as ?203 asked ("as few as possible").
    - **Density-ineligible 37 to 29.** Tests: `param_test` (`test_concrete_scaled` rows, new `test_impact_reads`), `water_test.test_drowning_dice_per_rank`; seven mutations failed and reverted. Suite 10189 checks, 0 failed.
    - **New names to review:** none.
- [ ] **Are Drown, Peel, Solar rank II+ values right?** Untuned. (?205)
- [x] **Clairvoyance, Send Off, Stoneskin, Elemental Mastery:** give them rank impact (tiers for Stoneskin), or keep them concrete? (?205) Clairvoyance, Send Off and Stoneskin built 2026-11-19 (?212); Elemental Mastery stays concrete (scales through Strike's `element`).

## Wave 5 (2026-11-19): the AI's cc, saves, burn, difficulty words, density

206. **The AI prices cc by the foe's next turn - built on judgement, open for review (2026-11-19).** Your card: the AI weighs `cc` and `shove` (?192), and casts Chaser's interrupt and Heavy Strike's pool well (?193, ?202). Plan: `docs/plans/w5-ai1.md`. Calls:
    - **shove was already priced** (`Battle.foresee()` reads a skill's behaviours and its shove, fear and entrance stats; `_line_up` walks to the tile that tells most); checked by `ai_tactics_test`, no change.
    - **cc was a flat rider before.** Now `Behaviour.foresee` reports an `afflicts` key: Stun's p, Hitch's p x 0.5, Jam and Slam Jam x 0.25; `_threat()` prices it by what the foe's next turn is worth (`BLOW` 5, `CC` 0.5), reading the foe's cc statuses through its Read, so a foe already stunned is not worth stunning again. Alternative: another weighting for the 0.5 and 0.25.
    - **Chaser and Heavy Strike:** `friction_ahead()` counts a chase's later rolls at their friction; `Behaviour.Forecast` plus a `forecasting()` hook (Heavy Strike's pool: one blow lands only when its last roll does).
    - **New names to review:** none (constants and keys, not content).
- [x] **A defensive cc read:** built in ?231 (`AI._dread()`). (?206)
- [ ] **Crit-triggered loops are not forecast** (Chaser's chase, Jugular's recast). (?206, ?213)

207. **Save the lapses; the museum sim check - built on judgement, open for review (2026-11-19).** Plan: `docs/plans/w5-save.md`. Calls:
    - `Save.gd` keeps no unit state and learned skills are not saved, so `Unit.lapses_out()` / `lapses_in(d)` carry `{leaned, waived}` as plain JSON, `Game.lapses` holds it between battles, `Save` writes a `lapses` key only when non-empty (no version bump), `Battle.starter()` calls `lapses_in`. It keeps only skills the unit has learned, so in the live game it filters everything today; nothing calls `lapses_out()` at battle end.
    - **Sim check, no tuning:** `worn` sim: Strike 12, Hex 3, damage 28.00 before; Strike 12, Hex 5, 29.88 after, so Hex does not outscore Strike in uses. Where the AI scores plans (`armor`): Hex 5 vs Strike 3, unchanged. `rider` and `kick` identical.
    - **New names to review:** none.
- [x] **Save learned skills** (so `Game.lapses` fills), and call `lapses_out` at battle end. (?207) Built 2026-11-20 (?216): `Game.roster`, `Game.keep()`.

209. **Burnout is Exhaustion - built on judgement, open for review (2026-11-19).** Your words: "Burnout *is* RecoveryEndurance / Exhuastion functionally (effects that increase Burnout increase Exhaustion the same amount) it builds when casting and using int mod, and it decays slowly." Plan: `docs/plans/w5-burn.md`. Calls:
    - **No fold, no code change:** `Burnout` holds no state; it is a penalty multiplier on `Exhaustion`'s one `uses` count, so anything that adds or relieves a use moves both equally. It builds on a cast and an `int` skill wears harder (1.25x, more on Mana); it decays 1 use a side-turn, more on a rest. One line added to `exhaustion_test.test_burnout`.
    - **RecoveryEndurance stays separate:** a con-mod budget that counts down on recoveries and refills on a rest at full; folding it would drop your recovery design.
    - **New names to review:** none.
- [ ] **Should recoveries also add Exhaustion uses?** Only if "/" means RecoveryEndurance feeds the same count; a new rule, not done. (?209)

210. **The no-new-flags rule is relaxed - built on judgement, open for review (2026-11-19).** Your words: "I don't fully remember why flags are banned: I want to restrict creep but not anything that alleviate's dry and build's rich systems. at the very least new flags could be confirmed but yes lets relax that." Calls:
    - CLAUDE.md rewritten; `no_density` and `scaling` stay as Skill fields. FLAG_CEILING (105) is a creep alarm: raising it takes `python3 Util/skill.py ceiling "<field: why>"`, which records the reason.
    - The w5-ceiling attempt to move them onto tags or Terms entries was dropped.
    - **New names to review:** none.
- [ ] **Confirm the two flags:** `no_density` (?203) and `scaling` (?204). (?210)

211. **One difficulty table - built on judgement, open for review (2026-11-19).** Your words: "Let's standardize "high, very high" etc with obvious synonyms, based on previous scaling table for check difficulty: the same reference for setting difficulty checks on imposed effects, attack rolls, world interactions etc should be used". Plan: `docs/plans/w5-diff.md`. Calls:
    - **One table:** `Difficulty.WORDS` maps synonyms onto the `LADDER` rungs (low, light, easy = easy; moderate, medium, normal = standard; high, hard, heavy = difficult; very high, very hard, very heavy = unfair; extreme = impossible; none = trivial); `Difficulty.word/index/magnitude/stat_at`.
    - **Users:** `Modifiers.KNOB_SIGHT := &"very high"` replaces VERY_HIGH_INT (int 16 a named entry, `STAT_SCORE`); Pricing's cost levels hang on the rungs; Recovery Endurance's bare 12 is `dc(standard)`; `skill.py check_difficulty_words`.
    - **To review:** the synonyms I added (effortless, simple, average, hard, very difficult, extremely high); "very high" intensity reads `intense`.
    - **Left alone, with reasons:** DENSE_CHECK/DILUTE_CHECK (shifts, not rungs), Stun's roll_bonus -5 (a roll bonus), Gallantry, Interject and Snapping Turtle contests (the queue card for Interject and Snapping Turtle stays).
    - **New names to review:** none (words, not content names).

212. **Density: fewer ineligible skills - built on judgement, open for review (2026-11-19).** Plan: `docs/plans/w5-density.md`. Calls:
    - `no_density` reasons 29 to 26 (Mage Armor, Manifest, Relay, Peel, Solar, Coalescing earlier; now Clairvoyance, Send Off, Stoneskin). Clairvoyance's stacks are rank impact (`Battle.ping(stacks)`) and reach takes Density's cut.
    - **Send Off gained a ward** (mitigate 5% per rank from rank II, `turns_per_rank` 1); it lands on a foe sent away too: a design choice to review. `Battle._cast()` skips an effect below its `min_rank` (the generic hook for rank-gated effects).
    - **Stoneskin has a new tier:** 5% per rank from II above 85% HP; rank I as before.
    - **The remaining 26** are traits, switches, build gates, Armor, drawback and form skills.
    - **New names to review:** none.
- [ ] **Should a ward on Send Off reach a foe sent away?** (?212)

## Wave 6 (2026-11-20): equipment links, multi-slot skills, the Party, the audit

214. **Equipment-skill links: `innate` and `optional` - built on judgement, open for review (2026-11-20).** Your words (?196): "not a bad idea, just keep them light. Armor may provide skills that can be optionally added to hotbar in the future (`optional`), or skills that don't need a hotbar slot (`innate`)... those tags are associated with an equipment's association to a skill rather than the skill itself (Igna may be provided for no equip cost by a robe, and with a slot equip cost on a medium armor set)". Plan: `docs/plans/w6-link.md`. Calls:
    - **The flags live on the item's link:** `Item.innate` and `Item.optional`, two `Array[Skill]` each a subset of `Item.skills`; `Item.link(s)` reads them. No Skill.gd field, no link Resource (it would have changed every `skills =` line).
    - **Meanings:** plain = a slot, on the bar by itself as before; `optional` = lent, works only once the wearer puts it on the bar (auto-equip, auto-fill and `_fill_bar` leave it; the spellbook offers it); `innate` = no slot, always equipped while worn (suppressed with traits), listed with the traits.
    - **`Unit.slot_cost(s)`** is the one price in slots (0 for a trait or an innate lend, else 1: ?215 changes it there); `bar_place`, `equip_skill`, `auto_fill`, the spellbook drag and the bar's drop all ask it.
    - **Edges:** (a) innate means something only on an always-on passive; on an active or toggle it reads as plain and `item.py check` flags it, so your Igna (an active) is not innate-able until something can cast from outside the bar; (b) two items linking one skill: innate beats plain beats optional; (c) a skill learned as well as lent is the unit's own, the link is ignored; (d) a lend that turns innate gives up its slot quietly, one that turns plain auto-equips; (e) the rank is the best item's, whatever the link.
    - **Armor's `equipment` skill is innate:** `Skill.is_trait()` no longer includes `equipment` (tag kept); all nine armors lend Armor innate; `item.py check` (run by `skill.py check`) fails an item lending an equipment skill not in its `innate`: the old "never on the hotbar" hold, through the link. `armor_skills()` also accepts the item's own innate link (armor in a Plating slot).
    - **Tooling:** `item.py new --skill kick:innate|optional`; `item.py lend <skill> --as innate|optional`; `check` flags a flag on a skill not lent, innate on a non-passive, both flags, equipment not innate.
    - **No demonstration of `optional`:** Hobnail Boots' Kick is an active, and making it optional would change how the boots play; not done.
    - **Tests:** `lent_test.test_links` (24 checks); `equip_test`, `lent_test`, `test.gd` changed to the new rule; two mutations failed and reverted. Suite 10265 checks before.
    - **New names to review:** none.
- [x] **Innate on an active** (your Igna on a robe): answered and reworked in ?228 (a lend is free by default, a free active sits in the band and is used from it). (?214)
- [x] **Which item first uses `optional`?** None yet; `item.py lend <skill> --ids <item> --as optional` makes one (?228). (?214)
- [ ] **`SkillTerms` and `Skill.describe()` still decide "Trait" from the skill alone** (Armor reads "Always on", shown nowhere). (?214)

215. **Multi-slot skills - built on judgement, open for review (2026-11-20).** Your words: "some skills take up multiple slots. if no slots property / tag is specified it's default 1 / restricted as usual (martial skills may use martial bonus slots etc). Skills with a rarity take up multiple slots by default: Rare: 2, Epic / Very Rare: 3, Legendary: 4, Mythic: 5" and "most often, this will come up for high tier skills that need to be nerfed in some fashion." Plan: `docs/plans/w6-slots.md`. Calls:
    - **Rarity tags (skills had none; `Item.rarity` is an enum):** `rare`, `epic`, `very_rare` (a child of `epic`, shown "Very Rare"), `legendary`, `mythic`, named as you wrote them (no ??), Glossary terms of kind `target`, in `Tags.PLAIN`; `Skill.RARITY_SLOTS` maps them to 2, 3, 4, 5; two on one skill: the dearer wins. `Item.rarity` is not unified with them (a later call).
    - **An explicit price is a behaviour:** `Behaviours/slot_cost.gd` (`@export slots`) answers `Behaviour.slots_taken()`, standing over the rarity either way (1 makes a rare skill ordinary). No Skill field, so no `skill.py ceiling`; `skill.py check` allows it unused (`UNUSED_OK`) until your first nerfed skill.
    - **`Unit.slot_cost(s)`:** 0 for a trait or an innate lend, else `slots_taken()`. **A pillar always takes 1** (pillars are pinned to single sure slots).
    - **Representation:** the hotbar stays an `Array[Skill]`; a multi-slot skill sits in its first slot and the slots after hold null, "covered" (`covered()`, `anchor()`, `skill_at()`, `slot_free()`, `span()`); saves unchanged. Not the skill repeated in each slot.
    - **A run of one kind:** the slots exist, work, fit the skill's type and are all sure slots or all one granting skill's slots (Cram's three caster slots are one run; two Magic Slot skills' are not); never across the clover slot.
    - **Placing:** `bar_place(s, i)` takes the run from i and takes off every skill with a slot in it, announced; a skill landing on exactly one skill swaps if that one fits the freed slots, else it comes off; a pillar in the run refuses; `bar_clear` on any covered slot clears the whole skill; auto-placement looks for a free run (actives first, passives last). With no run the skill stays learned, unequipped.
    - **The sort (`_arrange()`):** a multi-slot skill goes through as that many copies; `_gather()` puts back one first slot or, if a copy was cut off, takes it off the bar whole (announced).
    - **Working:** `equipped(s)` needs every slot of its run unsealed and not idle in a bonus slot. In Cram's caster bonus slots a spanning skill works only if it carries the type for each slot; its Burnout wear is the highest bonus rank among its slots. **Density doubles what a skill's rank grants and leaves its price alone** (a rare skill costs 2 under any emblem). A burning slot burns a skill once.
    - **Disabling:** one skill is one entry in `disable_order()`; a disabling effect counts slots as ever, so **a 3-slot skill is cheaper to reach than three 1-slot ones**: part of the nerf, a number to tune.
    - **HUD:** a covered slot shows "(continued)" dimmed with the skill's stripe; a number key or click uses the skill; right-click unequips whole; a drop is `bar_place` on the slot clicked; a failed drop says "takes N slots side by side"; the tooltip says "Takes N hotbar slots ..."; no wider slot.
    - **AI** places nothing; NPC and monster bars set up through `_fill_bar()`, which looks for runs.
    - **Existing content:** no skill carries a rarity or SlotCost, so 0 skills take more than one slot; nothing re-tiered. With 4 sure slots at level 1 (5 at level 4) a Mythic (5) can't be on a bar before level 4 and a Legendary (4) fills a level 1 bar: whichever skill is tagged first decides whether that is meant.
    - **Tests:** `equip_test.test_multi_slot` (30 checks); four mutations failed and reverted. Suite 10279 checks before.
    - **New names to review:** none (the rarity words are yours).
- [ ] **Which skill is the first to carry a rarity or `slots`?** and is a Mythic unplaceable before level 4 meant? (?215)
- [ ] **A disabling effect counts slots as ever**, so a wide skill is cheaper to disable; keep as the nerf or weight by span (`slot_weight` is rank alone)? (?215)
- [ ] **A rare pillar skill (Cram) stays 1 slot; Density leaves the price alone.** Right? (?215)
- [ ] **Runs across two granting skills' slots** are not allowed; the wider HUD slot is built (?230); `Item.rarity` is not the same tags. (?215)

216. **Persistent roster and Party - built on judgement, open for review (2026-11-20).** Your words: "Go ahead and set up persistent units to keep track of saved skills / a configurable 'Party'. Party size is level / 4, + base cha mod if positive. at least 2." (the floor was replaced in ?226) Plan: `docs/plans/w6-party.md` (two builders; the first was interrupted). Calls:
    - **The roster:** `Game.roster`, the player's persistent units, each a `Unit.to_dict()` (side, class, name, level, XP, hearts, learned skills with rank, points and on, purchases, trees opened and picked, the bar by skill id, worn items by `Save.item_out()`, `lapses_out()`); `Unit.from_dict()` puts it back on a fresh unit of its class; a gone skill or item is left out; unspent points are level - 1 less what `purchases` spent.
    - **"Level" is the leader's:** `Game.party_size(lvl, cha) = max(lvl / 4 + max(cha mod, 0), 2)` (superseded by ?226: `max(cha mod, 0) + max(lvl / 4, 1)`, solo at 1) from `Game.level` (the hero, roster entry 0) and its class's base charisma (`Role.stats`), not effects in play; the leader counts toward the size.
    - **`Game.hero` stays the leader's record** and entry 0; `Game.level/xp/hearts/outfit/equipped/lapses` stay its live fields and win over the entry where both speak; its hearts are its class's plus `Game.hearts`, not the entry's.
    - **Who is on the roster:** a new game makes the leader plus one recruit of each other starting class, as new as it, named by its class (a stand-in until recruiting exists; no made-up names). The party starts as the first that fit.
    - **The Party screen** (`Scripts/PartyPanel.gd`): a "Party: n of m" button on Entry (when the roster has more than the leader); a box per member, the leader always ticked, others while there's room.
    - **A battle fields the party** (`Battle._field_party()`): each picked member as a unit of its class on the player's side, on the free tiles nearest the leader, following it (Command puts it in the leader's party from the start); Command's `party_size()` never drops below what was brought. NPC and companion class units stay fresh.
    - **Keeping:** `Game.keep()` reads each fielded unit back into its entry, and the leader's `lapses_out()` into `Game.lapses`; it runs as the battle leaves the tree and inside `Save.pack()`; every battle with a player connects it.
    - **Save version 2** adds `roster` and `party`; a version 1 file migrates (`Save.migrate()`: hero, level, XP, hearts, outfit, bar and lapses become the one entry) and writes back as 2.
    - **Bar with null slots** (from ?214, ?215): `to_dict` writes "" for an empty slot; `from_dict` sets it through `set_equipped()`.
    - **Tests:** `save_test.test_roster`, `test_migrate`, `test_party_size`; `Tests/run.gd` resets roster, party and fielded between files; five mutations failed and reverted. Suite 10304 checks, 976 tests. Visual: `S/shot_w6-party/`.
    - **New names to review:** none (class names are yours).
- [ ] **Recruiting and dismissing roster members in play** (needs the user: where recruits come from, names). (?216)
- [ ] **What a death does to a roster member** (a fallen member is not removed; permadeath is a design call). (?216)
- [x] **Party members' outfits can't be changed between battles.** Built (?234). (?216)
- [ ] **Is "level" the leader's the right reading** (vs the highest or the average on the roster)? (?216)

217. **Queue audit - built on judgement, open for review (2026-11-20).** Plan: `docs/plans/w6-audit.md` (skipped by instruction: the AI turn cost card). Verdicts:
    - **Interject's and Snapping Turtle's checks take the reaction bonus: already built** (`Interject.check_bonus()` feeds `contest()` in the `hit` and `snap` branches and `foils()`; Snapping Turtle re-asks Interject as `&"snap"`, so no code change); row in `param_test.test_concrete_scaled`.
    - **The AI casts Skeleton: built** (`AI._summon()` in `act()`; consts `BODY` 5.0 HP a body, `SUMMON_SEEN` a foe read within 10 tiles, `SUMMON_CAP` 12 units a side; not when posture is defensive or temper stoic; the cast tile is the free tile within the skill's reach nearest the foe). `Behaviour.bodies()` is a generic hook (overridden in `summon_per_rank.gd`), no Skeleton special case. Sim `host` in `ai_sim.gd`: bodies 0.00 to 8.00, every other line identical; damage 0.00 both (the skeletons don't reach the soaker 9 tiles off in 10 rounds). `BODY = 0` failed `test_ai_raises_host`; reverted.
    - **Hunt sim near variant: built** (`hunt_10v10.gd` `near`, `sweep.sh SIM=`); **no `AI.LOST` retune**, it stays 0.5.
    - **Edge-pan sideways: built** (`BattleCamera.gd` middle-drag; `meadows_test`).
    - **Deathlust AI awareness: partly.** Built: `AI._wear()` asks `wearing()` hooks, so a killing blow's exhaustion is unworn. Not built: the HUD float or log line on its relief; the AI pricing the relief a death in reach gives other counts.
    - **New names to review:** none.
- [x] **Retune `AI.LOST` with the near hunt sim.** Built, 0.5 to 0.35; the user picks (?233). (?217)
- [x] **A sim where Skeleton reaches the foe** (`hostnear`). Built (?233). (?217)

## Wave 7 (2026-11-20): facing and level in the glow, studies, Bard, preparation uses, art

Your words: `docs/agents/answers-2026-11-20b.md`. Each call below is for you to review.

218. **Facing in the glow - built on judgement, open for review (2026-11-20).** Plan: `docs/plans/w7-facing.md`. Calls:
    - **High wisdom is the word "high"** (`Unit.HEADING_SIGHT`); `Difficulty.STAT_SCORE` gains `difficult: 14`, beside `unfair: 16`. **14 is a pick: say if it should be 16** (then only adventurers and such read it).
    - **The viewer is `HUD.eyes()`** (the selected unit, else the observer); `Unit.reads_heading(viewer)` is the one rule.
    - **Every visible unit, own side and foes alike, except a silhouette**; a disguise gives nothing away (the lean is its true facing).
    - **A lean, not a pointer:** alpha up to 1.5x (`Unit.HEADING` 0.5) on the facing side, fading by `smoothstep(-0.1, 1, cos)`; the old chevron (`heading_tick`) is gone.
    - **Glow API:** `Scenes/UI/unit_glow.gdshader` on each unit's own `Glow` material; one uniform per thing the glow says; `Unit.glow_param(name, value)` is the one way in. `HUD.look_of()` gains `heading`.
    - **Tests:** `hud_test.test_facing_in_the_glow`; one mutation failed and reverted.
    - **New names to review:** none.
- [x] **Is wisdom 14 right for "high" in `STAT_SCORE`, or 16?** Confirmed by the user (answers-2026-11-20c). (?218)

219. **Studies UX and the top box - built on judgement, open for review (2026-11-20).** Your words: cut the message to "No studies left" and only on click; a magnifying glass by the mouse on a studyable tile or unit, grey if none left; the banner a top box, "Preparing" over a smaller "Study: X". Plan: `docs/plans/w7-studies.md`. Calls:
    - **`PhaseBox`** (`Scripts/PhaseBox.gd`): `show_lines(title, sublines)`, knows nothing of studies. **`HUD.prep_uses`** (a `Dictionary[StringName, Callable]`, insertion order, each returns its subline) is how a later use adds a line.
    - **Wording:** "Study: 1 ally, 2 foes or tiles" (zero parts left out; "Study: none left"); the bottom hint says nothing in preparation.
    - **The cursor is a sprite** following the pointer, up and to the right of the arrow so the unit tooltip is not covered; placeholder `Icons/UI/study.png` (`icon.py glyph study --shape magnifier`).
    - **Grey (`spent`)** when no study of that kind is left (ally by cha, foe or tile by wis) **or the thing is already studied** (my call: the same dead end the click calls "Already studied"). Not shown over the leader.
    - **Tests:** `prep_test.test_hud` extended; four mutations failed and reverted.
    - **New names to review:** none.
- [ ] **Should an already-studied thing grey the magnifier?** (?219)

220. **Bard: String Theory, Conductor, Symphony, `impact` - built on judgement, open for review (2026-11-20).** Your words: mid String Theory (the higher of int or cha for performance checks), high Conductor (rested last turn: + rank to command limits and range), Symphony (a bonus on checks for every check a commanded unit passes, up to rank; the first to act is First Chair, +rank impact on its first skill), `impact` in the Glossary. Plan: `docs/plans/w7-bard.md`. Calls:
    - **Performance checks are checks of `cha`-tagged skills.** String Theory is a stand-in (`Skill.stand_in`, the Meathead seam), tagged only `cha`; the stand-in's rank gate (the replaced stat at least 80/60/40/20% of the stand-in below rank 5) stays, so "the higher of" is rank-gated. Bandwagon's DC reads it too.
    - **Placement:** Bard's Performance root, Freedom tab: String Theory after Personify (mid), Conductor after it (high), Symphony after Conductor.
    - **Conductor is data:** a new Effect condition `rested` (`Unit.rested_turns > 0`); `strategy`, `tactics`, `command` +1 a rank. "Command limits" read as allies commanded a turn, orders each and reach; party size is not one.
    - **Symphony's id is `symphony_bard`**; `Skills/symphony.tres` is the Wizard's expanded study. **Rename either as you like.**
    - **"Commanded unit" is a unit in the holder's command range** (`Command.hears()`), not one given an order; the holder's own passes do not count. A check passes when `Battle.check()` is won or an attack lands; hook `Behaviour.passed`. The reward is the status Cadence ?? (`Effects/cadence.tres`, `check` +1 a rank, 1 turn, up to Symphony's rank).
    - **First Chair is a use-scoped impact bonus** (`Behaviour.opening`, `Volley.first`, `Volley.impact`, `Battle.impact_of`), carried by every blow of the first unit's first use and a data heal.
    - **`impact` and `first_chair`** are Glossary terms (kind `target`, your words; colour `#f2a56b`).
    - **Tests:** `symphony_bard_test` (four tests); five mutations failed and reverted. Suite 10393 checks.
    - **New names to review:** Cadence ??.
- [x] **Rename `symphony_bard` or the Wizard's `symphony`** (the id clash): answered, the Bard's is Harmony (?227). (?220)
- [x] **Not forecast:** First Chair is now in `damage_range`, Cadence shown as a numeral and a sign (?232). (?220)

221. **Level in the glow - built on judgement, open for review (2026-11-20).** Your words: "On level up, flash a units glow to 2x intensity briefly. Units with a higher level have a subtly larger glow, lower level have a subtly smaller glow. (while not indicating targeting)". Plan: `docs/plans/w7-glow.md`. Calls:
    - **Flash:** `Unit.leveled_up` tweens the shader's `flash` from `Unit.FLASH` 2.0 to 1 over 0.6 s; alpha is clamped on screen, so a glow near full gains less than a true 2x.
    - **Reference:** the average level of the player's side, not the selected unit, so sizes do not jump with selection.
    - **Scale:** `Unit.level_reach(level, ref)` = 1 + 0.03 a level, within +-0.15, by growing the shader's quad.
    - **Not while targeting:** `HUD._target_glow()` says what an armed skill does to a unit; such a unit keeps plain size. **Command readiness is not targeting, so it is sized**; say if it should hold the size.
    - **Silhouettes** plain; everyone else its true level, disguises included. The size follows on the next HUD refresh.
    - **Tests:** `hud_test.test_glow_by_level`; two mutations failed and reverted.
    - **New names to review:** none.
- [ ] **Should command readiness also hold the glow's plain size?** (?221)

222. **Preparation uses: Surveyor, Evaluator, Inquisitor - built on judgement, open for review (2026-11-20).** Your words: three low-tier Specialist skills, each a rank of a preparation use and +rank on its kind of check in battle (Surveys: tile intel with advantage; Evaluates: unit intel; Inquisitions: suspicion, extra investigation checks with advantage). Plan: `docs/plans/w7-prep.md`. Calls:
    - **One table `Prep.USES`** (`of`, `intel`, `suspicion`, `edge`, a count from a stat mod or the Effect stat `prep_use` tagged with the use): `study_ally`, `study`, `survey`, `evaluate`, `inquire`. `Battle.study()` became `prepare()`; `studied_allies` became `Battle.prepped`.
    - **The tag is the use and the check:** `survey ??`, `evaluate ??`, `inquire ??` (Glossary, kind check); the stat `prep_use` is "Preparation" ??.
    - **A click spends the first fitting use** in table order that has one left and still gives the target something; a studied unit goes to an Inquisition else "Already studied"; **no picker**.
    - **Outcomes:** intel is a recon level better, once per target across uses; suspicion inspects a tile or doubts a unit that fools the leader; an Inquisition on an honest unit spends the use for nothing.
    - **Advantage on an intel-only use is carried and changes nothing** (intel is a level, not a roll); an Inquisition's is a real advantage on `doubt()`.
    - **In battle:** Surveyor on `inspect()`; Inquisitor on `doubt()`, `investigate()` and `seen_odds()` (not the trickster's side); Evaluator is `recon` tagged `evaluate` (`Perception.sizing`), which also counts against trickery.
    - **Placement:** tier 2 on `general_specialist` ("low"; Synergy and Decisive Strike are 2); offered outright: Surveyor to Fighter and Druid, Evaluator to Fighter, Inquisitor to Cleric and Paladin; `skill.py new --role` takes several roles.
    - **HUD:** a line per use in the top box ("Surveys: 2 tiles"); the log says "X surveys / evaluates / inquires about Y".
    - **Tests:** `prep_test` extended (four tests); six mutations failed and reverted. Not covered: `their_tags = []`, Inquisition's advantage.
    - **New names to review:** survey ??, evaluate ??, inquire ??, prep_use ??.
- [ ] **Should intel-only uses roll?** (advantage means nothing on them today.) (?222)
- [ ] **Is tier 2 right for "low"?** (?222)

223. **Placeholder art from utumno - built on judgement, open for review (2026-11-20).** Your words: "use assets in /Users/jtrex/assets/utumno for placeholder icons where possible, there's one for siren as well". Plan: `docs/plans/w7-art.md` (the full mapping). Calls:
    - **39 mapped:** 38 skill icons and `Units/Siren.png`; all 32x32, copied unchanged; the source is untouched; `icon.py check` and `skill.py check` pass.
    - **Coloured, not white:** skill icons are meant to be white on clear and tinted by state; the utumno ones are coloured and the tint multiplies over them. Revisit if it reads badly.
    - **Only drawn placeholders overwritten;** `Shade.png` and `Elmit.png` were skipped (odd sizes, possibly real art), so the silhouette icon is Invisibility's.
    - **Siren:** `Units/Siren.png` is new and `Scenes/siren.tscn` points at it (the one scene edit); Undine keeps Elmit.
    - **No status mapped** (only Suspicion has an icon, drawn in code); Surveyor, Evaluator, Inquisitor skipped (a sibling's ids).
    - **New names to review:** none.
- [x] **Do coloured icons read well under the state tint, or should they be white-tinted?** Answered: coloured or white-and-tinted, both fine; built as ?229. (?223)

224. **Passive signage - built on judgement, open for review (2026-11-20).** Your words: passives muted on name and number, unmuting or flashing as they act; a passive acting on a unit shows "<icon> Name amount" above a non-viewed unit in the tag colour; Luck "+1" with a sparkle only when it enabled an action; amounts italic when rounded down, bold when rounded up; hold what cannot be done without noticeable performance cost. Plan: `docs/plans/w7-passives.md`. Calls:
    - **One signal:** `Battle.passive_fired(u, skill, amount, stat, rounded)`, emitted only through `Battle.passive()`; the HUD is the one listener; never from previews, planned walks or the AI's weighing. `Luck.rounded()` is the one place rounding is named (-1 down, 1 up, 0 exact).
    - **Call sites:** regen (signed by the skill that put it on), Luck (a step, a clover-slot use, or a target only luck's rounding reached), skills that spare hp or siphon a heal (Molothrus), and every reaction (the old gold `reacted` floater became this sign, in the skill's tag colour).
    - **Shown how:** the viewed unit's slot lights (unmuted, gold rim fading over 0.8 s); **"often" = acting again within 4 s, then it only unmutes**; otherwise a floater "Name +amount stat" in the tag colour, a stat's own sign (Luck, Regen) in `HUD.SIGN_TINT` with a four-point glint (**the glint marks every stat-only sign, not Luck by name**); a regen floater stacks beside the existing "+4" hp number.
    - **Who may see it:** own side always with amounts; another side's unit only as `skill_sense()` allows (none, name, name and amount).
    - **Muted:** one rule for every always-on passive (not a toggle or hybrid), so traits and innate armor passives in the hotbar and the spellbook, not the class skills screen (a shop).
    - **Rounding faces** (a font variation per direction) done for sign floaters and damage numbers. **Held (not for performance, for scope): rounding on heals other than regen, on the log, and on previews** (a range has no one rounding).
    - **Performance:** `Tests/sims/busy_fight.gd -- 15 20 n=3`, before and after: 15v15 unit turn 64.1 / 63.0 against 64.3 / 64.0 ms, 20v20 76.1 / 74.8 against 75.9 / 75.7; within noise, fight digests unchanged; a sign costs 0.05 to 0.24 ms on the HUD.
    - **Tests:** `Tests/passive_signs_test.gd` (2 tests); five mutations failed and reverted. Suite 10472 checks, 0 failed.
    - **New names to review:** none.
- [ ] **Are 4 s for "often", the glint on every stat-only sign, and one muted rule for all always-on passives right?** (?224)
- [x] **Should rounding italic and bold reach other heals, the log and previews?** Heals and the log built, previews held (?232). (?224)

225. **Widescreen hotbar and one lead per description line - built on judgement, open for review (2026-11-20).** Your words: "skills don't fit in widescreen"; "cut down / standardize skill verbiage: no multiple 'On a foe' lines". Plan: `docs/plans/w7-wide.md`. Calls:
    - **Wrap, not scale:** the hotbar and traits are `SlotColumns` (one column while it fits, else the fewest that do, filled top to bottom); at 16:9 a level-20 bar is 2 columns, level 1 unchanged.
    - **Room:** `HUD._fit_bar`; columns at least 62 px, the panel at most 0.45 of the window width, then squeezed to 40 px (names cut) rather than clip. Refit each frame, tightening only, so columns do not flip.
    - **Wording:** one shared pass, `Skill.merge_leads()`, joins every later line with the same "On <who>: " lead to the first with "; ", order kept; facts unchanged; behaviour wording not rewritten and joined segments not lowercased. Sing's foe line keeps an inner sentence.
    - **Undone:** a multi-slot skill's span is not kept whole across a column break; a very large bar at 16:9 (4 or more columns) squeezes names.
    - **Tests:** `Tests/slot_columns_test.gd` (new), `sweep_test.test_description_leads`; two mutations failed and reverted. Suite 10532 checks, 0 failed.
    - **New names to review:** none.
- [ ] **Is wrapping into columns (with names squeezed at the extreme) the right widescreen answer, and is "; " the right way to join lines?** (?225)
- [x] **Keep a multi-slot skill whole across a column break.** Built in ?230. (?225)

226. **Party size without the floor - built on judgement, open for review (2026-11-21).** Your words (?216): "base cha mod increases party size (at least +0) + level/4 (at least +1); unit can't market themselves / has nothing to market? they'll have to go solo." Plan: `docs/plans/w8-party.md`. Calls:
    - **The rule:** `Game.party_size(lvl, cha) = max(cha mod, 0) + max(lvl / 4, 1)`, the leader's level and base charisma as before; level 1, cha 10 is now 1 (was 2), level 1, cha 16 is 4 (was 3).
    - **Size 1 is solo:** no one to bring; `party_now()` already returned `[0]` at cap 1.
    - **Wording:** Entry's button "Party: solo" at 1 (else "Party: n of m"); the panel reads "Going solo: no one to bring yet".
    - **Left alone:** `Command.party_size()` (in-battle allies who hear orders, cha mod at least 1) is a different number. A new game starts solo for most classes at level 1 (the default Adventurer, cha 16, brings 3).
    - **Tests:** `save_test.test_party_size` (table, a Fighter solo case, the Entry text); one mutation failed and reverted.
    - **New names to review:** none.

227. **Harmony, unique skill names, ?? only on tags' shown names - built on judgement, open for review (2026-11-21).** Your words (?220, ?222): "call the new one 'harmony' instead we should keep the string names unique"; "don't add ?? to tags that might break functionality unless you are inventing a new tag". Plan: `docs/plans/w8-names.md`. Calls:
    - **The Bard's skill is Harmony** (`harmony.tres`, `Behaviours/harmony.gd`, `Tests/harmony_test.gd`; yours, no ??); the Wizard's `symphony` stays; `symphony_bard` is gone from code.
    - **The Mage's old Harmony stub became "Accord ??"** (`accord`; the nearest word to its Concord college; icon and Roles/mage.tres moved). **A call to confirm: another name, or give the Mage that Harmony and rename the Bard's?**
    - **Saves:** `Skill.RENAMED` (old id to new) and `Skill.by_id()`, read by `Unit._skill_by_id` and `Save._equipped_in`; `save_test.test_renamed_skill`.
    - **Unique names:** `skill.py check_names` (shown name without " ??", case-insensitive) and `skill.py new` refuses a clashing `--title`. Items, classes, tiles, units are not covered.
    - **?? on tags is display-only already** (an id is lower_snake; the ?? sits in the Glossary term's shown name). `mechanic.py check` now fails a tag id that isn't lower_snake or a ?? not at a name's end; `mechanic.py tag --human` strips a typed ??; `tag_colors_test.test_marked_names_are_display_only`. The rule is in CLAUDE.md and `new-mechanic`.
    - **Names:** `survey`, `evaluate`, `inquire` lost their ?? (yours); `prep_use` was never marked in code. **Cadence ?? kept** (a status I named, not a tag).
    - **Tests:** the two new ones; four mutations failed and reverted.
    - **New names to review:** Cadence ?? (Accord confirmed, ?? dropped).
- [x] **Is "Accord ??" right for the Mage's stub?** (?227) Closed: the user confirmed "Accord is fine" (docs/agents/answers-2026-11-22.md); ?? dropped.
- [ ] **Should unique names also be checked for items, classes, tiles and units?** (?227)

228. **Free lends and the band - built on judgement, open for review (2026-11-21).** Your words (?214, reworked): "armor passives are similar to innate passives: they both should be grayed out and not take a numbered hotbar slot unless activatable. The skills provided by innates / equipment *may* be considered "equippable" but are free and auto-equipped by default... (e.g. if a robe provides "Igna B" as an optional slot in skill, some units will elect not to slot it, whereas a harpy hauberk might provide a toggle skill Hollow Bones: double dex ap generation and gain flight, halve defense.)" Plan: `docs/plans/w8-bar.md` (15 calls). Main calls:
    - **A lend is free by default** (no slot, equipped while worn, any kind of skill); **`optional` costs a slot** and is not slotted by itself (read: "optional slot-in" means it costs a slot, why a unit may elect not to); free beats optional when two items lend one. `Item.innate` is removed (nine armors, `item.py`).
    - **Existing plain lends became free** (my call): Broadsword's Strike, Hobnail Boots' Kick, the Coyote Scepter's and Charm's skills; `item.py lend <skill> --ids <item> --as optional` restores a slot. A skill both learned and lent keeps its slot.
    - **"Innates" read as traits** (already free); a role's or species' own skills (a villager's Strike) still take slots, as freeing them would empty most bars. **Question.**
    - **Optional and setup:** a unit filling its bar slots an optional lend last into a leftover slot; auto-equip leaves it; a saved bar keeps the player's choice.
    - **The band** (`HUD.band()`): every slotless skill under the hotbar; activatable first, on the number keys after the bar's, used like a slot; always-on passives follow unkeyed. Orders reach an ally's band; free actives can't be disabled and stop under suppressed traits; Sigil reaches the band.
    - **Hollow Bones** (yours, lent only, data): a toggle; `dex_ap` +1, Defense x0.5, tag `flight`; tags `flight, dex`. **Harpy Hauberk** (yours): rare medium mail, lends Armor and Hollow Bones; no loot table (a drop would shift every seeded drop). The AI never switches Hollow Bones.
    - **`flight`** (yours, no ??; Glossary "Aloft"): every step costs 1 movement, deep water neither slows nor drowns. Not done: flying over walls or units, traps skipping a flyer, the AI weighing flight, height.
    - **A toggle's tags count only while it is on** (`Unit.has_tag`), for every toggle; **a `defense` mul scales the whole of Defense** (`Unit.stat(base)`), adds still add.
    - **Tests:** `equip_test.test_hauberk`, `test_band`; `lent_test.test_links` rewritten; eight mutations failed and reverted.
    - **New names to review:** none (Hollow Bones, Harpy Hauberk and `flight` are yours).
- [ ] **Should a role's or species' own skills (a villager's Strike) also be free?** (?228)
- [ ] **What does flight mean beyond its movement cost** (over walls and units, traps, height, the AI)? (?228)
- [ ] **Existing plain lends (Broadsword, Hobnail Boots, the Coyote kit) became free: keep, or make some `optional`?** (?228)
- [ ] **Hollow Bones is never switched by the AI** (an NPC in the Hauberk flies at half Defense always); should it? (?228)
- [ ] **The band's wrapping into columns at 16:9 beyond the names** (seen in `S/shot_w8-bar/`; fixed for names in ?230). (?228)

229. **Coloured against white icons - built on judgement, open for review (2026-11-21).** Your words (?223): skill icons should be coloured or white-and-tinted, expected to be icons / thumbnails. Plan: `docs/plans/w8-icons.md`. Calls:
    - **`Skill.is_coloured(tex)`** scans once, cached by path: any solid pixel (alpha >= 0.78) not near white (a min channel below 0.78); 38 of 272 icons are coloured art.
    - **`Skill.icon_ink(tex, ink, dim, alpha)`:** a placeholder keeps its tag tint; coloured art gets grey `dim` at `alpha`. Learned 1.0, open 0.85, locked 0.4 at 0.55, stub 0.5, learned-but-unworn x0.8; the hotbar's brightness as alpha. Dimmed, not framed, not desaturated (modulate only darkens; a shader per slot was over-abstract).
    - **Used in** SkillSlot, SkillGrid, SkillWheel; the spellbook list draws no icon.
    - **Tests:** `skills_test.test_icon_ink_tints_placeholders_not_coloured_art`; a mutation failed and reverted. Not screenshotted: a white-placeholder skill on the hotbar, the hotbar's lit state.
    - **New names to review:** none.
- [ ] **Do coloured icons read right with a dimmed grey state instead of a tag tint?** (?229)

230. **The hotbar's layout - built on judgement, open for review (2026-11-21).** Your words (?215, ?225): multi-slot skills; "skills don't fit in widescreen". Plan: `docs/plans/w8-layout.md`. Calls:
    - **Band names whole:** `_fit_bar` reserved a row too few and counted a 3 px gap twice (fixed: the bar may stand 3 px taller in a few windows); a slot says what it wants (`SkillSlot.want_width()`), a column is at least that wide while `max_width` holds, and the band reserves the rows its names stand in (`SlotColumns.standing_rows()`). At 16:9 a level-20 mage's band is two columns with whole names; the hotbar uses the same rule; where the width cannot hold them names are still cut (tooltips whole).
    - **A multi-slot skill is one tall button** over its slots' rows (raised, covered slots unseen); it answers drops and right-clicks for every slot it covers (`SkillSlot.slot_at(y)`); a click is `use_slot(anchor)`; covered slots' numbers are not drawn but their keys work; "(continued)" stays only where a span had to be cut.
    - **Spans kept whole across a column break:** `SlotColumns.starts(runs, cols, fit)` cuts at most `cols` columns of at most `fit` rows between spans (tallest column shortest, then most even); a column may be taller than the even share but not past `fit`; with no such cut the even columns and a cut span as before.
    - **Tests:** `slot_columns_test.test_runs`, `test_names`, `equip_test.test_multi_slot`; three mutations failed and reverted. Screenshots `S/shot_w8-layout/`.
    - **New names to review:** none.
- [ ] **A 9-slot bar with three spans still needs its full `fit` rows**, leaving the band one row so names are cut again at 16:9. (?230)
- [ ] **No HUD test for the band's reservation**, and covered slots' keys aren't drawn. (?230)

231. **The AI: Deathlust's relief, plate tolls, crit loops, a defensive cc read - built on judgement, open for review (2026-11-21).** Cards from ?182, ?206, ?213, ?217. Plan: `docs/plans/w8-ai1.md`. Calls:
    - **Deathlust's sign is `Battle.passive()`, no HUD edit:** `neutralize()` and `_settle_wear()` sign any passive whose `neutralized` / `wearing` hook lowered its holder's total count (`Exhaustion.total()`); generic, amount 0; a kill signs twice. No log line (Battle has none; a sibling edits the HUD).
    - **The relief is priced by a dry run** (`AI._relief()`): a killing blow asks u's own passives, the largest fall in another skill's wear counts (not the sum), added in `_strike()` over the KILL bonus; allies' passives are not asked.
    - **Own plates' tolls** (`_dress()`, `_plated()`): the Defense times the share a block keeps after `Behaviour.slot_toll()`; a swap only when the net gain is positive. With `BLOW` 5 a toll chooses between slots, it never refuses armor.
    - **Crit loops** in the forecast: `Behaviour.Forecast` gains `loops`, `grace`, `rolled`, `crits()`; `Battle.attack_odds()` takes `rub`; `_use_ratio()` adds each follow-up at its chain's friction; Chaser's `forecasting()` hook and Jugular's `recast_on_crit` flag read generically. A chase is valued as the use again; free of AP.
    - **A defensive cc read** (`AI._stunners()`, `_dread()`): the chance a foe's best cc lands from where it could reach; `DREAD` 4.0 tiles of walking in `_approach()` and a key in `_retreat()`. Insensitive for 1 to 8. **Tried and dropped: a gate** (hold off or back off), which made the unit lose more (stuns 1.88 to 2.25, wins 2 to 1 of 8).
    - **Sim:** every scenario unchanged except `dread` (stuns taken 2.25 to 0.00, still lost 1-v-2). `soak` 10812 checks, 0 failed.
    - **Tests:** `deathlust_test.test_ai_prices_relief`, `plating_test.test_ai_weighs_tolls`, `chaser_test.test_forecast_counts_crit_loops`, `ai_tactics_test.test_dreads_a_cc`; eight mutations failed and reverted (the `_strike` relief line is not covered).
    - **New names to review:** none (`DREAD`, `_relief` and the rest are code names).
- [x] **No Deathlust log line:** built (?244). (?231)
- [x] **The plate slot does not switch off as Power runs down:** built (?244); `_threat()` not. (?231)
- [x] **`sure_crit` doubling not priced:** built (?244); allies' Deathlust not in `_relief`. (?231)

## Wave 8 batch 3 (2026-11-21): First Chair forecast, misc follow-ups, party outfits

232. **First Chair forecast, Cadence shown, rounding on heals and the log - built on judgement, open for review (2026-11-21).** Cards from ?220, ?224. Plan: `docs/plans/w8-fc.md`. Calls:
    - **One seam:** `Battle.damage_range()` adds `Battle.impact_ahead(caster, skill)` (the impact a use would carry were it opened now, via the shared `_open()` / `opening()` hook) to every blow's bonus, so the HUD span and every AI read forecast First Chair with no per-skill case. A foe's threat read on our turn is not "first". No heal preview exists, so nothing to forecast there.
    - **Cadence shown twice, both generic:** the status chip's corner numeral shows the stack for any `per_rank` effect above rank 1 with no roll of its own (Charge, Winded, Soaked now show too); Harmony signs each build through `Battle.passive()` ("Harmony +1 cadence" on every unit it grew on).
    - **Rounding on heals:** `Unit.heal(h, heard, rounded)`; threaded through potions, skill stat mods (`Skill.heal_raw()`), regen and Regeneration Pulse. The Heal skill, Lovely Caster and Resuscitate are not luck-rounded, so plain. The log's two RichTextLabels take italic and bold from `Overlay.face()`; a log line is styled only if every blow rounded one way and the post-cut sum is the amount shown; a mix is plain. **Previews stay unstyled** (a span has no one rounding).
    - **Perf unchanged** (`busy_fight` 15v15 unit turn 69.0 to 69.2 ms, digests identical). Mutation spot-checks failed the right tests. 10672 checks, 0 failed.
    - **New names to review:** none.
233. **Prep tests, Scrapper and Bulwarker, the hostnear sim, AI.LOST, item icons - built on judgement, open for review (2026-11-21).** Cards from ?222, ?213, ?217, ?178, ?223. Plan: `docs/plans/w8-misc.md`. Calls:
    - **Prep tests:** `prep_test.test_doubt_sides` (a trickster's `their_tags = []`, an Inquisition's advantage on `doubt()`); no rules change.
    - **Two units with a `pack`:** Scrapper ?? (level 3, Scrap Plating 3, Brigandine + Habergeon) and Bulwarker ?? (level 5, Power Armor 2, Half Plate + Plate), Fighter role, faction nemes, sprites `--color` placeholders. **`unit.py --set` cannot write an item array, so the `pack =` lines were added to the .tscn by hand** (`unit.py check` ok). No new items, no loot drop; in no battle scene. Their stats are the villager's (at the default 5s a unit has 4 AP and armor costs 10 - dex mod, so it never dresses: armor in battle is dear). `plating_test.test_packs`.
    - **Sim `hostnear`** (`ai_sim.gd`, soaker 5 tiles off): BODY 0 against 5 is about neutral (30.50 against 30.25 at n=8; 30.83 against 32.83 at n=24); **`SUMMON_CAP` 4 did better (41.6, +35%)**. Left as is: a body's worth as target and blocker is not measured. **Question for the user: should the cap drop?**
    - **`AI.LOST` 0.5 to 0.35 (a call to review):** the near hunt sim found 0.70 to 0.75 at 0 to 0.35 against 0.32 to 0.53 at 0.5 (at or above `WORTH` the ranger casts the look and stands still); the lone-hunter sim (`ai_sim hunt`) prefers 0.5 (4.67 / 5.10 rounds against 5.07 / 5.37), so 0.35 all but switches off the stuck-hunter fix. No value serves both. **The user should pick;** 0.5 back with "stop the look repeating where it stands" is the alternative.
    - **Utumno second pass:** eight item icons mapped in `Icons/Items/` (plate, robe, starblade, burning_blade, heart, heart_up, hobnail_boots, shackles; matches are guesses by name and look). **Locked coloured icons (0.4 at 0.55 opacity) are nearly illegible on the dark field.** No status art (a status has no icon field: code, not a mapping); `Shade.png` and `Elmit.png` untouched.
    - **New names to review:** Scrapper ??, Bulwarker ??.
234. **Party members' outfits - built on judgement, open for review (2026-11-21).** Card from ?216. Plan: `docs/plans/w8-outfits.md`. Calls:
    - **An Outfit button per member in the Party panel** opens the existing `CharacterSheet` (`between` hides Use on potions; a consumable offers Use only for hearts) on a unit built from the roster entry (hidden, freed on close). Grid now 4 columns. Each change writes `Game.roster[i]` and saves; the leader is pickable too and also writes `Game.outfit` / `Game.equipped`.
    - **Items conserve** (stash loses what is worn, gains what it replaced); no AP is charged; a bound item can't come off. No bar editor: items change the bar as in battle.
    - **Not done:** the Party button hides on a solo roster, so a solo new game has no between-battle stash screen; `PartyPanel.outfit()` copies `Battle.from_role()` rather than sharing it.
    - **Tests:** `save_test.test_member_outfit`; three mutations failed and reverted.
    - **New names to review:** none.
- [x] **Locked coloured icons are nearly illegible:** reworked as the icon states (?236). (?233)
- [ ] **Statuses have no art** (an `Effect` icon is code; needs the user's wish). (?233)
- [x] **No Deathlust log line:** built (?244). (?232)
- [x] **No HUD test for the band's row reservation:** `hud_test.test_band_rows` (?241). (?230)
- [x] **A pack does not drop as loot:** it does (?242). (?233)
- [x] **`Battle.from_role()` copied into `PartyPanel.outfit()`:** static and shared (?242). (?234)
- [x] **A solo roster has no Party button:** shown (?242). (?234)
- [ ] **The Heal skill's and Lovely Caster's heals have no luck rounding** to show (not a rule: a roll is a roll); heal previews do not exist. (?232)

## Wave 9 (2026-11-22): Disturbed, icon states, Siren, undead, typing pilot, Grave Aura, band columns, Party, AI cost

235. **Disturbance and Disturbed - built on judgement, open for review (2026-11-22).** Your card: Warlock mid skill, a check, Disturbed for rank rounds, no commands given or taken, acts by behaviour. Plan: `docs/plans/w9-disturb.md`. Calls:
    - **Disturbance** in the Elmon tree after Brainfog (tier 3, "mid"), foes only (a `dual` one would open the AI to using it on allies), range = rank tiles, Sweet Nothings preferred; no attack roll: a wisdom check vs `Difficulty.dc` unfair (non-leader) or easy (leader); duration = rank impact. "Leader" = `Battle.leads(u)` (the player, or a unit someone `follows`).
    - **Disturbed** (`Effects/disturbed.tres`, stat `disturbed`, tag `cc`, `Unit.disturbed()`) reuses the `uncontrolled` seam: Command refuses to order or join it, `hears()` is false, `idle()` always lists it; a Disturbed player leader makes the side play itself (`HUD.autopilot()`, log "Your mind is Disturbed"). Any status, item or trait can lend the stat.
    - **Tests:** `disturbed_test` (4 tests); seven mutations failed and reverted; `forced_test` cc tables extended (not weakened); `_pose` sets endurance 9 in the sweep. Suite 10691 checks at merge, 0 failed.
    - **New names to review:** none (Disturbance and Disturbed are yours).
236. **Icon states - built on judgement, open for review (2026-11-22).** Your words: disabled 25% saturation 70% brightness, untoggled 15% and 85%, one hook for why a skill is disabled, a non-colour cue. Plan: `docs/plans/w9-icons.md`. Calls:
    - **`Skill.mute()`** is the colour maths (`LOOK_*`); look zero is the old behaviour. Cue: a slash (disabled, locked), a hollow ring (untoggled). Opacity stays 1 with a look (colour carries the state; text still dims).
    - **Hook:** `Unit.disable(..., src: Skill)` records `disabled_by[skill]`; the slot shows the source's mark first character as a badge and a "Disabled by X" tooltip; any skill that passes `src` joins. Brainfog is the one example. Postponed disablings carry no `src`.
    - **Skills screen:** coloured art only (locked = disabled look plus slash, unworn = untoggled look plus ring); placeholders unchanged. No locked coloured icon showed in the shots (the Mage tree is mostly placeholders), so the legibility is unchecked.
    - **Tests:** `brainfog_test.test_hotbar`, `skills_test` icon test; one mutation (mute ignores value) failed and reverted. 10691 checks, 0 failed.
    - **New names to review:** none.
237. **Siren Seaborn ??, `Effect.only_on`, betrayal, `shows_boon` - built on judgement, open for review (2026-11-22).** Your card: one trait passive from `4fe2c05`. Plan: `docs/plans/w9-siren.md`. Calls:
    - **A new trait "Seaborn ??"**, innate on the Siren scene (`unit.py trait`), not Oceanic (the user's toggle drawback stays: -4 unless on water). On water they stack. `movement = 2` is on the scene, not an Effect.
    - **Generic `Effect.only_on`** (terrain tags needed; the twin of `unless_on`; `Unit.stat()` reads it, `describe()` says "only on x"): +2 str, dex, con on water.
    - **Cheaper water movement is the `aquatic` tag** (`Battle._cost()` already makes water cost 1 and forbids drowning), so `4fe2c05`'s `move_cost -2 [water]` is redundant and not added. Side effect: the Siren cannot be drowned.
    - **Rake doubling is a generic stat `betrayal` ??** (tagged `slash`, +fraction damage to a target that trusts the holder: `Battle._trusts()`, Alluring's Friendly stance feeds it), read in `Battle.cast()`'s main damage line only (not chains, cones, traps), not `4fe2c05`'s `crit_trusting` flag.
    - **`shows_boon`** is a Skill field (**`FLAG_CEILING` 105 to 106**), a Unit field and `Read.boon`, copied by `_take_looks()` and `Perception._lie()`; nothing displays it yet. **Question for you: is this the right place for the shows_* look family?**
    - **Detective, Ambush, Opportunist not rebuilt.** Detective needs the removed Investigation system (marks, watchers); Ambush needs a watch hook (a Behaviour on `moved` / `seen`); Opportunist needs a new "ran beside it" reaction trigger from Battle's move path (the smallest; best next).
    - **Tests:** `aquatic_test` (`test_seaborn`, `test_rake_trusting`); three mutations failed and reverted; `lure_test.test_drown`, `perception_test.test_siren_fools`, `equip_test.test_traits`, `sweep_test._gain` updated to the new rule. 10734 checks, 0 failed.
    - **New names to review:** Seaborn ??, betrayal ?? (a stat id).
238. **Undead, Restless Dead ??, laid to rest, the summon soft cap - built on judgement, open for review (2026-11-22).** Your card (undead plus Disturbed acts as "Restless Dead ??"). Plan: `docs/plans/w9-undead.md`. Calls:
    - **No Undead faction:** a restless unit keeps its side (it acts on its side's turn, after cognizant allies; "allies on ties" needs the side). A faction switch would show its side to every reader at once (no room for the noticing check), add a turn-order entry mid-battle and block victory checks. Attitude is per reader (`Read.dead_eye`, `Read.restless`, `Read.kin` in `Battle._read`).
    - **The cap only adds Disturbed:** `summon_per_rank` cap = rank + the cast's stat mod; summons over it, furthest from the summoner first, gain Disturbed lasting; Disturbed summons do not count and the cap never lifts it (lifting would slay it). **No zombie unit exists: none added.**
    - **`SUMMON_CAP` removed** from the AI: `bodies()` prices only the bodies that stay under control. A low-int caster holds none (villager int 8 at rank I: cap 0), so the AI will not raise and a player's cast sends both restless: your formula, kept, flagged.
    - **Allies notice only on a cast:** `Scripts/Undead.gd settle()` at the end of the outermost cast and at `end_turn`, one wisdom roll (inquire) vs a flat DC 8 ("medium easy") per witnessed action; not on a walk. A restless undead no longer Disturbed is slain (`Unit.slay`). `Command.cognizant_first` orders the Disturbed last.
    - **Left open:** no Bio or HUD text names "Restless Dead ??" on a unit; a persona claiming undead also spares a living unit (a synergy).
    - **Tests:** `undead_test` (4 tests); seven mutations failed and reverted; `summon_test.test_ai_raises_host` changed to the soft cap (caster int 14). Sims: `ai_sim host`, `hostnear` (41.6), new `restless`; `busy_fight` 20v20 no errors.
    - **New names to review:** Restless Dead ??.
239. **Typing pilot - built on judgement, open for review (2026-11-22).** Your card: untyped-declaration warnings, type the hot paths, measure. Plan: `docs/plans/w9-typing.md`. Calls:
    - **No speedup:** `busy_fight` 15v15 unit turn 69.0 / 69.7 / 69.1 ms before, 69.2 / 68.6 / 68.3 after; back-to-back A/B 67.1 / 67.1, 67.4 / 67.4 (digest 47676114 unchanged). The cost is `Unit.stat`, Perception and walk logic, already typed.
    - **Done:** `untyped_declaration` warning on in `project.godot` (headless prints no GDScript warnings here, so counts come from a regex script); typed loop vars (`for s: Skill in`) in AI.gd (76 lines) and Perception (4); `reads` is `Dictionary[Unit, Read]` with `AI.reads_from()` for 13 tests that hand-build reads. No game bug exposed; typed dicts rejected untyped `{}` at runtime in 13 tests (a strictness benefit, with churn).
    - **27 untyped declarations left** (Save.gd 12, Unit.gd 5, Battle.gd 4, Game.gd 3, Skill.gd 2, PartyPanel.gd 1).
    - **Recommendation:** do not expand for speed. Expand only for safety, cheaply: loop-var typing and those 27 (Save.gd first); do not type shared dict params without a helper. Your call.
    - **New names to review:** none.
240. **Grave Aura - built on judgement, open for review (2026-11-22).** Your card: Warlock necromancy / death-cleric tier 3, persona undead, allied undead make no checks against persona. Plan: `docs/plans/w9-grave.md`. Calls:
    - **On `mortis_arcalis`** (the necromancy tree, a second root-level branch, not tier 3: the tree has one skill). **No death-cleric tree exists** (Cleric has a Death skill, no tree): not invented, not placed.
    - **A passive** (not a trait: those are tree-less innates), persona +1 a rank, `shows_tags` [undead]; no new mechanic. The rule is in `Battle.doubt()`: no check, no suspicion when the observer has `undead`, the target's `shows_tags` has `undead` and the factions are friends; generic to any persona claiming undead. Undead's noticing (?238) is a flat DC, untouched.
    - **Tests:** `undead_test.test_grave_aura`; one mutation failed and reverted.
    - **New names to review:** none (Grave Aura is yours).
241. **The band's columns at 16:9 - built on judgement, open for review (2026-11-22).** Cards from ?228, ?230. Plan: `docs/plans/w9-band.md`. Calls:
    - **`SlotColumns._plan`** takes one more column (down to `FLOOR_WIDTH` 40) before cutting a span; `HUD._fit_bar`'s `MIN_ROWS` floor is the tallest span when the bar has spans. L12 (7 slots, spans 2, 3) at 16:9 is now whole everywhere.
    - **L20 (9 slots, spans 2, 3, 2) trades names: band whole, bar cut.** The room is 5 rows and the bar needs 6, or 4 wide columns of 62 (254 px, over the 0.45 `BAR_SHARE`). The bar sits in 4 squeezed columns (~51 design px: "Strik", "Aeth", "M"); the old plan left the bar whole and cut the band ("Hollo", "Darkvisi"). **Your call: which names matter more?** One line to flip it: the `most` bound in `SlotColumns._plan`.
    - **Tests:** `hud_test.test_band_rows` (closes the band-reservation item), `slot_columns_test.test_runs` (+2); three mutations failed and reverted.
    - **New names to review:** none.
242. **Party button, `Battle.from_role` static, pack loot - built on judgement, open for review (2026-11-22).** Cards from ?233, ?234. Plan: `docs/plans/w9-party.md`. Calls:
    - **The Party button shows on a solo roster** (non-empty, was more than one); the text stays "Party: solo". `Battle.from_role` is static and `PartyPanel.outfit()` calls it (no drift).
    - **A pack drops whole:** `Battle._drops(u)` = one roll of `u.loot` plus every item in `u.pack`, each its own spoil and `dropped` emit; the pack is cleared (never twice). No new field or flag: any unit with a pack joins. Not taken: rolling the pack through a loot table (a unit's whole kit lying where it fell is the point of carrying it).
    - **Tests:** `plating_test.test_packs` (+ drop), `save_test.test_party_size` (+ solo); no mutation beyond the one-liners. **New names to review:** none.
243. **AI turn cost - built on judgement, open for review (2026-11-22).** Card from ?183. Plan: `docs/plans/w9-aiturn.md`. Calls:
    - **Built:** `Battle.skill_reach` and a `_line_up` that takes per-tile distance and per-skill reach once; `_look_harder` reads in one stretch; `suspicious(o, known)` skips candidates it would filter; `Unit._held_fx(viewer)` shares one null view; `Perception._seem` shares an unfronted dict; `Unit.held()/hold()` per-stretch memo (cleared with the effects). `ai_tactics_test.test_planning_holds_and_bounds` (a mutation failed; the unit-bound line is uncovered).
    - **Result (15v15, n=2, back-to-back A/B):** unit turn 68.4 to 58.8 ms (p95 125 to 96); `end_turn` 235 to 100 (p95 554 to 216); digest 47676114 and `ai_sim` output unchanged. At M3 x 4 the unit turn is ~235 ms against the 100 ms budget: **still over**; `end_turn` ~403 ms is within 1000.
    - **Tried and dropped:** a `Unit.stat` plain-value memo and a footing-keyed `_line_up` cache (no gain).
    - **Left:** the per-read floor ~250 us (`Unit.kit` ~45, `defense` ~25, `_dim` ~25); a cross-stretch cache needs a mutation version on Unit; `route()` tile-read memo; `react()` per moment; `_sightings` and `_first_look` re-reading 29 units. **New names to review:** none.
244. **The AI's plates and Deathlust's log - built on judgement, open for review (2026-11-22).** Cards from ?231, ?232. Plan: `docs/plans/w9-aiplate.md`. Calls:
    - **Deathlust log:** `Battle.passive()` now carries stat `exhaustion` (amount 0) from `neutralize()` and `_settle_wear()`; `HUD._on_passive` logs "X's Deathlust eases its exhaustion" (generic, no amount, so no `Overlay.face()` styling).
    - **Plate lapse:** hook `Behaviour.slot_works(holder, rank, spent := 0)` (+ `Unit.plate_works`, `Unit.power_share`); `AI._plated()` counts blocks (up to **`AI.BLOCKS` = 3, a guess**: blows before its holder rests) whose slot still works after the earlier tolls and scales worth by blocks / BLOCKS. Own plates only; a foe's plates in `_blocks` and `_threat()` are unchanged. `plating_test.test_ai_weighs_tolls` 3.0 to 1.0 (Power Armor I at full Energy lapses after one block).
    - **`sure_crit` doubling** priced in `AI.score()`'s glance line (a crit hit doubles, a glance stays half), so every loop follow-up is priced; allies' Deathlust still not in `_relief`.
    - **Tests:** `deathlust_test.test_log_line`, `plating_test.test_ai_plate_lapses`, `chaser_test` (+1); three mutations failed and reverted.
    - **New names to review:** none.
- [x] **Siren Opportunist:** built (?246). Detective (needs a removed Investigation system) and Ambush (a watch hook) stay unbuilt. (?237)
- [x] **`Skill.shows_boon` is shown nowhere:** shown as a note (?247). (?237)
- [x] **A mention of "Restless Dead ??" on a unit; noticing on a walk:** built (?247). (?238)
- [x] **The 27 untyped declarations:** all typed (?248). (?239)
- [ ] **Locked coloured icons never seen in a shot** (the Mage tree is mostly placeholders); postponed disablings carry no `src`. (?236)
- [x] **AI turn cost, the per-read floor, `route()` tile reads, `react()` asking `on_passives`:** built in part (?245); still over at M3 x 4 (~168 ms vs 100). (?243)
- [ ] **A foe's plates and `_threat()` ignore tolls and lapse; allies' Deathlust is not in `_relief`.** (?244)
- [ ] **A death-cleric tree for Grave Aura.** Needs the user. (?240)

## Wave 10 (2026-11-22): AI turn cost again, Opportunist, shows_boon and Restless Dead, typing

245. **AI turn cost: per-read stretch caches - built on judgement, open for review (2026-11-22).** Plan: `docs/plans/w10-aicost.md`. Calls:
    - **Built:** `kit`, `defense` (no tags), `core_stats` and a unit's strengths/weaknesses held per stretch (`Unit.begin_read` / `end_read`, `held`, `hold`; getters return copies); `on_passives` found once per stretch with the effects (`_held_fx`); micro-stretches in `reacts`, `stopped`, `helpless`, `rank`, `actives`; `Perception.embellish` returns early when nothing is puffed; `Battle._tile_read(u, c)` keeps a planner's tile read while the unit stands still; `bonus_slots()` asks `slot_count()` once. 15v15 on the M3: unit turn 56-58 to 41-43 ms, `end_turn` 69 to 57; at M3 x 4 the unit turn is ~168 ms against the 100 budget (still over; was ~230).
    - **No cross-stretch cache behind a mutation version:** `timed`, `slots`, `items`, `hotbar`, `learned` are written at about 35 sites with no one hook, and a missed site gives stale stats silently; the stretch was widened and shared instead.
    - **Not built (each risks changing what units see):** an out-of-range viewer skip in `_sightings` / `suspicious` (sight covers nearly everyone in the sim), a `_sightings` pre-walk gate (cover is not knowable before the move), and `in_range` / `_seem` caching (both depend on every side member's position; ~3% each).
    - **Digest reference is now 3296533323**, not 47676114: the old digest no longer reproduces at the tip (w9 merges changed AI decisions); this work leaves it unchanged. Confirm it as the reference.
    - **Remaining:** `_cast` is ~22% of a unit turn (reactions, evaluators, r0 gathers); ~18K unit reads a fight at ~0.1 ms each.
    - **Tests:** `ai_tactics_test.test_stretch_holds_what_a_read_asks`; two mutations failed and reverted. 10793 checks at the branch, 0 failed.
    - **New names to review:** none.
246. **Opportunist - built on judgement, open for review (2026-11-22).** Siren trait from `4fe2c05`; plan `docs/plans/w10-opp.md`. Calls:
    - **"Ran into" is a walk that ends beside it** (not a bump or a pass-by); the reaction trigger `&"beside"` fires at the end of `Battle.travel()` only, not on a push, pull or lure. `Behaviours/opportunist.gd`, `Skills/opportunist.tres` (human name from `4fe2c05`); `grant_interrupt` takes an optional `aim`.
    - **Uses its first active** (`actives[0]`) on the walker, only if hostile and in reach; no limit per mover (Energy limits it); hostility is by faction, not by read, so a walker fooled by Alluring is still struck. The AI does not weigh Opportunist when approaching.
    - **Tests:** `reaction_test.test_beside`, `test_opportunist`; `equip_test.test_traits` and `perception_test.test_siren_fools` updated (Siren skills 7 to 8); the stub `opportunist_test.gd` deleted. No visual check done.
    - **New names to review:** none (the name is yours).
247. **`shows_boon` and Restless Dead on the unit - built on judgement, open for review (2026-11-22).** Plan: `docs/plans/w10-boon.md`. Calls:
    - **`Read.boon` shows as a note** "Claims to be doing <boon>." (`HUD._info`), a note and not a chip. A red "Restless Dead ??" chip is a chip, not a rename: on the leader's card, on a read card once the observer has noticed, and on own-side cards; an observer who has not noticed sees none.
    - **Allies notice on a walk:** one line `UNDEAD.settle(self, u)` after `_first_look(u)` in `Battle.travel`; the check runs once per walk, at the end.
    - **Not captured visually:** the boon note and the read-card chip.
248. **Typing: the 27 untyped declarations - built on judgement, open for review (2026-11-22).** Plan: `docs/plans/w10-typing.md`. Calls: Save 12, Unit 5, Battle 4, Game 3, Skill 2, PartyPanel 1, all typed. Values from `d.get` or a dictionary index are `: Variant`, checked with `is` after; `load()` results `: Resource`; `Battle.best_luck`, `best_dexterity`, `members` take `side: Variant` (a Unit, Faction or Array); `_flip`'s temp is Variant; no shared dict params typed. Digest unchanged.
249. **`tooling_test.test_icons` flaps in builder worktrees (2026-11-22).** Four skills show no icon there (Disturbance, Grave Aura, Opportunist, Seaborn) but it passed at the landed tip (10814 checks, 0 failed; 1029 tests). Likely the icon files or their `.import` files are not all committed, so the check leans on a worktree's import cache. Check `Icons/Skills/` and the `.import` files.
- [x] **AI turn cost: the unit turn is ~168 ms at M3 x 4 against 100:** built in part (?250), now ~150 ms, still over; open item below. Was: `_cast` (~22% of a unit turn), the unit reads of `_reads`, `_look_harder`, `_first_look`, `_sightings`; the skipped speedups only with a test that proves what units see is unchanged. (?245)
- [x] **Confirm digest 3296533323 as the `busy_fight` reference.** Dropped: the digest pin is replaced by outcome checks (the user, 2026-11-23: "no strong preference but make sure tests aren't overly concrete"). (?245, ?257)
- [x] **Opportunist: the AI does not weigh it when approaching:** built (?252). Detective and Ambush stay unbuilt. (?246)
- [ ] **Boon note and the read-card chip not seen in a shot.** (?247)
- [x] **Skill icons and `.import` files; `tooling_test.test_icons` no longer depends on a worktree's cache:** built (?251). (?249)

## Wave 11 (2026-11-22): AI turn cost, the cast; icon check; the AI weighs Opportunist

250. **AI turn cost: the cast - built on judgement, open for review (2026-11-22).** Plan: `docs/plans/w11-cast.md`. Calls:
    - **Built:** `react()` asks only reaction-tagged passives; `rank` held per stretch; `_hunt`, `_look_harder` and cover one stretch each; `_line_up` early exit; `restless()` asks the undead tag first; evaluators ask `evaluates()` before `asleep()`; slots in one pass; `link` skips non-lending items. 15v15 on the M3: unit turn 43 to 38 ms, `end_turn` flat ~57; at M3 x 4 the unit turn is ~150 ms against the 100 budget: STILL OVER.
    - **The react filter goes by the `reaction` tag:** an override of `react()` cannot be detected at run time, so a reacting skill left untagged would never react; `skill.py check` enforces the tag.
    - **Not taken (no test can prove them):** out-of-range viewer skip, `_sightings` pre-walk gate, ally-read skip in `suspicious`, `in_range` / `_seem` caching. No cross-stretch cache.
    - **Digest 3296533323 unchanged** (still the unconfirmed working reference; it replaced 47676114, ?245).
    - **Remaining:** the warm-read floor ~100 us (29K reads a fight); `_approach` / `route` done by ?252; `_chain`, actives held, `can_afford` under noise.
    - **Tests:** `ai_tactics_test.test_cast_cost_answers_as_before`; 4 mutations caught. Suite 10875 checks, 0 failed (1031 tests).
    - **New names to review:** none.
251. **Icon check (2026-11-22).** Plan: `docs/plans/w11-icons.md`. `tooling_test.test_icons` failed in builder worktrees because it `load()`ed each icon (needs the `.godot/imported` cache; the copied template predates four icons). It now checks `Icons/Skills/<id>.png` and `.png.import` exist per skill. No art added; all were tracked. Closes ?249.
252. **The AI weighs Opportunist when approaching - built on judgement, open for review (2026-11-22).** Plan: `docs/plans/w11-oppai.md`. Calls:
    - **New generic hook `Behaviour.strikes(r, holder, rank) -> Skill`** (null default; Opportunist overrides, its `react` uses it). `AI._strikers` (foes within 2 tiles of the target that react, read as foes, located, reaction passive known) and `AI._struck` (expected blow = damage x hit chance, capped at the AI's HP) feed `_approach` at `STRUCK` = 0.5 tiles per HP, a guess like DREAD.
    - **Edited `Scripts/Behaviour.gd`**, outside the card's file list, for the hook; `route()` untouched.
    - **Only tiles the striker's skill reaches count:** Rake does not reach a diagonal, so the AI takes the diagonal beside a Siren.
    - **Not weighed:** the striker's Energy/AP cost, `_line_up`, `_retreat`.
    - **Digest and sims:** no Siren in either sim, so digest 3296533323 and `ai_sim` output are unchanged. **Test:** `test_approach_weighs_opportunist`, mutation caught. No visual check.
    - **New names to review:** none.
- [x] **AI turn cost: ~150 ms at M3 x 4 against 100:** built in part (?254), now ~132 ms, still over; open item below. Was: the warm-read floor, `_chain`, actives held, `can_afford` under noise. (?250)
- [x] **Opportunist in the AI: weigh the striker's Energy/AP cost, `_line_up` and `_retreat`:** built (?253). (?252)
- [ ] **`AI.STRUCK` 0.5 tiles per HP is a guess.** Needs the user. (?252)

## Wave 12 (2026-11-22): the AI prices Opportunist's cost; AI turn cost, the warm read

253. **The AI prices a striker's cost and weighs the blow in `_line_up` and `_retreat` - built on judgement, open for review (2026-11-22).** Plan: `docs/plans/w12-oppcost.md`. Calls:
    - **`_struck` counts a striker only if `holder.funding(skill, price_cut)` is non-null.** AP is not asked: the reaction is a free interrupt (`INTERRUPT_AP` 99).
    - **`_strikers(b, u, at, within, reads)` takes a centre and a radius,** shared by all three planners: `_approach` (t.cell, 2); `_line_up` and `_retreat` (u.cell, ceil(move_left) + 1). `_struck` is never called when there are no strikers.
    - **`_line_up` subtracts the struck HP from each tile's worth,** not scaled by `STRUCK` (that is `_approach`'s unit); **`_retreat` adds it to the `_shoved` term** (the first key term).
    - **Not done:** flee and other walks, `route()` pricing, Energy shared across several strikers.
    - **Digest 3296533323 unchanged; the unit turn no slower.** **Test:** `test_approach_weighs_opportunist` extended with a Siren (out of Energy by setting Rake's cost to 3 and restoring: Rake is free as shipped); 3 mutations caught.
    - **New names to review:** none.
254. **AI turn cost, the warm read - built on judgement, open for review (2026-11-22).** Plan: `docs/plans/w12-warm.md`. Unit turn 37.5 to 33.1 ms (-12%), `end_turn` 57 to 52, warm read 144 to 96 us; **at M3 x 4 the unit turn is ~132 ms against 100: STILL OVER.** Calls:
    - **Built:** `has_tag` and `emblems` as loops (tag checked before `equipped()`); `restless()` asks the held `disturbed` stat first inside a stretch; new `Unit.lends(s)` per stretch, and `Perception._seem` skips an ally unless it lends `brood`. `lends` is a per-stretch superset scan of what `_gather_effects` draws on, so a false answer is exact (no hp in its key).
    - **Dropped as under noise or unprovable:** a per-stretch `stat()` memo, the `_on_passives` loop, `lends`-gating trickery / concealment / nullify, a `candid` rewrite, `members(Faction)` in one loop, read dedup (only 87 of 29K reads repeat).
    - **Left alone (each <= 2%):** `_chain`, actives, `can_afford`, `in_range`, `Read.new()`, `mod()`, `armor_defense`.
    - **Digest 3296533323 unchanged** (still the unconfirmed working reference), `ai_sim` diff empty. **Test:** `test_warm_read_answers_as_before` (+88 checks); 5 mutations caught.
    - **New names to review:** none.
    - **The gap is spread thin:** a further turn-cost card is likely not worth queuing unless you want to push the budget.
- [x] **Opportunist in the AI: flee and the other walks, `route()` pricing, Energy shared across several strikers.** Shared Energy built (?263); flee already priced; `route()` and `_recover` / `_escape` / `_hunt` / `_keep_up` stay unpriced (queue). (?253)
- [x] **AI turn cost: ~132 ms at M3 x 4 against 100.** Answered 2026-11-23: the budget is raised (200 ms a unit turn) as long as players do not wait on large factions; built (?256, ?257).

## Wave 13 (2026-11-23): the lost investigation layer, fast AI turns, looser tests

The user's words (docs/agents/answers-2026-11-23.md): "we can raise the budget provided players dont actually spend time waiting for large factions to take turns"; "for ai 20/80 / shortcuts and creative solutions can be embraced if they cut processing time e.g. do bot / auto units commanded by a skilled leader even need to check their behavior preferences outside of extenuating circumstances?"; "no strong prefefence but make sure tests aren't overly concrete / 20/80 and consolidate tests dont take things too far"; "did we lose the entire investigation system including trickery, persona, concealment etc? if so yes those need to be recovered or rebuilt".

255. **The investigation layer rebuilt (w13-invest) - built on judgement, open for review (2026-11-23).** Plan: `docs/plans/w13-invest.md`, tests in `Tests/suspicion_test.gd` and `Tests/ambush_test.gd`. The old `Investigation.gd` mostly survived under `Battle.inspect`, `doubt`, `suspect`, `spread`, `_look_harder`; trickery, persona, concealment were not lost. Three gaps rebuilt. Calls:
    - **Hit by an unseen attacker is a free inspect** (`Battle._hurt_by(t, by)`: a deceiver is doubted, one that cannot be made out is inspected at its cell). Only when the hit does damage (main's doubt gate); the original gave it on any attack, a miss included.
    - **Detective** (Effect stat `detective`, data-only skill, passive per rank): an own pass that finds something adds recon on what it saw through. Dropped from the original: "observes the unconcealed things it could not fully read" (Study and Evaluate cover reading).
    - **Ambush** (`Behaviours/ambush.gd`, Ranger after Snare, tag `defensive` so the AI uses it through `_defend`): hidden marks on the tiles nearest the aimed one within weapon reach (the original let the player pick up to rank tiles), concealment = rank, lasting to its side's next turn end; a foe walking onto one is stopped and takes a free attack, like Opportunist. **The effect is a guess.** Marks are concealed, so inspecting finds ambushes.
    - **New generic hooks:** `Battle.Mark.halts` (a walk that triggers it stops there, like a trap), `Battle.Mark.skill`, `Behaviour.tripped(b, mark, u)`. No Skill.gd field, no ceiling raised.
    - **Suspicion per pass stays main's 1 stack** (original: max(1, wis mod - distance)); **word of suspicion stays units-only** (original also shared tile suspicion).
    - **Not rebuilt:** Coordinate's support watch; the AI weighing where to Ambush beyond `_defend`; no visual check (marks draw through Overlay's generic mark path).
    - **New names to review:** `Detective`, `Ambush`, `Mark.halts`, `Mark.skill`, `Behaviour.tripped`, `Battle._hurt_by`. Suite: 10997 checks, 0 failed.
256. **Calm followers drill; a frame per unit (w13-aifast) - built on judgement, open for review (2026-11-23).** Plan: `docs/plans/w13-aifast.md`; answers "do bot units commanded by a skilled leader even need to check their preferences". Calls:
    - **Skilled leader = `Command.cha_of(leader) > 0`.** A calm follower (`AI._calm`): follows a living, skilled leader of its side that it hears and can locate. Not calm: hurt since its last act, Downed, channeling, a `behaviour` nature set, restless, cc'd, held, betrayed by its own side, party or leader. A calm one drills (`AI._drill`): reads only what is within reach plus 2, remembers, heals, strikes, else walks on the leader's aim or its best target, else keeps up. It skips temper, support, summon, line-up, search and the rest.
    - **HUD: a frame per unit** (`await process_frame` after each act, pace > 0 only), **opening looks lazy** (one a frame over the turn banner, `Battle.lazy_looks`), **`end_turn` runs under the last walks.** Same decisions where a unit plans in its own frame; a late unit's look comes after earlier units acted.
    - **Not built:** a far-from-foe routine (nothing measurable: the drill already covers followers, leaders start 12 tiles off and close by round 2).
    - **Player wait, M3 x 4, parties of 5 (mean / p95 ms):** 15 a side 1190 / 2800 to 218 / 737; 30 a side 4300 / 9800 to 776 / 3210. **30 a side p95 is still over the 1000 ms side budget.** Fights with parties run a little bigger (more acts a side turn).
    - **New names to review:** `AI._calm`, `AI._drill`, meta `calm_hp` and `aim`, `Battle.lazy_looks`, `looks_done`. Test: `test_calm_followers_drill` (7 mutations caught).
257. **The turn budget raised and the digest pin retired (w13-aifast) - built on judgement, open for review (2026-11-23).** Answers ?254 and closes ?245. `busy_fight.TURN_BUDGET_MS` 100 to 200 (a unit plans in its own frame while earlier walks and numbers show; a 3-tile walk shows 0.21 s); a side's player stare is reported against `SIDE_BUDGET_MS` 1000. The digest 3296533323 is gone: `busy_fight` prints `OUTCOME ok|FAIL` (each fight: at least a third of the side falls, someone is left standing, no unit alive at the end that never moved or acted). **Is 200 ms the number you meant, and is the stare of the first two rounds at 30 a side (3.2 s p95) acceptable?** Names to review: `TURN_BUDGET_MS`, `SIDE_BUDGET_MS`, `OUTCOME`.
258. **Tests loosened and consolidated (w13-tests) - built on judgement, open for review (2026-11-23).** Plan: `docs/plans/w13-tests.md`. About 35 pins loosened: content pins became relations to the data (tower portal menu, `Loot.describe`, the princess, champions' stat blocks, per-class tier numbers as orderings, quality `RANK_COST` monotone); 4 tests removed or folded (timid wait into craven; three describe-text tests, covered by the describe sweep); sampling loops sized to 3 sigma (last_stand 1500 to 600 casts and so on); `test_every_tab_draws_its_skills` 6.8 to 3.5 s. Suite 11017 to 11012 checks, 1037 to 1033 tests, 106 to 101 s. **Left alone on purpose:** rule arithmetic (defense, xp curve, respec, Pricing, slam), the AI relation tests, champions' skill lists (your spec), `hex_iii` at 60 seeds. **Not done:** merging the 137 tiny tests (staged state leaks; "dont take things too far"). **The one big cut left is game code:** about 41 ms a test is the museum `add_child` (Battle and Unit `_ready`), about 43 s of the suite. Names to review: none.

- [x] **Investigation layer lost in the sirens merge** (?255). Built; the player's yes to "recovered or rebuilt" answered it.
- [x] **Ambush: the effect is a guess**, and Coordinate's support watch is not rebuilt. Superseded by the user's answer 2026-11-23 (first attack roll out of concealment, Sally, Ambush Fusillade): built (?269). Coordinate's support watch stays unbuilt. (?255)
- [ ] **Free inspect on an unseen hit only when it does damage** (the original: any attack). Needs the user. (?255)
- [x] **What "skilled leader" means.** The user: tag `leader` or high charisma; built as `Command.skilled` (?271). Whether a calm follower also skips the strike choice stays as built. (?256)
- [ ] **30 a side: the first two rounds still stare ~3 s (p95)** against the 1000 ms side budget; raise it or cut further. Needs the user. (?257) Cut to 754 ms with parties (?260); no parties still 1842 ms (queue).

## Moved from todo.md (2026-11-19 consolidation): the user's annotations

- **Stun, Stunned, Borrowed Time (?83, ?85, ?119).** Your words: "Martial prowess high tier skill: Stun: attempt a very difficult attack. on a hit target attempts a difficult constitution check. On a failure, target is stunned for rank rounds". "Stunned is an easy debuff to cleanse, it's rank for cleanse purposes is halved". "Stunned is a `wound`: it can be healed off with an active skill". "Stunned units are tapped". Downed: "It does not end for the berskerker variant who acts as normal on borrowed time, but does for adventurers etc. who are tapped until they're back up". Built in the section "Tapped, helpless, Stun, Mindless Fury, Drone" above.
- **Contact with a concealed unit (?68).** Your note: physically contacting a concealed unit (a move blocked by it) grants 1 recon. Recorded in `docs/requirements.md`; built with Fixes (?127).

## Wave 14 (2026-11-23): a cheaper museum, far reads, Detective and Ambush in the AI

259. **A cheaper fresh museum (w14-museum) - built on judgement, open for review (2026-11-23).** Plan: `docs/plans/w14-museum.md`. Calls:
    - **`Unit.stat` and `_grants` outside a read stretch return the base at once if `lends(s)` is false** (a superset check, no cache to go stale); `_touch_bar` sets off the auto-equip the old gather did, so the bar order is unchanged (`command_test.test_default_bar` pins it).
    - **`pools()` skips `picks()` for a choice none of whose trees gives a reserve; `_lends_any` walks the slots without the dedupe; `Unit._ready` draws bars once** (was about 4 times).
    - **Measured:** museum `add_child` 43 to 17.8 ms; suite 107 to 67 s (interleaved), 11012 checks, 0 failed. `meadows_test.test_camera` and `test_tower_difficulty` crash in reverse order on base too (not touched).
    - **Left:** `Battle._enter` 7.5 ms (opening looks, Perception reads), `_fill_bar` 10 ms; the bar order depends on when effects are first gathered (a latent quirk, kept; worth a design look).
    - **New names to review:** none.
260. **The AI stare at 30 a side (w14-stare) - built on judgement, open for review (2026-11-23).** Plan: `docs/plans/w14-stare.md`. Calls:
    - **Cheap reads:** a foe beyond its side's sight reads `Perception.nothing()` (net -4); in sight but past half range with nothing hiding it (`Battle._plain`) reads `vague()` (net -2); both skip `Perception.unit`. `deceived`, `doubt`, `heard` and `twist` bookkeeping is skipped for them (guarded where a persona front at wisdom mod -3 or trickery could matter).
    - **`travel`** runs `_sightings` only if `_may_hide`; `suspicious` and `_check_stall` read only who `_plain` or `in_range` says matter; **`Unit.tick`** refits only on a change.
    - **`AI._far` / `_prowl`:** a unit with no nature or temper and every non-friend `_plain` 0 or 1 reads foes and allies within reach plus 1 and skips the full phases; **`HUNT_FAR` 2.0** heads straight for a hunt goal beyond move_left + 2. Drill reads allies within reach + 1 only.
    - **Measured (M3 x 4, p95 / mean ms):** 30 a side with parties 3380 to 754 / 231; 15 a side 790 to 268; no parties 4343 to 1842 (**still over 1000**). Unit turn mean 197 to 118; fights end a little different (30 lead 47.5 to 48 fallen); `astral_test.test_envoy` loses 29 checks (it loops until the battle ends).
    - **Not done:** no-party boxed-in full turns (~150 ms each: skip far allies' reads in `_full`, early-out in `_approach` / `_line_up`); `end_turn` per unit ~1.3 ms of stat reads outside a stretch.
    - **New names to review:** `AI._far`, `AI._prowl`, `Battle._plain`, `HUNT_FAR`. Test: `test_far_reads_and_turn` (7 mutations caught).
261. **Detective observes the unconcealed; word carries tiles (w14-detective) - built on judgement, open for review (2026-11-23).** Plan: `docs/plans/w14-detective.md`. Calls:
    - **`Battle._observe(o, center, reach)`** at the end of `survey()`: with stat `detective` > 0, each foe read at net 0 to 2 and each empty tile in reach at net 0 gets recon (rank per survey per target); it goes through `read()`, so lent reads count. Not at turn start; the original did it as a lead.
    - **`spread(o, t: Variant)`:** tile suspicion spreads by the unit word rule (WORD + cha mod); a unit standing on the tile can stop it (Bandwagon). Signal `told`'s `of` is a Variant.
    - **Tests:** `test_detective_observes`, `test_tile_word`; `clairvoyance_test.test_location_only` now expects the ally in earshot to be told. The `hud_test` seed was moved to 1 here (a Siren stall, fixed in ?262).
    - **Not done:** the AI weighing tile suspicion; a visual check.
    - **New names to review:** `Battle._observe`.
262. **The AI waylays with Ambush (w14-ambush) - built on judgement, open for review (2026-11-23).** Plan: `docs/plans/w14-ambush.md`. Calls:
    - **`Behaviour.waylays(c, cell) -> {tiles, skill}`** (empty default; Ambush answers from its own footprint); **`AI._waylay`** (self-directed, after `_rally`) walks each foe it makes out toward the nearest of the caster and its allies, prices the first covered tile with `score`, casts the best if the value beats the AP cost, then holds. Skips if its marks are up. No per-skill branch.
    - **Untuned:** the value against AP cost x AP and `PUSH x RIDER`; **the goal "nearest of caster and allies" stands in for an objective the AI does not have**; no seen-through discount; the ambusher holds, so the mark may be left behind next turn.
    - **Seed-3 stall fixed:** a luring Siren far from a song with no `_best_target` (a vague read) held forever; with no target it now hunts the last-seen cell. `hud_test.test_play_scene` is back on seed 3.
    - **Visual check done:** marks draw red-outlined (frames in the scratchpad, `shot_w14-ambush`). Test `ambush_test.test_ai_waylays` (a mutation caught).
    - **New names to review:** `Behaviour.waylays`, `AI._waylay`.
263. **Opportunist pricing, the rest of ?253 (w14-minor) - built on judgement, open for review (2026-11-23).** Plan: `docs/plans/w14-minor.md`. Calls:
    - **Shared Energy built:** `AI._struck` tallies what counted blows take from each holder's pool (Energy or reserve) in hotbar order; a blow beyond the pool counts 0. Test: `test_approach_weighs_opportunist` +2 checks. Not modelled: a holder's pool spent by its own non-reaction skills later in the turn.
    - **Flee already priced** through `_retreat` (only a walk's end beside the holder fires Opportunist; passing beside costs nothing).
    - **Not done:** `route()` pricing (it lives in Battle, which has no reads); `_recover`, `_escape`, `_hunt` / `_keep_up` unpriced (niche).
    - **New names to review:** none.

- [x] **A cheaper fresh museum** (?258's card). Built (?259).
- [x] **Detective observes the unconcealed, tile word** (?255). Built (?261).
- [x] **The AI weighs where to Ambush; a visual check of marks** (?255). Built (?262).
- [ ] **`HUNT_FAR` 2.0.** Needs the user. (?260) The Ambush pricing and the foe goal are gone with `AI._waylay` (?269).

## Waves 15 and 16 (2026-11-23): tile suspicion priced, the stare, the Nexus, the test audit, Ambush rebuilt, Ire

The user's words: `docs/agents/answers-2026-11-23b.md`.

264. **The AI prices suspected tiles (w15-tilesus) - built on judgement, open for review (2026-11-23).** Plan: `docs/plans/w15-tilesus.md`. Calls:
    - **`Battle.dread(..., wary, doubt)`:** `doubt` = `u.suspects(c)`; on a wary walk with doubt > 0 and net < 0 the tile costs at least `SUSPECT_TILES` (3) x min(doubt, `SUSPECT_STACKS` 3). Stack 1 equals a hint's price (max, not sum). No AI.gd change: every walk prices through `route()`.
    - **Only while net < 0** (once the tile is made out, the real hazard price takes over); wary walks only; every tile of the route.
    - **Test:** `path_test.test_suspected_tile_costs_more` (a mutation caught). busy_fight 15: OUTCOME ok, turn time noise.
    - **Not done:** a visual check. **New names to review:** `SUSPECT_TILES`, `SUSPECT_STACKS`.
265. **The rest of the museum (w15-museum) - not built, open for review (2026-11-23).** Plan: `docs/plans/w15-museum.md`. Calls:
    - **Not worth it as is:** a read stretch around `_fill_bar` fails `command_test.test_default_bar`, `test_bar_place`, `hud_markers` / `hud_test` toggles (in a stretch `stat()` skips the `_touch_bar` path, so the bar auto-equip order changes); any other memo needs invalidation on slots, timed, items, footing, hp, ground. Gain at most ~10 s of the suite. `Battle._enter` 7.5 ms is gameplay.
    - **Lead:** make auto-equip explicit rather than a side effect of `stat()`; then a stretch around `_fill_bar` is safe (card in `docs/queue.md`).
    - **New names to review:** none.
266. **The AI stare at 30 a side, again (w15-stare2) - built on judgement, open for review (2026-11-23).** Plan: `docs/plans/w15-stare2.md`. Calls:
    - **`_reads(b, u, near)`:** a plain full turn reads allies only within longest reach + 1. **`_approach`:** a foe beyond move_left + `APPROACH_FAR` (3.0) gets the nearest free tile beside it, unpriced. **`_stretch`** asks for self-only stride skills first; **`_line_up`** drops foes beyond ceil(move_left) + longest drive reach + `LINE_UP_MARGIN` (2).
    - **Measured (M3 x 4, stare mean / p95 ms):** 30 no-party 338-342 / 2050-2105 to 244-248 / 939-959 (**only ~5% margin**); 15 no-party 89 / 172 to 96 / 194 and 15 lead 123 / 228 to 130-143 / 236-264 (slightly worse, under 1000); 30 lead flat. Fights end a little different (30 a side 51.0 to 51.5 fallen).
    - **Not done:** a unit whose straight line to a far foe runs through its allies still does not move (`walk()` pops the occupied tail; a path round the column would fix it); `end_turn` stat reads (under 5%).
    - **Test:** `test_crowd_shortcuts` (4 checks, 2 mutations caught). **New names to review:** `APPROACH_FAR`, `LINE_UP_MARGIN`.
267. **The Astral Nexus (w16-nexus) - built on judgement, open for review (2026-11-23).** Plan: `docs/plans/w16-nexus.md`. Calls:
    - **`astral_void`:** enter 99, tags void and detrimental; a tile on the map, so effectively impassable by budget, flyers cross at 1, no fall damage. **`starpower_generator`:** a full source (x5 Power regen on its lattice), passable, not brittle, inert: no self-recharge.
    - **Power Star:** `Item.soaks` (share per rank of the wearer's overflow Power kept, rank 1 = 15%, up to the wearer's max base Power) and `Item.held`; used from a slot gives `held` as Power, then 0 (a copy, as `emptied()`); `Item.usable()` replaces `restores and not empty`. **It is the dungeon's win reward on all floors, not a starman drop** (Starman is shared with the Envoy); drops empty; **the charge is lost on save** (items save by id).
    - **Layout** in `Scripts/AstralNexus.gd` (seeded): 23x13, 3 generators, startile grid on even offsets 25% broken, panes fill the gaps, 15% void, an unreachable lattice voided; 4 to 6 starmen on `unaligned` (`starmen` is neutral).
    - **Tests:** `tower_test.test_nexus`, `test_power_star` (mutations caught). **New names to review:** `starpower_generator`, `astral_void`, `power_star`, `soaks`, `held`.
268. **The test audit, segments, a risk tier (w16-testaudit) - built on judgement, open for review (2026-11-23).** Plan: `docs/plans/w16-testaudit.md`. Calls:
    - **Audit:** of the 20/80 cuts only the `busy_fight` digest was medium risk (nothing in `quick` played a whole AI fight); new `sims_test.test_fight_outcome` (10 v 10 in parties, ~2 s; a mutation that idles one side caught). Tier numbers, content pins and describe tests: low, left.
    - **Segments by file** in `Tests/segments.txt` (ai 189, ui 115, rules 270, sims 12, tools 12, content 441 as the default): `t.sh <wt> <segment>`, they combine. **`risk`** runs `Tests/risk.txt` (26 tests, ~680 checks, seconds); `quick` keeps risk tests even if slow-listed (+7 s).
    - **Left:** `level_down`'s 0.07 band (a DC off by 1 can slip it; check_test forecasts cover the odds); no per-test risk comments.
    - **Numbers:** full 11033 checks, 1039 tests, ~60 s; quick 10193 checks, 48 s. **New names to review:** `risk`, `segments.txt`.
269. **Ambush as the first attack roll out of concealment (w16-ambush) - built on judgement, open for review (2026-11-23).** Plan: `docs/plans/w16-ambush.md`. Your words (answers-2026-11-23b): "ambushes are the first attack rolls out of concealment. It usually only works on the first attack"; Sally "+ rank * 20% damage on 'ambush'"; "Ambush Fussilade: 'Ambush' and triggered effects from 'Ambush' proc on rank subsequent attack rolls". Calls:
    - **`Unit.ambush_rolls`** counts attack rolls made as ambushes since its side's turn began (zeroed with `exposed`); `Battle.ambushes()` is true for the first roll (concealment test) or while the count is within the `fusillade` stat; `roll_attack()` counts. **A miss uses the ambush up; re-hiding mid-turn does not reset it; checks and area blows with no attack roll do not spend it; auto multi-target: only the first target.**
    - **`Requirement` test `ambush`** (any skill can pay off on an ambush). **Ambush skill:** now a melee dex blow, 1d10 a rank, contingency `test=ambush edge=1`, flat price (3 AP, 2 cost); lost its `defensive` tag, so `AI._defend` no longer casts it. **Sally:** passive, damage 0.2 a rank tagged ambush, on Slayer after Gank and on Rogue's Blade root after Backstab (Rogue has no Slayer tree). **Ambush Fusillade** (you wrote "Fussilade"): passive, stat `fusillade` +1 a rank, Slayer after Sally.
    - **`damage_range` now counts the attacker's `damage` stat** on the blow's tags: every damage effect shows in forecasts (HUD and AI), not only Sally.
    - **Removed:** `Mark.halts` and `skill`, the walk halt, `Behaviour.tripped` / `waylays`, `AI._waylay`, `Behaviours/ambush.gd`: the tile marks of ?262 (you asked what they meant).
    - **Tests:** `ambush_test` rewritten (first roll only, chain, fusillade, who); 4 mutations caught. busy_fight 15 flat.
    - **New names to review:** `Unit.ambush_rolls`, `fusillade`, Sally, Ambush Fusillade.
270. **Ramut's Ire on a tree (w16-ire) - built on judgement, open for review (2026-11-23).** Plan: `docs/plans/w16-ire.md`. Your words: Ire belongs on Ramut's tree. Calls:
    - Ramut had a god file (pool only), so a new `Trees/ramut.tres` (root "Ramut", physical, `role.py tree`) is wired as his own Divinity tab in `Gods/ramut.tres`, as Luun's and Eros's. **Ire at tier 2, after Pray** (Pray stays tier 1 through `Role.shared`), as Luun's Level Down; the only skill on it, and a drawback-ish effect, so no higher.
    - **Oddity:** learned, Ire's effect lands on its holder (own concealment defeated); no cost or ap fields, system-applied. Left as is.
    - **Tests changed:** `god_slots_test.test_cleric`, `test_paladin`, `hogel_test.test_cleric` (Ramut now offers Divinity). **New names to review:** `Trees/ramut.tres`.

- [x] **The AI weighs tile suspicion** (?261). Built (?264).
- [x] **No-party 30 a side stare** (?260). Built (?266): ~950 ms p95, ~5% margin.
- [x] **Ambush: the first attack roll out of concealment, Sally, Ambush Fusillade; Astral Nexus; Ire on Ramut's tree; test audit** (the user, 2026-11-23). Built (?267 to ?270).
- [x] **Make auto-equip explicit, then a read stretch around `_fill_bar`** (the museum lead). Built (?273); the gain was ~4%, ~2.5 s (?277).
- [ ] **Ambush and Sally numbers as built, the concealment stretch (since its side's turn began, a miss uses it up), the Nexus void / generator / Power Star calls, whether Ire needs a cost, `SUSPECT_TILES` 3.** Needs the user. (?264, ?267, ?269, ?270)
- [ ] **Optional micro-cuts (each under ~5%):** `end_turn` per-unit stat reads, a path round a unit's own column, Opportunist on `_recover` / `_escape` / `_hunt`, `Battle._enter`. Needs the user. (?263, ?265, ?266)
- [x] **Vindictive and flirty tempers, first-time pop-ups, longer holds, "skilled leader"** (the user, 2026-11-23). Built (?271).
- [x] **Cheap macro decisions for packs, armies, swarms** (the user, 2026-11-23). Built (?272).
- [ ] **The "Grudge" pop-up shares the Grudge skill's word; weights, cha 14, hold lengths; units facing a swarm read every rat; herd members in a fight take full turns.** Needs the user. (?271, ?272)

## Wave 16 tempers and swarm (2026-11-23)

The user's words: `docs/agents/answers-2026-11-23b.md`.

271. **Tempers: vindictive, flirty, pop-ups, holds, skilled leader (w16-tempers) - built on judgement, open for review (2026-11-23).** Plan: `docs/plans/w16-tempers.md`. Calls:
    - **Vindictive:** `Unit.wrongs[Faction]` = blows that unit landed on each side this fight (kept on the striker; cleared in `Battle._listen`). Ally hit = the victim's side is a friend; word travels, no sight check. `AI._grudge` joins `_hunted`: 2.0 a blow, at most 3 blows (6.0), in tiles in `_targeting` and HP-worth in `_strike`. `Bio.grudges` words naming the target (name, tag, class, race, looks, as read) = HUNT. Your "Persona" is read as the unit's Bio (the code's Persona group is the deception system).
    - **Flirty:** affinity = `Bio.fancies` words, else charisma as read >= 14 (`Difficulty.stat_at("high")`), else a benevolent look (Beautiful, Radiant) with no stats read. Support skills go to fancied allies first; on a fancied foe a soft skill (no damage tiers, or love-tagged) +2.0, a damaging one half.
    - **Pop-ups:** `Battle.first_time(u, what)` once per unit per fight: "Grudge" on a strike or main approach at a grudged target, "Smitten" on a support or soft strike at a fancied unit. **"Grudge" is also the Grudge skill's name.** HUD holds `SIGN_HOLD` 0.3 s per visible sign during a unit's AI act, at most 0.9 s; every passive sign counts, not only temper ones.
    - **`Command.skilled(l)`** = tag `leader` or cha >= 14; `AI._calm` uses it (was cha > 0). `ai_tactics_test.test_calm_followers_drill` changed: a +1 leader is no longer skilled.
    - **Tests:** `bio_test.test_vindictive_grudge`, `test_flirty_supports_fancied`; 5 mutations caught. Suite 11065 checks, 0 failed. busy_fight 30: stare p95 743 ms (main 764).
    - **Not done:** a soft-strike test, screenshots, a `leader` Glossary tag (nothing carries it), `unit.py new` flags for grudges and fancies. **New names to review:** `Unit.wrongs`, `Bio.grudges`, `Bio.fancies`, `first_time`, `SIGN_HOLD`, `Command.skilled`.
272. **Herds, ranks (w16-swarm) - built on judgement, open for review (2026-11-23).** Plan: `docs/plans/w16-swarm.md`. Calls:
    - **Herd:** like = same side, Role, Race; a herd needs 3 alive. Turn order calm, herd, far, full. One plan per kind a side turn (`_herd_plan`, cached in Battle meta): the lowest-key plainly seen foe within walk + `COHESION` 3 of the centre (key = HP for `weakest`, else magical or physical Defense), else the nearest seen, shape or last sighting. A member walks beside the goal without reads or pricing; one 3 tiles ahead of the centre waits. A member that is hurt, cc'd, tempered, hunting, on a non-`weakest` strategy or with a foe in reach takes a full turn.
    - **`Scripts/Ranks.gd` (`Battle.ranks`):** sorted arrays per side (HP kept on `hp_changed`, Defenses rebuilt once a side turn). Only consulted for foes plainly seen.
    - **Measured (M3 x 4, stare mean / p95 ms):** 30 no party 199-215 / 741-803 to 147-154 / 293-298; 30 parties 162-168 / 528-555 to 135-136 / 292-305; 15 no party unchanged (87 / 185); 60 rats v 15 (`busy_fight swarm=M`) 159 / 311 to 111 / 293. Winners flipped in 30 with parties (0 v 9 to 7.5 v 1, even sides).
    - **Tests:** `test_herds` (20 checks), `test_ranks_match_a_scan` (9); 7 mutations caught. Suite 11086 checks, 0 failed.
    - **Not done:** non-herd units facing a swarm still read every rat (Ranks or a spatial cut could serve `_targeting`); herd members in a fight take full turns; no visual check. **New names to review:** `HERD`, `COHESION`, `Ranks`, `Battle.ranks`.

## Wave 17 equip (2026-11-23)

273. **Auto-equip explicit (w17-equip) - built on judgement, open for review (2026-11-23).** Plan: `docs/plans/w17-equip.md`. Calls:
    - **Cause:** `_fill_bar`'s first `_slot_keys()` reached `stat()` -> `_touch_bar()` -> `_sync_new()`, which filled the bar in auto-equip order whenever a passive was on; in a stretch `stat()` skipped it, so the passes ran in another order.
    - **One hook:** public `Unit.sync_bar()` (was `_sync_new`), called by `unlock()`, `_sync_granted()`, `_fill()` and the HUD's `_refresh_bar()` (was `get_equipped()` called for its sync). Removed from `equipped()` and `get_equipped()`; `_touch_bar()` deleted. `_fill_bar()` = begin_read, `_fill()`, end_read. No `learn()` API.
    - **Checks:** `equip_test.test_auto_equip` +2 (a read auto-equips nothing; `sync_bar` does); mutations: hook back in `equipped()` fails it, no explicit sync in `_fill()` fails 8. Suite 11088 checks, 0 failed, 1047 tests. `reverse`: `meadows_test` camera crash is the same on main.
274. **The fill-order quirk kept (w17-equip).** A unit with a passive on that takes a slot fills in auto-equip order, others by the passes (pillars, actives and toggles, passives from the right, optional lends); 13 roles x levels 1/5/9/13/20 and the museum's units (89 bars) are identical on main. Unifying would move Icor's bar (Mana before Hex): for the user (also ?259).
275. **Tests call `sync_bar()` on the line that hands a skill** (545 sites, 118 files, by script): mechanical, no check changed, a noisy diff. A helper was not added.
276. **The `_filling` cache drop in `_held_fx()`** (`_fx_bar` = hotbar hash) is defensive: no role has a slot-granting passive at setup, and removing it fails nothing. Keep or drop.
277. **The gain was ~4%, not ~16%:** A/B alternating, main 62, 63 s against branch 60, 60 s. Remaining setup cost is `refit()` / `_take_looks()` in `_ready`; not pursued. Lead: per-test museum setup outside `_fill_bar`.

## Wave 17 reverse (2026-11-23)

278. **`reverse` crash fixed at the helper and a runner sweep (w17-reverse) - built on judgement, open for review (2026-11-23).** Plan: `docs/plans/w17-reverse.md`. `Test.hud()` parented the HUD to the root, so a test's `scene.free()` left it; a leaked HUD's `selected` pointed at a freed Unit and `BattleCamera` assigned it in `meadows_test` under `reverse`. Fixed in `Tests/test.gd` (parent = the battle's parent) and `Tests/run.gd` (frees new root children after each test, prints a count). The sweep frees rather than fails (failing would break single-word runs of tests that free late). Suite 11088 checks, 0 failed; `reverse` 0 failed; mutations caught.
279. **Game code left alone (w17-reverse).** `BattleCamera` taking the group's last `hud` and not checking `hud.selected` is only reachable through a leaked HUD, which exists only in tests.

## Wave 18 batch 1 (2026-11-23)

The user's words: `docs/agents/answers-2026-11-23c.md`.

280. **Horizontal scroll, reusable (w18-hscroll) - built on judgement, open for review (2026-11-23).** Answers "horizontal scrolling for class selection / implement on parent menu so it can be used as needed for nonbreaking horizontal lists". Plan: `docs/plans/w18-hscroll.md`. Calls: new `Scripts/HScroll.gd` (an HBoxContainer: arrow, ScrollContainer, arrow; not a ScrollContainer subclass because arrows cannot be its children); "parent menu" read as `Choice` (entry's Side, Role, Scenario all use it), `choice.tscn` Options now under `Scroll`; only a row wider than `max_width` 440 scrolls; one static `HScroll.amount(event, width)` rule (wheel either axis goes sideways, `STEP` 48 px, trackpad by larger axis, drag with a 4 px slop that cancels the pressed button and swallows the release); arrows both shown while it scrolls, the end one disabled, a click pages; `Choice.pick()` scrolls the pick into view; scrollbar hidden. `champions_test.test_entry` lookup became `%Options`. Tests `Tests/hscroll_test.gd`. Names to review: "HScroll".
281. **Combat camera pan (w18-camera) - built on judgement, open for review (2026-11-23).** Answers "allow scrolling using multitouch, mousing to edge (only when mouse is in window)", "adjust speed based on scroll speed / distance to edge, tempered by map size" and the ?279 adjustments (elliptical radius, same total velocity at top-middle and top-right, dead zones, pause at the very edge outside full screen). Plan: `docs/plans/w18-camera.md`. Calls: edge zone is outside an ellipse inscribed in the view, `EDGE_DEAD` 0.88, smoothstep ramp to full speed at the ellipse, direction the normalised offset (`edge_vec` replaces `edge_dir`); `map_gain` = sqrt(map / view) clamped 0.75 to 2, on edge-pan and trackpad only; trackpad `InputEventPanGesture` times `GESTURE` 1.5 (**sign and scale unverified on hardware**); two-finger touch drag pans 1:1; pinch skipped (no zoom exists); the window check polls `DisplayServer.mouse_get_position()` each frame, pausing on the outermost `WINDOW_RING` 2 px when windowed (headless skips it). Names to review: "edge_vec", "map_gain".
282. **Leak list (w18-leaks) - built on judgement, open for review (2026-11-23).** Answers "proactively cleaning up leaks is fine" and "add it to a running list of leaking items ... leaks are leaks" (?278 answered: leaks are listed, not failed). Plan: `docs/plans/w18-leaks.md`. Calls: `Tests/run.gd` appends `test<TAB>Class<TAB>path` to `Tests/leaks.txt`, merged and sorted (order-stable under `reverse`), written atomically; committed, not gitignored; starts with a one-line `#` header (nothing leaks now); parallel runs can lose a line to a race and the next run re-adds it. Names to review: none.
283. **Nexus layout (w18-nexus) - built on judgement, open for review (2026-11-23).** Answers "starpower generators are darker orange tiles with a star ... sprinkled through the nexus dungeon which should be a little larger. Procedural generation example ... pane * base power, tile * x, (Gen), tile * x, pane * base power. Diagonals are panes ... a wired circuit", "same tiles as astral envoy encounter". Plan: `docs/plans/w18-nexus.md`. Calls: the rule read as written (tiles x 1 to 2 out each of 4 sides of a generator, panes on its diagonals) and "pane * base power" as the pane run filling the way to the next generator (a wire), not a count; generators 4 to 6 by seed joined by L-shaped wires along a nearest-neighbour tree plus one loop, the landing wired in; the rest stone floor within 2 of the circuit (15% void), void beyond; map 23x13 to 29x17; same `startile` / `starpane` resources; art `Tiles/starpower_generator.png` (#a84a0c with a yellow star), drawn by `Overlay` through a layer's own `look`. Files: `Scripts/AstralNexus.gd`, `Scripts/Overlay.gd`. Names to review: "starpower generator".
284. **Power Siphon (w18-nexus) - built on judgement, open for review (2026-11-23).** Answers "the generators have Power Siphon: draining 5% health on turn end to gain 5% power, from each unit standing on the live circuit". Calls: "live circuit" = lattice cells joined side-on to a generator with charge > 0 (`Battle.circuit_ends`); a new Effect stat `power_siphon` 0.05 (not `siphon`, which exists) on the generator's `at_end`, applied for one turn and read after the tick (`Battle._siphon`): loses 5% of max HP, gains 5% of max energy via `grant_energy`, each at least 1; counts as helpful in `Effect.helps()`, so cleanses skip it; Starmen on the circuit are siphoned too. Not built: the AI ignores it (it walks the circuit blind), generators do not recharge from siphoned Power. Names to review: "Power Siphon".
285. **Flex trees offered while levelling (w18-flex) - built on judgement, open for review (2026-11-23).** Answers "Flex trees reflect backgrounds ... Most classes get one flex tree per 10 levels. Rogues and Bards get one every 5, Adventurers get one every 3. flex trees have prereqs, they are slackened for Rogues and Bards (`generalist`) adventurers and jesters don't have requirements (`jack`)". Plan: `docs/plans/w18-flex.md`. Calls: one `TreeChoice` named "Flex Tree" per unit (`Unit.flex_choice()`) drawn on the base General tab, saved through `picked`; slots = level / `Role.flex_every` (10; Rogue, Bard 5; Adventurer 3) plus `Unit.flex_extra`; which trees: `Role.flex` keys, a `jack` unit every grant tree; prereqs are base-stat floors (`SkillTab.needs`), `generalist` lowers every floor by 2, `jack` none; `generalist` and `jack` are tags on a new `Role.tags`, and `Unit.has_tag()` reads them; the Skills badge lights for a tree due; `Util/role.py flex`. Jester hook ready: `flex_needs`, `flex_extra`, `flex_missing`. Names to review: "Flex Tree", "generalist", "jack".
286. **Scout tree and who offers it (w18-flex) - built on judgement, open for review (2026-11-23).** Answers "Ranger General, Scout Martial: Rogues, Paladins have access to Scout Martial as a flex option". Calls: `Trees/general_scout.tres` (General, category martial) with the Ranger's Scout skills minus its capstone (Hide, Stamina T1; Eyes Forward, Wary T2; tiers made up); prereq dexterity 10, wisdom 11 (made up); the Ranger lists it under its general tab, which duplicates its own Scout root (the alternative is not listing it); Student offered as a flex to Wizard, Warlock and Bard (?199); Student has no prereq. Open: the Paladin's and Warlock's god-slot "Flex" choice shares the word with flex trees. Not built: NPC or hireling exclusive flex users; the AI never picks a flex tree. Names to review: "Scout".
287. **Rolling window for the bar cache (?276 answered "probably keep a rolling window?") - not built (2026-11-23).** Best guess: keep the `_held_fx()` stretch cache and bound it as a small LRU keyed by the hotbar hash, instead of dropping it when the hash changes while `_filling`. Not built: `Unit._held_fx` holds a single entry and the reading is unclear (a window of recent bars, or of recent reads?). `docs/plans/w17-equip.md`.

## Wave 18 batch 2 (2026-11-23)

The user's words: `docs/agents/answers-2026-11-23c.md`. Plans: `docs/plans/w18-starmen.md`, `docs/plans/w18-jester.md`.

288. **Astral void, jumps and Hop (w18-starmen) - built on judgement, open for review (2026-11-23).** Answers "astral void: impassable to units without floating/flying; like pits, can be jumped over" and "Hop (active movement skill, small Power cost, performs a Jump)". Plan: `docs/plans/w18-starmen.md`. Calls: walkers keep enter 99 on void (?267), so it is "impassable" in paths and the Path overlay; a unit tagged `floating` or `flight` ignores it (`Battle._cost` over void = 1); a jump must land on a tile its jumper can stand on (`Battle.footing(u, c)`), so not on void unless aloft; a new behaviour hook `fits_at(b, caster, cell)` is asked before payment in `Battle._cast_at`; `Behaviours/jump.gd`; Hop is an innate active (1 AP, 1 cost in Power, radius 2, lent), not a `trait`-tagged skill, because the tooling's traits are always-on passives (`skill.py` refuses an active one); any unit with a jump skill jumps first on its main approach when that lands nearer its goal (`AI._leap()`); tags `floating`, `jump`, `void` (Glossary). Names to review: "floating", "jump", "void", "fits_at", "footing".
289. **Floaty's numbers (w18-starmen) - built on judgement, open for review (2026-11-23).** Answers "Floaty (Jump skills' distance x (rank+1); movement / (rank+1))". Plan: `docs/plans/w18-starmen.md`. Calls: the rank is Floaty's own (a starman has it at 1): Jump x2, movement /2, Hop's base 2 tiles becomes 4; two new Effect ops `scale` (x(1 + amount * rank)) and `divide` (/(1 + amount * rank)); `Skill.span` hands its range to range effects as the stat base, so a range `mul` or `scale` scales the whole range; Floaty's range effect is tagged `jump`, so any later jump skill scales; movement is left fractional (2.5 at rank 1 on 5), not rounded up. Floaty is a trait (`unit.py trait`), tagged `floating`. Names to review: none (Floaty, Hop and Jump are yours).
290. **Starmen tempers: Flippant, Vindictive, Power Hungry and several tempers a unit (w18-starmen) - built on judgement, open for review (2026-11-23).** Answers "Flippant (skirts evasively/aimlessly; significant damage switches it to aggressive)", "Vindictive (for starmen: single-mindedly prioritises hostile astral creatures unless otherwise aggressed; one composable rule)", "Power Hungry (moves beside targets with high Power, else Energy or reserves, transfers energy; also to neutrals)". Plan: `docs/plans/w18-starmen.md`. Calls: a Bio can carry further tempers in `Bio.also` beside `behaviour` (`Unit.tempered(t)`; `temper()` stays the lead one; `unit.py --also`); the starman is vindictive with `grudges = ["astral"]` (one rule: a standing grudge on the tag, blows add grudge as before), its `hunts` (Stellar Order) and aggressive behaviour dropped, default faction Starmen (neutral; battles set their own), appearance Beast. Flippant turn: feed if a rich target can be reached this turn, else skirt (4 random safe walk tiles, then a random safe hop, else away), no scoring; it turns aggressive for the rest of the fight at 25% of max HP lost (any source, `Unit.harmed`, `Bio.FLIPPANT`). Power Hungry: not hostile (any non-friend, neutrals included, stays neutral); `AI._richest()` ranks Power, then Energy, then reserves by share of max (`Read.energy`); skips targets under 25% (`Bio.FEED`); once aggressive a hunger pull in `_hunted()` (`HUNGER` 4 x share); drains with any siphon-tagged skill (Energy Transfer added to the starman). Names to review: "also", "tempered", "harmed".
291. **Grudge weight 5 against 10, and the 25% thresholds (w18-starmen) - built on judgement, open for review (2026-11-23).** Answers the same words as ?290. Plan: `docs/plans/w18-starmen.md`. Calls: a foe named in `Bio.grudges` is now `GRUDGED` 5 (it was a HUNT 10), so under 3 blows (6) a foe that keeps striking the unit outweighs the standing grudge ("otherwise aggressed"); the three thresholds are all 25% (Flippant's damage, Power Hungry's floor, `FEED`) and are guesses. Mutations: `GRUDGE` 0 and `GRUDGED` 20 each fail a test. Names to review: none.
292. **Jester's inverted page and what it costs (w18-jester) - built on judgement, open for review (2026-11-23).** Answers "jesters have a class skill page and an inverted class skill page. They may unlock flex trees through their inverted page by spending base stats instead of skill points. martial: costs a chosen mental stat. specialist: costs str or int. caster: costs a chosen physical stat." Plan: `docs/plans/w18-jester.md`. Calls: the page is `SkillRoot.inverted` on a root (`Trees/inverted.tres`, "Inverted"; a tab kind with its own colour); any open tab holding such a root sells flex trees for stats (`Unit.inverted()`); `Unit.buy_flex(t, stat)`: price 1 point (`FLEX_PRICE`), permanent (base stat lowered and saved), floor 6 (`FLEX_FLOOR`; a stat at 6 can't pay), stat in `FLEX_PAY[kind]` (martial int, wis, cha; specialist str, int; magical str, dex, con), the tree is picked as "Flex Tree/<t>" and opens like a levelled one; the offer is every grant tree not native or taken (wider than `Role.flex`), prereqs still asked (floors) unless `jack`, checked before paying only; the UI shows the trees in a box "INVERTED · PAY 1 BASE STAT", a click shows a button per paying stat in the footer ("Dex 13>12"), greyed with the reason when it can't; levelled flex slots still come on the General tab. The mental stats are read as int, wis, cha and the physical as str, dex, con. Names to review: "Inverted".
293. **Jester class and its skills (w18-jester) - built on judgement, open for review (2026-11-23).** Answers "Jester is a new class". Plan: `docs/plans/w18-jester.md`. Calls: focus specialist, stats str 9 dex 13 con 10 int 11 wis 11 cha 14, noun "Performer", tends pragmatic, gambeson and dagger, `flex_every` 10 (its route is stats), tag `jack`; on the entry screen. Skills are data only, no behaviours, all `??`: Jester root: Jape (cha vs wis save, Jeered: Defense -1 a rank, 2 turns), Heckle (after Jape; Heckled: luck -1 a rank), Tumble (passive Defense +1 a rank), Juggle (dex pierce 1d4, range 4), Read the Room (capstone, needs 3: insight +1 a rank); Inverted root: Fool's Luck (passive luck +1 a rank), Pratfall (adjacent, dex save, Off Balance). Names to review: Jape ??, Heckle ??, Tumble ??, Juggle ??, Read the Room ??, Fool's Luck ??, Pratfall ??.
294. **Jovia, the warlock patron (w18-jester) - built on judgement, open for review (2026-11-23).** Answers "New warlock patron: Jovia, allows warlocks to use the inverted Jester tree." Plan: `docs/plans/w18-jester.md`. Calls: Jovia's own tree is the Jester's Inverted root itself (one `SkillRoot`, shared by the class tab and the god), so a Jovia warlock gets the very same page; the warlock pays the same stat costs; picked as a patron like Hogel or Elmon (Flex burns work as for any patron); she must meet the trees' prereq floors (a Scout needs dex 10, wis 11), checked before paying; colour #e08fc4 (`PATRONS`). Not built: a `jest` tag (no rule would read it, a token) and a suit (no suit system in code yet). Names to review: "Jovia".
295. **`flex_kind` on tabs (w18-jester) - built on judgement, open for review (2026-11-23).** Answers ?285's open "which trees count as martial, specialist, caster". Plan: `docs/plans/w18-jester.md`. Calls: new `SkillTab.flex_kind` (empty means its own category): Scout martial, Journeyman specialist (its category stays "", its tier gating unchanged, so `flex_kind` carries the type), Student caster; `SkillTab.flex_type()` reads it. Names to review: "flex_kind".
296. **`skill.py` wrote `intensity = &"faint"` on Juggle (w18-jester) - open, for the user or a tooling card (2026-11-23).** The builder's `skill.py` run wrote that line on one skill; no other skill has the field, and `skills_test` flagged it undescribed; removed by hand. Why the tool writes it (a default, a flag, a stale template) was not traced. Best guess: a tooling bug, fix in `Util/skill.py` so no skill gets the field unless it is set. Card in `docs/queue.md` (w18-skillpy). Plan: `docs/plans/w18-jester.md`.

## Wave 18 batch 3 (2026-11-23)

The user's words: `docs/agents/answers-2026-11-23c.md`. Plans: `docs/plans/w18-fog.md`, `docs/plans/w18-monster.md`, `docs/plans/w18-theseus.md`.

297. **Fog of war: range, shades and memory (w18-fog) - built on judgement, open for review (2026-11-23).** Answers "units can only see others within full wis range. tiles outside this radius are in the 'fog of war'". Plan: `docs/plans/w18-fog.md`. Calls: the fog radius is the existing `Battle.perception_range` (wisdom total, the full ring and not the half), the same number as unit sight, and the fog is the union over the player's side (`command.faction()`), hidden where `sight` is off; three shades: in sight clear, explored (seen once, out of sight now) dimmed (`FOG_EXPLORED` 0.45), never seen darker (`FOG_UNSEEN` 0.75, terrain faintly visible, not black); "remembered terrain" is the dim shade only, not a stored copy of the ground, so a changed tile shows its live look; memory is `Battle.explored[faction]`, filled only when asked (`sight_cells()`) so AI sides pay nothing; drawn as one Sprite2D `Fog` (1 px a tile, nearest filter) above the Overlay and below the units, redrawn on a HUD refresh only when the side's eyes change; units in fog stay hidden by `read()`, pings and Clairvoyance still show. Names to review: "fog", "explored".
298. **The AI needed no fog change (w18-fog) - built on judgement, open for review (2026-11-23).** Answers "units can only see others within full wis range" (the AI must respect it). Plan: `docs/plans/w18-fog.md`. Calls: every AI target and react path already goes through reads and `located()` (`_foe`, `_strike`, `_best_target`, `_far`, `_hunt`; stare and investigation use `in_range` >= 2), so nothing was added and no turn cost; `sight_test.test_fog` pins it (a foe 2 tiles off past wisdom 1 is not struck). Not built: the AI's `known_ground` does not consult `Battle.explored` (its pathing through unseen terrain is unchanged), no minimap to show fog on, no frozen copy of explored tiles. Cards in `docs/queue.md` (w18-fog-ai, w18-fog-frozen).
299. **`TreeChoice.free`: a path that costs no points (w18-monster) - built on judgement, open for review (2026-11-23).** Answers "At level 1 a singular path must be selected or will already be pre-selected ... Monsters get their traits for free, and may rank them up with skill points". Plan: `docs/plans/w18-monster.md`. Calls: one generic flag on a `TreeChoice`: picking a tree of it learns its opening skills (root branches with no `after` or `needs`) at rank I for nothing (`Unit.take_free()`, run on pick and on ready, idempotent); not a purchase, so a level curse does not take it back; ranks past I raise as any skill (II costs 2); a later skill on a path with a prereq costs points as usual; the skills badge lights while a free choice is unpicked (`Unit.free_due()`); not forced, a Monster can enter battle unpicked (no traits). Names to review: "free".
300. **The three Monster paths and what is in them (w18-monster) - built on judgement, open for review (2026-11-23).** Answers "We'll start with three paths: starmen, Sirens, skeletons". Plan: `docs/plans/w18-monster.md`. Calls: tabs kind "Path" named Starmen, Sirens, Skeletons over roots `Trees/monster_{starmen,sirens,skeletons}.tres`, tag martial; Starmen = Floaty and Hop (Hop an active); Sirens = the Siren's innate traits Alluring, Seaborn ??, Opportunist (not Oceanic, a learned toggle drawback; not Rake, Drown, Sing, Tonefoolery, which are "the unit's own"); Skeletons: the Skeleton had no trait skill (only unit tags undead and summon), so a new invented trait **Undead ??** (`Skills/undead.tres`, tag `undead`, data only, carries the tag since `has_tag` reads learned skills); ranking Undead ?? changes nothing yet (no per-rank effect), so the Skeletons path is thin (one trait). Card in `docs/queue.md` (w18-undead-rank). Names to review: "Undead ??", "Seaborn ??", "Monster".
301. **Monster class setup, playable, `picked` exported (w18-monster) - built on judgement, open for review (2026-11-23).** Answers "Monsters are a unique class". Plan: `docs/plans/w18-monster.md`. Calls: Role `Roles/monster.tres`, focus martial (str 14 dex 11 con 14 int 8 wis 10 cha 9), noun "Monster", tends pragmatic, gambeson and dagger, race human (the tool's default), colour #7a9a6a, placeholder sprite, general martial; playable, on the starting screen, the path picked on the skills screen's choice box at level 1; its own tab holds only the Path box, other skills come from the unit (scene) or its general trees; pre-selection without a second system: `Unit.picked` is now `@export` (a scene can list "Path/Sirens"), `Unit.monster(f, path, at, nick)` sets it, and the `picks()` fallback reads a unit made with a path's trait as having picked that path; Siren, Skeleton and Starman scenes untouched (roleless); UI fixes: `SkillGrid` draws a tab with choices but no skills, `SkillDetail` says "Its first skills come free, at rank I; skill points rank them up". Not built: the AI never picks a path for an unpicked Monster, no Monster skill points spent by the AI, no monster-specific sprite. Card in `docs/queue.md` (w18-monster-ai).
302. **Thesis of Theseus: where it is placed (w18-theseus) - built on judgement, open for review (2026-11-23).** Answers "Wizards, warlocks, dark mages, dark clerics have t6 skill `dark` `nature` Thesis of Theseus". Plan: `docs/plans/w18-theseus.md`. Calls: t6 is a root `needs = 5`; placed on the Wizard's Transgression root (forbidden lore, blood magic) and on Elmon (the Warlock's patron tree, `needs` 5; a Wizard's Witchery Pact reaches it too); "dark mage" would be a Mage on Mortis Arcalis, but that root holds only 2 skills so no t6 there (not placed, waits for the tree to grow); "dark cleric": there is no dark god or death-cleric tree (?240), not placed; tags `dark`, `nature` plus `magical`, `int` (as Skeleton: a spell, int its stat for the soft cap and kept AP). Names to review: "Thesis of Theseus".
303. **Thesis of Theseus: level, design, and the picker (w18-theseus) - built on judgement, open for review (2026-11-23); superseded in part by ?321 and ?323.** Answers "Casting it allows them to design and summon a monster at rank level". Plan: `docs/plans/w18-theseus.md`. Calls: the Monster's level is the cast's impact rank (the rank, raised by a modifier that raises rank impact), one Monster a cast; "design" is a path only (Starmen, Sirens, Skeletons), its traits come free (`Unit.monster`) and its level - 1 skill points stay unspent (superseded: ?321, they are now spent); the picker is a general option list, not a per-skill branch: `Behaviour.choices(c)` (labels) and `Cast.chose`, `Battle.cast_at(.., chose)`, and the HUD asks with its `_choose` panel when a tile skill's behaviour has choices, before aiming (an empty or invalid choice lets the behaviour pick, as the AI does); the Monster arrives in its class outfit (gambeson, dagger, now in `Unit.monster()`), nick "<Path> Monster". Not built: trait-level design; Elemental Strike still has its own HUD branch (`_pick_element`) and could migrate (done: ?323); a cast by click without a hotbar press picks for itself. Card in `docs/queue.md` (w18-picker-es).
304. **Thesis of Theseus: how the AI picks and values it (w18-theseus) - built on judgement, open for review (2026-11-23).** Answers the same words as ?303. Plan: `docs/plans/w18-theseus.md`. Calls: the AI picks the path fewest on its side (a unit counts for a path if it holds any of that path's opening traits: a Siren scene, a Starman, a Monster of it), ties by `Battle.rng`; its value `bodies()` = count x (rank + 1), so a level L class unit weighs as L + 1 Skeletons (a level 1 Monster is about 10 HP and a dagger against a Skeleton's 6), because as one body (5) it never repays 4 AP and 3 cost (7.5) and the AI would never cast it. Names to review: none.
305. **Thesis of Theseus: price and summon rules (w18-theseus) - built on judgement, open for review (2026-11-23).** Answers the same words as ?303. Plan: `docs/plans/w18-theseus.md`. Calls: calculator "even" gives 4 AP and 3 cost at every rank (as Skeleton); impact impactful from the behaviour's terms; `rank_impact` "level"; `Behaviours/theseus.gd` extends `summon_per_rank` (soft cap rank + stat mod, kept AP, Disturbed past the cap, `raised_by`) with `make()` split out so a subclass builds its own unit, and `Battle.summon` split so `bring(u, ..)` places a built one. Names to review: none.
306. **`skill.py check` reads a behaviour's parent for its hooks (w18-theseus) - built on judgement, open for review (2026-11-23).** Not from the user's words: the tool refused a skill whose hooks live on the behaviour's parent (`extends "res://Behaviours/x.gd"`), so `Util/skill.py check` now reads the parent file as well. Plan: `docs/plans/w18-theseus.md`. Names to review: none.

## Wave 18 follow-ups (2026-11-23)

Plans: `docs/plans/w18-skillpy.md`, `docs/plans/w18-ai-siphon.md`, `docs/plans/w18-hud-also.md`.

307. **`skill.py new` writes the intensity only beside an explicit tier (w18-skillpy) - built on judgement, open for review (2026-11-23).** Answers ?296 (why `intensity = &"faint"` appeared on Juggle). Plan: `docs/plans/w18-skillpy.md`. Calls: the cause was `new --intensity X` writing the field, while `SkillTerms` derives the same word from the rank I tier `new` writes, so it was redundant and `skills_test.flags_described` called it unsaid; `new` now writes `intensity` only with an explicit `--tier`. Probe skill made with `new`: no intensity line, `flags_described` passed. Files: `Util/skill.py`. Names to review: none.
308. **`skill.py check` fails on an undeclared field (w18-skillpy) - built on judgement, open for review (2026-11-23).** Answers ?296 ("a check that fails on a skill with an undeclared field"). Plan: `docs/plans/w18-skillpy.md`. Calls: new `check_declared` in `check`: a `.tres` field not declared on `Skill.gd` fails; mutation (`bogus = 1` in `undead.tres`) failed the check and was reverted. Not done: a check on default-valued fields (many skills set `passive = false` and the like, harmless, skipped). Files: `Util/skill.py`. Names to review: `check_declared`.
309. **Stray `description` removed from `Skills/undead.tres` (w18-skillpy) - built on judgement, open for review (2026-11-23).** Not from the user's words: `check_declared` found a `description` line in `undead.tres` (?300's invented Undead ??), which `Skill.gd` does not declare; removed by hand, the skill's text is unchanged where it is read. Plan: `docs/plans/w18-skillpy.md`. Files: `Skills/undead.tres`. Names to review: none.
310. **The AI prices Power Siphon as turn-end HP (w18-ai-siphon) - built on judgement, open for review (2026-11-23).** Answers ?284 (the AI ignored the siphon on the circuit). Plan: `docs/plans/w18-ai-siphon.md`. Calls: the hook is `Battle.hazard()` (the one estimate behind `route()`, the AI's approach and retreat dread and the HUD forecast): when a walk ends on a lattice tile (`on_lattice`), each `circuit_ends` effect goes through `_owe_wound`, whose new case `power_siphon` owes `max(round(amount * max_hp), 1)` HP, priced like other turn-end ground (`HAZARD_TILES` per HP); no `AI.gd` branch. Test `stars_test.test_siphon_priced` (hazard at the end against passing through, siphon off, circuit cut; the route price); mutation (gate off) failed 2 checks. Timing flat: `circuit_ends` runs only on lattice tiles; busy_fight 15v15 mean 20.5 ms, p95 46 ms per unit turn. Files: `Scripts/Battle.gd`, `Tests/stars_test.gd`. Names to review: none.
311. **Power gain not weighed, generators do not recharge from it (w18-ai-siphon) - built on judgement, open for review (2026-11-23).** Answers ?284 (the optional "let generators recharge from the siphoned Power"). Plan: `docs/plans/w18-ai-siphon.md`. Calls: the Power the siphon gives is not weighed (`_owe` holds losses only, and the gain is a wash for every unit; small benefit for a Power reserve); generators recharging from siphoned Power skipped (not trivial: needs a Battle hook choosing a generator and charge bookkeeping). Cards in `docs/queue.md` (w18-siphon-gain, w18-siphon-recharge). Gain half built (?327, ?328); the recharge half is not queued (F49).
312. **`circuit_ends` reads the true circuit for the AI (w18-ai-siphon) - built on judgement, open for review (2026-11-23).** Answers ?284. Plan: `docs/plans/w18-ai-siphon.md`. Calls: the pricing reads the real circuit, not the unit's own read of it, since the siphon is plain on-screen status (nothing hidden to be unsure of). Files: `Scripts/Battle.gd`. Names to review: none.
313. **HUD chips for `Bio.also` on the leader's card only (w18-hud-also) - built on judgement, open for review (2026-11-23).** Answers ?290 (the HUD showed `Bio.behaviour` only). Plan: `docs/plans/w18-hud-also.md`. Calls: in `_info` the chips branch that shows behaviour (own side, the leader) adds one MUTED chip per further temper, skipping the lead one, `capitalize()` giving "Power Hungry"; foes show no bio chips, as before, so a foe starman's tempers stay unshown. Test `hud_test.test_tempers_show` (a starman as leader); screenshot checked; mutation not run. Cards in `docs/queue.md` (w18-hud-foe-also). Files: `Scripts/HUD.gd`, `Tests/hud_test.gd`. Names to review: none. Foe half built (?329).
314. **The chip loop reads `bio.also` directly (w18-hud-also) - built on judgement, open for review (2026-11-23).** Answers ?290. Plan: `docs/plans/w18-hud-also.md`. Calls: the loop walks `u.bio.also` itself instead of `Unit.tempered()` (the card wants the list of names, not the live temper gating), so a temper in `also` shows even if `tempered()` would not return it. Files: `Scripts/HUD.gd`. Names to review: none.

## Wave 18 follow-ups, second batch (2026-11-23)

Plans: `docs/plans/w18-fog-ai.md`, `w18-flex-ai.md`, `w18-fog-frozen.md`, `w18-monster-ai.md`, `w18-undead-rank.md`, `w18-picker-es.md`, `w18-flip-test.md`.

315. **`known_ground` reads `explored` (w18-fog-ai) - built on judgement, open for review (2026-11-23).** Answers ?298 (the AI left unchanged by the fog). Plan: `docs/plans/w18-fog-ai.md`. Calls: with sight on, `Battle.known_ground(u, c)` is PLAIN unless `c` is in the side's `explored` set, where the old read rule applies (hidden or obscured reads as plain); never-seen ground is therefore treated by the unknown-terrain rule. Sight off: unchanged. Test `sight_test.test_known_ground_follows_explored`; mutation (explored check off) failed 1. Suite 11326 checks, 0 failed. Timing flat: busy_fight 15v15 mean 20.5 / p95 48.0 ms before, 20.3 / 47.1 after; 20v20 23.5 / 51.8 against 23.5 / 51.5. Files: `Scripts/Battle.gd`, `Tests/sight_test.gd`. Names to review: `_marked_at`.
316. **The AI fills `explored` lazily from its own disc (w18-fog-ai) - built on judgement, open for review (2026-11-23).** Answers ?298. Plan: `docs/plans/w18-fog-ai.md`. Calls: `_mark_seen(u)` adds the planning unit's own perception disc (a few hundred cells, not the side's union) once per cell it plans from; no per-turn rebuild and no `sight_cells` call for the AI; teammates' discs join when they plan. Gap: ground a unit walked past without planning from stays unmarked until it plans again. Card in `docs/queue.md` (w18-fog-seen). Files: `Scripts/Battle.gd`. Names to review: `_mark_seen`. Gap closed (?330).
317. **NPCs take a flex tree: `Unit.take_flex` (w18-flex-ai) - built on judgement, open for review (2026-11-23).** Answers ?285, ?286 (the AI never picked a flex tree). Plan: `docs/plans/w18-flex-ai.md`. Calls: an NPC is a unit with a `bio` and a role; `take_flex()` runs on `_ready` and `level_up`, only when no "Flex Tree/" is already in `picked` (an authored pick stands, tested): a due flex slot takes the first of `flex_options()`. Authored "Flex Tree/<t>" in `picked` already worked through `general_trees`. Files: `Scripts/Unit.gd`, `Tests/general_test.gd` (`test_flex_npcs`, a 7-row table plus an at-floor Jester and `level_up`); four mutations (no bio gate, dearest stat, no `level_up` hook, no already-picked gate) each failed 1. Suite 11339 checks, 0 failed. Names to review: `take_flex`.
318. **A Jester NPC buys flex trees with its lowest stat above floor 6 (w18-flex-ai) - built on judgement, open for review (2026-11-23).** Answers ?292, ?294 (the Jester's inverted page). Plan: `docs/plans/w18-flex-ai.md`. Calls: on an inverted page `take_flex` takes the first `invert_options()` tree some stat pays for, paying with the cheapest stat above floor 6 (lowest value; ties in `FLEX_PAY` order), one tree per run. The Jester picks Student first (tree order) when a stat pays; at the floor for caster payers it falls through to Scout via cha. Jovia's warlock page uses the same path. Files: `Scripts/Unit.gd`. Names to review: none.
319. **The fog freezes terrain only (w18-fog-frozen) - built on judgement, open for review (2026-11-23).** Answers ?297, ?298 (explored tiles show the look last seen). Plan: `docs/plans/w18-fog-frozen.md`. Calls: `Overlay.memory` is a TileMapLayer with the same tile set between the Map and the Overlay; `fog_of_war` copies the map cell onto it when a tile leaves sight (`_freeze`) and erases it on re-entry; rebuilt on a rect change. Cost only on transition cells (tens of `set_cell` a move); fog redraw base 0.88 ms on Meadows, added work estimated under 0.1 ms, not separately profiled. Limit: terrain only, so Overlay-drawn ground effects (layers, marks) stay live; unseen tiles stay live; not time-frozen. Test `sight_test.test_fog` +2 checks. No visual shot taken. Cards in `docs/queue.md` (w18-fog-effects). Files: `Scripts/Overlay.gd`. Names to review: `memory`, `_freeze`. Effects half built (?331 to ?333).
320. **Monsters pick a path: `Unit.take_path`, `fewest_path` (w18-monster-ai) - built on judgement, open for review (2026-11-23).** Answers ?301 (the Monster class; the AI picking for an unpicked one). Plan: `docs/plans/w18-monster-ai.md`. Calls: home is `Unit.take_path()` beside `take_flex`, run on `_ready` and `level_up`; no `AI.gd` change. It applies to an NPC (has a `bio`) or a summoned Monster (`path_auto`, set by `Unit.monster()`); a player's Monster (no bio) is left to the player. The pick is `Unit.fewest_path(side, rng)`, lifted from `Theseus.path` (which now calls it); at ready the side is the same-faction siblings in the parent (no Battle ref), ties first. Test `monster_test.test_ai` (pre-picked Starmen, Sirens and Skeletons, unpicked L1 and L5, fewest path, the player's Monster left alone, a summoned L5); mutations (no bio / `path_auto` gate: 13 failed; no pick: crash). Files: `Scripts/Unit.gd`, `Behaviours/theseus.gd`, `Tests/monster_test.gd`. Names to review: `take_path`, `fewest_path`, `path_auto`.
321. **Monsters spend their points (reverses ?303) (w18-monster-ai) - built on judgement, open for review (2026-11-23).** Answers ?301, ?303 (reverses ?303's "its level - 1 skill points stay unspent"). Plan: `docs/plans/w18-monster-ai.md`. Calls: an NPC or summoned Monster now spends owed = max(`skill_points`, level - 1 - purchases) on its path's opening traits, cheapest `raise_cost` first (ties in tree order), until none is affordable or capped; leftover stays. A Theseus Monster therefore arrives with its points spent, where ?303 left them unspent (?303 is superseded on that point). Changed tests: `monster_test.test_paths` sets `path_auto = false` (it checks the unspent helper output); `thesis_of_theseus_test.test_theseus` now expects traits held (at least I) and 0 points left. The host fixed a merge by setting `path_auto = false` in `test_undead_rank`. Mutation: dearest first failed 1 (the L8 row). Files: `Scripts/Unit.gd`, `Tests/monster_test.gd`, `Tests/thesis_of_theseus_test.gd`. Names to review: `path_auto`.
322. **Undead ?? gives +1 pierce Defense a rank (w18-undead-rank) - built on judgement; SUPERSEDED by ?347 and ?348 (2026-11-23).** Answers ?300 (Undead ?? had no per-rank effect). Plan: `docs/plans/w18-undead-rank.md`. Calls: a guess: the Skeleton unit gets nothing but the `undead` tag and stats, so there was nothing to lift; bones turn piercing instead: an Effect of Defense +1 a rank tagged `pierce` (existing Effect fields, no `Skill.gd` change), rank I = +1, blunt flat, still undead; the name and `??` kept. Test `monster_test.test_undead_rank` (ranks I to III step pierce Defense; per_rank off failed rank II and III). Suite 11350 checks, 0 failed. Files: `Skills/undead.tres`, `Tests/monster_test.gd`. Names to review: `Undead ??`.
323. **One HUD picker for any non-tile skill with choices (w18-picker-es) - built on judgement, open for review (2026-11-23).** Answers ?303 (the shared picker; Elemental Strike not migrated). Plan: `docs/plans/w18-picker-es.md`. Calls: Elemental Strike's `imbue.choices()` now returns the elements capitalised and `apply` reads `c.chose` (else the AI rule: own element if listed, else the first). `HUD._pick_choice` casts on the unit at once for any non-tile skill whose behaviour has choices; `_pick_element` and the imbue branch are deleted, so the rule is generic, not Elemental Strike's. Test `general_test.test_elemental` +1 check (pick "Water" through a cast with `chose`); no old-path test changed. Files: `Scripts/HUD.gd`, `Behaviours/imbue.gd`. Names to review: `_pick_choice`.
324. **`Battle.cast` takes a `chose` argument (w18-picker-es) - built on judgement, open for review (2026-11-23).** Answers ?303. Plan: `docs/plans/w18-picker-es.md`. Calls: `Battle.cast(.., chose)` sets `_chosen` as `cast_at` already did, so a self-cast can carry the picked option. Files: `Scripts/Battle.gd`. Names to review: none.
325. **Floaty never stalls a starman (w18-flip-test) - built on judgement, open for review (2026-11-23).** Answers ?289 (Floaty's fractional movement). Plan: `docs/plans/w18-flip-test.md`. Calls: `stars_test.test_floaty_no_stall`: 6 starmen (Floaty ranks 1, 2, 3, two each; move 2.5 / 1.67 / 1.25, Jump x2 to x4) against 4 villagers, both on `AI.act`, 14 rounds; a stall is 3 turns running with no move, HP change, log line or Energy change while a free tile would take it further from every villager. 66 checks. Finding: no stall in `_leap()` or the fractional move; no `AI.gd` change. One non-bug: a villager's death ended the battle (`Phase.OVER`, all travel no-ops), so the test resets the phase each turn. Files: `Tests/stars_test.gd`. Names to review: none.
326. **A cornered Flippant starman holds still 3 to 4 turns (w18-flip-test) - built on judgement, open for review (2026-11-23).** Answers ?289, ?290. Plan: `docs/plans/w18-flip-test.md`. Calls: at the map edge with every tile unsafe, a Flippant starman holds still 3 to 4 turns (`_away` returns its own cell), turning aggressive once struck; judged a hold, not a stall, and exempted in the test; no `AI.gd` change. Files: `Tests/stars_test.gd`. Names to review: none.

## Wave 20 follow-ups (2026-11-23)

Plans: `docs/plans/w20-siphon-gain.md`, `w20-hud-foe-also.md`, `w20-fog-seen.md`, `w20-fog-effects.md`.

327. **The AI weighs the Power a siphon gives: `SIPHON_POWER_HP` 0.5 (w20-siphon-gain) - built on judgement, open for review (2026-11-23).** Answers ?311 (gain half; "the Power gain not weighed"). Plan: `docs/plans/w20-siphon-gain.md`. Calls: in `Battle._owe_wound` case `power_siphon`, a powered unit (`u.powered()`) subtracts `SIPHON_POWER_HP` (0.5 HP) per Power gained, the gain being min(max(round(amount * max_energy), 1), room); 0.5 HP per Power is a guess. Test `stars_test.test_siphon_priced` extended (a Starman with room against one full); mutation (gain dropped) fails 1. Timing flat by construction (only under `ends` and `on_lattice`; `busy_fight` has no lattice, not re-benched). Files: `Scripts/Battle.gd`. Names to review: `SIPHON_POWER_HP`.
328. **No negative bonus; Energy units unchanged (w20-siphon-gain) - built on judgement, open for review (2026-11-23).** Answers ?311. Plan: `docs/plans/w20-siphon-gain.md`. Calls: `_owe` floors the hazard at 0, so a gain larger than the loss is a free tile, never a lure (`hazard()` stays losses-only so the HUD forecast keys are unchanged); a unit on Energy is unchanged since regeneration makes the siphon a wash. Generator recharge from siphoned Power stays unbuilt (?311). Files: `Scripts/Battle.gd`. Names to review: none.
329. **A foe's further tempers show as MUTED chips (w20-hud-foe-also) - built on judgement, open for review (2026-11-23).** Answers ?313 (foe half; a foe starman's tempers unshown). Plan: `docs/plans/w20-hud-foe-also.md`. Calls: `Read.also` (Array[StringName]) is set in `Perception.gd` beside `Read.temper` under the same gate (an insightful observer, tier 2 and up), so no new reveal; the HUD's foe branch adds one MUTED chip per `also` entry other than `r.temper`, and the lead temper stays in the "Seems X" note; a deceived read is unchanged (the existing temper gate has no deceive check). Test `hud_test.test_foe_tempers` (wis 8: none; wis 18 with recon 2: Vindictive and Power Hungry, no Flippant chip); mutation (ungated `also`) fails the unreading check. No visual shot. Files: `Scripts/Perception.gd`, `Scripts/HUD.gd`. Names to review: `Read.also`.
330. **Ground walked past is marked explored (w20-fog-seen) - built on judgement, open for review (2026-11-23).** Answers ?316 (the gap). Plan: `docs/plans/w20-fog-seen.md`. Calls: `travel()` with sight on calls `_mark_seen` at every passed cell but the last (the last is marked lazily when the unit plans, `known_ground`); `_mark_seen` now takes `from := u.cell`; one sight disc per step, not a path-cell set, so no whole-map loop; applies to every unit with sight on (the player side's `explored` is also filled by `sight_cells`, a harmless duplicate). Bench `busy_fight` 15v15 lead unit turn mean 18.7 to 18.6 ms (p95 48.4 to 50.5, noise), 30v30 25.0 to 25.2 / 24.8: flat. Test `sight_test.test_walk_marks_ground_passed`; mutation (marking call to pass) fails. Files: `Scripts/Battle.gd`. Names to review: none.
331. **The fog freezes ground effects too: `Overlay._ghost` (w20-fog-effects) - built on judgement, open for review (2026-11-23).** Answers ?319 (effects half). Plan: `docs/plans/w20-fog-effects.md`. Calls: `Overlay._ghost[cell]` holds {layers (a copied Layer), trodden, marks (the visible ones from `tile_view`)}, set in `_freeze` on the same transition cells as `memory`, erased on re-entry, cleared on a rect rebuild; `_layers` split into `_stack(c, stack, trodden)` shared by live and ghost; marks are ghosted as the same Mark object (kind, tint and swell do not change, the animation continues). Cost 83 us a move on M3; test `sight_test.test_fog` +5 checks (ghost set, live, kept, dropped; a 1 ms budget on `fog_of_war` alone); mutation (`_sighted` to true) fails the laid-out-of-sight check, a budget under 1 us fails. Files: `Scripts/Overlay.gd`. Names to review: `_ghost`, `_sighted`, `_stack`.
332. **Layers and marks laid out of sight, or on never-seen tiles, are hidden (w20-fog-effects) - built on judgement, open for review (2026-11-23).** Answers ?319. Plan: `docs/plans/w20-fog-effects.md`. Calls: `_sighted(c)` says a tile out of sight (fog on, not in `_fog_clear`) draws only its ghost, so a layer or mark laid after the tile left sight, or on a tile never seen, is no longer drawn live (it used to leak through the fog). A fixed leak, but a visible change: a fire lit in the dark is not seen until the tile is seen again. Files: `Scripts/Overlay.gd`. Names to review: none.
333. **Lattice, debris and traps are not frozen (w20-fog-effects) - built on judgement, open for review (2026-11-23).** Answers ?319. Plan: `docs/plans/w20-fog-effects.md`. Calls: only layers, the trodden flag and marks are frozen; the lattice (panes, starpower), debris and traps are not (the lattice is HUD-gated already; debris and traps were not asked). Files: `Scripts/Overlay.gd`. Names to review: none.

Not done (w20):
- [ ] **A visual shot of the frozen ground effects** (?331): `w20-fog-effects` took no screenshot; a fire or layer left behind in the fog should show its last-seen look, a layer laid in the dark should stay hidden (`Overlay._ghost`, `_sighted`).

## Wave 21 batch 1 (2026-11-23)

Plans: `docs/plans/w21-vscroll.md`, `w21-sprites.md`, `w21-anim.md`, `w21-hudpanels.md`, `w21-undead.md`. From the user's fourth batch of 2026-11-23 (`docs/agents/answers-2026-11-23d.md`). Class authoring needed no card: `Util/role.py` already does it (new, tree, tab, include, god).

334. **VScroll, the vertical twin of HScroll (w21-vscroll) - built on judgement, open for review (2026-11-23).** Answers the user's "menus should have vertical scrolling as needed". Plan: `docs/plans/w21-vscroll.md`. Calls: new `Scripts/VScroll.gd` (a ScrollContainer, vertical only) rather than a generalised HScroll: HScroll's arrows, drag and sideways wheel are row things, a column has room for a bar and the wheel and pan are native; it asks its parent for min(content height, screen height - `reserve`), `reserve` default 16, refits on content, visibility and viewport changes; `VScroll.wrap(content, keep)` for code-built menus. The screen is never shorter than 270 (stretch expand), so "short" means 270. Tests `vscroll_test` (test_rule, test_menus at a pinned 480x270). Files: `Scripts/VScroll.gd`. Names to review: `VScroll`, `reserve`.
335. **Which menus got the vertical scroll (w21-vscroll) - built on judgement, open for review (2026-11-23).** Answers the same. Plan: `docs/plans/w21-vscroll.md`. Calls: applied to the entry page (the whole Center; the class row stays an HScroll within), the Party screen (the grid only, title and Done stay put), the skills screen (the whole Column, so a wheel tab at 270 needs about 60 px of scroll; chosen over scrolling only the Body), the portal menu in GamutsTower (text body only). Not touched: the battle HUD's side panels (fit at 264 and 267), the sheet, settings, spellbook (fit or own scrolls). Undone, small: no mouse-drag scroll on VScroll (HScroll has it), and picking a skill does not scroll to the Unlock button. Movie capture is 1440x810 whatever the window, so short windows were checked by numbers (642x270). Files: `Scenes/entry.tscn`, the Party and skills screens, `Scripts/GamutsTower.gd`. Names to review: none.
336. **HScroll: `max_width` 420, an idle row passes the wheel (w21-vscroll) - built on judgement, open for review (2026-11-23).** Answers the same. Plan: `docs/plans/w21-vscroll.md`. Calls: `HScroll.max_width` 440 to 420 so the page's 8 px bar does not clip the form's 476 against 480; a row with nowhere to scroll (arrows hidden) no longer eats the wheel, so over Side or Scenario the page scrolls. `hscroll_test` extended, no test changed. Files: `Scripts/HScroll.gd`. Names to review: none.
337. **Util/sprites.py: where output goes and what counts as a sprite (w21-sprites) - built on judgement, open for review (2026-11-23).** Answers the user's sprite-extraction card ("copy sheet ... clip out individual sprites ... name the resulting png after average color"). Plan: `docs/plans/w21-sprites.md`. Calls: output in `Assets/sorted/<sheet-stem>/` (per sheet, so sheets stay traceable); the "copy" is the sheet decoded to RGBA in memory, sortme untouched; alpha > 0 is in a sprite (8-connected, diagonals attached), so stray alpha 7 to 11 specks become sprites; default `--min-size 1` keeps all, non-lossy: 718 PNGs committed (275, 147, 296), 48 of them 1-px specks (1-px sparkles may be real effects). `.png.import` files committed beside each PNG. Files: `Util/sprites.py`, `Assets/sorted/`. Names to review: none.
338. **Sprite names: average colour hex, a small colour word, clash suffix (w21-sprites) - built on judgement, open for review (2026-11-23).** Answers the same ("append -<color> ... based on computed avg hex"). Plan: `docs/plans/w21-sprites.md`. Calls: average is alpha-weighted over alpha > 0 pixels, rounded, lowercase hex; the word is the nearest of 12 typical RGBs by redmean distance (light grays near 190 read as pink or white: the palette is small by the spec); clashes get `-2`, `-3` in reading order of each sprite's first pixel, so the names are deterministic; a re-run overwrites by name and never deletes stale files. Files: `Util/sprites.py`. Names to review: none.
339. **sprites.py decoders and its check (w21-sprites) - built on judgement, open for review (2026-11-23).** Answers the same. Plan: `docs/plans/w21-sprites.md`. Calls: Pillow if importable (any mode), else a plain zlib decoder (8-bit non-interlaced only, otherwise says it needs Pillow); output is always zlib-encoded; `check` cuts a synthetic 12x6 sheet through both decoders (diagonal pair, unequal-alpha average, clash `-2`, speck cut) and tests every `Assets/sorted` PNG is named `<hex>-<colour>[-n].png` and imported; wired by adding `sprites` to `Tests/tooling_test.gd` test_checks (no new test file); mutation (diagonals dropped) fails the check. Files: `Util/sprites.py`, `Tests/tooling_test.gd`. Names to review: none.
340. **Animation: frames beside the sprite, pose to state mapping (w21-anim) - built on judgement, open for review (2026-11-23).** Answers the user's animation convention (requirements.md "Animation"). Plan: `docs/plans/w21-anim.md`. Calls: `Util/anim.py setup` writes a SpriteFrames `Units/<Name>.tres` beside the sprite, found by path from `look` at `_show_look()` (no scene or role field; no .tres means today's 1-frame `default`); `default` is always the neutral pose, first frame. Mapping (tool `STATES`): attacking = left then right (one-shot), hit = left (one-shot), investigating = right (one-shot), waiting = the numbered cycle else neutral (loops); a missing pose falls back to neutral. Frame rates: default 5, waiting 4, attacking 6, hit 6, investigating 3. A one-shot returns to waiting on `animation_finished`. Files: `Util/anim.py`, `Scripts/Unit.gd` (`ANIMS`, `animate`). Names to review: `ANIMS`.
341. **Animation triggers (w21-anim) - built on judgement, open for review (2026-11-23).** Answers the same. Plan: `docs/plans/w21-anim.md`. Calls: attacking = `Battle._done_casting()` on a finished outermost cast (any skill, not only hostile); hit = `Unit.hit()` taking more than 0 damage; investigating = `Battle.inspect()` (past its early return) and `investigate()`, the looker; waiting = the default. Test `anim_test` (2 tests, 13 checks); mutations (waiting fallback, hasted 0.6, hit animate) caught. Files: `Scripts/Battle.gd`, `Scripts/Unit.gd`, `Tests/anim_test.gd`. Names to review: none.
342. **Animation pace: moods multiply (w21-anim) - built on judgement, open for review (2026-11-23).** Answers the same ("wounded or slowed units play animations at lower speeds. Hasted and frightened ... higher"). Plan: `docs/plans/w21-anim.md`. Calls: `Unit.ANIM_PACE`, multiplied: wounded 0.6 (HP under half, or a status bearing `wound`), slowed 0.6 (a status lowering movement or initiative), hasted 1.5 (raising movement or initiative), frightened 1.5 (a `fear` status); re-read on each `animate()` and each loop. The thresholds and factors are guesses. Files: `Scripts/Unit.gd` (`ANIM_PACE`, `moods`, `anim_pace`). Names to review: `ANIM_PACE`.
343. **anim.py: what `setup` writes and which names count (w21-anim) - built on judgement, open for review (2026-11-23).** Answers the same ("classes / units / monsters and prefabs"). Plan: `docs/plans/w21-anim.md`. Calls: `setup <targets|--all> [--dry-run]` takes Units/<Name>, Roles, Scenes or Formations ids (scene to role, formation to scenes); `--all` writes only sprites with poses beyond the base (no 27 identical .tres), a named target always gets one; base names any case or hyphenated (`starman-left.png`); numbered `X1`, `X-1`, `X_1` all count and sort by number; `-neutral` is the base when no plain `X.png`; an extra suffix (`-left-raise`) is listed by `show` as an unused variant. `check` flags a stale .tres, a posed sprite without one, an `ANIMS` name `STATES` never makes. No posed art is in `Units/` yet, so no .tres was written and no visual capture taken (a temp trial loaded in Godot, then removed). Files: `Util/anim.py`, `CLAUDE.md`, `.claude/skills/new-unit`. Names to review: none.
344. **Objectives: a generic hook, the default "Foes left", `?` under fog (w21-hudpanels) - built on judgement, open for review (2026-11-23).** Answers the user's "objective panel in top left ... tracks map objective (x or ? combatants left, y demons slain etc)". Plan: `docs/plans/w21-hudpanels.md`. Calls: `Battle.objectives: Array[Callable]` (side to text, `\n` splits lines), `objective_lines(f)`, signal `objective_changed`; a map registers a callable; Meadows registers its kills and portal clock and its `_tally` Label is gone (test line replaced). Default line from the HUD: "Foes left: N", dropped when a foe side is in `Battle.lasting` (no end by elimination). With the fog on the count is `?`, or "? (3 seen)" once some are made out (`unit_seen`); fog off, the exact count of units it can see. Files: `Scripts/Battle.gd`, `Scripts/Meadows.gd`, `Scripts/HUD.gd`, `Scenes/UI/hud.tscn`. Names to review: `Battle.objectives`.
345. **The objective panel: menus, placement, no fade (w21-hudpanels) - built on judgement, open for review (2026-11-23).** Answers the same ("not obscuring menus"). Plan: `docs/plans/w21-hudpanels.md`. Calls: hidden while `_panel_open()` (the same predicate as the tile pane and camera: the book, skills, settings, persona and sheet cover the whole map), and once the battle is OVER; not moved or dimmed. Placed at the top left of the visible map between the side panels (`_corners()`, from the old `_place_pane`); the turn clock and Banner not moved. The task names the tile panel only, so the objective panel does not fade. Input untouched (w21-focus). Files: `Scripts/HUD.gd`. Names to review: `_corners`.
346. **The tile pane: top right, always up, fades while the view moves (w21-hudpanels) - built on judgement, open for review (2026-11-23).** Answers the same ("tile panel consistently show in top right, fade it while scrolling"). Plan: `docs/plans/w21-hudpanels.md`. Calls: `pane_cell()` is the hovered tile; pointer off the map, the last tile shown; before any, the selected unit's (else the leader's) tile; a hovered tile gone still hides it. Fade (`fade_step`): to 0.2 at 6 a second while the Camera2D's screen centre moves, back to 1 at 2.5 a second once still for 0.25 s (every cause counts, no new signal). Test `hud_test.test_corner_panels` (14 checks); mutations caught; shots in `S/shot_w21hp/` (not committed). Files: `Scripts/HUD.gd`. Names to review: `pane_cell`, `fade_step`.
347. **Undead: rank adds to checks against instant death (replaces ?322) (w21-undead) - built on judgement, open for review (2026-11-23).** Answers the user's "Undead rank effect: add this rank to any check defending against instant death". Plan: `docs/plans/w21-undead.md`. Calls: supersedes ?322 (+1 pierce Defense a rank, a guess). No code: `Skills/undead.tres` Effect stat `check`, kind defensive, tags `[execute]`, +1 per rank; `Unit.check_bonus()` already feeds `Battle.stand_bonus()` (the shared last-stand and Death check) the execute-tagged effects. Luun's Smite execute is an HP threshold, not a check: untouched. `monster_test.test_undead_rank` rewritten. Files: `Skills/undead.tres`, `Tests/monster_test.gd`. Names to review: none.
348. **Undead: healing tagged dark or undead is boosted 5% a rank (w21-undead) - built on judgement, open for review (2026-11-23).** Answers the user's "incoming healing effects tagged 'Dark' or 'Undead' get a rank * 5% boost". Plan: `docs/plans/w21-undead.md`. Calls: new Effect stat `healed` (via `mechanic.py`), tags `[dark, undead]`, amount .05 per rank, read in `Unit.heal()` (new `tags` param, only when heard) as h * (1 + stat); `Battle.mend()` passes tags and `Battle.cast` passes `caster.skill_tags(skill)`. Untagged heals (items, pulse, regen) are unboosted; the boost is applied before `being_healed` listeners, so Molothrus cuts the boosted amount. Tags dark, undead, execute already existed. Mutations: execute tag dropped fails ranks II and III, heal tags ignored fails heal and mend checks. Files: `Scripts/Unit.gd`, `Scripts/Battle.gd`, `Skills/undead.tres`. Names to review: `healed`.

Not done (w21 batch 1):
- [ ] **VScroll: drag scroll and scroll-to-Unlock** (?335): VScroll has no mouse-drag scroll (HScroll has it), and picking a skill on a scrolled skills screen does not scroll to the Unlock button.
- [ ] **Posed unit art and `anim.py setup --all`** (?340, ?343): no `Units/*.png` has `-left`, `-right` or numbered poses yet, so no `Units/*.tres` exists and no animation was seen in play; cut sheets with `Util/sprites.py`, move posed sprites into `Units/`, run `python3 Util/anim.py setup --all`.
- [ ] **A visual shot of the animations and of the short-window menus** (?335, ?343): the movie capture is 1440x810 whatever the window, and no posed art existed.
