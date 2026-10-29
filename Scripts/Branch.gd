class_name Branch
extends Resource

# A skill's place on a skill tree root (SkillRoot): what a unit must learn before it can learn it.
@export var skill: Skill
@export var after: Array[Skill] = []  # every one of these first (Hazard Expert: Snare); none: open from the start
@export var needs := 0  # and this many of the root's other skills (capstones: 3)
