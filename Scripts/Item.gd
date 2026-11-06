class_name Item
extends Resource

# Something a unit equips in one of its slots (Unit.armor, Unit.weapon, Unit.trinket), or uses up
# (a consumable: Battle.use_item()). Items come from drops and scenario rewards (Battle.spoils), kept
# between battles in Game.stash.
@export var name := ""
@export_enum("armor", "weapon", "trinket", "consumable") var slot := "armor"
@export var tags: Array[StringName] = []  # what it is: cloth, enchanted...
@export var enchant := 0  # enchanted (Pray, to Urlo): armor +1 Defense, a weapon +1 damage to strength attacks
@export var enchanted_as: Item  # its own enchantment: enchanted, it becomes this instead of taking the +1
@export var effects: Array[Effect] = []  # on its wearer while it's equipped (Burning Blade: str mod to max HP)
@export var requires := &""  # it can only be worn with a positive mod in this (Heart Up-Link: constitution)
@export var hearts := 0  # extra lives: while it's worn (Heart Up), or given for good as it's used (a Heart)
@export var hearts_mod := &""  # ...plus its wearer's mod in this, while positive (Heart Up-Link: con mod)
@export var rank := 1  # how good it is: what its effects scale by (per_rank)
@export var weight := -1  # what it adds to its wearer's weight while equipped (heft()); -1: by its kind - armor by class (light 0, medium 1, heavy 2), a weapon medium (1) unless tagged light (0) or heavy (2), anything else 0
@export_enum("common", "uncommon", "rare") var rarity := "common"  # how often it turns up as a drop (Loot weights by it): mundane armor common, armor with added effects rare

@export_group("Armor")  # sets its wearer's Defense (Unit.armor_defense())
@export var defense := 0  # the least it gives (Gambeson: 10)
@export var per_level := 0.0  # or the wearer's level times this, when that's higher (Gambeson: 0.5)
@export var dex_share := 0.0  # then adds the wearer's dex x this, luck-rounded (Half Plate: dex / 4)
@export var plus_dex := false  # then adds the wearer's dex mod; armor setting none of these, and of no weight, leaves Defense unarmored (Heart Up-Link)
@export var full_dex := false  # heavy armor that takes its wearer's whole dex mod all the same (Aethendine)
@export var no_dex := false  # weighted armor that adds no dex mod to Defense at all (Robe: cloth)
@export var mind_stat := &""  # ...adds its wearer's mod in this as magical Defense instead (Robe: wisdom)
@export var eases := &""  # the heavy-armor AP drag it lifts from a wearer strong enough: dexterity (with con: Aethendine) or wisdom (with str: Ignauldron) (Unit.armor_drag())
@export var heat := 0  # fire it deals its wearer as each of its turns starts, x rank (Ignauldron)

@export_group("Weapon")
@export var damage_tag := &""  # what its blows deal, for skills that take it (Strike): slash, pierce, blunt (Skill.weapon_tag)
@export var attack_stats: Array[StringName] = []  # strength attacks may use the best of these instead (Rapier: dexterity)
@export var refills := 0.0  # a melee hit gives back (gross damage / the target's base stat total) x this x (1 + enchant) of its wielder's max Energy (Power) (Starblade)

@export_group("Trinket")
@export var spent_defense := false  # adds the hearts its wearer has spent to its Defense (Heart Up)
@export var revives := 0.0  # a life once a battle: falling, its wearer gets up with this x rank of its max HP - past 100%, more than full - and Resurrection Sickness for rank turns (Red Spinel Ring; Battle._revive())
@export var restores := &""  # used up from its slot, it gives back hp, energy or reserve (its `reserve`)... (potions; Battle.use_item())
@export var reserve: Reserve  # ...this one (Mana Potion: mana; Sweet Something: Sweet Nothings)
@export var restore_share := 0.0  # ...this x rank of its max (potions: 15%)...
@export var restore_mod := &""  # ...plus the user's mod in this (potions: constitution)...
@export var restore_flat := 0  # ...plus this (Sweet Something: 1)
@export var burning := false  # its wearer burns for 10% x rank of its max HP (fire) as its turns start, and again each time it uses a skill in the slots it grants (Burning Bag; Unit.burning_slots())
@export var empty := false  # used: a potion is emptied rather than used up, and fills again as the battle ends (Battle.refill())
@export var binding := false  # put on a unit against its will (Shackles: Skill.binds): it can't be taken off for free or swapped out; while Shackled it's locked, after that taking it off costs its rank in AP (Battle.unshackle())
@export var picks := &""  # it can be lockpicked off: a dex check at this difficulty, at its rank (Shackles: approachable)
@export var prised := &""  # it can be pried apart: a str check at this difficulty, at its rank (Shackles: unfair - built not to break)

