class_name Item
extends Resource

# Something a unit equips in one of its slots (Unit.armor, Unit.weapon).
@export var name := ""
@export_enum("armor", "weapon") var slot := "armor"
@export var tags: Array[StringName] = []  # what it is: cloth, enchanted...
@export var enchant := 0  # enchanted (Pray, to Urlo): armor +1 Defense, a weapon +1 damage to strength attacks
@export var enchanted_as: Item  # its own enchantment: enchanted, it becomes this instead of taking the +1

@export_group("Armor")  # sets its wearer's Defense (Unit.armor_defense())
@export var defense := 0  # the least it gives (Gambeson: 10)
@export var per_level := 0.0  # or the wearer's level times this, when that's higher (Gambeson: 0.5)
@export var plus_dex := false  # then adds the wearer's dex mod (Gambeson)

@export_group("Weapon")
@export var attack_stats: Array[StringName] = []  # strength attacks may use the best of these instead (Rapier: dexterity)


# "Defense: the higher of 10 and level / 2, + dex mod".
func describe() -> String:
	var plus := ", enchanted +%d" % enchant if enchant else ""
	if slot == "weapon":
		if attack_stats.is_empty():
			return "Weapon" + plus
		return "Weapon: strength attacks may use %s%s" % [" or ".join(attack_stats), plus]
	var text := "Defense: %d" % defense
	if per_level > 0.0:
		var by := "level"
		if per_level < 1.0:
			by += " / " + Skill.num(1.0 / per_level)
		elif per_level > 1.0:
			by += " x " + Skill.num(per_level)
		text = "Defense: the higher of %d and %s" % [defense, by]
	return text + (", + dex mod" if plus_dex else "") + plus


func enchanted() -> bool:
	return enchant > 0 or &"enchanted" in tags
