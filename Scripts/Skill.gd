class_name Skill
extends Resource

@export var name := ""
@export var passive := false  # passives are always on and cost nothing
@export var tags: Array[StringName] = []  # e.g. physical, dark, magic, str, wis
@export var effects: Array[Effect] = []  # passives: on the holder; actives: put on the target

@export_group("Active")
@export var ap := 0.0
@export var resource := &"energy"  # what `cost` is paid in
@export var cost := 0
@export var radius := 0.0  # range before reach and size
@export var hostile := true  # targets enemies (false: allies)
@export var power := 0  # damage
@export var stat := &""  # adds the caster's mod in this stat to power, e.g. strength
@export var direct := false  # skips mitigation
