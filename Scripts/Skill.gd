class_name Skill
extends Resource

# ACTIVE: chosen on the unit's turn and paid for with EP. PASSIVE: always on, no cost.
enum Kind { ACTIVE, PASSIVE }

@export var name := ""
@export var kind := Kind.ACTIVE
@export var tags: Array[StringName] = []  # e.g. dark, magic, wis
@export var effects: Array[Effect] = []  # passives: always on the holder; actives: put on the target

@export_group("Active")
@export var cost := 0  # EP
@export var radius := 0.0  # circle, in tiles between cell centres
@export var hostile := true  # targets enemies (false: allies)
@export var damage := 0  # direct: skips mitigation
