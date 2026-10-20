class_name AP
extends RefCounted

# One pool of action points. `only` limits what it can pay for (&"move", &"skill");
# empty pays for anything. A unit's AP is a list of these, refilled each turn.
var amount: float
var only: StringName


func _init(a: float, o := &"") -> void:
	amount = a
	only = o
