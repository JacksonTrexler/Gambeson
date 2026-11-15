extends Test

# Rules of the Effect stats that act on their own (Util/mechanic.py stats): foresight, hale, regain. What
# the plain ones move by amount x rank is swept over every skill (sweep_test).


# foresight: hazard estimates a turn on top of the int mod (HUD.foresight_allowance(); where it acts is
# tested beside the forecast: hud_test test_foresight_stat and test_forecast_fire_and_wounds).
func test_foresight() -> void:
	stage(lancin, {v(1): Vector2i(2, 3), v(3): Vector2i(3, 3)})
	ok(v(1).stat(&"foresight") == 0.0, "none by default: the allowance is the int mod alone")
	v(1).afflict(effect("foresight", 1.0), 5)
	v(1).afflict(effect("foresight", 2.0), 5)
	ok(v(1).stat(&"foresight") == 3.0, "effects add up through Unit.stat()")


# hale: above 0, every execute takes the unit to be whole - an execute's cut of its defensive check
# (Battle.executed()), Death's last stand (Battle.last_stand()) and Luun's Smite threshold all read
# execute_share(), so a hale unit at 1 HP is executed as if at full.
func test_hale() -> void:
	stage(lancin, {v(1): Vector2i(2, 3), v(3): Vector2i(3, 3)})
	var sure := Skill.new()
	sure.tags = [&"execute"]
	v(3).max_hp = 100
	v(3).hp = 10
	ok(is_equal_approx(v(3).execute_share(), 0.1) and is_equal_approx(Battle.executed(v(3), sure, 2), 0.05), "at 10% HP an execute at rank II counts 5% of its check")
	v(3).afflict(effect("hale", 1.0), 3)
	ok(is_equal_approx(v(3).execute_share(), 1.0) and is_equal_approx(Battle.executed(v(3), sure, 2), 0.5), "hale: as if at full HP, half its check at rank II")
	ok(is_equal_approx(Battle.executed(v(3), strike, 2), 1.0), "no execute, no cut")
	b.rng.seed = 7
	var whole := b.last_stand(v(3), 4)
	v(3).timed.clear()
	b.rng.seed = 7
	ok(whole > b.last_stand(v(3), 4) or whole <= 0, "its last stand against an execute is stronger hale (%d)" % whole)


# regain: AP back at once to the pool its tag names, up to what that pool started the turn with, and
# nothing stays on the unit (Unit.afflict() -> Unit.regain()).
func test_regain() -> void:
	stage(lancin, {v(1): Vector2i(2, 3), v(3): Vector2i(3, 3)})
	v(1).refresh()
	var start_dex: float = v(1)._ap_start[1]
	ok(start_dex >= 1.0, "it has dex AP to start (%s)" % start_dex)
	v(1).ap[1].amount = 0.0
	var move_back := effect("regain", 2.0, [&"dex"])
	var a := v(1).afflict(move_back, 1, 1)
	ok(a != null and move_back not in v(1).timed, "it isn't kept")
	ok(is_equal_approx(v(1).ap[1].amount, minf(2.0, start_dex)), "dex AP back, up to what it started with (%s)" % v(1).ap[1].amount)
	var general: float = v(1).ap[0].amount
	v(1).ap[0].amount = 0.0
	v(1).afflict(effect("regain", 1.0), 1)
	ok(is_equal_approx(v(1).ap[0].amount, minf(1.0, general)), "no tag: the general pool")
	v(1).afflict(effect("regain", 99.0, [&"dex"]), 1)
	ok(is_equal_approx(v(1).ap[1].amount, start_dex), "never above what it started the turn with")
	var per := effect("regain", 1.0, [&"dex"])
	per.per_rank = true
	v(1).ap[1].amount = 0.0
	v(1).afflict(per, 1, 2)
	ok(is_equal_approx(v(1).ap[1].amount, minf(2.0, start_dex)), "per rank: x rank")
	ok(Effect.new().describe() != "" and per.describe(1) != "", "it describes itself: %s" % per.describe(2))
