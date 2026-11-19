# Power Armor and Scrap Plating: armor slots a skill gives (w3-armor, 2026-11-19)

The user's words (answers-2026-11-18b, item 8): "Power Armor (martial protection prowess, caster abjuration, astral capstone): unit gets an
additional armor slot. It stays enabled as long as the unit has 100% - (rank * 10%) power. Attacks blocked by this added armor deal
damage to power, divided by rank." / "Scrap Plating (martial protection prowess, specialist smith t5 skill): Gain an armor slot. Armor
equipped to this slot only confers up to rank defense. Armor AP penalty stacks additively (harder to overcome, additional armor applies
full penalty)." Names are the user's (`--human`, no ??).
Baseline suite: 9918 checks, 0 failed (945 tests).

## Readings and calls

1. **A generic slot read, on the behaviour.** `Behaviour.armor_slot()` says a passive gives its holder an armor slot; three more hooks
   are the slot's rules, each defaulting to a plain slot: `slot_works(holder, rank)`, `slot_defense(holder, rank, defense)`,
   `slot_blocked(battle, holder, rank, power)`. Unit reads them for any skill: `plate_skills()`, `plates()`, `plated_defense()`. No
   Skill.gd flag, no item or skill special case in Unit/Battle. Future "extra armor slot" skills are one behaviour.
2. **Slots are named for the skill.** `plate_<skill id>` (`Unit.plate_slot()`), held in `Unit.plating`. Unit's `_get`/`_set` answer those
   names, so the sheet, `Game.outfit`, the save, `Battle.equip/unequip` and `u.get(slot)` treat it as any slot (weapon, armor, trinket).
   `Unit.equip(item, slot)` and `Battle.equip(u, item, slot)` take an optional slot; the sheet's `equipped` signal gains a slot argument
   (`""`: the item's own). Only armor goes in, and only in a slot the unit has. Call: a skill gives one slot, a unit with both skills
   has two, and a unit may learn neither (nothing changes for any unit that has no plating: `plating.is_empty()` short-circuits).
3. **A slot that is off keeps its armor.** An unlearned, disabled, off-the-bar or (Power Armor) underpowered slot confers nothing but
   the armor stays worn in it; an unlearned skill's slot isn't on the sheet, but the item stays in `Game.outfit` (a starter re-learns
   its skills each battle) rather than vanishing.
4. **Armor in a slot confers its Defense, its AP drag and its weight, and nothing else.** Not its other effects, enchant, lent skills, `mind_stat` (Robe) or Bracing: it is
   not in `Unit.items()`. That keeps the slot out of the lent-skill cycle (granted() -> items()) and is what "confers up to rank
   defense" reads as. Its Defense is what the equipment skills it lends set (`_set_by(item)`, the old `armor_defense()` loop), so
   the Armor skill's table (dex mod included) applies to it as to the armor proper. Call: the Defense of armor proper and the slots
   **add**, whole (a plate in the slot of Power Armor is 11 + the plate's own, dex mod twice); the user did not say otherwise, and the
   caps and power gating are what balance it.
5. **Drag stacks additively, in full.** `armor_drag(pool)` is each worn armor's drag worked out alone (`_drag_of`) and summed, for
   every extra slot, so Scrap Plating's Defense cap never caps its drag ("additional armor applies full penalty"). Call: this is the generic rule for any armor in a slot,
   Power Armor's too (the user wrote it under Scrap Plating only). `weight()` adds the slot's heft the same way.
6. **Power is the Energy it runs on.** `Unit.power_share()` = Energy / max Energy, or the reserve it runs on (`runs_on()`: Mana,
   Stamina) over its pool: Power Armor works while that is at least 100% - 10% x rank (rank 5: half). Call: not only `powered()`
   (Powerful) units; every unit has Energy, which spends and comes back, so the armor goes on and off with it. Max rank 5 (my pick).
7. **"Blocked by the added armor."** A missed attack whose roll would have hit against Defense less that slot's own contribution
   (`Battle.roll_attack()` -> `_plate_blocks()`, checked with `Check.outcome` on the same faces, so advantage, glancing and guard all
   count). Each slot that made the difference blocked it; its `slot_blocked()` runs. Power Armor takes `ceil(damage / rank)` off Power
   (`Unit.sap_power()`). Damage = the blow's: the attacking skill's tier at its caster's rank (power + dice + stat mod, x damage
   stat), the figure a hit would have rolled (an attack with no skill in a use does none). Extra RNG is spent only when a plated unit
   is missed. Call: the damage is estimated at the miss (a hit's real damage is never rolled on a miss); multi-hit skills count
   per roll; Power Armor's rank is its learned rank (`own_rank`).
8. **Trees.** Power Armor: Protector (after Snapping Turtle: the prowess shared by Fighter and Paladin), Astral (a capstone: `needs = 3`
   like Protector's slot capstone), and a new **Abjuration** (caster, `role.py tree abjuration --human`). Scrap Plating: Protector (after
   Turtle Tactics) and a new **Smith** (specialist, `role.py tree smith --human`), its branch at `tier = 5`. Both stubbed trees hold
   the one skill and are **not on any class tab yet**: Abjuration is for a Mage school (the Mage is Student's sibling's ground) and Smith
   for a Specialist flex tree like Student; neither is offered until the caller picks where. Tags `martial, defensive` on both skills
   (they sit in a martial prowess; the same skill serves all trees).
9. **UI.** The sheet gets a row per slot ("Scrap Plating: Plate") and, for armor in the stash, one more button per slot; the unit's
   Defense line lists the armor in the working slots ("22 · Gambeson + Plate"). Not done: the unit card's equipment trims (`HUD.trims`) only show the three item slots.

## Tests

`Tests/plating_test.gd` (new, 4 tests, ~50 checks): the slot table (Power Armor ranks 1, 3, 5 at the Energy edges, Scrap Plating's cap,
off by disabled / off the bar / unlearned, both skills, armor alone); drag and weight stack, off with the slot; blocks (by hand at the
edges, and through real casts); the sheet, outfit and save. Mutation spot-checks, each failing it then reverted: Scrap cap removed (5
fail), drag not stacked (2), blocks ignore the slot's Defense (2), Power threshold off by one (3), no division by rank (2).
No existing test changed. `Tests/sweep_test.gd` casts or applies both skills as it does every skill.

## As built

Files: Scripts/Behaviour.gd (4 hooks), Scripts/Unit.gd (`plating`, `PLATE`, `plate_skills/slots/slot/label`, `_get/_set`, `plates`,
`plated_defense`, `power_share`, `sap_power`, `armor_defense`, `_set_by`, `armor_skills(item)`, `armor_drag`, `_drag_of`, `weight`, `equip(it, to)`),
Scripts/Battle.gd (`roll_attack`, `_plate_blocks`, `equip(u, it, slot)`), Scripts/CharacterSheet.gd, Scripts/HUD.gd, Scripts/Save.gd,
Behaviours/power_armor.gd, Behaviours/scrap_plating.gd, Skills/power_armor.tres, Skills/scrap_plating.tres, Icons/Skills (2), Trees/protector.tres,
Trees/astral.tres, Trees/abjuration.tres (new), Trees/smith.tres (new), Util/skill.py (hook names), Tests/plating_test.gd.
The skills' second and third tree placements were written by hand (no tool adds a made skill to another tree); `skill.py check` and
`role.py check` pass.
Not done: Abjuration and Smith aren't on a class tab; Robe's magical Defense, Bracing and item effects ignore the slots (call 4); the AI never equips or
weighs plating; the unit card's trims; `lapsed()` (a leaned skill's prerequisites) is not read by `plates()`.
