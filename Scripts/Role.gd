class_name Role
extends Resource

# A unit's class ("class" is reserved in GDScript).
@export var name := ""
@export var look: Texture2D
@export var race: Race  # default race for units created from this role (Paladin: Halfling)
@export var innate: Array[Slot] = []
@export var stats: Dictionary[StringName, int] = {}  # starting stats for new units
