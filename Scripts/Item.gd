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

@export_group("Armor")  # sets its wearer's Defense (Unit.armor_defense())
@export var defense := 0  # the least it gives (Gambeson: 10)
@export var per_level := 0.0  # or the wearer's level times this, when that's higher (Gambeson: 0.5)
@export var plus_dex := false  # then adds the wearer's dex mod (Gambeson)
@export var heart_defense := false  # in place of all that: level + the higher of con mod and hearts spent (Heart Up-Link)

@export_group("Weapon")
@export var attack_stats: Array[StringName] = []  # strength attacks may use the best of these instead (Rapier: dexterity)
@export var refills := 0.0  # a melee hit gives back (gross damage / the target's base stat total) x this x (1 + enchant) of its wielder's max Energy (Power) (Starblade)

@export_group("Trinket")
@export var spent_defense := false  # adds the hearts its wearer has spent to its Defense (Heart Up)


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
	if hearts or hearts_mod:
		var n := ("%d" % hearts if hearts else "") + (" + " if hearts and hearts_mod else "") + ("%s mod" % String(hearts_mod).left(3) if hearts_mod else "")
		lines.append(("Gives %s extra li%s for good" if slot == "consumable" else "%s extra li%s while worn") % [n, "fe" if n == "1" else "ves"])
	if spent_defense:
		lines.append("+1 Defense for each heart its wearer has spent")
	if requires:
		lines.append("Needs a positive %s mod" % String(requires).left(3))
	for e in effects:
		lines.append(e.describe())
	return "\n".join(lines)


func _armor() -> String:
	if heart_defense:
		return "Defense: level + the higher of con mod and hearts spent"
	var text := "Defense: %d" % defense
	if per_level > 0.0:
		var by := "level"
		if per_level < 1.0:
			by += " / " + Skill.num(1.0 / per_level)
		elif per_level > 1.0:
			by += " x " + Skill.num(per_level)
		text = "Defense: the higher of %d and %s" % [defense, by]
	return text + (", + dex mod" if plus_dex else "")


func enchanted() -> bool:
	return enchant > 0 or &"enchanted" in tags
