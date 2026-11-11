extends Test

# Blur: concealment of rank on an ally in reach (or itself), for rank turns.

var blur: Skill = load("res://Skills/blur.tres")


func test_blur() -> void:
	v(1).learned.append(slot(blur, 2))
	stage(lancin, {v(1): Vector2i(4, 3), v(2): Vector2i(5, 3)})
	ok(b.cast(v(1), blur, v(2)) and is_equal_approx(v(2).stat(&"concealment"), 2.0), "concealment 2 on the ally")
