class_name Slot
extends Resource

# A skill as a particular unit has it: its rank, and whether a toggled passive is on.
@export var skill: Skill
@export var rank := 1
@export var points := -1  # skill points put into it; -1: what its rank is worth on the even curve (Unit.points_in(), Unit.worth())
@export var on := true
