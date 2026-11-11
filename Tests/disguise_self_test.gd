extends Test

# Disguise Self: trickery of rank on its user for 2 x rank turns, investigated by foes that see it.

var disguise: Skill = load("res://Skills/disguise_self.tres")


func test_disguise_self() -> void:
	v(1).learned.append(slot(disguise, 2))
	stage(lancin, {v(1): Vector2i(4, 3)})
	ok(b.cast(v(1), disguise, v(1)) and is_equal_approx(v(1).stat(&"trickery"), 2.0), "trickery 2")
