# Gambeson todo

`[ ]` to do · `[x]` done · `(?N)` waits on open question N · *Now:* what the game does today

## Design rules (decided)

Every skill follows these, so skill descriptions don't repeat them. Move to `design.md` once stable.

- **Costs and numbers.** Where a skill's AP, cost, duration, tags or other numbers aren't given, pick sensible ones. Every one of them stays exposed in the editor for tuning later.
- **Luck rounds up.** Divisions in formulas (level / 2, level / 4, (con mod + wis mod) / 2) round down, or up for a unit with positive luck.
- **Damage floor.** Nothing on the attacker's side (mods, debuffs) can bring an attack below 1 damage: if it hits, it does damage. (?1)
- **Range.** Every skill aimed at another unit has a range: the skill's own, plus the caster's reach and both units' sizes. A small unit may have to walk a little further to bring another small unit into range. A skill cast on others can always reach an adjacent unit. Past adjacent, a skill may put a % penalty on its roll instead of a hard limit; how much is up to the skill.
- **Attack rolls.** Most `offensive` skills roll d20 + an attack mod against the target's Defense; meeting it hits. A skill whose nature calls for something else checks that instead (a Siren's charm: cha against wis). (?5)
  - The attack mod is the skill's stat, from its stat tag (Strike: str; Hex: wis).
  - Weapons can let strength attacks use another stat: dex for bows, daggers and rapiers; a spellcasting stat for enchanted weapons. The unit uses whichever is best.
  - A natural 20 hits and doubles the damage.
  - A miss does nothing to the target. The target still loses a level of concealment, since it was aimed at; the attacker loses one only on a hit.
  - Skills, passives and equipment can change any of this.
