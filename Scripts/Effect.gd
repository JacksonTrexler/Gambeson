class_name Effect
extends Resource

# Changes a unit stat. Any stat Unit.stat() knows works; the dropdown just guards typos
# (and stores names, not numbers, so reordering it can't corrupt saved skills).
# Perception stats take a kind as their tag: concealment/nullify [dark], trickery [sound], recon [trap].
# command / party: added to how far the leader's orders reach and how big its party can be.
@export_enum("luck", "mitigate", "initiative", "reach", "movement", "move_cost", "size",
		"strength", "dexterity", "constitution", "intelligence", "wisdom", "charisma",
		"recon", "concealment", "trickery", "nullify", "trap_power", "persona",
		"command", "party") var stat := "luck"
@export_enum("add", "mul") var op := "add"  # mul: multiplies the stat after everything is added
@export var amount := 1.0
@export var tags: Array[StringName] = []  # only counts for queries carrying one of these; empty: always
@export var per_stat := &""  # optional scaling: amount x floor(stat / per), e.g. charisma / 10
@export var per := 10
@export var per_rank := false  # amount x the skill's rank (Hex III: luck -3)
@export var min_rank := 0  # only from this rank of the skill up (Wary V: traps hit enemies harder)
@export var above_hp := 0.0  # only while hp is above this fraction of max (Stoneskin: 0.85)
@export var unless_on: Array[StringName] = []  # off while the unit stands on ground with these tags (Oceanic: water, wet)


# "Luck -3", "Damage taken -40% (physical), above 85% HP", at a skill rank.
func describe(rank := 1) -> String:
	var x := amount * (rank if per_rank else 1)
	var text: String
	if op == "mul":
		text = "%s x%s" % [stat.capitalize(), Skill.num(x)]
	elif stat == "mitigate":
		text = "Damage taken %s%%" % _signed(-x * 100.0)
	else:
		text = "%s %s" % [stat.capitalize(), _signed(x)]
	if per_stat:
		text += " per %d %s" % [per, per_stat]
	if not tags.is_empty():
		text += " (%s)" % ", ".join(tags)
	if above_hp > 0.0:
		text += ", above %d%% HP" % roundi(above_hp * 100.0)
	if min_rank > 0:
		text += ", from rank %s" % Skill.roman(min_rank)
	if not unless_on.is_empty():
		text += ", except on %s" % " or ".join(unless_on)
	return text


static func _signed(x: float) -> String:
	return ("+" if x > 0 else "") + Skill.num(x)
