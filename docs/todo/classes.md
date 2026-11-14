# Todo: classes

`[ ]` to do · `(?N)` waits on open question N (numbered across all todo files) · *Now:* what the game does today. Done items and decided rules: `docs/done/`. Index: `todo.md`.

Every tree's capstone, for now (later a mid-tree capstone), is a **Basic Martial / Magic / Specialist Skill Slot +1**. (?10)

## Adventurer

Three roots, **Magic**, **Martial** and **Specialist**, with flat, radial trees: most paths are a few nodes long, and each root branches into about 6 strong applications of the basics. Paths are shallow slices of other classes' trees, but Adventurers can learn core skills many classes share: **Hex** and **Rejuvinate** are a first choice at any time. The three starting passives are separate skills on purpose, since each takes a slot; once Adventurers have skills that use them, they can become mid-tier passives in the tree instead.

- [x] **Rejuvinate** on the core ring (see Paladin): built (`docs/done/classes.md`). (?12)
- [ ] **Skill Slot +1** (unspecified type): acts like a base slot, slightly darker. Sits at the center, locked until current slots are filled. *Now:* a stub at the centre of the wheel. (?3)
- [ ] **Trade Skills** (passive): skill limits scale partly with wis: (base stat + wis × rank) / rank. *Now:* a stub on the core ring. (?2 ?11)
- [ ] **Grind** (passive): str mod can count toward martial limits; max HP drops by the % overage. *Now:* a stub on the core ring. (?2 ?11)
  - Rank 2+: bonus slots, each −10 × (rank − 1)% max HP while in use.
  - Rank 11+: bonus slots also cut max energy the same way.
- [ ] If a skill that grants slots is unequipped, its slots disappear, skills and all (Losing a slot). *Now:* skills can't be unequipped; a level buff's slots already go that way.
- [x] **Igna** and **Aetha**: built as starter spells (`docs/done/classes.md`), the AP at once.
- [ ] **Martial root**: not designed yet. *Now:* Wary, then the capstone; the general Martial tree helps. (?15)
- [ ] **Specialist root**: more specialist skills to come.

3. The Adventurer's extra slot "sits at the center, locked until current slots are filled". Center of the hotbar (its middle slot) or of the radial tree? Does it unlock once every slot holds a skill?
10. Adventurer: is Mage (Red Mage) a class separate from Wizard? *(Answered 2026-11-07: yes - see Wizard / Mage, ?70.)* The Wizard uses the Red Mage sprite, and has the Mana passive. Do Igna and Aetha grant AP immediately, or for rank turns? Sola's +1 persona does nothing on a unit with no disguise set up: intended? The Magic root now has 8 branches against "about 6": fine? Which slot type does each tree's capstone give (Divinity: Magic, Prowess: Martial, Idealism: Specialist)?
11. Trade Skills and Grind formulas, once 2 is settled. As written, (base + wis × rank) / rank works out to base / rank + wis.
15. Adventurer, as built (each can change):
    - Capstones need 3 of their root's skills learned (tier 4). The Martial root has only Wary so far, so its capstone can't be reached yet. Is 3 right, or should a capstone come after particular skills?
    - The starting passives and the capstones stop at rank I, since ranks would do nothing for them. Fine?
18. Specialist skills, as built (each can change):
    - Clever Disguise's ranks: unlocking costs 1 like any skill, then II costs 4, doubling each rank (8, 16, 32). Right base and growth?
    - Move +1 stops at rank I. Hide and Clever Disguise are used on the unit itself only.
    - Meander counts tiles walked each turn: the first rank tiles count as standing still. A tile effect's level is a laid trap's rank; map traps and ground are level 1. Nothing deals damage for moving yet, so its last part waits for something that does.
    - Effects put on your own side during your turn used to count that turn as one of theirs, so Sola I or Nadira I on an ally wore off before any enemy acted. Now the current turn doesn't count (see Effect durations). Right?
