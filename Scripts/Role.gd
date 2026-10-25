class_name Role
extends Resource

# A unit's class ("class" is reserved in GDScript).
@export var name := ""
@export var look: Texture2D
@export var race: Race  # default race for units created from this role (Paladin: Halfling)
@export var innate: Array[Slot] = []
@export var options: Array[Skill] = []  # the class's skills a unit can unlock with skill points
@export var stats: Dictionary[StringName, int] = {}  # starting stats for new units
