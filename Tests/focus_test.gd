extends Test

# Focus (Skills/focus.tres). STUB(skill.py): what it does, and what these tests pin down.

var focus: Skill = load("res://Skills/focus.tres")


func test_focus() -> void:
	v(1).learned.append(slot(focus, 2))
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	ok(focus.describe(2) != "", "STUB(skill.py): it says what it does: %s" % focus.describe(2))