20. Self-evaluation, as built (each can change):
    - The rolls it shows are attack rolls and the one roll of a deceiving skill (Hide, Clever Disguise). Are there others?
    - Its rank is its reach in tiles, and its holder's own rolls count. Asleep allies don't see them.
    - Without it, the log keeps the imposter's roll hidden ("(9)"), but still says whether each investigator saw through. Should the outcome be hidden too?
    - Effect icons show on the cards of units the player knows (its own side's, or ones it has seen through). Should enemies' advertised effects show too, and which?

## Wizard / Mage

Two classes now (your answer to the first part of 10, 2026-11-07). **Wizards** are flexible casters, biased toward the arcane, with a tab for everything they dabble in: pacts with patrons, affiliations with gods, the world's natural and magical powers. They screw with powers they ought not to: great potential, a major liability. **Mages** are dedicated and limited, but their trees feed each other: a school of magic, the general Mage tree, and a magical college. They're conventional: their spells are more refined and safer, and commitment takes their element further (still a large overlap with Wizards and other arcane casters).

*Now:* both trees are laid out with every new skill a stub carrying its plan (`Skills/*.tres`, `plan`), so the skills screen shows the shape. Nothing new is learnable but the starter spells and what was built before. (?70)

- [ ] **Wizard** (`Roles/wizard.tres`): its own tab keeps Mana, Mage Armor, Darkstone and every starter spell (Igna and Aetha added) on the core ring.
  - **Arcane** root (the bias): Arcana, Dispel, Blink; Spellweave after Arcana, Counterspell after Dispel (a reaction); the Magic Skill Slot +1 capstone.
  - **Transgression** root (the liability): Overchannel, Blood Magic, Wild Magic; Forbidden Lore after Overchannel; Rift after Wild Magic (lets demons through: spawning mid-battle); Unbound, a capstone needing 4.
  - **Pact: Elmon** and **Pact: Hogel** (one of them, `one_of = pact`): the Pact skill first, then two of the patron's own skills behind it (Brainfog and Haluca; Gasp and Humble).
  - **Affiliation: Urlo** and **Affiliation: Sol** (one of them, `one_of = affiliation`): the god's Favour first, then Wellspring (Urlo) or Flamewall (Sol). Other gods can get a tab each.
  - **World: Nature**: an **Elements** root (Attunement, Draw from the Land, Weathercraft) and a **Leylines** root (Ley Sense, Ley Tap).
- [ ] **Mage** (`Roles/mage.tres`, new; "Caster", the Red Mage sprite, 10 Mana, robe, staff and a mana potion; not on the entry screen, like the Wizard): its own tab is the general Mage tree, with Mana, Mage Armor and every starter spell on the core ring.
  - **Refinement** root (safer, refined): Precise Casting, Extend Spell, Reach Spell; Quicken after both; the Magic Skill Slot +1 capstone.
  - **Commitment** root (the extra mile): Focus, then Resonance, then Piercing Focus.
  - **Schools**, one of them (`one_of = school`), each opening after its starter spells: **Radiance** (fire and light: Searing, Radiant Lance, Sunburst), **Currents** (water and wind: Undertow, Gale, Maelstrom), **Stone** (Quake, Rampart, Bedrock), **Shadow** (Darkstone, built, then Umbral Step and Eclipse), **Stars** (Fortune, Constellation, Starfall).
  - **Colleges**, one of them (`one_of = college`): **Battle** (Battle Casting, Volley, Spellstrike), **Wards** (Ward, Counterspell, Sanctum), **Concord** (Spell Share, Linked Casting, Harmony).

16. Mana, as built (each can change):
    - A Wizard's starter spells are all tier 1 on its core ring, so ranking Mana past I does nothing for them yet. Fine?
    - Only the starter spells are "basic spells". Hex stays 2 Energy flat (half AP paid with Mana), and Darkstone 3. Right?
    - Starting Wizards get 10 Mana (Icor, level 5, has 12). Right amount?
    - With Working Knowledge, Energy would get Mana's half cost too, but only for a unit that also has the Mana passive. Adventurers can't learn it, so this doesn't come up yet. Right?

70. **Wizard and Mage trees - stubbed on judgement, open for review (2026-11-07).** The shape is what to look at; every new skill's plan is my sketch.
    - Wizards' variety vs Mages' commitment is the spine: Spellweave and Attunement reward switching spells and elements; Focus and Resonance reward sticking to one.
    - The Wizard's liability lives in its Transgression root: Backlash (Overchannel, Unbound), paying Mana in HP (Blood Magic), surges (Wild Magic), Taint (Forbidden Lore, a new liability resource, undesigned), demons through a Rift. Should the liability be in every Wizard tab instead (pacts and affiliations cost something too)?
    - A pact and an affiliation are each a choice of one, but a Wizard can have both. Pacts borrow two of the patron's real skills, behind the stubbed Pact skill; a Wizard's pact uses int for Sweet Nothings. Only Urlo and Sol have affiliation tabs so far.
    - Schools are elements, paired the way the gods pair them (Sol fire and light, Drael water and wind), each opening after its starter spells. Colleges are postures: Battle offensive, Wards defensive, Concord supportive. "Synergized" read as the three trees feeding each other, and Concord casting with other casters.
    - Counterspell sits on both (the Wizard's Arcane root, the Mage's Wards college). Darkstone stays a Wizard option and is the Mage's first Shadow skill.
    - Both use the Red Mage sprite, and neither is on the entry screen. Starting Mana 10 for both.
    - The tab row now wraps to a second line: an undecided Mage has 11 tabs, 5 once it has a school and a college.

### Wizards, revised (2026-11-08)

- [x] **Dabblings**: a branch of the Wizard's own tree, its way into other classes' trees: the Bard's magic trees, and really any tree tagged Caster. Your answer (2026-11-09): not a fixed list; Wizards get the other casters' actual trees, penalized for trees outside their own. Built (`docs/done/classes.md`). (?71 ?76)
  - **Expanded studies** (guest trees at -1 Affinity): **Divinity** gains a religious domain, **Symphony** a Bard genre, **Witchery** a Warlock pact.
  - No Affinity penalty: **Mastery** gains a Mage school.
  - Guest skill trees default to -1 Affinity.
- [x] **Picking trees**: every class picks its trees on its own (universal) tree by unlocking their tier 0 roots there. A box around the choice says "Pick up to x" (the cap), and darkens the tree's backdrop behind it. Built (`docs/done/classes.md`). (?71)
- [x] **Emergency Exit** (high tier): makes the forming escape portal open rank turns early where it's forming; otherwise warps the party to a bland pocket dimension of stone (still in the scenario, reachable only by a two-way portal). The pocket lasts rank rounds, then returns its units in a clump. Built (`docs/done/classes.md`). (?75)
- [x] **Rift**, revised: opens an actual portal to an extra-planar domain (`docs/todo/world.md`). Opened in line of sight within rank range: usually adjacent, but higher ranks can open one over walls. Optionally channeled: its duration shows as infinite until the Wizard stops channeling it. Your answer (2026-11-09): it can be cast unchanneled, and its duration only starts when the caster stops channeling; doors both ways is right. Built (`docs/done/classes.md`). (?75 ?76)

76. **Borrowed trees and Rift's count - built on judgement, open for review (2026-11-09).**
    - Each Dabbling borrows a kind of caster tree (its roots all magical) from whichever class has one, found as the game runs (`TreeChoice.borrows`, `TreeChoice.caster()`): Domain every Divinity tab (the Cleric's Luun, Sol and Eros), Genre every Genre tab, Pact every Patron tab (the Warlock's Elmon and Hogel), School every School tab (the Mage's five). A new class with a tab of one of those kinds is on offer with no change to the Wizard.
    - "Penalized for trees not representing its own" read as before: -1 Affinity on domains, genres and pacts; none on Mage schools, which are arcane like its own.
    - Answered (2026-11-09): Clerics get Eros too, and Wizards get caster trees, not just the trees of caster classes - but none of a class's own features on them. Built: Eros is the Cleric's third god (the Paladin's own Divinity: Eros tree), so it's a Wizard domain again. Class features are tagged with their class (`Skill.classes`, shown first in their tags) and locked for anyone else ("Paladin only", `Unit.missing()`).
    - My call: which skills are class features. On the trees anyone can borrow today, only the Paladin's three on Eros: Smite, Lovely Caster and Impassioned Fighter. Pray and Renew stay open to anyone with Eros, Hex and Sweet Nothings to anyone with a pact, since the trees start after them.
    - The Bard's Song moved from a root on its own tab to a tab of its own, kind Genre, so it can be borrowed. The Bard now shows two tabs, Genre: Song and Calling: Freedom.
    - A borrowed tree brings its class's shared row first on its core ring, as that class shows it: the Cleric's Pray and Renew on a domain, the Warlock's Hex, Sweet Nothings and Chant on a pact. The Pact box now shows the Warlock's trees by their own kind, "Patron: Elmon".
    - Rift: Alt-click on the target casts it unchanneled. Its count is 3 x its difficulty turns (2, 3, 5, 5, 5 by rank), and the doors stay open both ways until it runs out; then the Wizard's side comes back in a clump and the domain goes with whatever else is in it. Using it again, channeling something else (Metea), or falling stops the channel and starts the count.

75. **Rift and Emergency Exit - answered (2026-11-09):** Rift can be cast unchanneled, its duration starting only when the channel stops; two-way doors are right. The rest stands as built:
    - Rift: no longer a stub or an AI design (your design now). It opens on the Transgression root once one skill is learned; range rank tiles, in a clear line (no earthwork or hole between) below rank III, over walls from III.
    - Its domain: a diamond 9 tiles across (41 tiles: "8x8" read as the diamond's span), far off on the same map, its door at the west tip, the escape portal at the centre. Its demons: the Undine-and-Sirens formation at 0.5 x rank difficulty (I: 2 of them), at the Wizard's level.
    - Channeled or not: see ?76.
    - Emergency Exit: on the Arcane root once three skills are learned, up to rank III. It hastens a forming escape portal by rank turns; otherwise it warps the Wizard and its allies within rank tiles to a 5x5 pocket of stone for rank turns. Its door goes both ways while it lasts, so foes can follow.

71. **Picking trees and Dabblings - answered (2026-11-09):** the Wizard's trees on offer are found, not listed (?76). The rest stands as built:
    - A tree's tier 0 root is the tree itself, not a skill: picking it is free (no skill point), and it opens the tree's tab. The tabs of trees not picked are hidden.
    - The choices: Paladin Prowess (1, only those that suit its god shown), Warlock Patron (1), Cleric God (1), Mage School (1) and College (1). Rogue's and Bard's Calling: Freedom, the Berserker's three Prowess tabs and the Wizard's World stay open without a pick.
    - Wizard: Divinity, Symphony, Witchery and Mastery each go to rank III, and each rank is one more pick.
    - The stubbed Pact and Favour skills from round 70 are gone; the real trees replace them.
    - Units authored with a tree's skills and no picks count those trees as picked (NPC Clerics keep their god).

## Warlock

*Now:* `Roles/warlock.tres` (cha 15, the Gaunt sprite; on the entry screen): a tab per patron, **Elmon** and **Hogel**, sharing a static tier 1 row (Hex, Sweet Nothings, Chant), with Hex and Sweet Nothings learned from the start. Elmon's tab: Analysis Dialysis, wauaw, Brainfog and Haluca, from tier 2. One patron per Warlock. Built entries are in `docs/done/classes.md`.

- [x] **Chant** and **Hogel's path** (Humble, Gasp, Breathtaking, Irradiate; resting whole satisfies him): built (`docs/done/classes.md`). (?42 ?45)
- [x] Level Down (tier 5) and Death (capstone) need a Sweet Nothing (`docs/done/classes.md`).
- [ ] **A Demon / Warlock / Dark Magic skill**: your message of 2026-11-09 cut off after "Demon / Warlock / Dark Magic skill:", between the XP rules and the level cap. Nothing built; what does it do?

42. Chant, as built: "waiting" is resting the whole turn (no move, no AP spent). It primes the next rank Sweet Nothing gains to bring one more each ("from the next rank gains"), and the next Warlock skill to be used a rank higher. Right reading?
45. Humble: "lasts longer the less max HP the unit loses (rank * (4 * % of max HP cut) turns)" - as written the formula grows with the cut. Built as rank x 4 x (1 - the share cut), at least 1 turn: rank I on a unit at full HP lasts 4 turns. Right?
46. Sol, where your text left gaps (each built my way):
    - Flamewall: "if a unit is standing on a targeted tile, they may attempt a dex check to we..." - cut off. Built: d20 + dex mod against the caster's d20 + wis mod; passing, it isn't burned as the wall goes up (it still stands in fire). The wall lasts rank of the caster's side's turns.
    - Inner Fire: the 5% x rank a turn is plain HP loss (poison), not fire; Flamecharm doesn't ward it.
    - Burning Bag: whatever trinket it replaces goes to the stash (for the player's side). Its slots are untyped.
    - Flamecharm at rank V+: "pick up to rank units" - there's no multi-target picking yet, so it takes the nearest rank allies, itself first. Its effects last rank turns.
    - Cindering: rolls to hit; burns the target's rightmost rank hotbar slots for rank turns.
    - Flamedance: lasts until the end of its holders' next turn.
    - Solar: "d20 + wis total" built as d20 + the wis score itself (not the mod); its length is wis mod tiles, at least 1.

## Cleric

- [x] **Cleric**, with Sol's full path: built (`docs/done/classes.md`). (?46)
- [ ] More Luun skills, so Death sits as a capstone; Death for Luun Paladins once Paladins have Divinity tabs.

## Rogue and Bard

- [ ] **Rogue**: will get more tricks. Sprite is a placeholder (Elman).
- [ ] **Bard**: will get songs. Sprite is a placeholder (Doebour).
- [x] **Bandwagon** and **Molothrus** (2026-11-10) on the Freedom tab's Performance root, after Personify; Blinthe, a level 16 Bard of his own side, has both at III. (?94)

19. Rogue and Bard, as built:
    - Each Freedom tab is the class's own copy, so the Bard's has no Snare. Should Calling: Freedom instead be one tree both classes share?
    - Performance (Tonefoolery, Glamour, Manifest) is tagged specialist, so it moved to the Bard's Freedom tab, leaving its own tab with Song. Or is Performance the Bard's own?
    - Hide and Clever Disguise are still each Freedom tab's centre (tier 1). Keep them there?

## Paladin

Three roots in the class tab, each starting with an active skill: **Divinity** (one so far: Eros), **Idealism** (one so far: Chivalry) and **Prowess**: any prowess somewhat aligned with its god, of the player's choosing.

**Divinity: Eros.** Spells are tagged `divine`, `cha`, `<3`. Divinity is in the caster family. (?12) Clerics of Eros and Wizards with it as a domain learn it too, but Smite, Lovely Caster and Impassioned Fighter are the Paladin's alone (?76).
- [x] **The Paladin's tree** - Divinity: Eros, Idealism: Chivalry, and a Prowess of its choosing (was Protector alone) - with Renew, Pray and Smite on Divinity and Coordinate on Idealism: built (`docs/done/classes.md`). Favour, Lightvision and Judgement stay on its core ring. (?12)
- [x] **Rejuvinate**, then **Send Off**, **Lovely Caster** and **Impassioned Fighter**: built (`docs/done/classes.md`). (?12)

**Idealism: Chivalry**
- [x] **Coordinate**: built (`docs/done/classes.md`). *Now:* opens the Idealism root.
  - [ ] **Final Act** (passive): once per battle, on reaching 0 HP, interrupt the current turn to take 1 free action; the interrupted turn then resumes. *Now:* a stub after Coordinate; needs Reactions. (?12)
  - [ ] **Gallantry** (passive): cha check against a unit attacking an adjacent ally. On a pass you become its target, and that ally can't be retargeted. *Now:* a stub after Coordinate; needs Reactions.

**Prowess** - any prowess somewhat aligned with its deity (2026-11-07).
- [x] **Choice of Prowess**: a Prowess tab per tree (`SkillTab.one_of = prowess`), the same roots the Fighter and Berserker use (`Trees/*.tres`). Only those that suit its god (`SkillRoot.gods`) show and open; learning a skill on one takes it up and closes the rest ("Took up Prowess: Protector"). (`paladin_test.test_prowess`)
69. **Prowess alignment - built on judgement, open for review.** Which gods each prowess suits. *Choices made:* Protector - Eros, Sol, Vetruvis; Vanguard - Ramut, Eros, Sol, Vetruvis; Slayer - Luun, Ramut, Drael; Brawn - Ramut, Vetruvis; Fury - Ramut, Sol, Urlo; Havoc - Ramut, Luun, Drael, Urlo. Each god has at least two; an Eros Paladin (the default) gets Protector or Vanguard. One Prowess per Paladin, the choice is permanent (no respec yet), and unaligned tabs are hidden rather than shown locked, to keep the tab row short.

12. Paladin: is "Rejuvinate" spelled on purpose? Is its distance decay fixed when cast? Send Off: who picks the landing tile, and does it work on enemies? Final Act: does the unit die after its free action? `<3` as a tag ID, or an internal `love` tag shown as <3?
    *Built on judgement (2026-11-06), open for review:* spelled as you wrote it; the decay is fixed when cast (moving later changes nothing); Send Off works on allies and foes (a foe gets an attack roll first) and lands on the furthest free tile on the straight line away from the caster - nobody picks it, since targeting takes one pick; `<3` is the internal `love` tag (Eros's damage tag). Final Act is still open.

48. Bracing, as built: every Bracing passive caps its bonus at its rank (you wrote "up to rank" only for Agility). "Effectively equipped" is read as worn with its requirements met. Right?
51. The Specialist opener is **Journeyman** (a skilled hand across trades; "Specialist" would clash with the tree's name). Specialist classes reach the other trees through Martialist and Thaumaturgist two tiers sooner (you said "a tier or two"). Both right?
52. Perfect, as built: the 36 hits count across one Strike's restrikes; the 300 HP heals up to max HP (it doesn't overheal). Should it overheal?
50. Strike's upgrades, where I filled gaps:
    - Tiers: low II, mid IV, high VII (Strike! too); the high-tier passives are mine: Decisive, Brutal and Elemental Mastery. Martial is red (you wrote "green" twice).
    - Brutal Strike: "add rank to your weapon ranks for this attack" built as + the weapon's rank + rank to damage.
    - Record Striker: the curse is the foe's wis against the striker's highest mental mod, and the rank lost lasts its next turn.
    - Elemental Strike's elements: fire, water, earth, air, light, dark.

## Fighter

Three roots, each a flavour of Prowess of the player's choosing. Three exist so far.

*Now:* the three roots are built (`Roles/fighter.tres`; Protector is `Trees/protector.tres`, shared with the Paladin, which picks one Prowess its god suits: ?69). Wary stays on the core ring. Unbuilt skills are stubs on their roots. (?67)

**Protector:** defense of self and others.
- [x] **Shields Up!**, **Obstruct**, **Interdict** and **Turtle Tactics**: built (`docs/done/classes.md`). (?67)
- [ ] **Interject** (passive, `defensive`): when an ally is hit, dex check; on a pass you become the target. −25% damage per rank when taking a hit that wasn't aimed at you, with no rank cap (past 100% it still blocks only 100%). Rank 5+: +25% × rank to Defense when taking hits for allies. *Now:* a stub after Shields Up!; needs Reactions. (?13)
- [ ] **Snapping Turtle** (passive): when the unit uses an `offensive` skill, it also triggers up to rank of its `defensive` passives, top to bottom. *Now:* a stub after Turtle Tactics; the defensive passives it would trigger (Interject) need Reactions.

**Vanguard:** front-line offense and tactics.
- [ ] **Warcry** (active; *Now:* a stub opening Vanguard, waiting on tile marks): pick up to rank enemies the unit can see. Rank tiles on the line to each get a one-use effect, triggered on entry, lasting a few turns:
  - Nearer half, **Charge!** (expanding translucent hot-orange squares): allies regain rank dex AP and deal +10% × rank damage until their turn ends.
  - Farther half, **Routed!** (collapsing translucent dark-blue squares): enemies pay +rank movement.
- [ ] **Inspire** (passive): hitting an adjacent enemy with a skill gives allies within rank tiles +rank damage. Allies whose luck is below 1 also get **+1 Luck ltd.** (?13)

**Slayer:** eliminating chosen targets.
- [x] **Jugular**: built (`docs/done/classes.md`). (?67)
- [ ] **Sundering** (passive): an attack rolling higher than the target's dex mod applies stacking **Sundered**: −1 Defense for rank turns. (?13)
- [ ] **Silent Strike** (active): disables rank of the target's `magical` skills, actives and passives, for rank turns, starting from the bottom of its hotbar. Disabled skills are greyed out. (?13)
- [ ] **Gank** (hybrid): not designed yet. *Now:* Sundering, Silent Strike and Gank are stubs after Jugular.

13. Fighter:
    - Interject: who can it trigger for (adjacent allies? any ally in sight?), and how often (once a round? every hit)?
    - Sundering: "an attack rolling higher than the target's dex mod". Its Defense instead, now that attacks roll against Defense?
    - Silent Strike: do `divine` spells count as `magical`?
    - Inspire: does "+1 Luck ltd." mean it can only raise luck as far as 1?

67. **Fighter and Protector - built on judgement, open for review (2026-11-06).**
    - Tree: each root opens on its active (Shields Up!, Warcry, Jugular); the rest come after it, Snapping Turtle after Turtle Tactics. Protector's capstone is a Basic Martial Skill Slot +1 (3 of its skills); Vanguard and Slayer have none yet. One Protector root serves the Fighter and, as one Prowess it may choose, the Paladin.
    - Shields Up!: range 8 (there's no line of sight yet, so "unobstructed" isn't checked); rank VIII blocks everything; it lasts through its next turn; a DEFEND order faces the nearest foe the unit makes out.
    - Obstruct: "its size penalty" is what moving through the obstructor would cost the mover (so the mover's dex eases it); "+25% per rank" multiplies that, x1.25 at rank I; two obstructors beside one tile both charge.
    - Interdict: the str check is a save (d20 + str mod + rank against the foe's d20 + str mod); Attack Down is -20% x rank damage dealt; the AP is the caster's str mod off the foe's next turn's general AP, never below 0. 3 AP, 2 Energy, adjacent.
    - Turtle Tactics: attack rolls count as offensive checks (-rank to hit); Defense isn't a check, so it stays as it is.
    - Jugular: 1d6 + str mod (its weapon's blow), 4 AP, 2 Energy, adjacent; recasts stop after 20 in a row, a guard against a runaway loop.

57. **Actualization - built on judgement, open for review.** The Adventurer's Path tab: Self-reflection (T1, rank levels of self-knowledge for the battle), Hardy (T2), Meditate (T3, paid with movement then AP; rank levels of self-knowledge; then a respec, each stat up to rank from birth). *Choice made for the cut-off "if a unit doesn't know themselves well enough to...":* the respec reaches no further than the unit knew itself before that Meditation, so a first Meditation without Self-reflection only teaches; respecs and self-knowledge last the battle, since class units are made fresh each one. Want them to persist between battles once progression saves?
    - **Earlier inline notes being built (2026-11-12, branch `a-small`).**
58. **Berserker - built on judgement, open for review.** Reckless Abandon (inherent): Offender +1, Unsupportive and Indefensible -1, and skipping defensive and supportive steps. Affinity picks a skill's cost curve and its points' rank, live. *Choices made:* the even curve stays today's 1 + r^2 steps (1, 3, 8, 18 - about n^2) rather than n^2 exactly, so no existing costs move; +1 is n log2 n rounded up, never below n (1, 2, 5, 8, 12); ranks never drop below I (unlocking always costs 1); a skill's Affinity is the sum over the postures it serves, so a dual skill pulled both ways nets out; a posture tag on a skill decides outright (Frenzy: offensive). The three Prowess tabs - Brawn (Bulwark -> Crushing Blow), Fury (Second Wind -> Frenzy), Havoc (Rally -> Savage Swing) - are my content. *Deferred:* investing in a skill per posture ("a certain rank under those circumstances"); a Berserker sprite (it borrows the Fighter's).
- [x] **Hardy** (Actualization passive; Alabaster borrows it): con mod counts (1 + rank) times in the HP each level brings.
64. **Wildfire - built on judgement.** Sol's tab, after Solar. *Choices:* a fixed 60 degree cone; extreme = (3 x rank)d6 + wis mod; it spares its caster (Solar doesn't); an earth unit's evasion uses the impossible rung's DC rather than failing outright (at rank I that's DC 10).
65. **Judgement - built on judgement; gods and patrons answered (2026-11-12), in progress (branch `a-gods`).** A Paladin option, and on the Cleric's Sol tab ("lawful domains": Sol among the Cleric's gods; Ramut's too, when a Cleric can follow him). *Choices:* an attack within rank tiles for 1d4 + wis mod, open from the start; the shackles are its payload.
    - **Answered (2026-11-12):** one god system for now. A god / patron grants every skill tree within its domain as choices: e.g. a Paladin picks 3 trees beside the universal ones, one prowess, one domain, one flex (a specialist leadership tree, an extra prowess, or a domain caster tree such as fire or light that the other domain god may offer), from whichever the god grants. That is one god, then the pool of trees it offers, then the unit picks 3 (if there is any choice at all).
    - **Warlock pacts** are simpler: a patron grants only its own tree, and a Warlock otherwise has two flex trees. With investment in the general Warlock tree it may form pacts with other patrons as flex trees, **or** deepen its devotion to one patron and burn a flex slot outright, gaining efficiency on that patron tree for skills up to rank tier. A tree burned this way is darkened with the cursed effect (the one that disables skills) and mirrors the patron tree's name.
    - **Bargaining** (Warlock general tree, tier 5, stackable): grants an efficiency stack to patron trees. **Acceptance** (tier 10, stackable, identical in kind): grants an additional efficiency stack up to rank tier patron trees.

## Ranger (2026-11-09)

Bounty hunters, scouts, detectives and border-justice types (an Arizona ranger), as well as foresters and protectors of nature: survival and efficiency, on Central's streets or in the circus wilds.
- [x] **The class** (`Roles/ranger.tres`): general Specialist and Martial trees; its own tab's roots - **Bounty** (Observe -> Snare, Special Eyes), **Scout** (Hide -> Eyes Forward, Wary), **Forester** (First Aid -> Field Experience) - borrow what's built. (?81)
- [x] **Discipline comes easier** (`Role.knack`: Affinity +1).
- [x] **Nature trees**: a Nature choice borrowing the Druid's biomes (pick 1), learned inefficiently (Affinity -1) until it has learned 4 magical skills, its "major investment in magical abilities" (`TreeChoice.invest`). (?81)
- [x] **Natural Talent** (core ring, passive): Nature skills up to tier rank are easier to learn, Affinity +1 (`TreeChoice.talent`).

**Discipline** (specialist general skill, tier 3; on the Paladin's and the Mage's own trees too) - [x] built: a toggle. An attack on a foe burns the AP its user has left (not dex move AP), up to rank; each point burned is +2 to hit, +25% damage and crits a face lower (19+ for one point). The less spent before it, the more to burn. (?80)

80. **Discipline - built on judgement, open for review.** *Choices:* a passive toggle, off-able when you'd rather keep the AP; it burns only up to its rank (not everything left); +2 to hit, +25% damage and a face off the crit range a point - "massive" - on Strike's every hit and any attack skill; area skills and saves aren't attacks, so they don't burn. *Deferred:* the initiative half of "the less AP / init you spend" - nothing spends initiative yet; when delaying a turn exists, initiative given up could burn the same way.
    - **Earlier inline notes being built (2026-11-12, branch `a-small`).**
81. **Ranger - built on judgement, open for review.** *Choices:* the three roots and their names (Bounty, Scout, Forester), all borrowed skills, no new ones; Specialist and Martial general trees; one Nature tree; "major investment" = 4 magical skills learned, lifting the -1 on every Nature skill; Natural Talent's +1 stacks with it (so a talented, invested Ranger learns low-tier Nature magic at +1). Gambeson, rapier and the Adventurer's sprite for now.
    - **Ranger capstones (2026-11-12, branch `a-gods`):** as rangers develop they get midpoint capstones that unlock a lighter martial prowess tree (your note under 81, now built with the gods).

## Druid (2026-11-09)

Oft-secluded experts in natural and celestial magic - wizards for natural magic, wildshaping.
- [x] **The class** (`Roles/druid.tres`): general Caster tree; **Beastshape** at tier 0.
- [x] **Biomes** - pick 1 or 2 on its own tab: **Astral** (stars, cosmic magic, spirit realms), **Sylvan**, **Montane** (mountains, highlands), **Xeric** (desert, drought), **Nival** (snow, ice), **Thalassic** (sea). Each borrows what's built where it fits (`Trees/<biome>.tres`):
  - Astral: Mana -> Astera, Fortune -> Starkind, Constellation, Starsap, Starfall. Picking it **grants mana** (10, `SkillTab.reserves`).
  - Sylvan: Regeneration Pulse -> First Aid, Snare -> Barkskin ??, Draw from the Land.
  - Montane: Stonegift -> Terestera, Quake -> Stoneskin, Rampart -> Bedrock.
  - Xeric: Igna -> Inner Fire, Searing -> Mirage ??, Sunburst.
  - Nival: Gale -> Hoarfrost ??, Weathercraft -> Whiteout ??.
  - Thalassic: Waterstrike -> Oceanic, Hydera -> Undertow, Well Up -> Maelstrom.
- [x] **Guest mage trees** (a Guest choice borrowing the Mage's schools and colleges, pick 1): Affinity -1, none for an elemental skill or a tree kin to a picked biome (`SkillTab.kin`: Astral - Stars, Thalassic and Nival - Currents, Montane - Stone, Xeric - Radiance, Sylvan - the Wizard's Nature). (?82)
- [x] **A skill on two trees is one skill**: learned and ranked once. Its tree's progress can't be skipped: a skill learned by one tree's way counts on another only once what comes before it there is learned too (`Unit.reached()`).
- [x] **Beastshape** (T0, 2 AP, self): body and mind become a beast that thrives on the tile and belongs to a picked biome, for rank + 1 turns; used again, back. Shaped, only Strike, beast skills and Beastshape work.
  - dirt, grass: **rabbit** - haste (+rank movement). [x]
  - wood, leaves, brush: **squirrel** - climber (occupies tree tiles). [ ] waits on tree tiles
  - stone, dirt: **mole** - tunneler (stone and dirt cost rank times less, at least 1) [x]; blindsense (non-solid visual blocks and visual illusions ignored within rank tiles) [ ]
  - Astral only - star, void: **wisp** - Siphon (steal Power from a nearby unit or occupied power source), floating. [ ]
  - Astral only - elemental ground: **mote** - <element>strike (its Strikes carry the element, rank uses: Elemental Strike's way) [x]; Coalesce: absorb tile or energy from a nearby unit to evolve into a basic elemental - water Undine, dark Wraith, light Seraph, magic Sandestin, stone/earth Oread, woodland Sprite, fire Ifrit, desert Djinn, ice Hrimling. [ ] (only the Undine exists)

82. **Druid - built on judgement, open for review.** *Choices:* which skills each biome borrows, and the four new stubs (Barkskin, Mirage, Hoarfrost, Whiteout, marked ??); the kin table above; elemental = fire, water, earth, light, dark, energy, ice, air/wind, nature tags; one guest tree; which biomes each beast belongs to (rabbit: Sylvan, Montane, Xeric, Nival; squirrel: Sylvan, Montane; mole: Sylvan, Montane, Xeric; wisp and mote: Astral); the first beast that fits wins, in that order; a mote of desert ground is air (the Djinn); shaping lasts rank + 1 turns and costs 2 AP. *Open:* Thalassic has no beast of its own yet (an otter? a seal?); no sprite change while shaped; Druid sprite borrowed (Elmit).
    - **Earlier inline notes being built (2026-11-12, branch `a-small`).**


## Downed, Tenacity and Grudge (2026-11-09)

Down but not out: one condition any skill configures by data. Plan: `docs/plans/downed.md`.
- [x] **Downed** (`Scripts/Downed.gd`; `Skill.downed`): a unit with such a passive, on its last life, taken to 0 HP doesn't die. Later blows take it below 0, to a limit of share x rank x max HP; past it, it dies. Healed above 0, it is saved and `Battle.rescued()` pays the rescue XP. (`docs/done/rules.md`) (?85)
- [x] **Tenacity** (Adventurer, Fighter; passive; beside Wary): lingers downed for rank rounds, 20% x rank limit, helpless. (?85)
- [x] **Grudge** (Berserker, low tier on `Trees/fury.tres`; passive): downed, it keeps acting for rank rounds, 20% x rank limit; more than rank skill uses in all, or a round ending without a melee attack, and it dies. (?85)
- [x] The card chip, log lines and floats ("Downed", "Saved") say so; the AI takes no turn for a helpless unit, strikes a helpless foe last, and closes in with a Grudge unit's last blows.
- [ ] **Draw a Downed unit differently on the map.** Nothing does: only the card chip, the log and the float text say so (unit drawing was being reworked elsewhere).
- [ ] **The AI doesn't try to starve Grudge of melee**: it won't keep away from a Grudge unit to let it die of a round without a melee attack, and a Grudge unit doesn't try to heal itself back up.
- [ ] **Bug, noticed and not fixed:** a side's last unit dying inside `Battle.end_turn()` (a bleed, now also a Downed unit's last round) makes `_on_died` pass the turn, and `end_turn` then passes it again; with three or more sides one is skipped.
- [ ] A helpless leader can still give orders, and a helpless unit still watches, guards (Shields Up!) and dodges as before.

85. **Downed, Tenacity, Grudge - answered (2026-11-10), built (`v-channel`, ?97).** Going Downed and helpless ends a channel; a Grudge unit keeps its channel (both: yes). Jam, below, is new. Built: `downed_test.test_channel` (the wiring was already there). The rest stands as built:
    - A round is one of the unit's own side's turns ending after it went down; if it went down on its own side's turn, the rest of that turn is free. Its last round ending at 0 HP or below, it dies. The blow that downs it leaves it at 0; at exactly the limit it lives. Overkill isn't carried into the negatives; a multi-hit Strike's later hits do land.
    - Hearts and a Red Spinel Ring are spent before a Downed skill does anything: Downed is only for the last life.
    - A Grudge action is each skill use it pays for (Strike counts once however many hits); walking, toggles and items don't. The use that goes over still resolves; then it dies. A melee attack is an attack, hit or miss, on a foe touching it.
    - Helpless (Tenacity): can't act, move, use items or take orders; still holds its tile, can be hit, targeted and healed; its effects tick, it still sees, its passives stay on, and its side isn't beaten while it lingers.
    - XP: fall XP is paid when it actually dies, not when it goes down; rescue XP when its HP rises above 0, two shares to whoever healed it last (if another unit), once. Downing gives no kill credit; the death does.
    - Executes (Death, Luun's Smite): a standing unit goes Downed as with a heart; one already Downed dies. With several Downed skills the highest rank counts, first listed on a tie, fixed as it goes down.
    - Placement: Tenacity beside Wary (Adventurer's Martial root, open from the start; among the Fighter's options). Grudge open from the start, `classes = [berserker]` (a Paladin borrowing Fury sees it locked).
    - **Going Downed and helpless ends a channel; a Grudge unit keeps it** (answered yes to both; `Downed.changed()` already did it, now pinned by a test).

- [x] **Jam** (2026-11-10): built (`docs/done/classes.md`, `docs/plans/channels-jam.md`), `Tests/jam_test.gd`. (?97)
- [x] **Jam's damage hits Focus** (2026-11-11): it takes as much off the target's Focus as the HP it lost. (?97, ?100)
- [ ] **No screenshot check** of Jam, or of the Jammed ?? icon.

97. **The channel rule, helpless, Jam - answered (2026-11-11), built (`w-focus`, ?100).** "Slayer is a good call": Jam on Slayer, reaching the Fighter and Berserker, is settled. Focus: "yeah focus is a resource that rangers and mages can access. Focus: builds up quickly, only while resting. can be used in place of energy. if fully used to cast ranged attack skill, rank bonus to accuracy" (built, ?100; `docs/plans/focus.md`). Still open: the Jammed ?? reading of stun; the rank-cost curve (1 + r^2, 19 skills capped). My calls: Your rulings on 85 and 89, built on `v-channel` (`docs/plans/channels-jam.md`). My calls:
    - **Rank-cost curve answered (2026-11-12), in progress (branch `a-items`):** a Grand Design is an equipment item, not learned and ranked like a skill, but however it is ranked up follows similar logic. A legendary item is about as powerful as 4 skills: ranking it up once costs what ranking up a skill 4 times would. Rarity multipliers: uncommon 1.5, rare 2, epic 3, mythic 5 (legendary 4).
    - **`enchanted`** equipment: the default effect is rank +1, applying as normal at higher rarities. **`honed`** (new equipment tag): mutually exclusive with `enchanted`, meaning material perfection; applies rank +1 and does not activate the `enchanted` bonus effects. These qualities may be given to skills too, when a skill must have a materially large impact to justify its place as a capstone.
    - **An idle channeler still gets half-rate Energy** (the light rate): holding a channel is light work, not none. It gives up the rest rate, extra exhaustion recovery, the watch bonus, Chant and Hogel's rest.
    - **Free recasts, 0-AP actions and reactions on the foe's turn don't break a channel.** Anything that spends AP, a move or a strike does, at turn's end. The turn it was cast in is exempt.
    - **Flamedance, glass and a posing traitor read "held still", not "rested"**: standing still with a channel is not acting.
    - **The AI holds still to keep a channel** it began earlier, when it has nothing to strike.
    - **Settled (2026-11-11):** Jam on Slayer. **Jam sits on the Rogue's Blade root and the Slayer tree** (the most offensive of the Paladin's six Prowesses: all four skills are attacks), so the Fighter and Berserker get it through Slayer. Say if Jam should be on another Prowess.
    - **"Instant stun" is read as the interrupt plus Jammed ?? through its next turn**: no dodge, no guard, no obstruction. No stun condition existed. **Jammed ?? is an AI-made name for you to review.** The interrupt ends a channel, hiding, Shields Up!'s guard, a primed Chant and the watch bonus; a disguise, a grapple, a beast shape and sleep stay.
    - **Answered (2026-11-11): built** (?100). Jam's damage counts against Focus.
    - **Found, not changed: the rank-up cost** is 1 + r^2 skill points (quadratic per rank: II 2, III 5, IV 10, V 17), and only Clever Disguise grows exponentially (`rank_cost` 4, `rank_growth` 2). 19 skills set a rank cap (12 at 1, 5 at 3, one at 5, one at 8). You said costs should grow exponentially with no cap. Shall I make the exponential curve the default and drop the caps?
- [x] **Focus** (2026-11-11): the Ranger's Bounty root and the Mage's Commitment root; built (`docs/done/classes.md`, `docs/plans/focus.md`), `Tests/focus_test.gd`. The Commitment stub that was called "Focus ??" is now **Fixation ??** (an AI-made name, for review). (?97, ?100)
- [ ] **The AI doesn't rest to build Focus** or save it for a shot. (?100)

## Clairvoyance (2026-11-09)

An arcane and Cleric spell, channeled: the caster senses where unseen foes are, and nothing more. Plan and what was built: `docs/plans/clairvoyance.md`. Built (`docs/done/classes.md`), `Tests/clairvoyance_test.gd`.
- [x] `Skills/clairvoyance.tres`: 3 AP, 3 cost, wisdom + rank range, location only, suspicion added, pings updated and the rank raised at each turn end held. (?89)
- [ ] **The AI never casts it.**
- [ ] **No screenshot check** of how pings look in the running game.
- [ ] **Lift `pings` into a behaviour** (see `docs/todo/systems.md`).

89. **Clairvoyance - answered (2026-11-10), built (`v-channel`, ?97).** There is never a rank cap, but the cost of ranking up rises exponentially, so it gets dear. "Moving does not end the channel" is overruled by the universal channel rule (`docs/todo/systems.md`): channeling has the same requirements as resting, so a unit that can't rest while moving ends the channel by moving. The rest stands as built:
    - A ping sees through walls (it is not sight).
    - The rank gained each turn has no cap while the channel holds.
    - AP and cost are paid once for the whole channel (3 AP, 3 cost), like Metea's; exhaustion counts it as one use.
    - Allies share the pings, as sight is shared across a side.
    - **Moving ends the channel now** (the universal channel rule, `docs/done/rules.md`); casting it again still stops it, free.
    - **Rank-up cost still isn't exponential** (?97): the rank-up cost is 1 + r^2, and 19 skills still set a rank cap.
    - Suspicion is added at the cast and at every update, so it builds each turn. Range is measured from the caster's current tile.
    - **Placement:** the Wizard's Arcane root; the Mage has no Arcane tree, so its Refinement root; for the Cleric, Luun's tree after Pray.
    - **Between updates a foe that moved is still drawn at its old pinged tile** ("Something may be here: sensed"), and only there until the next update.

## Siphon, Overcharge, Energy Transfer and the Sorcerer (2026-11-11)

Plan, readings and what was built: `docs/plans/siphon-sorcerer.md`; done in `docs/done/classes.md`. `Tests/siphon_test.gd` and `Tests/sorcerer_test.gd`.

117. **Siphon, Overcharge, Energy Transfer, Powerful, the Sorcerer - built on judgement; Energize and Heal answered (2026-11-12), being built (`a-recover`).** Your design notes on Power, Energy Transfer, Overcharge and Stellar Soul. Suite after both merged: 41663 checks, 565 tests, 0 failed. My calls, each for you to confirm or change:
    - **Answered (2026-11-12):** **Energize** is a basic AP to Energy skill, general tree, tier 4: no Energy cost but a quite expensive AP cost; grants 1 Energy per 2 AP spent, up to rank Energy purchasable. A unit may overcharge by 20% x rank of its total resource (Mana, Stamina, Sweet Nothings plus Energy and so on). Burnout and Recovery Endurance: ?116 in `docs/todo/systems.md`.
    - **Heal** and **Megaheal** (2026-11-12, `a-recover`): Cleric tier 8, life / love domain general. Heal applies a medium heal + caster mod + rank. Megaheal applies a very large heal + caster mod + rank, and costs more than Heal.
    - **Unbuilt, listed as work (2026-11-12):** Resuscitate, Intervention, Borrowed Time and the friendly-fire wisdom check (their texts are in your notes under 84 and 85 in `todo.md`).
    - **Siphon order:** a siphon attack's damage comes off the target's Overcharge, then the fund its last skill was paid from, then Energy, then its other reserves, fullest first; never HP. It takes precedence over the energy rule (no carry to HP). Confirm?
    - **A powered target loses x1.5** (`Unit.POWER_SIPHON`), since Power never comes back; doubling would let two Energy Transfers empty a Starmote. Confirm?
    - **Overcharge** is an extra buffer spent before any fund on a point-for-point cost; it only covers a cost when nothing else can. Focus and Sweet Nothings never use it. It decays over the granting skill's rank in turns, each turn's end taking (left / turns left) rounded up (10 over 3 turns: 10, 6, 3, 0); granted again, the points add and the timer restarts. The unit card shows "OC +n". Confirm?
    - **Energy Transfer:** `energy`, `siphon`, `magical`, int, 3 AP, 1 Energy, range 4; 1d4, 1d6 from rank III, no modifier. The caster gets what it drained as Energy up to its max; the rest (bar full, or no bar) as Overcharge at rank x 20%, rounded down, for rank turns. On the general Caster tree at tier 2, so every Mana user reaches it. Confirm?
    - **All energy grants go through `Unit.grant_energy()`** (Starblade, an Energy Potion, starlight, Starsap, Energy Transfer): on a powered unit they arrive as Power. Regen is not a grant. No "degenerate bonus effects" were invented.
    - **The Sorcerer:** caster focus, noun Caster, tree **Stellar Soul**: Powerful (root, learned first, not innate) then Energy Missile and Starsap, borrowed as they are; Energy Transfer from the general Caster tree. int 10, cha 15 (Mage's stats with the two swapped, since Energy Missile is a cha spell); no Mana; robe, staff, an Energy Potion; god Urlo (magic, energy); pale starlight blue tab. Confirm?
    - **Stellar Soul's description** ("Beings with a heart that originated from and yearns for the Astral.") lives only in docs and the test header: trees have no description field. Show it? That needs a field.
    - **Side effect:** Energy Missile and Powerful now sit on a magical tree, so they are magical by kind everywhere (exhaustion sharing; Mana may pay for Energy Missile). `exhaustion_test` now uses a copy on no tree as its skill of no kind.
    - **Open, for you to define:** **Energize** and **Power Transfer** are named in your notes but not defined, so not built. Guesses: Energize turns a Mana user's Mana into plain Energy (an active or toggle, for Starmen and Sorcerers); Power Transfer is the Sorcerer's counterpart to Energy Transfer, giving its Power to an ally (or siphoning Power at a better rate). What should each do?

## Trickster and Illusion (2026-11-11)

109. **The Rogue's Trickster tab - built on judgement, open for review (2026-11-11).** "A new trickster rogue skill tree with focus on trickery, persona, and deception. Left is showmanship, middle is deception, right is a caster hybrid wing that dips into illusion, teleportation, and utility magic." My calls:
    - **A tab of its own** beside Freedom (not a Calling the Bard shares), shown as TRICKSTER, mauve; no centre or core ring, just the three roots.
    - **Showmanship** (specialist, cha): **Flourish ??** (on itself, persona +rank for rank turns; 2 AP, 1), then **Stage Presence ??** (passive, cha +rank) and **Showstopper ??** (a foe within 1 + rank saves on wis or is **Dazzled ??**, luck -rank, for rank turns; 3 AP, 2).
    - **Deception** (specialist, cha): **Vanishing Act ??** (on itself, concealment and trickery +rank till it moves, investigated: it vanishes before its watchers' eyes; 3 AP, 2), **Double Bluff ??** (passive, embellish +rank), **Illusionist** at the top, tier 3 (?110).
    - **Legerdemain ??** (magical, cha - the Rogue's own stat, so a hybrid): **Phantasm ??** (illusion: a foe within 2 + rank saves on wis or is **Haunted ??**, recon -rank, for rank turns), then **Switcheroo ??** (teleportation: trade places with a unit within 1 + rank, a foe saving on dex; traps spring on whoever lands on one) and **Prestidigitation ??** (utility: an ally gets cha mod + rank AP to move with, at once).
    - All numbers are first guesses ("don't get hung up on balance").
110. **Illusionist and the Illusion school - built on judgement, open (2026-11-11).** "Illusionist mid-capstone for tricksters: unit gets access to Illusion spellcasting school. No purchase / rank up penalty for first t spells." My calls:
    - **"t" read as Illusionist's rank** (up to V): the first rank spells it learns from the school, in the order learned, have none of the guest penalty. Say if t meant something else (a tier, a fixed count).
    - **The penalty** is a picked guest tree's -1 Affinity (`TreeChoice.affinity`): unlocking costs the same, ranking up costs more. Spells past the grace pay it.
    - **Picked, not given:** once Illusionist is learned, the Illusion school is picked on the Rogue's own class tab, in the box the Wizard's studies use; it's the only tree in that box.
    - **A Mage school too**, beside Radiance, Currents, Stone, Shadow and Stars (and so one a Wizard can borrow).
    - **Its spells** (magical, int, paid in Energy): **Blur ??** (concealment +rank on an ally for rank turns), **Disguise Self ??** (trickery +rank for 2 x rank turns, investigated), **Mirror Image ??** after Blur (a tenth of each hit a rank turned aside, rank turns), **Phantasmal Force ??** after Disguise Self (a foe saves on wis or takes 1d6 + int mod), **Invisibility ??** after Mirror Image (concealment +2 x rank on an ally till it moves, investigated).
