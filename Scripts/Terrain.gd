class_name Terrain
extends Resource

# One per kind of ground, stored in the TileSet's "terrain" custom data. Tiles left blank count
# as plain ground: entering costs 1 unless a terrain says otherwise.
@export var name := ""
@export var enter := 1  # movement to step onto it
@export var exit := 0  # extra movement to step off it (sticky ground)
@export var tags: Array[StringName] = []  # beneficial / detrimental, rough, sticky, trap, water, wet...

@export_group("Concealment")  # traps: what it really is hides behind levels of concealment
@export var concealment := 0
@export var kind := &""  # concealment kind ("" plain sight, dark, light, sound)
@export var looks_like := &""  # what the unaware see it as (Grass)
@export var shape := ""  # the hint at concealment 2: "disturbed earth?"
@export var vibe := ""  # the hint at concealment 3: "a prickle of unease"

@export_group("Effects")
@export var effects: Array[Effect] = []  # on whoever stands here (Shrine: Heal, regen 0.1)
@export var afflicts: Array[Effect] = []  # put on whoever steps here, for `turns` of their turns (Poison)
@export var turns := 0

@export_group("Trap")  # sprung when a unit steps on it
@export var dice := Vector2i.ZERO  # damage
@export var damage_tags: Array[StringName] = []  # trap, pierce...
@export var blast := 0.0  # hits every unit within this radius, not just the one who stepped on it


func is_trap() -> bool:
	return dice != Vector2i.ZERO


# +1 explicitly beneficial, -1 explicitly detrimental (by tag). Most ground is neutral, even with
# minor effects either way (bramble's sticky exit, a conveyor's push). Tie-breaks between equally
# near tiles use it, and it's what tiers of perception reveal as good or bad ground.
func worth() -> int:
	return int(&"beneficial" in tags) - int(&"detrimental" in tags)
