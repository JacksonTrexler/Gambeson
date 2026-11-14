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
- [ ] **The HUD shows only a unit's largest reserve**: a Ranger with Energy, Stamina and Focus sees one bar. (?100)
- [x] **A save-Stamina toggle**: Stamina and Mana are now toggles on the hotbar (2026-11-11, ?116); switching is a channel. (?98, ?116)
- [ ] **The AI has no idea of a `stamina` skill's extra effect** (Move ??). (?98)
- [x] **`tapped` and `helpless`** (2026-11-12, built 2026-11-14, ?119): `tapped` is a utility effect other effects may apply; a tapped unit can't act or take orders. It is not a debuff and can't be cleansed, but its sources can be addressed (healing off a stun, a wound), which removes it, and the unit is free to use AP and reactions on its turn. Tapped when: out of AP; it has received cha mod orders this turn (until the commander ends the command phase; afterward it may use remaining AP on autopilot); downed or stunned with no effect or skill letting it act (see Mindless Fury). `helpless` is for stun and other full action-disabling spells. (?65, ?90)
- [x] **Tapped saturation** (2026-11-12, built 2026-11-14, ?119): a unit acting in a reduced capacity is drawn at 50% saturation, instead of 0% for tapped or 75% for low AP / command limit.
- [x] **Stun** (2026-11-12, built 2026-11-14, ?119): a wound-type cause of `tapped`/`helpless`; healing it off removes the tap.
- [x] **Mindless Fury** (2026-11-12, built 2026-11-14, ?119): Berserker passive, tier 5. A unit may take rank actions in a reduced capacity when it would otherwise be interrupted or incapacitated; its effective mental stats are 1 while acting this way. It can't power through `tapped` to take unlimited actions in a turn, and needs blanket mitigation of unit-inflicted disabling effects.
- [x] **Drone** (2026-11-12, built 2026-11-14, ?119): tier 4, Mage general / Specialist Merchant. The unit does not tap when the command limit is exceeded; its mental stat mods are capped at +rank when acting this way.
- [ ] **Rebalance the museum** (Nemes leans on Hex), or teach the AI to weigh a raised cost and vary. Now Lancin 27 / Nemes 3 with exhaustion on (13 / 17 off); Stamina and Move ?? change none of it. (?87)
- [ ] **Nothing on the hotbar shows a worn skill until hovered**; a mark on the slot may be wanted.
- [ ] **Static skill descriptions** (skills screen, spellbook) show base costs only.

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
- [ ] **Behaviours don't run on the early-return paths in `Battle.cast()`** (Strike's chain, contests, saves).
- [ ] **The HUD forecast and the AI don't know Kick's tile effects.**
- [ ] **No map has a hole tile yet**, so Kick's hole push is only tested.
- [ ] **The stale-count check covers only the Adventurer wheel** (`hud_test`).
- [ ] **`skills_test.test_wiring` skips without python3.**
- [ ] **Waterstrike's tag `bludgeon` probably should be `blunt`.**
- [ ] **Shrink `UNSAID`**: 11 existing `Skill` fields that no description mentions are exempted in `skills_test`.
- [ ] **Lift `pings` into a behaviour and lower `FLAG_CEILING`** (raised from 124 to 125 because Clairvoyance's `pings` flag was built in parallel, beside the seam).

88. **Skill tooling, Kick, CLAUDE.md - settled (2026-11-10):** "that's fine for now"; the calls stand.
    - **"g-action skill/ tool"** was read as a Claude Code agent skill (`.claude/skills/new-skill`) plus a script (`Util/skill.py`). Say if you meant something else.
    - It paid: Kick took 9 files with no hand wiring, against 17 files and about 12 hand-edited .tres for Tenacity and Grudge.
    - **Kick:** General Martial tier 1, 4 AP, 1 Energy, 1d4 + str, range = rank, effects last rank turns. "The tile between" is the tile at the kicker's feet toward the target. Checks run trap, water, loose ground, hole/edge, bare; the first match wins. A trap springs on the target but stays where it is, revealed. Water leaves **Soaked** (movement -rank), loose ground (leaves, sand, debris) **Blinded** (offensive checks -rank), a hole, edge or off-map tile pushes rank tiles, bare ground is plain damage; adjacent targets take a 1-tile push. Soaked and Blinded are new reusable effects (`Effects/soaked.tres`, `blinded.tres`).
    - **CLAUDE.md** is four lines: two on skills (data first, behaviours in `Behaviours/*.gd`, never a new `Skill.gd` flag; use `skill.py new` and `check`), one on reading the big files by range, one on running the tests.
    - New skills use behaviours; old flags move over only when touched. `check` runs as `skills_test.test_wiring`; `skills_test.test_flags_described` fails when a field a skill sets doesn't change its description.

## Unit bios (2026-11-10)

- [ ] More tempers as they're wanted (cowardly, vengeful...): each is a word in `Bio.BEHAVIOURS` and a branch in `AI.act()`. (?91)
- [ ] Bio text on the character sheet and the Guide; appearance words beyond the Bio tables are flavour only. (?91)
- [ ] Clout earned in play (helping a side, lying to it) rather than set by hand. (?93)

100. **Focus, and Stamina's recovery - built on judgement, open for review (2026-11-11).** Your rulings on 97 and 98, built on `w-focus` (`docs/plans/focus.md`). Suite after both merged: 38408 checks, 535 tests, 0 failed. My calls:
    - **Who:** the Ranger's Bounty root and the Mage's Commitment root. Commitment's earlier AI stub "Focus ??" is renamed **Fixation ??** (an AI-made name, for review).
    - **Size** (wis mod + 2) x rank; starts each battle empty; builds half its max (rounded up) on each turn spent resting, none when light or busy, none while channeling.
    - **Payment:** it pays first for a ranged attack (reach > 1.5), otherwise only once Energy can't. A ranged attack that leaves Focus at 0 gets + rank to its roll (the forecast counts it). Violet.
    - **Jam drains Focus** by the HP the target lost.
    - **Stamina recovers** on Energy's tick and rate (full resting, half light, none busy) plus its rank on a resting turn; it recovers even with Energy full, and Power doesn't stop it; an idle channeler gets half and no bonus.
    - Open: the HUD shows only a unit's largest reserve (a Ranger with Energy, Stamina and Focus sees one bar); the AI doesn't rest to build Focus.

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
    - **The AI never toggles**; a Wizard or Mage under the AI just runs on Mana.
    - **Bars:** a unit shows what it runs on first, then its other reserves (a second 2px bar on demand); the Energy bar only when it holds Energy; the unit card lists each held reserve. Mana and Stamina sit on the hotbar as toggles.
    - Open: the hotbar marks no switch in progress, only the log line ("switching to Energy, channeled"); a Druid holds Mana from its Astral tab before learning the skill (with no toggle, both pay as before).

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
- [ ] **No screenshot of the new saturation.** (?119)
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
- [ ] **The AI doesn't use Heal, Megaheal or Energize**: `Skill.heals()` reads `heal_mods`, which they don't carry. (?121)
- [ ] **Other gains don't report**: Sweet Nothings on a kill, Focus building, Downed saves via `hp =`, post-battle refills. Which should count? (?121)
- [ ] **Burnt max has nothing to restore it.** (?121)
- [ ] **No burnout out of combat.** (?121)
- [ ] **A Life tree** to hold Heal and Megaheal as domain-general skills. (?121, ?122)
