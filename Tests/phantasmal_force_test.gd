extends Test

# Phantasmal Force: a foe in reach saves (wis) or takes 1d6 + int mod from what it believes is there.

var force: Skill = load("res://Skills/phantasmal_force.tres")


func test_phantasmal_force() -> void:
	v(1).learned.append(slot(force, 1))
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	v(1).intelligence = 60
	v(3).wisdom = 1
	v(3).max_hp = 999
	v(3).hp = 999
	ok(b.cast(v(1), force, v(3)) and v(3).hp < 999, "it fails its save and takes it (%d)" % (999 - v(3).hp))