# Armor by weight (its tag: light, medium, heavy) shares its basic piece's scaling: Defense the higher of
# a floor and level x a share, + dex mod x a share (Unit.armor_defense()). Heavy armor also drags at
# its wearer's dex and wis AP (Unit.armor_drag()).
const WEIGHTS := {
	&"light": [10, 0.5, 1.0],  # Gambeson: low level scaling, high dex scaling
	&"medium": [12, 0.75, 0.5],  # Habergeon: balanced
	&"heavy": [14, 1.0, 0.25],  # Brigandine: high level scaling, low dex scaling
}
const ARMOR_AP := 10  # armor takes this - its wearer's dex mod in AP to put on in battle: hardly worth it mid-fight
const RARITY_WEIGHT := {"common": 1.0, "uncommon": 0.4, "rare": 0.15}  # a drop table's relative pull, before its own weights


# "Defense: the higher of 10 and level / 2, + dex mod".
func describe() -> String:
	var plus := ", enchanted +%d" % enchant if enchant else ""
	var lines: PackedStringArray = []
	match slot:
		"weapon":
			lines.append("Weapon" + (": strength attacks may use %s" % " or ".join(attack_stats) if not attack_stats.is_empty() else "") + plus)
			if refills > 0.0:
				lines.append("A melee hit gives back Power: damage / the target's base stats x %s of max" % Skill.num(refills * (1 + enchant)))
		"armor":
			lines.append(_armor() + plus)
		"trinket":
			lines.append("Trinket" + plus)
		"consumable":
			lines.append("Used up")
	if restores:
		lines.append(("Empty: it fills again as the battle ends" if empty else "Used from its slot: gives back %s; emptied, it fills again as the battle ends" % restoring()))
	if hearts or hearts_mod:
		var n := ("%d" % hearts if hearts else "") + (" + " if hearts and hearts_mod else "") + ("%s mod" % String(hearts_mod).left(3) if hearts_mod else "")
		lines.append(("Gives %s extra li%s for good" if slot == "consumable" else "%s extra li%s while worn") % [n, "fe" if n == "1" else "ves"])
	if spent_defense:
		lines.append("+1 Defense for each heart its wearer has spent")
	if revives > 0.0:
		lines.append("Once a battle, falling: gets up at %d%% of max HP, with Resurrection Sickness for %d turn%s (-10%% HP as each turn starts, gone if one starts at full HP)"
				% [roundi(revives * rank * 100.0), rank, "" if rank == 1 else "s"])
	if damage_tag:
		lines.append("Deals %s blows" % damage_tag)
	if binding:
		lines.append("Bound on: locked while Shackled; unlocked, taking it off takes %d AP" % rank)
		if picks:
			lines.append("Lockpicked off: a %s dex check (DC %d)" % [Glossary.name_of(picks).to_lower(), Difficulty.dc(picks, rank)])
		if prised:
			lines.append("Pried apart: a %s str check (DC %d)" % [Glossary.name_of(prised).to_lower(), Difficulty.dc(prised, rank)])
		lines.append("Weight %d" % heft())
	if burning:
		lines.append("Burns its wearer for %d%% of max HP as its turns start, and again for each skill used from the slots it grants" % (10 * rank))
	if requires:
		lines.append("Needs a positive %s mod" % String(requires).left(3))
	for e in effects:
		lines.append(e.describe(rank))
	lines.append(("%d - dex mod AP to put on in battle" % ARMOR_AP) if slot == "armor" else "%s AP to put on or use in battle" % Skill.num(ap_cost()))
	return "\n".join(lines)


