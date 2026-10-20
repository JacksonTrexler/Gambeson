class_name Terrain
extends Resource

# One per kind of ground, stored in the TileSet's "terrain" custom data. Tiles left blank count
# as plain ground: entering costs 1 unless a terrain says otherwise.
@export var name := ""
@export var enter := 1  # movement to step onto it
@export var exit := 0  # extra movement to step off it (sticky ground)
@export var tags: Array[StringName] = []  # good / bad, rough, sticky, trap...
@export var hidden := false  # looks like plain ground (traps): luck can't see it coming


# For tie-breaks between equally near tiles: +1 good, -1 bad.
func worth() -> int:
	return int(&"good" in tags) - int(&"bad" in tags)
