extends Test

# Sutemi (Skills/sutemi.tres, Behaviours/sutemi.gd): lunges up to rank tiles to beside a foe, then
# 1d10 + str; Off Balance: -1 Defense a tile lunged, through its next turn.

var sutemi: Skill = load("res://Skills/sutemi.tres")


func lunger(r := 2) -> void:
	v(1).learned.append(slot(sutemi, r))
	v(1).strength = 40
	stage(lancin, {v(1): Vector2i(2, 3), v(3): Vector2i(5, 3)})
	v(1).refresh()
	v(3).max_hp = 300
	v(3).hp = 300


func test_lunge() -> void:
	lunger()
	var d := v(1).defense()
	var moved := v(1).moved
	ok(b.cast(v(1), sutemi, v(3)), "used from 3 tiles at rank II")
	ok(v(1).cell == Vector2i(4, 3), "lunged to beside it (%s)" % v(1).cell)
	ok(v(3).hp < 300, "and struck")
	ok(v(1).defense() == d - 2 and is_equal_approx(v(1).moved, moved), "Off Balance: -2 Defense for 2 tiles, no movement spent")
	b.end_turn()
	ok(v(1).defense() == d - 2, "through the foe's turn")
	b.end_turn()
	b.end_turn()
	ok(v(1).defense() == d, "gone once its next turn is over")


func test_blocked() -> void:
	lunger()
	stage(lancin, {v(1): Vector2i(2, 3), v(3): Vector2i(5, 3), v(4): Vector2i(3, 3)})
	ok(not b.cast(v(1), sutemi, v(3)), "something in the way: it can't")
	lunger(1)
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	var d := v(1).defense()
	ok(b.cast(v(1), sutemi, v(3)) and v(1).defense() == d, "already beside it: no lunge, no Off Balance")
	ok(not sutemi.ai and "Off Balance" in sutemi.describe(2), sutemi.describe(2))
