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
	duel(move, 2)
	ok(move.kinds() == [&"general"] and move.ai and move.title().ends_with("??"), "on the base General tree: general, and an AI's name")
	var before := v(1).move_left()
	ok(b.cast(v(1), move, v(1)) and v(1).energy == 9, "used on itself for 1 Energy")
	ok(is_equal_approx(gained(v(1), before), 2.0), "Move II, paid with Energy: 2 tiles more")
	ok(move.describe(2) != "" and not "STUB" in move.describe(2), move.describe(2))


func test_with_stamina() -> void:
	v(1).learned.append(slot(move, 2))
	duel(stamina)
	v(1).set_store(pool, v(1).pools()[pool])
	var was := v(1).store(pool)
	var before := v(1).move_left()
	ok(v(1).funding(move) is Reserve and v(1).funding(move) == pool and b.cast(v(1), move, v(1)), "paid with Stamina")
	ok(v(1).store(pool) == was - 1 and v(1).energy == 10, "1 Stamina, no Energy")
	ok(is_equal_approx(gained(v(1), before), 4.0), "Move II paid with Stamina: 2 + 2 tiles")


func test_adventurer() -> void:
	v(1).learned.append(slot(move, 1))
	duel(field_experience)
	var before := v(1).move_left()
	ok(not v(1).pools().has(pool) and b.cast(v(1), move, v(1)) and v(1).energy == 9, "no Stamina: Energy pays")
	ok(is_equal_approx(gained(v(1), before), 2.0), "Field Experience: its Energy counts as Stamina, so Move I gains 1 + 1")
	Exhaustion.on = true
	v(1).exhaustion.used(strike)
	ok(is_equal_approx(v(1).exhaustion.of(strike), 1.0), "but no exhaustion cut: that's the passive's")
	Exhaustion.on = false


# docs/plans/ai-support-2.md. The AI casts Move when its foe is out of reach on foot but within what Move adds,
# and weighs what the payment would give (Behaviour.strides(): doubled paid with Stamina) - and so strikes.
func test_ai_stretches() -> void:
	v(1).learned.append(slot(move, 1))
	var mv := int(v(1).stat(&"movement"))
	var cell := Vector2i(1, 3)
	stage(lancin, {v(1): cell, v(3): cell + Vector2i(mv + 3, 0)})  # reach 1.x: mv + 2 tiles to walk, 2 over
	v(1).refresh()
	soak(v(3), 900)
	var cast := b.cast_of(v(1), move, v(1), 1, false)
	ok(move.behaviours[0].strides(cast) == 1, "Move I paid with Energy: 1 tile")
	var log := AI.act(b, v(1))
	ok(not log.any(func(l: String): return "uses Move" in l) and v(3).hp == 900, "a tile short: it doesn't (%s)" % [log])
	duel(stamina)
	stage(lancin, {v(1): cell, v(3): cell + Vector2i(mv + 3, 0)})
	v(1).refresh()
	soak(v(3), 900)
	v(1).set_store(pool, v(1).pools()[pool])
	ok(move.behaviours[0].strides(b.cast_of(v(1), move, v(1), 1, false)) == 2, "paid with Stamina: 2")
	log = AI.act(b, v(1))
	ok(log.any(func(l: String): return "uses Move" in l) and v(3).hp < 900, "with Stamina it closes the gap and strikes (%s)" % [log])
	stage(lancin, {v(1): cell, v(3): cell + Vector2i(mv + 3, 0)})
	v(1).refresh()
	v(1).set_store(pool, v(1).pools()[pool])
	v(1).ap = [AP.new(float(mv), &"")]  # enough to cast Move, and to reach with it, but not to walk the gap and strike after
	ok(not AI.act(b, v(1)).any(func(l: String): return "uses Move" in l), "no AP to spare for the blow after it: it doesn't")
