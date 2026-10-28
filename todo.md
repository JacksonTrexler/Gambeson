# Gambeson todo

`[ ]` to do · `(?N)` waits on open question N · *Now:* what the game does today

## Design rules (decided)

Every skill follows these, so skill descriptions don't repeat them. Move to `design.md` once stable.

- **Damage floor.** Nothing on the attacker's side (mods, debuffs) can bring an attack below 1 damage: if it hits, it does damage. (?1)
- **Range.** Every skill aimed at another unit has a range: the skill's own, plus the caster's reach and both units' sizes. A small unit may have to walk a little further to bring another small unit into range. A skill cast on others can always reach an adjacent unit. Past adjacent, a skill may put a % penalty on its roll instead of a hard limit; how much is up to the skill.
- **Attack rolls.** A damaging attack rolls d20 + an attack mod against the target's Defense. Martial attacks usually add str mod. Weapons can change the attack mod: dex for bows, daggers and rapiers; a spellcasting mod for enchanted weapons. A natural 20 doubles the damage. Skills, passives and equipment can change any of this.
- **Defense.** Set by the unit's armor, then raised or lowered by skills (Mage Armor, Sundered). (?5)
  - Unarmored: dex mod + con mod. Poor, often worse than nothing, for most low-level units.
  - **Gambeson** (the game's namesake, and the most common armor): the higher of 10 and level / 2, + dex mod.
  - **Plate**: the higher of 20 and level.
  - **Robe** (`cloth`): the higher of 8 and level / 4.
- **Checks.** Each skill sets its own check: a contest of the same stat (a Siren dragging a unit into water: str against str) or one stat against another (a Siren's charm: its cha against the target's wis). `defensive` checks are the ones a unit makes to avoid or lessen harm, and they trigger its `defensive` passives. `offensive` checks are the ones it makes to act on others.
- **Checks first.** If a skill's check passes, it almost always does *something*, even when its stat would otherwise give nothing or worse.
- **Skill slots.** A unit has **4 + floor(level / 4)** slots: 4 at levels 1–3, 5 at 4–7, and so on. Slots are the definitive limit on what it can equip, actives and passives alike. Passives take the last slots, keeping the low number keys free for actives. Slots are meant to be scarce: by mid to late game, players choose which of a unit's learned skills suit its build.
- **Hotbar order.** The hotbar is a vertical list; a horizontal layout may come later as an option. Skills that work through another unit's skills in order read its hotbar top to bottom (Snapping Turtle) or bottom to top (Silent Strike).
- **Typed slots.** Martial, Magic and Specialist slots only hold skills from a tree with that tag. In the hotbar they're dull red, purple and green.
- **Learning.** Skills are learned with skill points, quest rewards and the like. A learned skill shows in the spellbook and equips itself when a slot is free (Settings toggle, on by default).
- **Ranks.** No rank cap. Unlocking a skill costs 1 point; raising it from rank r to r + 1 costs **1 + r²**: II costs 2, III 5, IV 10, V 17. (?7)
- **Vision.** You see what your leader sees. **Synergy** works between a party leader and a party member in command range: while the member is selected to take orders, you see what it sees. If the member has Synergy, it works whenever the leader orders that member; if the leader has it, it works for all of its party members. Your own units always show.
- **No static hints.** Nothing like "Click a tile…" or the key legend sits on screen. Dynamic information stays: tooltips (after 1 s), the tile pane, move and damage forecasts. Instructions move to a **Guide** under Settings.

## Open questions

Rules and systems
1. Attacker-side effects can't take an attack below 1. Can the *defender's* mitigation still reduce it to 0? Earlier wording was "at least 1 damage if they hit and aren't mitigated".
2. Are the stat caps (con mod martial, int mod magic, cha mod specialist) gone now that typed slots exist? If so, Trade Skills and Grind need new definitions, since both modify those caps.
3. The Adventurer's extra slot "sits at the center, locked until current slots are filled". Center of the hotbar (its middle slot) or of the radial tree? Does it unlock once every slot holds a skill?
4. Coordinate shares recon between teammates. With vision through the leader only, does it also let you see what those teammates see, or only improve what they know?
5. Defense details:
    - Is Sundering's AC the same thing as Defense?
    - Terestera and Hydera grant "physical" and "magical" Defense. Is Defense split in two, or are they bonuses to the one Defense against those damage types?
    - Does today's mitigation (damage reduction by %, as in Stoneskin) stay a separate stat?
    - Do Plate and Robe add dex mod, as Gambeson does? Do level / 2 and level / 4 round down?
6. Energy recovery: every unit, or Adventurers only? How much is "sluggish"? What if (con mod + wis mod) / 2 is negative?
7. Rank cost: is r the skill's current rank (II costs 2, III costs 5)?
8. When a slot-granting skill is removed, which equipped skills drop: the player's choice, or the most recent?
9. Infernal Meadows: what wins or loses the battle while demons keep spawning? Spawn rate and cap? Does "out of view" mean off-camera or outside your units' perception? Which faction are demons, and do they join initiative mid-battle? How does the camera move? Does Enter start the meadows or the museum?
10. Lore keeper: skill data (numbers) + optional flavour text + small behaviour scripts for one-off mechanics. Is that the "hybrid" you mean?
11. Equipment: where do items come from (loot, shops, quests), and is the character sheet (the dock's character icon) where they're equipped?

Content
12. Adventurer: is Mage a class separate from Wizard? Do Igna and Aetha grant AP immediately, or for rank turns? Sola's +1 persona does nothing on a unit with no disguise set up: intended? The Magic root now has 7 branches against "about 6": fine? Which slot type does each tree's capstone give (Divinity: Magic, Prowess: Martial, Idealism: Specialist)?
13. Trade Skills and Grind formulas, once 2 is settled. As written, (base + wis × rank) / rank works out to base / rank + wis.
14. Paladin: is "Rejuvinate" spelled on purpose? Is its distance decay fixed when cast? Send Off: who picks the landing tile, and does it work on enemies? Final Act: does the unit die after its free action? `<3` as a tag ID, or an internal `love` tag shown as <3?
15. Fighter:
    - Shields Up!: how long does it last, and does it use 4 or 8 directions?
    - Obstruct: is "or" the larger of the two? Enemies only?
    - Interject: who triggers it (adjacent allies?), how often, and is its damage reduction capped?
    - Interdict: AP and energy cost?
    - Warcry: AP and cost, and how long its tile effects last?
    - Inspire: unfinished.
    - Jugular: does a recast cost anything, and is there a limit?
    - Sundering: "higher than the target's dex mod" or its Defense?
    - Silent Strike: AP and cost? Does it need to hit first? Do `divine` spells count as `magical`?
16. Faction trim: which resource / energy bars, the unit card's in the left panel? On-map HP bars already have trim.
17. Siren: what does a passed charm do to the target?

## Systems

Build roughly in this order; the content below depends on them.

- [ ] **Attack rolls and checks.** d20 + attack mod against Defense (a natural 20 doubles damage), advantage/disadvantage, per-skill range penalties, skill-defined checks and contests with `offensive` / `defensive` tags. *Now:* attacks always land if in reach; no Defense. Needed by Jugular, Sundering, Interject, Interdict, Gallantry, Turtle Tactics, the Siren.
- [ ] **Defense.** Set by armor, changed by skills: Mage Armor, Terestera, Hydera, Sundered; Attack Down (Interdict) on the attacker's side. *Now:* one mitigation stat by damage tag. (?5)
- [ ] **Equipment.** Two slots per unit for now: **armor** and **weapon**. Armor sets Defense; a weapon can change the attack mod and carry effects of its own (Burning Blade). *Now:* none. (?11)
- [ ] **Skill trees and ranks.** Roots, branches with prerequisites, capstones; ranking up at 1 + r². *Now:* flat lists (class, species, knowledge); points only unlock at rank I.
- [ ] **Equipping.** Learned vs equipped; 4 + floor(level / 4) slots shared by actives and passives, passives filling from the bottom of the hotbar; typed slots; auto-equip (on by default); what drops when a slot-granting skill goes. *Now:* a fixed 4-slot hotbar for actives and toggles; every learned passive is active. (?8)
- [ ] **Disabled skills.** Skills switched off for a number of turns, greyed out in the hotbar (Silent Strike).
- [ ] **Vision through the leader, plus Synergy.** *Now:* you see the clearest view any of your units has.
- [ ] **Energy recovery.** Rest (no movement or actions): (con mod + wis mod) / 2. Light Activity (only dex-move or wis-skill AP spent): slower. *Now:* energy never recovers. (?6)
- [ ] **Skill categories and resources.** martial / magic / specialist tags on skills and trees; new resources (Stamina, Rage, Focus, Sweet Nothings, Power, Hype, Clout, Gold). *Now:* only Mana.
- [ ] **Reactions and interrupts.** Units acting outside their turn: Interject, Gallantry, Final Act. *Now:* only the side whose turn it is acts.
- [ ] **Facing and direction**, for Shields Up!.
- [ ] **Effect strength set when cast**, for Rejuvinate's distance decay. *Now:* a timed effect's strength is fixed.
- [ ] **Dual-target skills**: buff allies, hurt enemies (starter spells). *Now:* a skill is either hostile or supportive.
- [ ] **One-use tile effects laid by skills**, triggered on entry (Warcry). *Now:* only traps and zones.
- [ ] **Teleport**, for Send Off.
- [ ] **Forced movement and submerging**, for the Siren's grapple.
- [ ] **Unbounded maps, camera control, spawning mid-battle**, for Infernal Meadows. (?9)

## UI and styling

- [ ] Faction trim around the hotbar and the resource / energy bars. (?16)
- [ ] Tooltips over icons after 1 s. *Now:* 0.5 s.
- [ ] Settings menu (cog): Gameplay toggles such as auto-equip, and a **Guide** with the instructions now in the hint line and key legend.
- [ ] Remove the hint line and key legend once the Guide exists.
- [ ] Typed hotbar slots: dull red / purple / green. The Adventurer's extra slot is a base slot, slightly darker. (?3)
- [ ] When targeting, if a unit is just out of range from the caster's current tile, show small circles for both units' sizes so the gap is visible. *Now:* a near miss is decided by luck, with no explanation.
- [ ] Skills screen as trees, radial for the Adventurer.
- [ ] Entry screen defaults: name **Shrike**, faction **Lancin**, class **Adventurer**. Enter starts the demo. (?9)
- [ ] Lore keeper: one reference per skill, and its hover description is what the skill is built from. (?10)

## Scenes

- [ ] **Infernal Meadows**: an endless plane of grass (grass is the default empty tile). Demons spawn out of view over time; just Sirens for now. (?9)

## Classes

Every tree's capstone, for now (later a mid-tree capstone), is a **Basic Martial / Magic / Specialist Skill Slot +1**. (?12)

### Adventurer

Three roots, **Magic**, **Martial** and **Specialist**, with flat, radial trees: most paths are a few nodes long, and each root branches into about 6 strong applications of the basics. Paths are shallow slices of other classes' trees, but Adventurers can learn core skills many classes share: **Hex** and **Rejuvinate** are a first choice at any time.

*Now:* Wary, Darkvision, Snare and Hazard Expert are its options.

Starting skills, unlocked from the start. They're separate skills on purpose, since each takes a slot.
- [ ] **Field Experience** (passive): resource bonuses (Stamina, Rage, Focus…) apply when paying Energy for martial skills.
- [ ] **Working Knowledge** (passive): resource bonuses (Mana, Sweet Nothings, Power…) apply when paying Energy for magic skills.
- [ ] **Everyman** (passive): resource bonuses (Hype, Clout, Gold…) apply when paying Energy for specialist skills.

Slot skills
- [ ] **Skill Slot +1** (unspecified type): acts like a base slot, slightly darker. Sits at the center, locked until current slots are filled. (?3)
- [ ] **Trade Skills** (passive): skill limits scale partly with wis: (base stat + wis × rank) / rank. (?2 ?13)
- [ ] **Grind** (passive): str mod can count toward martial limits; max HP drops by the % overage. (?2 ?13)
  - Rank 2+: bonus slots, each −10 × (rank − 1)% max HP while in use.
  - Rank 11+: bonus slots also cut max energy the same way.
- [ ] If a skill that grants slots is removed, skills that needed those slots are removed too. (?8)

**Magic root.** Starter spells, shared with Wizard / Mage (?12). On an ally: the listed effect. On an enemy: 1d4 + int mod damage. Range: int mod. Rank multiplies cost.
- [ ] **Sola** (light): ally +1 persona rank for rank turns.
- [ ] **Nadira** (dark): ally +1 concealment rank for rank turns.
- [ ] **Astera** (magic): ally +1 luck for rank turns.
- [ ] **Igna** (fire): ally gains int mod + rank skill AP.
- [ ] **Aetha** (wind): ally gains int mod + rank movement AP.
- [ ] **Terestera** (earth): ally gains rank physical Defense. (?5)
- [ ] **Hydera** (water): ally gains rank magical Defense. (?5)
- [ ] Capstone: **Basic Magic Skill Slot +1**.

**Martial root.** Not designed yet. Capstone: **Basic Martial Skill Slot +1**.

**Specialist root.** Not designed yet. Capstone: **Basic Specialist Skill Slot +1**.

### Wizard / Mage

- [ ] **Mage Armor** (passive, `magical`, switched on and off; early in the tree): + int mod to Defense while on. (?12)

### Paladin

Three roots in the class tab, each starting with an active skill: **Divinity** (one so far: Eros), **Idealism** (one so far: Chivalry) and **Prowess** (default: Protector; see Fighter).

**Divinity: Eros.** Spells are tagged `divine`, `cha`, `<3`. (?14)
- [ ] **Rejuvinate** (root · active · 3 AP · 5 Energy · range: rank): regeneration for 3 turns of (10% + 5% × rank) of the recipient's max HP, + the caster's cha mod. Strength decays 5% per tile beyond 1 from the caster, with no decay when paid entirely with mana. (?14)
  - [ ] **Send Off** (active): teleport an adjacent unit cha mod + rank tiles away. (?14)
  - [ ] **Lovely Caster** (passive): `<3` skills used on an adjacent ally also heal it 10% × rank of its max HP.
  - [ ] **Impassioned Fighter** (passive): +rank to a skill's primary mod when targeting an adjacent unit.

**Idealism: Chivalry**
- [ ] **Coordinate** (root · active · 1 AP · 3 Energy): teammates within cha mod tiles share recon on the area's tiles and units, up to rank levels. (?4)
  - [ ] **Final Act** (passive): once per battle, on reaching 0 HP, interrupt the current turn to take 1 free action; the interrupted turn then resumes. (?14)
  - [ ] **Gallantry** (passive): cha check against a unit attacking an adjacent ally. On a pass you become its target, and that ally can't be retargeted.

**Prowess: Protector.** See Fighter.

### Fighter

Three roots, each a flavour of Prowess of the player's choosing. Three exist so far.

**Protector:** defense of self and others.
- [ ] **Shields Up!** (active · 3 AP): choose a direction (default: toward the nearest enemy). Damage from that direction is reduced by 20% + 10% × rank. The reduction tapers past 90° to 0% at 180°; higher ranks soften the taper. (?15)
- [ ] **Obstruct** (passive): adjacent tiles cost moving units half this unit's size penalty, or half its con mod / 10. +25% per rank. (?15)
- [ ] **Interject** (passive, `defensive`): when a unit is hit, dex check; on a pass you become the target. −25% damage per rank when taking a hit that wasn't aimed at you. Rank 5+: +25% × rank to Defense when taking hits for allies. (?15)
- [ ] **Interdict** (active): str check against an adjacent unit. On success: Attack Down (20% × rank) and −str mod AP recovery for one turn. (?15)
- [ ] **Turtle Tactics** (passive): +2 × rank to the unit's `defensive` checks, −rank to its `offensive` checks.
- [ ] **Snapping Turtle** (passive): when the unit uses an `offensive` skill, it also triggers up to rank of its `defensive` passives, top to bottom.

**Vanguard:** front-line offense and tactics.
- [ ] **Warcry** (active): pick up to rank enemies the unit can see. Rank tiles on the line to each get a one-use effect, triggered on entry: (?15)
  - Nearer half, **Charge!** (expanding translucent hot-orange squares): allies regain rank dex AP and deal +10% × rank damage until their turn ends.
  - Farther half, **Routed!** (collapsing translucent dark-blue squares): enemies pay +rank movement.
- [ ] **Inspire** (passive): hitting an adjacent enemy with a skill grants allies within rank tiles a bonus to… (unfinished) (?15)

**Slayer:** eliminating chosen targets.
- [ ] **Jugular** (active): an attack at disadvantage, +(rank − 1) to the roll; a hit is a critical. When an attack would crit anyway (natural 20, or other skills), recast immediately. (?15)
- [ ] **Sundering** (passive): an attack rolling higher than the target's dex mod applies stacking **Sundered**: −1 Defense for rank turns. (?5 ?15)
- [ ] **Silent Strike** (active): disables rank of the target's `magical` skills, actives and passives, for rank turns, starting from the bottom of its hotbar. Disabled skills are greyed out. (?15)

## Items

Armor (see the Defense rule)
- [ ] **Gambeson**: Defense the higher of 10 and level / 2, + dex mod. (?5)
- [ ] **Plate**: Defense the higher of 20 and level. (?5)
- [ ] **Robe** (`cloth`): Defense the higher of 8 and level / 4. (?5)

Weapons
- [ ] **Burning Blade** (enchanted): attacks use the highest of cha, wis or int. The wielder adds its str mod to max HP, even if negative. (?11)

## Monsters

### Siren
- [ ] **Grapple**: str contest against a unit. On a win, the Siren drags it to the nearest water tile, submerging both of them.
- [ ] **Claw**: its attack instead of a grapple when no water is in range for the target.
- [ ] **Charm**: the Siren's cha check against the target's wis check. (?17)



___
NEXT PROMPT
5: Yup if I say AC I probably mean Defense, they're the same thing.
Defense is universal AC. there will be skills and equipment that may give tagged Defence, such as `physical` defense, `magical` defense, `piercing``bludgeoning` defense, or `fire` defense

Tagged defenses only apply to matching / child tags (physcial defense would apply to `piercing`, `bludgeoning`, `slashing`

level / 2 etc rounds down unless the unit has positive luck, then it rounds up. This will be a clover green (different shade than 'Specialist' slots) If the unit's luck were to later decrease / rounding is no longer needed, this slot will be disabled / converted into a regular skill slot



