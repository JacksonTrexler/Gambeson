extends Test

# Hitch (Skills/hitch.tres, Behaviours/hitch.gd): 1d4 + str; a hit grapples (str + rank contest); won,
# the caster's moves this turn tow the foe rank tiles the same way (tow); the grip ends with its turn.

var hitch: Skill = load("res://Skills/hitch.tres")


func test_tow() -> void:
	v(1).learned.append(slot(hitch, 2))
	v(1).strength = 60
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	v(1).refresh()
	v(3).max_hp = 300
	v(3).hp = 300
	v(3).strength = 1
	v(3).dexterity = 1
	ok(b.cast(v(1), hitch, v(3)), "used")
	var a := b.held_by(v(3))
	ok(a != null and a.by == v(1) and is_equal_approx(v(3).stat(&"tow"), 2.0), "held, tow 2")
	b.travel(v(1), Vector2i(4, 5))
	ok(v(1).cell == Vector2i(4, 5) and v(3).cell == Vector2i(5, 5), "towed 2 tiles the same way (%s)" % v(3).cell)
	b.end_turn()
	ok(b.held_by(v(3)) == null, "let go as its turn ends")
	ok(not hitch.ai and "tow" in hitch.describe(2), hitch.describe(2))
