class_name Tier
extends Resource

# What a skill does from a given rank up. A skill uses its highest tier at or below the
# unit's rank (Hex: 1 direct damage at rank 1, d6 + mod from rank 3).
@export var rank := 1
@export var power := 0  # flat damage
@export var dice := Vector2i.ZERO  # (count, sides): Vector2i(1, 6) is d6
@export var stat := &""  # adds the caster's mod in this core stat, e.g. strength
@export var direct := false  # skips mitigation
