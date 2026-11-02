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
@export var rank := 1  # how good it is: what its effects scale by (per_rank), and AP to put on, take off or use in battle (ap_cost())

@export_group("Armor")  # sets its wearer's Defense (Unit.armor_defense())
@export var defense := 0  # the least it gives (Gambeson: 10)
@export var per_level := 0.0  # or the wearer's level times this, when that's higher (Gambeson: 0.5)
@export var dex_share := 0.0  # then adds the wearer's dex x this, luck-rounded (Half Plate: dex / 4)
@export var plus_dex := false  # then adds the wearer's dex mod (Gambeson); armor setting none of these leaves Defense unarmored (Heart Up-Link)

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
@export var empty := false  # used: a potion is emptied rather than used up, and fills again as the battle ends (Battle.refill())

const WEIGHTS := {&"medium": 2, &"heavy": 3}  # AP to change it in battle: rank x this (light: x1)


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
	if requires:
		lines.append("Needs a positive %s mod" % String(requires).left(3))
	for e in effects:
		lines.append(e.describe(rank))
	lines.append("%s AP to put on or use in battle%s" % [Skill.num(ap_cost()), "" if weight() == 1 else " (%s: rank x %d)" % [weight_name(), weight()]])
	return "\n".join(lines)


# AP it takes in battle to put it on, take it off or use it: its rank, x2 tagged medium, x3 heavy.
func ap_cost() -> float:
	return float(rank * weight())


func weight() -> int:
	for t in tags:
		if t in WEIGHTS:
			return WEIGHTS[t]
	return 1


func weight_name() -> String:
	for t in tags:
		if t in WEIGHTS:
			return String(t)
	return "light"


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
func sets_defense() -> bool:
	return defense > 0 or per_level > 0.0


func _armor() -> String:
	if not sets_defense():
		return "Armor: Defense as if unarmored (dex mod + con mod)"
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
