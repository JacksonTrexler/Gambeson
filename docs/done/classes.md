# Done: classes

`[x]` done · `(?N)` an open question in `docs/todo/` that may still change it · *Now:* what the game does today. Index: `completed.md`.

## Adventurer

*Now:* the tree is built (`Roles/adventurer.tres`; the skills screen draws it as a wheel). Skills that wait on a question are stubs: on the wheel with their question number, but they can't be learned.

Starting skills, unlocked from the start:
- [x] **Field Experience** (passive): resource bonuses (Stamina, Rage, Focus…) apply when paying Energy for martial skills. *Now:* no martial resource exists yet, so it does nothing.
- [x] **Working Knowledge** (passive): resource bonuses (Mana, Sweet Nothings, Power…) apply when paying Energy for magic skills. *Now:* Hex costs half AP paid with Energy, as with Mana.
- [x] **Everyman** (passive): resource bonuses (Hype, Clout, Gold…) apply when paying Energy for specialist skills. *Now:* no specialist resource exists yet.

Core: **Hex** and **Rejuvinate** (built; see Paladin).

**Magic root.** Starter spells, also Wizard options (?10). On an ally: the listed effect. On an enemy: an attack roll (d20 + int mod), then 1d4 + int mod damage. Range: int mod, reaching an adjacent unit at least. Each is 3 AP and 2 Energy × rank; Mana pays half, for a unit with the Mana passive (Adventurers don't have it).
- [x] **Sola** (light): ally +1 persona rank for rank turns. (?10)
- [x] **Nadira** (dark): ally +1 `dark` concealment rank for rank turns.
- [x] **Astera** (magic): ally +1 luck for rank turns.
- [x] **Terestera** (earth): ally gains rank `physical` Defense, for 3 turns.
- [x] **Hydera** (water): ally gains rank `magical` Defense, for 3 turns.
- [x] **Renew** (see Paladin): Divinity is in the caster family, so renewal sits in the caster tree. Tier 1.
- [x] Capstone: **Basic Magic Skill Slot +1**, after 3 Magic skills. (?15)

**Martial root.** *Now:* Wary, then the capstone, **Basic Martial Skill Slot +1** (built; needs 3 Martial skills, so it can't be reached yet). (?15)

**Specialist root.** *Now:* First Aid; Snare, then Hazard Expert and Move +1; Darkvision, then Meander, then Hide and Clever Disguise; Self-evaluation; Personify, then Embellish and Brood, then Conspire; and the capstone, **Basic Specialist Skill Slot +1** (built; needs 3 Specialist skills). (?15 ?18)
- [x] **First Aid** (tier 1 active, `physical`, `specialist`; also on Calling: Freedom's core): heals an adjacent ally (or itself) (dex mod + wis mod) / 2 + 1 HP, at least 1, clearing wounds up to its rank, and rank more HP for each wound it treats. *Now:* 3 AP, 1 Energy.
- [x] **Snare**: its trap leaves **Bleeding** on whoever it hits: 1d4 + the setter's dex mod as each of its side's turns ends, not the one it was sprung on (at least 1), a wound at the snare's rank, for rank + the setter's dex mod turns (at least 1).
- [x] **Self-evaluation** (tier 1 passive): when an ally uses an active skill within rank tiles, its roll pops up above that ally, tallied up like the initiative rolls. Then, if the skill's effects show on the unit, the roll labels the effect's icon in the top right. *Now:* its holder's own rolls count too. It shows attack rolls, and the one roll Hide and Clever Disguise make (which investigators must beat). Without it, the log keeps that roll hidden. (?20)
- [x] **Move +1** (tier 2 passive, after Snare): +1 movement, so the unit can move one more tile before AP penalties start.
- [x] **Meander** (tier 2 passive, switched on and off, after Darkvision): the unit can move rank tiles while technically **standing still**, for resting, concealment and skill purposes. Standing still, it passes by tile effects that trigger on passing whose level isn't greater than its rank. It also takes no damage from effects that proc when it moves, if its rank is higher than the effect's. *Now:* the first rank tiles it walks each turn count as standing still: it still rests, stays hidden, and walks over traps and ground effects of its rank or lower without setting them off. Nothing deals damage for moving yet, so that last part waits. (?18)
- [x] **Hide** (tier 3 active, after Meander): the unit gains rank levels of concealment, lasting until it moves (by default). Enemy units that can see it investigate at once (see Investigating). *Now:* used on itself from the hotbar (no target to pick). An investigator who passes keeps seeing it; the log shows each investigation. (?18)
- [x] **Personify** (tier 1 hybrid, `specialist`): a passive and an active effect. Passive: + rank persona while it advertises. Active (2 AP): opens the persona modal (see Persona and insight). *Now:* the Persona skill, renamed.
- [x] **Embellish** (tier 2 active, after Personify): gasses up a unit, itself or an ally within rank − 1 tiles (self only at rank I). Rank of its stats, highest first, seem 20% higher, inflating its perceived BST. Past six it loops back to the highest (rank 7: the highest +40%). No effect on enemies it doesn't fool. Insightful units who see through it read the stats it fronts ("strong", "charming"). *Now:* 2 AP, 2 cost, 3 turns.
- [x] **Conspire** (tier 4 passive, switched on and off, after Embellish and Brood; Adventurers and Bards): while on, allies within rank + cha mod tiles fail persona checks against it on purpose. Switched off on its turn, its allies pass them automatically. It gets up to (rank − 1) trickery for each ally it fools. No infighting between allies using trickery: they "defect" together. Rank × 33% less friendly-fire damage. *Now:* (rank − 1) trickery per ally in range, uncapped; allies in on it take its Enemy or Traitor stance for Friendly.
- [x] **Brood** (tier 2 passive, switched on and off, after Personify; Bards, Adventurers and Rogues): its stats seem 25% lower a rank when advertised, to no less than 1. Rank 5+: allies within rank − 4 tiles seem 10% × (rank − 4) lower. Insightful units who see through it read "weak". *Now:* only to those it fools; the aura only to those the brooder fools.
- [x] **Clever Disguise** (tier 3 active, after Meander): the unit gains rank levels of trickery. Enemy units within sight investigate at once (see Investigating). The disguise holds for rank turns, then decays a level a turn. Its ranks cost more: a high base, growing exponentially. *Now:* II costs 4 points, then double each rank. Enemies it fools may take it for one of their own. (?18)

- [x] **Observe** (Specialist root, after Darkvision; Rogue's Eyes root; 2 AP, 1 Energy, range wis mod + rank): pick a tile; the unit investigates every tile around it (`Battle.observe()`: within max(wis mod, 1) + rank) as if it had rested rank turns, the distance penalty counted from that tile. The AI, with no foe to go after, Observes the tile in reach whose area holds the most it finds suspicious; with no clues it doesn't search.
- [x] **Eyes Forward** (passive, after Observe; the `eyes_forward` stat): ending its turn after completing a move (moving was the last thing it did), the unit investigates every tile rank + wis mod tiles forward the way it moved, and rank tiles to either side, in place of looking around. Non-adjacent tiles take −1 a tile.
- [x] **Special Eyes** (passive, after Observe; the `keen_eyes` stat): the distance penalty on non-adjacent tiles is cut to distance / (rank + 1).

## Wizard / Mage

- [x] **Mana** (tier 1 passive; Mages and Wizards start with it at rank I): the starter spells cost half paid with Mana, up to its rank in tier. *Now:* a Wizard option and starting skill. Wizards start with 10 Mana. (?16)
- [x] **Mage Armor** (passive, `magical`, switched on and off; early in the tree): + int mod to Defense while on. *Now:* a Wizard option, unlocked with a skill point. (?10)
- [x] The Adventurer's starter spells (Sola, Nadira, Astera, Terestera, Hydera, Igna, Aetha) are Wizard and Mage options too. (?10)
- [x] **Two classes**: the Wizard (flexible, many tabs) and the Mage (`Roles/mage.tres`: a school, the Mage tree, a college). Their trees are laid out: the Wizard's own tab (Arcane, Transgression), Pact: Elmon / Hogel and Affiliation: Urlo / Sol (one of each, `SkillTab.one_of`), World: Nature; the Mage's own (Refinement, Commitment), five School tabs and three College tabs (one of each). New skills are stubs with their plans (`docs/todo/classes.md`, ?70). `casters_test.gd`.
- [x] **Picking trees** (`Role.choices`, `TreeChoice`; `Unit.pick()`, `picks()`, `pick_missing()`, `class_trees()`): a class's choices of trees sit on its own tab as boxes of tier 0 roots, "Pick up to x". Picking one is free and opens its tab; skills on a tree not picked wait ("Pick School: Shadow first"). Paladin Prowess, Warlock Patron, Cleric God, Mage School and College. Shared trees live in `Trees/` (Luun, Sol, Elmon, Hogel, Song, Eros, the five schools). (?71)
- [x] **Dabblings** (Wizard): Divinity, Symphony, Witchery and Mastery (`Skill.studies`) each open a choice, picking up to their rank, of every other class's trees of a kind, found as the game runs (`TreeChoice.borrows`, `all()`): Divinity tabs (Luun, Sol), Genre tabs (the Bard's Song), Patron tabs (Elmon, Hogel), School tabs (the Mage's five), each with its class's shared row (Pray and Renew; Hex, Sweet Nothings and Chant). Guest trees' skills rank at -1 Affinity (`TreeChoice.affinity`, `Unit.guest_affinity()`); Mastery's schools at none. A Wizard can serve gods and a patron at once (`Unit.devotions()`). (?71)
- [x] **Rift** (Wizard, Transgression; `Skill.rifts`, `Battle.open_rift()`, `close_rift()`): a door on a tile in a clear line (over walls from rank III) to a domain - an 8x8 diamond of grass with demons at 0.5 x rank difficulty and the Wizard's level - open both ways while channeled (infinite), or cast unchanneled (Alt-click). Its count of 3 x its difficulty turns starts once the channel stops (used again, another channel, falling: `Battle.end_channel()`), or at once unchanneled; then the Wizard's side comes back. (?75 ?76)
- [x] **Emergency Exit** (Wizard, Arcane, high tier; `Skill.exits`, `Battle.emergency_exit()`): a forming escape portal opens rank turns sooner (`Meadows.hasten()`); else the Wizard and its allies within rank tiles warp to a pocket of stone for rank turns, a door back and forth, then come back in a clump. Pockets: `Battle.Pocket`, `Battle.paint()`, `pockets_test.gd`. (?75)
- [x] **The tab row wraps**: a class with more tabs than fit across takes a second row (`SkillTree._fill_tabs()`, an HFlowContainer).

## Warlock

`Roles/warlock.tres`: cha 15, "Caster", the Gaunt sprite; on the entry screen. A tab per patron, **Patron: Elmon** and **Patron: Hogel** (light and death magic), each opening with the shared tier 1 row (`Role.shared`): Hex, Sweet Nothings and Chant. Hex and Sweet Nothings are learned from the start. A Warlock serves one patron: its first skill on a patron's roots devotes it, and the other patron's tab closes ("Devoted to Elmon"; `SkillTab.devotes`, `Unit.devotion()`). Its magical skills use cha where they'd use wis (`Role.swaps`): Hex rolls and hits with cha mod.

- [x] **Sweet Nothings** (tier 1 passive, `warlock`, switched on and off from the hotbar; `Reserves/sweet_nothings.tres`, pink): a reserve of cha mod × rank (none at +0), full as each battle starts. Switched on, one Sweet Nothing pays a Warlock skill's whole cost, whatever it is, when that saves Energy; switched off, nothing is spent from it (it's kept), and skills that need one can't be used (`Unit.spends()`). Higher-tier skills can need one (`Skill.needs`). One back for each foe the Warlock's skills slay, and more as its patron is satisfied.
- [x] **Chant** (tier 1 passive, shared row): waiting a turn out (resting: no move, no AP spent) primes it: its next rank Sweet Nothing gains each bring one more, and its next Warlock skill is used a rank higher (`Battle._chant()`, `Unit.chant_gains`, `Unit.chant_up`). (?42)
- [x] **Analysis Dialysis** (Elmon, tier 2 passive, after Sweet Nothings): unmasking a foe it took for friendly or neutral gives 2 Sweet Nothings × rank; each level of concealment its suspicion takes off a hiding foe, 1 × rank (`unmask_gain`, `uncover_gain`; `Battle._dialysis()`).
- [x] **wauaw** (Elmon, tier 2 active, after Sweet Nothings; 3 AP, cost 2, range rank): on any unit, ally or foe, with no roll, for 3 + 2 × rank turns: more damage taken and more damage dealt, both 10% steps climbing to the middle of its turns and back down (rank I: 10, 20, 30, 20, 10%).
- [x] **Brainfog** (Elmon, tier 2 curse, after Hex; 4 AP, cost 3, range cha mod + rank): the foe saves, d20 + wis mod + the ranks of the skills it would lose, against d20 + cha mod + rank (the caster wins ties). Failing, the caster's sqrt(rank) - rounded down, up while lucky - of its skill slots are disabled from the right (see Pillar skills) for rank + 1 turns. Passing, it grows suspicious of the caster.
- [x] **Level Down** (Elmon, tier 5: 4 of Elmon's skills first; 5 AP, cost 4 and a Sweet Nothing, range cha mod + rank; `warlock`, `curse`): rank rolls of d20 + cha mod, each against the higher of the foe's average stat mod + level and its last stand. Each that beats it takes a level off the foe, for as many turns (rank − misses). The curse is easy to cleanse (×2). Clerics of Luun have it too, without the Sweet Nothing (a skill needs one only from a unit that has them).
- [x] **Death** (Elmon capstone: 5 of Elmon's skills first; 6 AP, cost 6 and a Sweet Nothing, range cha mod + rank; `dark`, `execute`): the foe's last stand × (HP left / max HP) / rank, against d20 + cha mod (the caster wins ties). Failing, it takes 1 true damage and dies; a heart left, it goes down as usual. Luun Clerics have it too; Luun Paladins will.
- [x] **Haluca** (Elmon, tier 2, after Hex): as before; a foe that saves now grows a stack of suspicion of the caster.
- [x] **Hogel is satisfied** by rest: a Hogel Warlock resting a turn out at full HP gets a Sweet Nothing (`SkillTab.satisfied_by`).
- [x] **Humble** (Hogel, tier 1 active, `curse`; 2 AP, cost 1; range rank − 1, so rank I is on itself): caps a unit's max HP at its HP now less 1% of its max, for rank × 4 × (1 − the share cut) turns, at least 1 - the less it cuts, the longer it holds (`Battle._humble()`). On itself at full HP, with Hogel's rest: a Sweet Nothing a turn. (?45)
- [x] **Gasp** (Hogel, tier 1 active, `light`, `curse`; 2 AP, cost 1; range cha itself + rank: `Skill.radius_stat`): 1 light curse damage. Easy to hit: the better of two d20s (`Skill.advantage`), + rank (`Skill.roll_per_rank`).
- [x] **Breathtaking** (Hogel, tier 2 passive, after Gasp): its curses that land (effects put on, or damage) give the target a stack of **Asphyxia**: 1% × rank of its max HP gone a stack (`Unit.refit()`), holding for 1 + rank of its turns after the last, then falling a stack a turn (`Battle._choke()`).
- [x] **Irradiate** (Hogel, tier 3 passive, after Breathtaking): an offensive light-damage skill whose roll beats Defense deals the overage as more light damage, up to rank + cha mod.

## Rogue and Bard

Stub trees from skills that exist, each with its own tab and **Calling: Freedom** beside it. (?19)
- [x] **Rogue** (`Roles/rogue.tres`; dex 15; "Tradefolk"). Starts with Strike and Move +1. Its own tab: Strike; **Blade** (martial): Wary. Calling: Freedom: centre **Hide** (tier 1 here); core **Move +1**, **Darkvision**, **Self-evaluation**, **First Aid**; **Shadow** (specialist): Meander, then Clever Disguise and Brood; **Traps** (specialist): Snare, then Hazard Expert; **Eyes** (specialist): Observe, then Eyes Forward and Special Eyes.
- [x] **Bard** (`Roles/bard.tres`; cha 15; "Tradefolk"). Starts with Strike and Meander. Its own tab: Strike; **Song** (magical): Sola, then Astera. Calling: Freedom: centre **Clever Disguise** (tier 1 here); core **Meander**, **Move +1**, **Self-evaluation**, **First Aid**; **Performance** (specialist): Tonefoolery; Glamour, then Manifest; Personify, then Embellish and Brood, then Conspire. Eyes Forward and Special Eyes are on its Freedom core.

## Cleric

`Roles/cleric.tres`: wis 15, "Caster", `Units/Cleric.png` (a placeholder: u.u over <> over / \); on the entry screen and among the Wayfarers. A **Divinity** tab per god, one god per Cleric (`SkillTab.god`, `devotes`: its first skill on a god's roots devotes it, and it prays to that god: `Unit.deity()`), each opening with Pray and Renew (learned from the start). Its magical skills use wis where they'd use cha (`Role.swaps`). Robe, Staff, Energy Potion.
- **Luun**: Level Down (after Pray), then Death.
- **Sol**, a path of fire, each after the one before (Flamecharmed after Igna). Fire damage is tagged `fire`; burning ground is also `environmental`. (?46)
- [x] **Igna** (I; also the Adventurer's): on an ally, int mod (a Cleric: wis) + rank skill AP at once; on a foe, 1d4 + int mod.
- [x] **Flamewall** (II; 4 AP, cost 3, range rank, on a tile): sets the tile, and rank tiles to either side of it across the caster's line to it, on fire for rank of the caster's side's turns. Entering a burning tile, or ending a turn on one, deals 1d8 + the caster's wis mod (`Battle.flames`, `Battle._flame()`). Someone standing there makes a dex check against the caster's d20 + wis mod to get clear as it goes up.
- [x] **Flamecharmed** (II, passive): 25% × rank fire mitigation. From rank V, an ally's fire heals it for 25% × (rank − 4) of what it deals.
- [x] **Inner Fire** (III; 2 AP, cost 2, on itself, rank turns): +10% × rank AP and damage dealt; loses 5% × rank of max HP as each turn starts.
- [x] **Burning Bag** (IV; 2 AP, cost 2): takes the one Burning Bag from wherever it is (another unit, the stash) and puts it on at the skill's rank: rank more untyped skill slots, which burn; the wearer burns for 10% × rank of max HP as its turns start, and again for each skill used from them (`Unit.burning_slots()`, `Battle._burn()`).
- [x] **Flamecharm** (V; 3 AP, cost 3, rank turns): 20% × rank fire mitigation on itself and its allies within rank tiles; from rank V, only the nearest rank of them, the mitigation split among them (`Battle._aura()`).
- [x] **Cindering** (VI; 4 AP, cost 4, range wis mod + rank, rolls to hit): the foe's rightmost rank hotbar slots burn for rank turns: each skill used from one burns it for 10% × rank of max HP + the caster's wis mod.
- [x] **Level Up** (VII; 5 AP, 5 cost, range wis mod + rank, on an ally): it gains rank levels for rank turns. Exceptionally easy to remove: dispelling takes 4 of its ranks for each spent.
- [x] **Flamedance** (VIII; 2 AP, cost 3): only as its turn opens (before it moves or spends AP). It and its allies within rank tiles take no environmental fire, and deal 10% × rank more fire, until their next turn ends.
- [x] **Solar** (IX, capstone; 8 AP, cost 8, on a tile): a 45° cone (+ 15° a rank past I), wis mod tiles long: d20 + the caster's wis score in fire to everyone in it, the caster too.

## The general trees

Four trees beside every class's own, on the far right of the skills screen (`Trees/general*.tres`; `Unit.general_trees()`), their tiers set on their branches (`Branch.tier`). Which a class gets: `Role.general` (Adventurer all; Fighter Martial; Paladin Martial, Caster; Rogue Specialist; Bard Specialist, Caster; Wizard, Warlock, Cleric Caster).

**General** (dark gray): Strike (tier 0); Generalist, Martialist, Journeyman, Thaumaturgist (I); Strike! (VII).
- [x] **Generalist** (Foundation): General-tree skills up to its rank in tier, without needing 3 of that tier. **Martialist**, **Journeyman**, **Thaumaturgist**: the same for the Martial, Specialist and Caster trees, opening them to a class that lacks them a tier lower (Journeyman III on a Fighter: up to tier 2) - but two tiers sooner for a class with the Specialist tree (`Unit.SPECIALIST_EDGE`: Martialist I on a Rogue reaches tier 2). (?51) Skills learned through one stop working while it's gone or disabled (`Unit.waived`, `Unit.lapsed()`).
- [x] **Strike!** (VII): landing 12 Strike hits in one use strikes again at once (a strike, bowled); from rank II with rank − 1 more hits. A reuse can trigger again, up to three in a row; 36 hits in a row is a **Perfect**: 300 HP healed at once (`Battle.PERFECT_HITS`, `Battle.PERFECT_HEAL`, the `perfect` signal, logged). (?52)

**Martial** (red): Brutal Strike (II), Strike Out (IV), the Bracing passives (V), Brutal Mastery (VII).
- [x] **Brutal Strike** (low tier, exclusive): Strike becomes Brutal Strike, a single attack adding its weapon's rank + rank to the damage. (?50)
- [x] **Strike Out** (mid): its first rank hits take no penalty, and a miss among them doesn't end the attacks.
- [x] **Brutal Mastery** (high, stacks): Strike's first hit adds its weapon's rank + rank.

**Specialist** (green): Synergy, Decisive Strike (II), Striking Features (IV), Agility and Balanced Bracing (V), Decisive Mastery (VII).
- [x] **Decisive Strike** (low tier, exclusive): Strike becomes Decisive Strike. After a critical, the rest of its hits land; damage by the higher of dex and str mod.
- [x] **Striking Features** (mid): its first rank hits add cha mod, up to rank.
- [x] **Decisive Mastery** (high, stacks): the same as Decisive Strike, as a passive.

**Caster** (light purple): Elemental Strike (II), Record Striker (IV), Meditative and Invigorating Bracing (V), Elemental Mastery (VII).
- [x] **Elemental Strike** (low tier, exclusive; active, 2 AP, cost 2): pick an element (fire, water, earth, air, light, dark: a menu as it's used); the next rank Strikes become <Element>strike (Firestrike), dealing it, the first hit of each + the highest mental mod (`Battle.imbue()`).
- [x] **Record Striker** (mid, `curse`): its first rank hits each try a curse - the foe's wis against the striker's highest mental mod; failing, the skill in its leftmost slot goes a rank down for its next turn. (?50)
- [x] **Elemental Mastery** (high, stacks): Strike always carries the unit's element (its last pick, else its god's, else fire), the first hit + its highest mental mod.

The Bracing passives (V; `brace` effects, `Unit.check_bonus()`) add equipped armor ranks to checks, up to their rank, while armor is worn to effect; each carries its gang's lore (`Skill.lore`). (?48)
- [x] **Agility Bracing** (Martial, Specialist): light armor ranks to dex rolls.
- [x] **Balanced Bracing** (Martial, Specialist): medium armor ranks to defensive str and dex rolls.
- [x] **Vanguard Bracing** (Martial): medium armor ranks to offensive str and dex rolls.
- [x] **Combat Bracing** (Martial): heavy armor ranks to str rolls.
- [x] **Meditative Bracing** (Caster): armor ranks to defensive mental (int, wis, cha) checks.
- [x] **Invigorating Bracing** (Caster): half armor ranks to offensive mental checks; rank more skill AP a turn while armored.
- Checks that take bracing: attack rolls (offensive, in the stat used), saves (the caster offensive, the foe defensive), drags, breaking free, Sing's resist, Flamewall's dodge (dex) and its caster (wis), Level Down's, Death's and Record Striker's rolls. Not yet: investigations, hiding, last stands.
- [x] **Synergy** (Specialist, II; also on the Human tree): see Vision. It reaches as far as the leader's command range over its party (2 × (cha mod + command)); a Quartz Ring makes that endless.

## Paladin

- [x] **Pray** (`Skills/pray.tres`; 2 AP, 2 Energy, on itself, or for Drael on an ally within rank tiles: `Skill.on_self()`; `Battle.pray()`): by the god the unit worships (`Unit.god`, else its class's: `Role.god`, Paladin: Eros; `Unit.GODS` with domains).
  - Ramut: its side waits rank turns less for the Ire.
  - Eros: up to rank units within rank tiles that can see it, nearest first, lose a stack of suspicion of it.
  - Sol: darkness zones lose every tile within rank tiles (any side's, Luun's included).
  - Urlo: its side's units within rank tiles, nearest first (itself first), get unenchanted items enchanted, weapon then armor, rank items in all (`Unit.enchant()`): what the item becomes enchanted (`Item.enchanted_as`), else a copy at `enchant` 1. Armor: +1 Defense; a weapon: +1 damage on strength attacks (`Unit.weapon_bonus()`). There are no trinkets or item skills yet.
  - Luun: the ground within rank tiles under dark concealment 1 for rank turns, hiding only its side's units from the rest (`Zone.allied`); the ground isn't shrouded.
  - Drael: `Battle.cleanse()`: debuffs (effects that hurt their holder) lose ranks, highest first, rank ranks in all; one at 0 is gone. Ramut's Ire isn't lifted.
  - Vetruvis: every tile within rank tiles becomes its side's disturbed earth (`Battle.earthworks`) for rank of its side's turns: entering costs enemies ×1.5 (`Battle.wading()`). Drawn as a furrowed brown wash.
  - *Now:* on the Paladin's Divinity root, open from the start.
- [x] **Coordinate** (Idealism root · active · 1 AP · 3 Energy · on itself; `Skills/coordinate.tres`): links the caster with its teammates within its cha mod in tiles (at least 1) and its leader, wherever it is, until the end of its side's next turn. Linked, each makes out units and tiles as well as the best of them does, up to rank levels better (`Battle.read()`): with the player's view being the leader's, it's how the rest of a side's sight reaches the player. *Now:* opens the Paladin's Idealism root.
- [x] **Smite** (tier 3: two skills learned first; active · 5 AP · 4 cost · adjacent, `divine`, `cha`; `Skills/smite.tres`): 2d12 / 3d12 / 4d12 + cha mod at ranks I / III / V, with an attack roll. Its damage carries the tag of the caster's god (`Skill.god_tag`, `Unit.GOD_TAGS`), and on a hit its god adds (`Battle._smite()`):
  - **Eros** (love): used on an ally, it heals what it would deal, overhealing what's left over at rank × 20%.
  - **Luun** (dark): a foe left at rank × 5% of its max HP or less dies (an execute).
  - **Sol** (fire): it burns again as its side's turn ends, for 20% × rank of the damage, pure fire.
  - **Urlo** (energy): drains Energy (or Power) first, from rank II (rank − 1) × 20% of what's left going on to HP; takes rank enchantments off its items, and enchants the caster's with what it didn't find.
  - **Drael** (water): takes rank ranks of its buffs off (`Battle.dispel()`).
  - **Vetruvis** (earth): radiates earth damage to everyone within rank tiles but the caster, the damage / (tiles away + 1).
  - **Ramut** (physical): nothing more.
  - *Now:* on the Paladin's Divinity root (still tier 3).
- [x] **Renew** (tier 1 active, `divine`, `wis`; Divinity): restores wis mod HP (at least 1), and the recipient gets rank AP back. Against wounds it counts rank × rank: Renew II clears wounds up to rank 4. *Now:* on the Paladin's Divinity root (3 AP, 2 Energy, range 2); also on the Adventurer's Magic root.
- [x] The **Adventurer** starts at 16 in every stat - a sandbox for the attribute-driven Actualization abilities (respec, Hardy, Self-reflection) to come.
- [x] **Hardy** (Actualization passive; `Skills/hardy.tres`): con mod counts (1 + rank) times in the HP each level brings. Alabaster borrows it at I: 30 + 25 = 55 max HP. Its home tree waits on the Actualization tree (?57).
- [x] **Judgement** (Paladin; Cleric, Sol): an attack within rank tiles, 1d4 + wis mod. On a hit, **Shackles** of the rank's weight replace the target's trinket (kept till they come off), locked for rank turns by a Shackled debuff (cleansing unlocks them). Locked: pick (approachable, dex) or pry (unfair, str), each try their rank in AP. Unlocked: off for their rank in AP. (?65 ?66)
- [x] **Wildfire** (Cleric, Sol, after Solar): evadable at difficult; a 60 degree cone, intense (2.5 x rank) tiles long; extreme ((3 x rank)d6 + wis) fire to every unit in it but the caster; units carrying earth (`Unit.has_tag()`) dodge at impossible and are hit as a crit; it burns leaves in its path. (?64)
- [x] **The Paladin's tree** (`Roles/paladin.tres`): **Divinity: Eros** (magical: Rejuvinate, Pray, Renew and Smite open, Send Off, Lovely Caster and Impassioned Fighter after Rejuvinate), **Idealism: Chivalry** (specialist: Coordinate, then Final Act and Gallantry, stubs waiting on Reactions) and **Prowess: Protector** (the Fighter's root, `Trees/protector.tres`). Favour, Lightvision and Judgement stay on its core ring. (?12 ?67)
- [x] **Rejuvinate** (Divinity root; also the Adventurer's core ring · 3 AP · 5 Energy · range rank · `divine`, `cha`, `love`, `magical`; `Skills/rejuvinate.tres`): regeneration for 3 turns of 10% + 5% × rank of the recipient's max HP, + the caster's cha mod in HP (`regen`, `regen_hp`). Its strength falls 5% a tile past the first between caster and target, set as it's cast (`Skill.decays`, `Battle.decay()`, `Unit.Applied.scale`), none when paid wholly with mana; the cha mod is fixed then too (`Effect.by_mod`). (?12)
- [x] **Send Off** (after Rejuvinate · 3 AP · 3 Energy · adjacent, ally or foe; `Skills/send_off.tres`): teleports the unit cha mod + rank tiles straight away from the caster, to the furthest free tile on that line (`Skill.sends`, `Battle.send()`, `Battle.place()`). A foe gets an attack roll first. (?12)
- [x] **Lovely Caster** (after Rejuvinate, passive; the `lovely` stat; `Battle._lovely()`): a `love` skill used on an adjacent ally - one tagged love, or an Eros Paladin's Smite - also heals it 10% × rank of its max HP at once.
- [x] **Impassioned Fighter** (after Rejuvinate, passive; the `impassioned` stat; `Battle.passion()`): + rank to a skill's primary mod used on an adjacent unit - its attack roll, its contest or save, and damage and heals that scale on that stat. Strike's chain takes it too.
- [x] **The Berserker**: Reckless Abandon (Offender, Unsupportive, Indefensible; skipping defensive and supportive steps), Affinity's live rank curves, three Prowess tabs. (?58)
- [x] **Actualization** (the Adventurer's Path tab): Self-reflection, Hardy, Meditate and its respec. (?57)

## Fighter

`Roles/fighter.tres`: three martial roots - **Protector** (`Trees/protector.tres`, also the Paladin's Prowess), **Vanguard** and **Slayer** - with Wary on the core ring. Each opens on its active; unbuilt skills are stubs (Interject, Snapping Turtle, Warcry, Inspire, Sundering, Silent Strike, Gank). Protector's capstone is a Basic Martial Skill Slot +1. (?67)

- [x] **Shields Up!** (Protector root · active · 3 AP · aimed at a tile within 8; `Skills/shields_up.tres`; `Skill.guards`, `Battle._guard()`): the unit faces the tile (`Unit.guard`); until its next turn is through, damage from a source whose tile lies within the 90° cone that way is cut by 20% + 10% × rank (the `guard` stat; `Unit.guarding()`, `Unit.hit()`). A DEFEND order faces the nearest foe it makes out (`AI._defend()`).
- [x] **Obstruct** (after Shields Up!, passive; the `obstruct` stat; `Battle.obstruction()`): a foe entering a tile beside it pays the larger of half the size penalty of moving through it and half its con mod / 10 more movement, × (1 + 25% × rank). Its allies pass freely. Walks, step costs and the AI's expected walks all count it.
- [x] **Interdict** (after Shields Up! · 3 AP · 2 Energy · adjacent; `Skills/interdict.tres`): a str save (d20 + str mod + rank against the foe's d20 + str mod). Won: **Attack Down**, -20% × rank damage dealt, and the caster's str mod off the foe's general AP (`base_ap`, scaled by `Effect.by_mod`), for one of its turns.
- [x] **Turtle Tactics** (after Shields Up!, passive; the `check` effect, `Unit.check_bonus()`): +2 × rank to its defensive checks and -rank to its offensive ones - attack rolls among them - armor or not.
- [x] **Jugular** (Slayer root · 4 AP · 2 Energy · adjacent · 1d6 + str mod, its weapon's blow; `Skills/jugular.tres`): an attack at disadvantage (`Skill.disadvantage`), + (rank - 1) to the roll (`roll_per_rank`, `roll_bonus`); a hit is a critical (`sure_crit`). A natural 20 casts it again at once on the same foe, free (`recast_on_crit`), up to 20 in a row.
