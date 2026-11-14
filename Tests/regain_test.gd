extends Test

# The regain Effect stat (Unit.afflict() -> Unit.regain()): AP back at once to the pool its tag names, up to
# what that pool started the turn with, and nothing stays on the unit.


func test_regain() -> void:
	stage(lancin, {v(1): Vector2i(2, 3), v(3): Vector2i(3, 3)})
	v(1).refresh()
	var start_dex: float = v(1)._ap_start[1]
	ok(start_dex >= 1.0, "it has dex AP to start (%s)" % start_dex)
	v(1).ap[1].amount = 0.0
	var move_back := effect("regain", 2.0, [&"move"])
	var a := v(1).afflict(move_back, 1, 1)
	ok(a != null and move_back not in v(1).timed, "it isn't kept")
	ok(is_equal_approx(v(1).ap[1].amount, minf(2.0, start_dex)), "dex AP back, up to what it started with (%s)" % v(1).ap[1].amount)
	var general: float = v(1).ap[0].amount
	v(1).ap[0].amount = 0.0
	v(1).afflict(effect("regain", 1.0), 1)
	ok(is_equal_approx(v(1).ap[0].amount, minf(1.0, general)), "no tag: the general pool")
	v(1).afflict(effect("regain", 99.0, [&"move"]), 1)
	ok(is_equal_approx(v(1).ap[1].amount, start_dex), "never above what it started the turn with")
	var per := effect("regain", 1.0, [&"move"])
	per.per_rank = true
	v(1).ap[1].amount = 0.0
	v(1).afflict(per, 1, 2)
	ok(is_equal_approx(v(1).ap[1].amount, minf(2.0, start_dex)), "per rank: x rank")
	ok(Effect.new().describe() != "" and per.describe(1) != "", "it describes itself: %s" % per.describe(2))
