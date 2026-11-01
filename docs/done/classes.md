# Done: classes

`[x]` done · `(?N)` an open question in `docs/todo/` that may still change it · *Now:* what the game does today. Index: `completed.md`.

## Adventurer

*Now:* the tree is built (`Roles/adventurer.tres`; the skills screen draws it as a wheel). Skills that wait on a question are stubs: on the wheel with their question number, but they can't be learned.

Starting skills, unlocked from the start:
- [x] **Field Experience** (passive): resource bonuses (Stamina, Rage, Focus…) apply when paying Energy for martial skills. *Now:* no martial resource exists yet, so it does nothing.
- [x] **Working Knowledge** (passive): resource bonuses (Mana, Sweet Nothings, Power…) apply when paying Energy for magic skills. *Now:* Hex costs half AP paid with Energy, as with Mana.
- [x] **Everyman** (passive): resource bonuses (Hype, Clout, Gold…) apply when paying Energy for specialist skills. *Now:* no specialist resource exists yet.

Core: **Hex** (built).

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
- [x] The Adventurer's starter spells (Sola, Nadira, Astera, Terestera, Hydera) are Wizard options too. (?10)

## Warlock

`Roles/warlock.tres`: cha 15, "Caster", the Gaunt sprite; on the entry screen. A tab per patron, **Patron: Elmon** and **Patron: Hogel** (a stub), each opening with the shared tier 1 row (`Role.shared`): Hex, Sweet Nothings and Chant (a stub). Hex and Sweet Nothings are learned from the start. (?26)

- [x] **Sweet Nothings** (tier 1 passive, `warlock`; `Reserves/sweet_nothings.tres`, pink): a reserve of cha mod × rank (none at +0), full as each battle starts. One Sweet Nothing pays a Warlock skill's whole cost, whatever it is; it's spent when that saves Energy. Higher-tier skills can need one (`Skill.needs`). One back for each foe the Warlock's skills slay, and more as its patron is satisfied. (?25)
- [x] **Analysis Dialysis** (Elmon, tier 2 passive, after Sweet Nothings): unmasking a foe it took for friendly or neutral gives 2 Sweet Nothings × rank; each level of concealment its suspicion takes off a hiding foe, 1 × rank (`unmask_gain`, `uncover_gain`; `Battle._dialysis()`). (?25)
- [x] **wauaw** (Elmon, tier 2 active, after Sweet Nothings; 3 AP, cost 2, range rank): on any unit, ally or foe, with no roll, for 3 + 2 × rank turns: more damage taken and more damage dealt, both 10% steps climbing to the middle of its turns and back down (rank I: 10, 20, 30, 20, 10%). (?26)
- [x] **Brainfog** (Elmon, tier 2 curse, after Hex; 4 AP, cost 3, range cha mod + rank): the foe saves, d20 + wis mod + the ranks of the skills it would lose, against d20 + cha mod + rank (the caster wins ties). Failing, the caster's sqrt(rank) - rounded down, up while lucky - of its skill slots are disabled from the right (see Pillar skills) for rank + 1 turns. Passing, it grows suspicious of the caster. (?23)
- [x] **Haluca** (Elmon, tier 2, after Hex): as before; a foe that saves now grows a stack of suspicion of the caster. (?26)

## Rogue and Bard

Stub trees from skills that exist, each with its own tab and **Calling: Freedom** beside it. (?19)
- [x] **Rogue** (`Roles/rogue.tres`; dex 15; "Tradefolk"). Starts with Strike and Move +1. Its own tab: Strike; **Blade** (martial): Wary. Calling: Freedom: centre **Hide** (tier 1 here); core **Move +1**, **Darkvision**, **Self-evaluation**, **First Aid**; **Shadow** (specialist): Meander, then Clever Disguise and Brood; **Traps** (specialist): Snare, then Hazard Expert; **Eyes** (specialist): Observe, then Eyes Forward and Special Eyes.
- [x] **Bard** (`Roles/bard.tres`; cha 15; "Tradefolk"). Starts with Strike and Meander. Its own tab: Strike; **Song** (magical): Sola, then Astera. Calling: Freedom: centre **Clever Disguise** (tier 1 here); core **Meander**, **Move +1**, **Self-evaluation**, **First Aid**; **Performance** (specialist): Tonefoolery; Glamour, then Manifest; Personify, then Embellish and Brood, then Conspire. Eyes Forward and Special Eyes are on its Freedom core.

## Paladin

- [x] **Pray** (`Skills/pray.tres`; 2 AP, 2 Energy, on itself, or for Drael on an ally within rank tiles: `Skill.on_self()`; `Battle.pray()`): by the god the unit worships (`Unit.god`, else its class's: `Role.god`, Paladin: Eros; `Unit.GODS` with domains).
  - Ramut: its side waits rank turns less for the Ire.
  - Eros: up to rank units within rank tiles that can see it, nearest first, lose a stack of suspicion of it.
  - Sol: darkness zones lose every tile within rank tiles (any side's, Luun's included).
  - Urlo: its side's units within rank tiles, nearest first (itself first), get unenchanted items enchanted, weapon then armor, rank items in all (`Unit.enchant()`): what the item becomes enchanted (`Item.enchanted_as`), else a copy at `enchant` 1. Armor: +1 Defense; a weapon: +1 damage on strength attacks (`Unit.weapon_bonus()`). There are no trinkets or item skills yet.
  - Luun: the ground within rank tiles under dark concealment 1 for rank turns, hiding only its side's units from the rest (`Zone.allied`); the ground isn't shrouded.
  - Drael: `Battle.cleanse()`: debuffs (effects that hurt their holder) lose ranks, highest first, rank ranks in all; one at 0 is gone. Ramut's Ire isn't lifted.
  - Vetruvis: every tile within rank tiles becomes its side's disturbed earth (`Battle.earthworks`) for rank of its side's turns: entering costs enemies ×1.5 (`Battle.wading()`). Drawn as a furrowed brown wash.
  - *Now:* a Paladin option, until Divinity has trees.
- [x] **Coordinate** (Idealism root · active · 1 AP · 3 Energy · on itself; `Skills/coordinate.tres`): links the caster with its teammates within its cha mod in tiles (at least 1) and its leader, wherever it is, until the end of its side's next turn. Linked, each makes out units and tiles as well as the best of them does, up to rank levels better (`Battle.read()`). *Now:* a Paladin option. (?27)
- [x] **Renew** (tier 1 active, `divine`, `wis`; Divinity): restores wis mod HP (at least 1), and the recipient gets rank AP back. Against wounds it counts rank × rank: Renew II clears wounds up to rank 4. *Now:* a Paladin option (3 AP, 2 Energy, range 2), until Divinity has a tree; also on the Adventurer's Magic root.
