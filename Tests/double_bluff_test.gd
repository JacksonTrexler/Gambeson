extends Test

# Double Bluff: a passive, embellish +rank: its stats seem other than they are (Perception).

var bluff: Skill = load("res://Skills/double_bluff.tres")


func test_double_bluff() -> void:
	v(1).learned.append(slot(bluff, 3))
	stage(lancin, {v(1): Vector2i(4, 3)})
	ok(is_equal_approx(v(1).stat(&"embellish"), 3.0), "rank III: embellish 3")
	ok(Perception.fronts(v(1)), "it puts on a front")