# AP it takes in battle to put on (or use, for a trinket or a consumable): a trinket or a consumable 1;
# a weapon 2, 3 if heavy; armor ARMOR_AP - its wearer's dex mod, at least 1. Taking anything off is
# free.
func ap_cost(u: Unit = null) -> float:
	match slot:
		"armor":
			return float(maxi(ARMOR_AP - (u.mod(&"dexterity") if u else 0), 1))
		"weapon":
			return 3.0 if &"heavy" in tags else 2.0
	return 1.0


# "15% x rank of max HP + con mod", "1 Sweet Nothing".
func restoring() -> String:
	var what: String = reserve.name if restores == &"reserve" and reserve else ("HP" if restores == &"hp" else String(restores).capitalize())
	var parts: PackedStringArray = []
	if restore_share > 0.0:
		parts.append("%s%% x %d of max %s" % [Skill.num(restore_share * 100.0), rank, what])
	if restore_mod:
		parts.append("%s mod" % String(restore_mod).left(3))
	if restore_flat:
		parts.append("%d %s" % [restore_flat, what])
	return " + ".join(parts)


# Copies of itself emptied (used) and filled again: a potion's own state, not every potion's.
func emptied() -> Item:
	var it: Item = duplicate()
	it.empty = true
	return it


func filled() -> Item:
	var it: Item = duplicate()
	it.empty = false
	return it


# Sets its wearer's Defense (armor): it has a floor or a level rule. One that doesn't (Heart Up-Link)
# leaves Defense as if unarmored.
const HEFT := {&"light": 0, &"medium": 1, &"heavy": 2}  # weight by class (heft())


# What it adds to its wearer's weight while equipped (Unit.weight()): its own weight if it has one,
# else by its kind - armor and weapons by their class (a weapon is medium unless tagged otherwise).
func heft() -> int:
	if weight >= 0:
		return weight
	match slot:
		"armor":
			return HEFT.get(weight_class(), 0)
		"weapon":
			return HEFT.get(weight_class(), HEFT[&"medium"])
	return 0


# How much a drop table leans toward it, by rarity (Loot.weight()).
func rarity_pull() -> float:
	return RARITY_WEIGHT.get(rarity, 1.0)


func sets_defense() -> bool:
	return weight_class() != &"" or defense > 0 or per_level > 0.0


# Its weight, by tag: light, medium, heavy, or none (armor of its own sort: Heart Up-Link).
func weight_class() -> StringName:
	for w in [&"heavy", &"medium", &"light"]:
		if w in tags:
			return w
	return &""


func _armor() -> String:
	if not sets_defense():
		return "Armor: Defense as if unarmored (dex mod + con mod)"
	var w := weight_class()
	if w:
		var base: Array = WEIGHTS[w]
		var lv := "level" if base[1] == 1.0 else ("level / %s" % Skill.num(1.0 / base[1]) if base[1] <= 0.5 else "level x %s" % Skill.num(base[1]))
		var dex := "no dex mod" if no_dex else ("dex mod" if full_dex or base[2] == 1.0 else "dex mod / %s" % Skill.num(1.0 / base[2]))
		var text := "%s armor: Defense the higher of %d and %s, + %s" % [String(w).capitalize(), base[0], lv, dex]
		if mind_stat:
			text += ", and %s mod as magical Defense" % String(mind_stat).left(3)
		if w == &"heavy":
			text += "\nHeavy: %s" % ("costs dex AP (less with con: none at con mod 2+ for this one) and wis AP (less with str)" if eases == &"dexterity"
					else "costs dex AP (less with con) and wis AP (less with str: none at str mod 2+ for this one)" if eases == &"wisdom"
					else "costs dex AP (less with con) and wis AP (less with str)")
		if heat:
			text += "\nBurns its wearer for %d as each of its turns starts" % (heat * rank)
		return text
	var text := "Defense: %d" % defense
	if per_level > 0.0:
		var by := "level"
		if per_level < 1.0:
			by += " / " + Skill.num(1.0 / per_level)
		elif per_level > 1.0:
			by += " x " + Skill.num(per_level)
		text = "Defense: the higher of %d and %s" % [defense, by]
	return text + (", + dex mod" if plus_dex else "") + (", + dex / %s" % Skill.num(1.0 / dex_share) if dex_share > 0.0 else "")


func enchanted() -> bool:
	return enchant > 0 or &"enchanted" in tags
