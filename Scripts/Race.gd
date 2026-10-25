class_name Race
extends Resource

@export var name := ""
@export var size := 3  # 2 Small (Halfling), 3 Medium (Human), 4 Large (Golem)
@export var options: Array[Skill] = []  # the species' skills a unit can unlock with skill points (Halfling: Relay)
