# Todo: classes

`[ ]` to do · `(?N)` waits on open question N (numbered across all todo files) · *Now:* what the game does today. Done items and decided rules: `docs/done/`. Index: `todo.md`.

Every tree's capstone, for now (later a mid-tree capstone), is a **Basic Martial / Magic / Specialist Skill Slot +1**. (?10)

## Adventurer

Three roots, **Magic**, **Martial** and **Specialist**, with flat, radial trees: most paths are a few nodes long, and each root branches into about 6 strong applications of the basics. Paths are shallow slices of other classes' trees, but Adventurers can learn core skills many classes share: **Hex** and **Rejuvinate** are a first choice at any time. The three starting passives are separate skills on purpose, since each takes a slot; once Adventurers have skills that use them, they can become mid-tier passives in the tree instead.

- [ ] **Rejuvinate** on the core ring (see Paladin). *Now:* a stub. (?12)
- [ ] **Skill Slot +1** (unspecified type): acts like a base slot, slightly darker. Sits at the center, locked until current slots are filled. *Now:* a stub at the centre of the wheel. (?3)
- [ ] **Trade Skills** (passive): skill limits scale partly with wis: (base stat + wis × rank) / rank. *Now:* a stub on the core ring. (?2 ?11)
- [ ] **Grind** (passive): str mod can count toward martial limits; max HP drops by the % overage. *Now:* a stub on the core ring. (?2 ?11)
  - Rank 2+: bonus slots, each −10 × (rank − 1)% max HP while in use.
  - Rank 11+: bonus slots also cut max energy the same way.
- [ ] If a skill that grants slots is removed, its slots are lost as the Losing a slot rule says. (?7) *Now:* skills can't be removed.
- [ ] **Igna** (fire, Magic root): ally gains int mod + rank skill AP. *Now:* a stub. (?10)
- [ ] **Aetha** (wind, Magic root): ally gains int mod + rank movement AP. *Now:* a stub. (?10)
- [ ] **Martial root**: not designed yet. *Now:* Wary, then the capstone. (?15)
- [ ] **Specialist root**: more specialist skills to come.

3. The Adventurer's extra slot "sits at the center, locked until current slots are filled". Center of the hotbar (its middle slot) or of the radial tree? Does it unlock once every slot holds a skill?
10. Adventurer: is Mage (Red Mage) a class separate from Wizard? The Wizard uses the Red Mage sprite, and has the Mana passive. Do Igna and Aetha grant AP immediately, or for rank turns? Sola's +1 persona does nothing on a unit with no disguise set up: intended? The Magic root now has 8 branches against "about 6": fine? Which slot type does each tree's capstone give (Divinity: Magic, Prowess: Martial, Idealism: Specialist)?
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

16. Mana, as built (each can change):
    - A Wizard's skills are still a list, so all tier 1: ranking Mana up does nothing for it until its tree exists. Fine?
    - Only the starter spells are "basic spells". Hex stays 2 Energy flat (half AP paid with Mana), and Darkstone 3. Right?
    - Starting Wizards get 10 Mana (Icor, level 5, has 12). Right amount?
    - With Working Knowledge, Energy would get Mana's half cost too, but only for a unit that also has the Mana passive. Adventurers can't learn it, so this doesn't come up yet. Right?

## Warlock

Devoted to a patron: **Elmon** or **Hogel**. Main stat: cha. The tree has a tab per patron. Every tab shares a static tier 1 row, already unlocked, with Hex and Sweet Nothings. From tier 2 on, each tab is its patron's path. (?17)

