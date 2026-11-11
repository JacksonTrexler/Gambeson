extends Test

# Flourish: a show of itself - persona of rank for rank turns, on its user alone.

var flourish: Skill = load("res://Skills/flourish.tres")


func test_flourish() -> void:
	v(1).learned.append(slot(flourish, 2))
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	var p := v(1).stat(&"persona")
	ok(b.cast(v(1), flourish, v(1)) and is_equal_approx(v(1).stat(&"persona"), p + 2.0), "rank II: persona +2 (%s)" % v(1).stat(&"persona"))
	ok(not b.cast(v(1), flourish, v(3)), "on its user alone")
	ok("persona" in flourish.describe(2).to_lower(), "it says so: %s" % flourish.describe(2))