- **Defense** (AC means the same thing) is set by armor, then raised or lowered by skills and equipment (Mage Armor, Sundered).
  - Bonuses can be untagged, counting against everything, or tagged: `physical`, `magical`, `blunt`, `fire`, `dark`, `whimsical`…
  - Tagged Defense counts against attacks carrying that tag or a child of it: `physical` covers `slash`, `pierce` and `blunt`.
  - Unarmored: dex mod + con mod. Poor, often worse than nothing, for most low-level units.
  - **Gambeson** (the game's namesake, and the most common armor): the higher of 10 and level / 2, + dex mod.
  - **Plate**: the higher of 20 and level.
  - **Robe** (`cloth`): the higher of 8 and level / 4.
  - Plate and Robe don't add dex mod, unless passives or skills say so.
- **Mitigation** is separate from Defense: a % cut to damage taken, tagged the same way. It can add up past 100%, but blocks at most 100%; later mitigation-reducing effects can eat into the overage.
- **Checks.** Each skill sets its own check: a contest of the same stat (a Siren dragging a unit into water: str against str) or one stat against another (a Siren's charm: its cha against the target's wis). `defensive` checks are the ones a unit makes to avoid or lessen harm, and they trigger its `defensive` passives. `offensive` checks are the ones it makes to act on others.
- **Checks first.** If a skill's check passes, it almost always does *something*, even when its stat would otherwise give nothing or worse.
- **Skill slots.** A unit has **4 + level / 4** slots: 4 at levels 1–3, 5 at 4–7, and so on. Slots are the definitive limit on what it can equip, actives and passives alike. Passives take the last slots, keeping the low number keys free for actives. Slots are meant to be scarce: by mid to late game, players choose which of a unit's learned skills suit its build.
- **Clover slot.** When luck rounds level / 4 up, the extra slot is a **clover slot**, clover green (a different shade from Specialist slots). (?6)
  - It works only while the unit is lucky. If its luck drops, the slot greys out, keeping its skill.
  - If a level makes the rounding exact, it becomes a plain slot.
- **Losing a slot.** When a unit loses a slot (a slot-granting skill removed, a slot debuff), the most recently equipped skill drops. Its slot deactivates and dims, and the skill stays there. If the slot comes back, the skill works again. (?7)
- **Hotbar order.** The hotbar is a vertical list; a horizontal layout may come later as an option. Skills that work through another unit's skills in order read its hotbar top to bottom (Snapping Turtle) or bottom to top (Silent Strike).
- **Typed slots.** Martial, Magic and Specialist slots only hold skills from a tree with that tag (`martial`, `magical`, `specialist`; skills on a tree's root carry its tag). In the hotbar they're dull red, purple and green. Slots granted by skills sit after a unit's sure slots and before its clover slot.
- **Learning.** Skills are learned with skill points, quest rewards and the like. A learned skill shows in the spellbook and equips itself when a slot is free (Settings toggle, on by default).
- **Ranks.** No rank cap. Unlocking a skill costs 1 point; raising it from rank r to r + 1 costs **1 + r²**: II costs 2, III 5, IV 10, V 17.
- **Tiers.** A skill's tier is 1 plus how many skills must be learned before it's reached: the skills it comes after, and theirs in turn, or the count a capstone needs. A tree's centre and core, the first skill of each root, and a class's listed options are tier 1.
- **Resource bonuses** are whatever a resource gives a skill paid with it (Hex: half AP paid with Mana).
- **Mana.** Basic spells (the starter spells) cost 2 Energy × rank. Mana is twice as efficient for them: half cost, for a unit whose **Mana** passive's rank reaches the spell's tier. Mages and Wizards start with Mana I.
- **Energy recovery.** Every unit gets energy back as its side's turn ends.
  - Resting (it neither moved nor spent AP): (con mod + wis mod) / 2 a turn, at least 1.
  - Below 0, a point every (1 − that) turns rested instead: at −2, one every 3 turns.
  - Light activity (it spent only dex-move or wis-skill AP): half as fast.
  - Anything more: none, so units that lean on their skills run dry over a battle.
  - The Adventurer's starting passives give its Energy the resource bonuses of each category's resources (see Adventurer).
- **Vision.** You see what your leader sees. **Synergy** works between a party leader and a party member in command range: while the member is selected to take orders, you see what it sees. If the member has Synergy, it works whenever the leader orders that member; if the leader has it, it works for all of its party members. Your own units always show.
- **No static hints.** Nothing like "Click a tile…" or the key legend sits on screen. Dynamic information stays: tooltips (after 1 s), the tile pane, move and damage forecasts, and status lines ("Waiting for Nemes"). How to play is in the **Guide** under Settings.

## Open questions

Rules and systems
1. Attacker-side effects can't take an attack below 1. Can the *defender's* mitigation still reduce it to 0? Earlier wording was "at least 1 damage if they hit and aren't mitigated".
2. Are the stat caps (con mod martial, int mod magic, cha mod specialist) gone now that typed slots exist? If so, Trade Skills and Grind need new definitions, since both modify those caps.
3. The Adventurer's extra slot "sits at the center, locked until current slots are filled". Center of the hotbar (its middle slot) or of the radial tree? Does it unlock once every slot holds a skill?
4. Coordinate shares recon between teammates. With vision through the leader only, does it also let you see what those teammates see, or only improve what they know?
5. Attack rolls, as built (each can change):
    - A natural 20 hits even when the total is short of Defense. Right?
    - A natural 1 has no special effect. Should it always miss?
    - Multi-hit skills (Strike III) roll once for all their hits. Or once per hit?
    - Hostile skills without damage roll too, and their effects land only on a hit (Hex's luck penalty). Is that right for Silent Strike-style skills too?
6. Rounding 1/4 up means a lucky unit has a clover fifth slot from level 1 (at levels 1–3: 5 slots). Intended? And is the clover slot untyped, like a base slot?
7. Your slot-loss answer stopped mid-sentence: "If it 'reactivates' for any reason (level down / slot debuff ends etc.)". I took it as: the skill in it works again. Right? And is "level down" a real thing, or did you mean regaining a level?
8. Lore keeper: skill data (numbers) + optional flavour text + small behaviour scripts for one-off mechanics. Is that the "hybrid" you mean?
9. Equipment: where do items come from (loot, shops, quests), and is the character sheet (the dock's character icon) where they're equipped? Until then, should anyone in the museum start armored (say, the player's unit in a Gambeson)? Nobody does now.

Content
10. Adventurer: is Mage (Red Mage) a class separate from Wizard? The Wizard uses the Red Mage sprite, and has the Mana passive. Do Igna and Aetha grant AP immediately, or for rank turns? Sola's +1 persona does nothing on a unit with no disguise set up: intended? The Magic root now has 7 branches against "about 6": fine? Which slot type does each tree's capstone give (Divinity: Magic, Prowess: Martial, Idealism: Specialist)?
11. Trade Skills and Grind formulas, once 2 is settled. As written, (base + wis × rank) / rank works out to base / rank + wis.
12. Paladin: is "Rejuvinate" spelled on purpose? Is its distance decay fixed when cast? Send Off: who picks the landing tile, and does it work on enemies? Final Act: does the unit die after its free action? `<3` as a tag ID, or an internal `love` tag shown as <3?
13. Fighter:
    - Interject: who can it trigger for (adjacent allies? any ally in sight?), and how often (once a round? every hit)?
    - Sundering: "an attack rolling higher than the target's dex mod". Its Defense instead, now that attacks roll against Defense?
    - Silent Strike: do `divine` spells count as `magical`?
    - Inspire: does "+1 Luck ltd." mean it can only raise luck as far as 1?
14. Siren:
    - Drown's text stops at "this is a movement skill, if…". How does it end?
    - Does "2+: Rank −1 mitigation to tile roll penalty" mean each rank past 1 takes 1 off the per-tile penalty?
    - What does a charm that lands do to the target? (Beating it is settled.)
15. Adventurer, as built (each can change):
    - Capstones need 3 of their root's skills learned (tier 4). The Martial root has only Wary so far, so its capstone can't be reached yet. Is 3 right, or should a capstone come after particular skills?
    - The starting passives and the capstones stop at rank I, since ranks would do nothing for them. Fine?
16. Mana, as built (each can change):
    - A Wizard's skills are still a list, so all tier 1: ranking Mana up does nothing for it until its tree exists. Fine?
    - Only the starter spells are "basic spells". Hex stays 2 Energy flat (half AP paid with Mana), and Darkstone 3. Right?
    - Starting Wizards get 10 Mana (Icor, level 5, has 12). Right amount?
    - With Working Knowledge, Energy would get Mana's half cost too, but only for a unit that also has the Mana passive. Adventurers can't learn it, so this doesn't come up yet. Right?
17. Warlock:
    - Chant's text stops at "Waiting with". How does it end?
    - Sweet Nothings: a reserve like Mana, paying for Warlock skills? How big, does it start full, and does anything else bring it back (resting, a new battle)?
    - What satisfies each patron, beyond Analysis Dialysis for Elmon?
    - Can a Warlock learn from both patrons' tabs, or does its first tier 2 skill devote it to one? Is Chant on the shared tier 1 row too?
    - Analysis Dialysis: does "unmasks" mean seeing through a unit's ally disguise (perception rank 2), by any means, or only by this unit's own actions? Units can only pretend to be allies now: does pretending to be neutral need adding?
    - wauaw: allies, foes or both? Does it roll on a foe? Can the mitigation penalty take a unit below 0 (taking extra damage)? Is the lowercase name on purpose?
    - Does Hex use cha for a Warlock (it's a wis skill)?

## Systems

Build roughly in this order; the content below depends on them.

- [x] **Attack rolls.** d20 + attack mod against Defense for the skill's tags; a natural 20 hits and doubles damage; at least 1 damage before mitigation. The forecast shows the chance to hit when the player can identify the target, and the log shows each roll. A skill's `rolls` switch (in the editor) turns its roll off. (?5)
- [ ] **Checks and contests.** Skill-defined checks with `offensive` / `defensive` tags, advantage/disadvantage, per-skill range penalties. Needed by Jugular, Interject, Interdict, Gallantry, Turtle Tactics, Snapping Turtle, the Siren.
- [x] **Defense.** Armor sets it; `defense` effects add to it, untagged or tagged, with child tags counting (`physical` covers `pierce`). The unit card shows it ("11 · Gambeson", plus any tagged extras). Still to come: Terestera, Hydera, Sundered, and Attack Down (Interdict) on the attacker's side.
- [ ] **Equipment.** Two slots per unit for now: **armor** and **weapon**. Armor sets Defense; a weapon can change the attack mod and carry effects of its own (Burning Blade). *Now:* both slots exist and are set in the editor (Unit → Equipment). The items are Gambeson, Plate, Robe and a Rapier (dex for strength attacks). There's no way to equip them in play, and no item effects yet. (?9)
- [x] **Skill trees and ranks.** Roots (`SkillRoot`) of branches (`Branch`: the skills a branch comes after, or a count of its root's skills for capstones), a class's centre and core, and stubs for skills waiting on a question. Ranking up costs 1 + r², from the skills screen; a skill's `max_rank` can cap it. Tiers (`Role.tier()`) show on the skills screen. *Now:* only the Adventurer has a tree; other classes list their options, which can be ranked up too.
- [ ] **Tabbed skill trees**: a tab per path, sharing a static tier 1 row (Warlock: a tab per patron). (?17)
- [ ] **Equipping.** Learned vs equipped; slots shared by actives and passives, passives filling from the bottom of the hotbar; auto-equip (on by default); losing slots. (?7) *Now:* the hotbar has 4 + level / 4 slots, then slots skills grant (typed slots built: `slots` effects), then the clover slot. Only actives and switched passives go on it, and every learned passive works.
- [ ] **Disabled skills.** Skills switched off for a number of turns, greyed out in the hotbar (Silent Strike).
- [ ] **Vision through the leader, plus Synergy.** *Now:* you see the clearest view any of your units has.
- [x] **Energy recovery.** Rest, light activity and busy turns, as in the rule. A float shows what's regained.
- [ ] **Skill categories and resources.** `martial` / `magical` / `specialist` tags on skills and trees; new resources (Stamina, Rage, Focus, Sweet Nothings, Power, Hype, Clout, Gold). *Now:* the category tags are on Strike and Wary (martial), the Magic spells and Hex (magical), and Snare, Hazard Expert and Darkvision (specialist). Only Mana exists, so Field Experience and Everyman have nothing to work with yet. Skills can be cheaper paid with a reserve (`cost_with`), once a passive opens that reserve up to their tier (`opens`: Mana). Classes can start with reserves (Wizard: 10 Mana).
- [ ] **Reactions and interrupts.** Units acting outside their turn: Interject, Gallantry, Final Act. *Now:* only the side whose turn it is acts.
- [ ] **Facing and direction**, for Shields Up!.
- [ ] **Effect strength set when cast**, for Rejuvinate's distance decay. *Now:* a timed effect's strength is fixed.
- [x] **Dual-target skills**: buff allies, hurt enemies (starter spells). A skill's `dual` switch: allies get its effects, foes its damage, after an attack roll.
- [ ] **One-use tile effects laid by skills**, triggered on entry (Warcry). *Now:* only traps and zones.
- [ ] **Teleport**, for Send Off.
- [ ] **Forced movement and submerging**, for the Siren's Drown.
- [ ] **Suspicion**: stacks one unit builds on another by beating its deception (a Siren's charm). While a unit has them, the other's false trickery and persona don't show to it.
- [ ] **Unbounded maps, camera control, spawning mid-battle**, for Infernal Meadows.

## UI and styling

- [x] Faction look on the map: a faint glow of the side's primary colour replaces the outline. HP, then 2px each of the main reserve and Energy, sit in one block with a darkened faction trim.
- [x] Tooltips over icons after 1 s.
- [x] Settings (cog) with the **Guide**: the instructions from the old hint line and key legend. The hint line now only shows status and notes.
- [ ] Settings › Gameplay toggles, starting with auto-equip, once Equipping exists.
- [x] Typed hotbar slots: dull red / purple / green, tinted and trimmed like the clover slot; an empty one says what it holds ("magic only").
- [ ] The Adventurer's extra slot is a base slot, slightly darker. (?3)
- [ ] When targeting, if a unit is just out of range from the caster's current tile, show small circles for both units' sizes so the gap is visible. *Now:* a near miss is decided by luck, with no explanation.
- [x] Skills screen as trees, radial for the Adventurer: a wheel with Skill Slot +1 at the centre, a core ring (starting skills, Hex, the slot skills), and the three roots in their slot colours. Learned skills are filled and ranked, learnable ones ringed (gold while there's a point), stubs dashed with their question number. Clicking a skill shows it beside the wheel, with Unlock or Rank up. *Now:* other classes still get lists, until their trees exist.
- [x] Entry screen defaults: name **Shrike** (muted in the empty name box, used until something else is typed), faction **Lancin**, class **Adventurer**. Enter starts the demo at once.
- [ ] Lore keeper: one reference per skill, and its hover description is what the skill is built from. (?8)

## Scenes

- [ ] **Infernal Meadows**: an overworld or challenge area for now. An endless plane of grass (grass is the default empty tile); demons spawn out of view over time, just Sirens for now. Once 30 enemies are slain, an escape portal opens, and a unit stepping onto it wins the battle at once.

## Classes

Every tree's capstone, for now (later a mid-tree capstone), is a **Basic Martial / Magic / Specialist Skill Slot +1**. (?10)

### Adventurer

Three roots, **Magic**, **Martial** and **Specialist**, with flat, radial trees: most paths are a few nodes long, and each root branches into about 6 strong applications of the basics. Paths are shallow slices of other classes' trees, but Adventurers can learn core skills many classes share: **Hex** and **Rejuvinate** are a first choice at any time.

*Now:* the tree is built (`Roles/adventurer.tres`; the skills screen draws it as a wheel). Skills that wait on a question are stubs: on the wheel with their question number, but they can't be learned.

Starting skills, unlocked from the start. They're separate skills on purpose, since each takes a slot. Once Adventurers have skills that use them, these three can become mid-tier passives in the tree instead.
- [x] **Field Experience** (passive): resource bonuses (Stamina, Rage, Focus…) apply when paying Energy for martial skills. *Now:* no martial resource exists yet, so it does nothing.
- [x] **Working Knowledge** (passive): resource bonuses (Mana, Sweet Nothings, Power…) apply when paying Energy for magic skills. *Now:* Hex costs half AP paid with Energy, as with Mana.
- [x] **Everyman** (passive): resource bonuses (Hype, Clout, Gold…) apply when paying Energy for specialist skills. *Now:* no specialist resource exists yet.

Core: **Hex** (built) and **Rejuvinate** (stub, ?12; see Paladin).

Slot skills
- [ ] **Skill Slot +1** (unspecified type): acts like a base slot, slightly darker. Sits at the center, locked until current slots are filled. *Now:* a stub at the centre of the wheel. (?3)
- [ ] **Trade Skills** (passive): skill limits scale partly with wis: (base stat + wis × rank) / rank. *Now:* a stub on the core ring. (?2 ?11)
- [ ] **Grind** (passive): str mod can count toward martial limits; max HP drops by the % overage. *Now:* a stub on the core ring. (?2 ?11)
  - Rank 2+: bonus slots, each −10 × (rank − 1)% max HP while in use.
  - Rank 11+: bonus slots also cut max energy the same way.
- [ ] If a skill that grants slots is removed, its slots are lost as the Losing a slot rule says. (?7) *Now:* skills can't be removed.

**Magic root.** Starter spells, also Wizard options (?10). On an ally: the listed effect. On an enemy: an attack roll (d20 + int mod), then 1d4 + int mod damage. Range: int mod, reaching an adjacent unit at least. Each is 3 AP and 2 Energy × rank; Mana pays half, for a unit with the Mana passive (Adventurers don't have it).
- [x] **Sola** (light): ally +1 persona rank for rank turns. (?10: it does nothing on a unit with no disguise set up.)
- [x] **Nadira** (dark): ally +1 `dark` concealment rank for rank turns.
- [x] **Astera** (magic): ally +1 luck for rank turns.
- [ ] **Igna** (fire): ally gains int mod + rank skill AP. *Now:* a stub. (?10)
- [ ] **Aetha** (wind): ally gains int mod + rank movement AP. *Now:* a stub. (?10)
- [x] **Terestera** (earth): ally gains rank `physical` Defense, for 3 turns.
- [x] **Hydera** (water): ally gains rank `magical` Defense, for 3 turns.
- [x] Capstone: **Basic Magic Skill Slot +1**, after 3 Magic skills. (?15)

**Martial root.** Not designed yet. *Now:* Wary, then the capstone, **Basic Martial Skill Slot +1** (built; needs 3 Martial skills, so it can't be reached yet). (?15)

**Specialist root.** Not designed yet. *Now:* Snare, then Hazard Expert; Darkvision; then the capstone, **Basic Specialist Skill Slot +1** (built; needs 3 Specialist skills). (?15)

### Wizard / Mage

- [x] **Mana** (tier 1 passive; Mages and Wizards start with it at rank I): the starter spells cost half paid with Mana, up to its rank in tier. *Now:* a Wizard option and starting skill. Wizards start with 10 Mana. (?16)
- [x] **Mage Armor** (passive, `magical`, switched on and off; early in the tree): + int mod to Defense while on. *Now:* a Wizard option, unlocked with a skill point. (?10)
- [x] The Adventurer's starter spells (Sola, Nadira, Astera, Terestera, Hydera) are Wizard options too. (?10)

### Warlock

Devoted to a patron: **Elmon** or **Hogel**. Main stat: cha.

The tree has a tab per patron. Every tab shares a static tier 1 row, already unlocked, with Hex and Sweet Nothings. From tier 2 on, each tab is its patron's path. (?17)

Starting skills
- [ ] **Hex I.**
- [ ] **Chant** (tier 1 passive): not designed yet. (?17)
- [ ] **Sweet Nothings** (tier 1 passive): an interesting resource that's hard to recover. The two main ways back are slaying an enemy unit, and using patron skills and passives to satisfy a patron. (?17)

**Elmon**
- [ ] **Analysis Dialysis** (tier 2 passive): unmasking an enemy unit that was pretending to be friendly or neutral gives 2 Sweet Nothings × rank. Removing a level of concealment from a hidden foe gives 1 × rank. (?17)
- [ ] **wauaw** (tier 2 active): puts an effect on a unit within rank tiles for 3 + 2 × rank turns. The unit gets a mitigation penalty and a general damage buff, both in 10% steps by how much of the effect is left. They're weakest at the start and end (10%) and strongest in the middle: at rank I (5 turns), 10, 20, 30, 20, 10%. (?17)

**Hogel.** Stubbed: not designed yet.

### Paladin

Three roots in the class tab, each starting with an active skill: **Divinity** (one so far: Eros), **Idealism** (one so far: Chivalry) and **Prowess** (default: Protector; see Fighter).

**Divinity: Eros.** Spells are tagged `divine`, `cha`, `<3`. (?12)
- [ ] **Rejuvinate** (root · active · 3 AP · 5 Energy · range: rank): regeneration for 3 turns of (10% + 5% × rank) of the recipient's max HP, + the caster's cha mod. Strength decays 5% per tile beyond 1 from the caster, with no decay when paid entirely with mana. *Now:* a stub on the Adventurer's core ring. (?12)
  - [ ] **Send Off** (active): teleport an adjacent unit cha mod + rank tiles away. (?12)
  - [ ] **Lovely Caster** (passive): `<3` skills used on an adjacent ally also heal it 10% × rank of its max HP.
  - [ ] **Impassioned Fighter** (passive): +rank to a skill's primary mod when targeting an adjacent unit.

**Idealism: Chivalry**
- [ ] **Coordinate** (root · active · 1 AP · 3 Energy): teammates within cha mod tiles share recon on the area's tiles and units, up to rank levels. (?4)
  - [ ] **Final Act** (passive): once per battle, on reaching 0 HP, interrupt the current turn to take 1 free action; the interrupted turn then resumes. (?12)
  - [ ] **Gallantry** (passive): cha check against a unit attacking an adjacent ally. On a pass you become its target, and that ally can't be retargeted.

**Prowess: Protector.** See Fighter.

### Fighter

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
- [ ] **Gank** (hybrid): 

## Items

Armor (see the Defense rule)
- [x] **Gambeson**: Defense the higher of 10 and level / 2, + dex mod.
- [x] **Plate**: Defense the higher of 20 and level.
- [x] **Robe** (`cloth`): Defense the higher of 8 and level / 4.

Weapons
- [x] **Rapier**: strength attacks may use dex instead.
- [ ] **Burning Blade** (enchanted): attacks use the highest of cha, wis or int. The wielder adds its str mod to max HP, even if negative. Needs item effects and a max HP effect. (?9)

## Monsters

### Siren

- [ ] **Persona names.** A persona that claims an identity (rank 3) goes by a random fake name instead of "Something": an adjective from its persona's pool and a general noun from its noun pool ("Beautiful Beauty", "Radiant Lady", "Serene Songstress"). Later, adjectives can carry effects and nouns their own sprites. For now, each noun shows a text stand-in for its sprite (":D", ";)", ":3").

### Siren Skills
- [ ] **Drown**: a grapple, str contest against a unit. On a win, the Siren drags it to the nearest water tile, submerging both of them. Water must be within the Siren's movement range: it can't drag a unit past where it could move itself. −1 to its roll for every tile it must travel to the water. (?14)
  - Rank 2+: rank − 1 off that per-tile penalty. (?14)
- [ ] **Claw**: its attack when no water is in range for the target.
- [ ] **Charm**: the Siren's cha check against the target's wis check. A target that beats it gets a standard investigation pass: suspicion stacks on the Siren, and while it has them, the Siren's false trickery and persona information don't show to that unit. (?14)
