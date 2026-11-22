extends Test

# Word of suspicion (Battle.spread()): a unit that grows suspicious of an enemy tells each ally within
# WORD + its cha mod tiles that's awake and doesn't suspect it yet; each told grows a stack itself, and
# doesn't pass it on.

func siren() -> Unit:
	return b.get_node("Units/Siren")


func test_spreads() -> void:
	stage(nemes, {siren(): Vector2i(8, 6), v(1): Vector2i(5, 6), v(2): Vector2i(5, 4)})
	var heard := []
	b.told.connect(func(by: Unit, to: Unit, of: Unit, ok_: bool): heard.append([by, to, of, ok_]))
	b.suspect(v(1), siren())
	ok(v(2).suspects(siren()) == 1, "an ally near grows suspicious too")
	ok(heard == [[v(1), v(2), siren(), true]], "told, and it got through: %s" % [heard])
	b.suspect(v(1), siren())
	ok(v(2).suspects(siren()) == 1, "already suspicious: not told again")


func test_reach() -> void:
	var reach := Battle.WORD + v(1).mod(&"charisma")
	stage(nemes, {siren(): Vector2i(8, 6), v(1): Vector2i(1, 1), v(2): Vector2i(1 + reach + 1, 1)})
	b.suspect(v(1), siren())
	ok(v(2).suspects(siren()) == 0, "out of earshot (%d tiles): not told" % reach)


func test_asleep_and_told_dont_pass_on() -> void:
	stage(nemes, {siren(): Vector2i(8, 6), v(1): Vector2i(1, 1), v(2): Vector2i(3, 1), v(4): Vector2i(9, 1)})
	var alabaster: Unit = b.get_node("Units/Alabaster")
	b.move(alabaster, Vector2i(6, 1))  # in v(2)'s earshot, not v(1)'s
	alabaster.suspicion.clear()
	b.suspect(v(1), siren())
	ok(v(2).suspects(siren()) == 1 and alabaster.suspects(siren()) == 0, "the told don't pass it on")
	v(2).suspicion.clear()
	v(2).afflict(effect("sleep", 1), 3)
	v(1).suspicion.clear()
	b.suspect(v(1), siren())
	ok(not v(2).asleep() or v(2).suspects(siren()) == 0, "asleep: it hears nothing")


func test_allies_not_spread() -> void:
	stage(lancin, {v(1): Vector2i(1, 1), v(2): Vector2i(2, 1)})
	b.suspect(v(1), v(2))
	ok(v(2).suspects(v(2)) == 0 and v(1).suspects(v(2)) == 1, "suspicion of an ally stays its own")