- [ ] **Haluca** (earth spell; `Skills/haluca.tres`): built but on no tree, until the Warlock has one. A foe within cha mod + rank tiles saves (d20 + wis mod beating d20 + the caster's cha mod + rank) or sees everyone's tags scrambled for cha mod + rank turns (the `scrambled` stat; `Perception.scramble()`: as many tags, drawn from the persona tag list, the same each look). Allies whose tags it sees scrambled count as suspicious to it, so its looks take them in; investigating one, against the caster's roll, sets that one straight (`Battle.untangled`, logged "X sees through Haluca --> Y (a - b)"). (?17)

Starting skills
- [ ] **Hex I.**
- [ ] **Chant** (tier 1 passive): not designed yet. (?17)
- [ ] **Sweet Nothings** (tier 1 passive): an interesting resource that's hard to recover. The two main ways back are slaying an enemy unit, and using patron skills and passives to satisfy a patron. (?17)

**Elmon**
- [ ] **Analysis Dialysis** (tier 2 passive): unmasking an enemy unit that was pretending to be friendly or neutral gives 2 Sweet Nothings × rank. Removing a level of concealment from a hidden foe gives 1 × rank. (?17)
- [ ] **wauaw** (tier 2 active): puts an effect on a unit within rank tiles for 3 + 2 × rank turns. The unit gets a mitigation penalty and a general damage buff, both in 10% steps by how much of the effect is left. They're weakest at the start and end (10%) and strongest in the middle: at rank I (5 turns), 10, 20, 30, 20, 10%. (?17)

**Hogel.** Stubbed: not designed yet.

17. Warlock:
    - Chant's text stops at "Waiting with". How does it end?
    - Sweet Nothings: a reserve like Mana, paying for Warlock skills? How big, does it start full, and does anything else bring it back (resting, a new battle)?
    - What satisfies each patron, beyond Analysis Dialysis for Elmon?
    - Can a Warlock learn from both patrons' tabs, or does its first tier 2 skill devote it to one? Is Chant on the shared tier 1 row too?
    - Analysis Dialysis: does "unmasks" mean seeing through a unit's ally disguise (perception rank 2), by any means, or only by this unit's own actions? Units can only pretend to be allies now: does pretending to be neutral need adding?
    - wauaw: allies, foes or both? Does it roll on a foe? Can the mitigation penalty take a unit below 0 (taking extra damage)? Is the lowercase name on purpose?
    - Does Hex use cha for a Warlock (it's a wis skill)?
    - Haluca: which patron's tab is it on? Should a target that passes its save grow suspicious of the caster?

## Rogue and Bard

- [ ] **Rogue**: will get more tricks. Sprite is a placeholder (Elman).
- [ ] **Bard**: will get songs. Sprite is a placeholder (Doebour).

19. Rogue and Bard, as built:
    - Each Freedom tab is the class's own copy, so the Bard's has no Snare. Should Calling: Freedom instead be one tree both classes share?
    - Performance (Tonefoolery, Glamour, Manifest) is tagged specialist, so it moved to the Bard's Freedom tab, leaving its own tab with Song. Or is Performance the Bard's own?
    - Hide and Clever Disguise are still each Freedom tab's centre (tier 1). Keep them there?

## Paladin

Three roots in the class tab, each starting with an active skill: **Divinity** (one so far: Eros), **Idealism** (one so far: Chivalry) and **Prowess** (default: Protector; see Fighter).

**Divinity: Eros.** Spells are tagged `divine`, `cha`, `<3`. Divinity is in the caster family. (?12)
- [ ] **Divinity tree**, with Renew in it. *Now:* Renew is a Paladin option.
- [ ] **Rejuvinate** (root · active · 3 AP · 5 Energy · range: rank): regeneration for 3 turns of (10% + 5% × rank) of the recipient's max HP, + the caster's cha mod. Strength decays 5% per tile beyond 1 from the caster, with no decay when paid entirely with mana. *Now:* a stub on the Adventurer's core ring. (?12)
  - [ ] **Send Off** (active): teleport an adjacent unit cha mod + rank tiles away. (?12)
  - [ ] **Lovely Caster** (passive): `<3` skills used on an adjacent ally also heal it 10% × rank of its max HP.
  - [ ] **Impassioned Fighter** (passive): +rank to a skill's primary mod when targeting an adjacent unit.

**Idealism: Chivalry**
- [ ] **Coordinate** (root · active · 1 AP · 3 Energy): teammates within cha mod tiles share recon on the area's tiles and units, up to rank levels. (?4)
  - [ ] **Final Act** (passive): once per battle, on reaching 0 HP, interrupt the current turn to take 1 free action; the interrupted turn then resumes. (?12)
  - [ ] **Gallantry** (passive): cha check against a unit attacking an adjacent ally. On a pass you become its target, and that ally can't be retargeted.

**Prowess: Protector.** See Fighter.

4. Coordinate shares recon between teammates. With vision through the leader only, does it also let you see what those teammates see, or only improve what they know?
12. Paladin: is "Rejuvinate" spelled on purpose? Is its distance decay fixed when cast? Send Off: who picks the landing tile, and does it work on enemies? Final Act: does the unit die after its free action? `<3` as a tag ID, or an internal `love` tag shown as <3?

## Fighter

Three roots, each a flavour of Prowess of the player's choosing. Three exist so far.

**Protector:** defense of self and others.
- [ ] **Shields Up!** (active · 3 AP): point the unit at the center of an unobstructed tile, occupied or not (default: the nearest enemy). Damage from a source whose tile center lies within the 90° cone around that direction is reduced by 20% + 10% × rank. Lasts until its next turn.
- [ ] **Obstruct** (passive): enemies moving through tiles next to this unit pay the larger of half its size penalty and half its con mod / 10, +25% per rank. Allies pass freely.
- [ ] **Interject** (passive, `defensive`): when an ally is hit, dex check; on a pass you become the target. −25% damage per rank when taking a hit that wasn't aimed at you, with no rank cap (past 100% it still blocks only 100%). Rank 5+: +25% × rank to Defense when taking hits for allies. (?13)
- [ ] **Interdict** (active): str check against an adjacent unit. On success: Attack Down (20% × rank) and −str mod AP recovery for one turn.
- [ ] **Turtle Tactics** (passive): +2 × rank to the unit's `defensive` checks, −rank to its `offensive` checks.
- [ ] **Snapping Turtle** (passive): when the unit uses an `offensive` skill, it also triggers up to rank of its `defensive` passives, top to bottom.

**Vanguard:** front-line offense and tactics.
- [ ] **Warcry** (active): pick up to rank enemies the unit can see. Rank tiles on the line to each get a one-use effect, triggered on entry, lasting a few turns:
  - Nearer half, **Charge!** (expanding translucent hot-orange squares): allies regain rank dex AP and deal +10% × rank damage until their turn ends.
  - Farther half, **Routed!** (collapsing translucent dark-blue squares): enemies pay +rank movement.
- [ ] **Inspire** (passive): hitting an adjacent enemy with a skill gives allies within rank tiles +rank damage. Allies whose luck is below 1 also get **+1 Luck ltd.** (?13)

**Slayer:** eliminating chosen targets.
- [ ] **Jugular** (active): an attack at disadvantage, +(rank − 1) to the roll; a hit is a critical. When an attack would crit anyway (a natural 20, 1 in 20, or other skills), recast it at once, free and without limit for now.
- [ ] **Sundering** (passive): an attack rolling higher than the target's dex mod applies stacking **Sundered**: −1 Defense for rank turns. (?13)
- [ ] **Silent Strike** (active): disables rank of the target's `magical` skills, actives and passives, for rank turns, starting from the bottom of its hotbar. Disabled skills are greyed out. (?13)
- [ ] **Gank** (hybrid): not designed yet.

13. Fighter:
    - Interject: who can it trigger for (adjacent allies? any ally in sight?), and how often (once a round? every hit)?
    - Sundering: "an attack rolling higher than the target's dex mod". Its Defense instead, now that attacks roll against Defense?
    - Silent Strike: do `divine` spells count as `magical`?
    - Inspire: does "+1 Luck ltd." mean it can only raise luck as far as 1?
