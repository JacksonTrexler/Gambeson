extends Test

# Deathlust (Skills/deathlust.tres) and the two generic hooks it stands on (docs/plans/r-deathlust.md):
# Behaviour.neutralized() (a unit taken out of the fight, anywhere, told to every other unit's passives)
# and Behaviour.wearing() (the exhaustion a paid use adds, settled once its cast is over, which a passive
# may lower), with Exhaustion.relieve() the one way a count comes off.

var deathlust: Skill = load("res://Skills/deathlust.tres")


# v(1) holds Deathlust at rank r, with 2 uses of Strike counted against it, stood at (4, 3).
func lusty(r: int, placed := {}) -> float:
	v(1).learned.append(slot(deathlust, r))
	var p := {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)}
	p.merge(placed)
	stage(lancin, p)
	Exhaustion.on = true
	soak(v(3), 100)
	v(1).exhaustion.uses[strike] = 2.0
	return 2.0


func uses(u: Unit) -> float:
	return u.exhaustion.uses.get(strike, 0.0)


func test_deaths_in_range() -> void:
	lusty(1, {v(2): Vector2i(3, 3), v(4): Vector2i(8, 3)})
	b.neutralize(v(4), &"killed")
	ok(is_equal_approx(uses(v(1)), 2.0), "a death 4 tiles off, past rank 1's 2: nothing")
	b.neutralize(v(3), &"killed")
	ok(is_equal_approx(uses(v(1)), 1.75), "a foe killed beside it: a quarter of a use off (%s)" % uses(v(1)))
	b.neutralize(v(2), &"killed")
	ok(is_equal_approx(uses(v(1)), 1.5), "an ally killed, either side counts (%s)" % uses(v(1)))
	b.neutralize(v(3), &"downed")
	b.neutralize(v(3), &"down")
	ok(is_equal_approx(uses(v(1)), 1.5), "downed, or Downed, doesn't")
	b.neutralize(v(1), &"killed")
	ok(is_equal_approx(uses(v(1)), 1.5), "nor its own death")
	v(1).learned.clear()
	v(1).learned.append(slot(deathlust, 2))
	b.neutralize(v(4), &"killed")
	ok(is_equal_approx(uses(v(1)), 1.0), "rank 2: reach 4 tiles, eases half a use (%s)" % uses(v(1)))
	v(1).exhaustion.uses[sk("hex")] = 0.2
	b.neutralize(v(3), &"killed")
	ok(not sk("hex") in v(1).exhaustion.uses and is_equal_approx(uses(v(1)), 0.5), "every skill's count, none below nothing")


func test_kill_skips_exhaustion() -> void:
	lusty(1)
	v(1).exhaustion.uses.clear()
	v(3).hearts = 1
	v(3).hp = 1
	v(1).refresh()
	ok(b.cast(v(1), strike, v(3)) and v(3).reviving, "a Strike that only downs")
	ok(is_equal_approx(uses(v(1)), 1.0), "gains its use as ever (%s)" % uses(v(1)))
	lusty(1, {v(4): Vector2i(4, 4)})
	v(1).exhaustion.uses.clear()
	v(4).hp = 1
	v(1).refresh()
	ok(b.cast(v(1), strike, v(4)) and not v(4).is_alive(), "a Strike that kills")
	ok(is_equal_approx(uses(v(1)), 0.0), "adds no use of Strike (%s)" % uses(v(1)))
