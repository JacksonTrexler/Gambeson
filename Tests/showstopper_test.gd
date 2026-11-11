extends Test

# Showstopper: a foe in reach saves (wis) against the caster's cha check or is Dazzled, luck -rank, for
# rank turns.

var stopper: Skill = load("res://Skills/showstopper.tres")


func test_showstopper() -> void:
	v(1).learned.append(slot(stopper, 2))
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	v(1).charisma = 60
	v(3).wisdom = 1
	var luck := v(3).luck
	ok(b.cast(v(1), stopper, v(3)) and v(3).luck == luck - 2, "it fails its save: Dazzled, luck -2 (%d -> %d)" % [luck, v(3).luck])
	ok(v(3).timed.keys().any(func(e: Effect): return e.name.begins_with("Dazzled")), "Dazzled ??, named for review")
