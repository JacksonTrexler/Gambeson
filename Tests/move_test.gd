extends Test

# Move ?? (Skills/move.tres, Behaviours/move.gd): the stamina tag's proof. On itself, rank tiles more
# movement this turn (move AP, and past its movement stat); paid with Stamina, rank more. An Adventurer's
# Energy counts as Stamina for it (Field Experience, Everyman: a general skill counts as any kind they
# name), without the reserve or its exhaustion cut.

var move: Skill = load("res://Skills/move.tres")
var stamina: Skill = load("res://Skills/stamina.tres")
var pool: Reserve = load("res://Reserves/stamina.tres")
var field_experience: Skill = load("res://Skills/field_experience.tres")


# Movement u can make this turn beyond what it could before: move_left() after less before.
func gained(u: Unit, before: float) -> float:
	return u.move_left() - before


func test_move() -> void:
	v(1).learned.append(slot(move, 2))
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	ok(move.kinds() == [&"general"] and move.ai and move.title().ends_with("??"), "on the base General tree: general, and an AI's name")
	var before := v(1).move_left()
	ok(b.cast(v(1), move, v(1)) and v(1).energy == 9, "used on itself for 1 Energy")
	ok(is_equal_approx(gained(v(1), before), 2.0), "Move II, paid with Energy: 2 tiles more")
	ok(move.describe(2) != "" and not "STUB" in move.describe(2), move.describe(2))


func test_with_stamina() -> void:
	v(1).learned.append(slot(move, 2))
	v(1).learned.append(slot(stamina))
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	v(1).set_store(pool, v(1).pools()[pool])
	var was := v(1).store(pool)
	var before := v(1).move_left()
	ok(v(1).funding(move) is Reserve and v(1).funding(move) == pool and b.cast(v(1), move, v(1)), "paid with Stamina")
	ok(v(1).store(pool) == was - 1 and v(1).energy == 10, "1 Stamina, no Energy")
	ok(is_equal_approx(gained(v(1), before), 4.0), "Move II paid with Stamina: 2 + 2 tiles")


func test_adventurer() -> void:
	v(1).learned.append(slot(move, 1))
	v(1).learned.append(slot(field_experience))
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	var before := v(1).move_left()
	ok(not v(1).pools().has(pool) and b.cast(v(1), move, v(1)) and v(1).energy == 9, "no Stamina: Energy pays")
	ok(is_equal_approx(gained(v(1), before), 2.0), "Field Experience: its Energy counts as Stamina, so Move I gains 1 + 1")
	Exhaustion.on = true
	v(1).exhaustion.used(strike)
	ok(is_equal_approx(v(1).exhaustion.of(strike), 1.0), "but no exhaustion cut: that's the passive's")
	Exhaustion.on = false
