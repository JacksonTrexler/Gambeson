class_name Effect
extends Resource

# Changes a unit stat. Any stat Unit.stat() knows works; the dropdown just guards typos
# (and stores names, not numbers, so reordering it can't corrupt saved skills).
@export_enum("luck", "mitigate", "initiative", "reach", "movement", "move_cost", "size",
		"strength", "dexterity", "constitution", "intelligence", "wisdom", "charisma") var stat := "luck"
@export_enum("add", "mul") var op := "add"  # mul: multiplies the stat after everything is added
@export var amount := 1.0
@export var tags: Array[StringName] = []  # only counts for queries carrying one of these; empty: always
@export var per_stat := &""  # optional scaling: amount x floor(stat / per), e.g. charisma / 10
@export var per := 10
@export var per_rank := false  # amount x the skill's rank (Hex III: luck -3)
@export var above_hp := 0.0  # only while hp is above this fraction of max (Stoneskin: 0.85)
