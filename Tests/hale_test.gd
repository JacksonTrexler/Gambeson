extends Test

# The hale Effect stat (Unit.execute_share()): above 0, every execute takes the unit to be whole - an
# execute's cut of its defensive check (Battle.executed()), Death's last stand (Battle.last_stand()) and
# Luun's Smite threshold all read execute_share(), so a hale unit at 1 HP is executed as if at full.


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
