class_name Skill
extends Resource

# ACTIVE: chosen on the unit's turn and paid for with EP. PASSIVE: always on, no cost.
enum Kind { ACTIVE, PASSIVE }

@export var name := ""
@export var kind := Kind.ACTIVE
@export var cost := 0  # EP, actives only
