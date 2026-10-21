class_name Terrain
extends Resource

# One per kind of ground, stored in the TileSet's "terrain" custom data. Tiles left blank count
# as plain ground: entering costs 1 unless a terrain says otherwise.
@export var name := ""
@export var enter := 1  # movement to step onto it
@export var exit := 0  # extra movement to step off it (sticky ground)
@export var tags: Array[StringName] = []  # good / bad, rough, sticky, trap, water, wet...

@export_group("Concealment")  # traps: what it really is hides behind levels of concealment
@export var concealment := 0
@export var kind := &""  # concealment kind ("" plain sight, dark, light, sound)
@export var looks_like := &""  # what the unaware see it as (Grass)
@export var shape := ""  # the hint at concealment 2: "disturbed earth?"
@export var vibe := ""  # the hint at concealment 3: "a prickle of unease"

@export_group("Trap")  # sprung when a unit steps on it
@export var dice := Vector2i.ZERO  # damage
@export var damage_tags: Array[StringName] = []  # trap, pierce...
@export var blast := 0.0  # hits every unit within this radius, not just the one who stepped on it


func is_trap() -> bool:
	return dice != Vector2i.ZERO


# For tie-breaks between equally near tiles: +1 good, -1 bad.
func worth() -> int:
	return int(&"good" in tags) - int(&"bad" in tags)
