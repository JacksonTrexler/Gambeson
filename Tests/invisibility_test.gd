extends Test

# Invisibility: concealment 2 x rank on an ally in reach until it moves, investigated by foes that see it.

var invis: Skill = load("res://Skills/invisibility.tres")


func test_invisibility() -> void:
	v(1).learned.append(slot(invis, 2))
	stage(lancin, {v(1): Vector2i(4, 3), v(2): Vector2i(5, 3)})
	ok(b.cast(v(1), invis, v(2)) and is_equal_approx(v(2).stat(&"concealment"), 4.0), "concealment 4")
