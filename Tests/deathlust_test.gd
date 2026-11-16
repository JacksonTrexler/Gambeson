extends Test

# Deathlust (Skills/deathlust.tres). STUB(skill.py): what it does, and what these tests pin down.

var deathlust: Skill = load("res://Skills/deathlust.tres")


func test_deathlust() -> void:
	v(1).learned.append(slot(deathlust, 2))
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	ok(deathlust.describe(2) != "", "STUB(skill.py): it says what it does: %s" % deathlust.describe(2))
