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
	lusty(1, {v(2): Vector2i(3, 4), v(4): Vector2i(8, 3)})
	var dl: Script = deathlust.behaviours[0].get_script()
	ok(is_equal_approx(dl.share(1), 0.25) and is_equal_approx(dl.share(2), 0.4375) and is_equal_approx(dl.share(3), 1.0 - pow(0.75, 3)), "eased by a curve: 25%, 44%, 58% ...")
	b.neutralize(v(4), &"killed")
	ok(is_equal_approx(uses(v(1)), 2.0), "a death 4 tiles off, past rank 1's 1: nothing")
	b.neutralize(v(3), &"killed")
	ok(is_equal_approx(uses(v(1)), 1.5), "a foe killed beside it: 25%% off (%s)" % uses(v(1)))
	b.neutralize(v(2), &"killed")
	ok(is_equal_approx(uses(v(1)), 1.125), "an ally killed on a diagonal, either side counts (%s)" % uses(v(1)))
	b.neutralize(v(3), &"downed")
	b.neutralize(v(3), &"down")
	ok(is_equal_approx(uses(v(1)), 1.125), "downed, or Downed, doesn't")
	b.neutralize(v(1), &"killed")
	ok(is_equal_approx(uses(v(1)), 1.125), "nor its own death")
	for r in [3, 4]:
		v(1).learned.clear()
		v(1).learned.append(slot(deathlust, r))
		b.neutralize(v(4), &"killed")
	ok(is_equal_approx(uses(v(1)), 1.125 * pow(0.75, 4)), "rank 3 reaches 3 tiles, not 4; rank 4 does, and eases 68%% (%s)" % uses(v(1)))
	v(1).exhaustion.uses[sk("hex")] = 0.2
	var was := uses(v(1))
	b.neutralize(v(3), &"killed")
	ok(is_equal_approx(v(1).exhaustion.uses[sk("hex")], 0.2 * pow(0.75, 4)) and is_equal_approx(uses(v(1)), was * pow(0.75, 4)), "every skill's count, by the same share")


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


# The AI prices a worn skill by the wearing() hooks: a blow that would kill costs no wear with Deathlust.
func test_ai_weighs_kill_discount() -> void:
	lusty(1)
	v(1).exhaustion.uses[strike] = 3.0
	var dmg := int(Battle.damage_range(v(1), strike, v(3), b).avg)
	var reads := {v(3): b.read(v(1), v(3))}
	var worn := AI._wear(v(1), strike, b, v(3), reads[v(3)])
	ok(worn > 0.0, "a blow that doesn't kill: its wear counts (%.2f)" % worn)
	soak(v(3), maxi(dmg, 1))
	reads = {v(3): b.read(v(1), v(3))}
	ok(AI._wear(v(1), strike, b, v(3), reads[v(3)]) == 0.0, "one that kills: no wear with Deathlust")
	v(1).learned.clear()
	v(1).refresh()
	ok(AI._wear(v(1), strike, b, v(3), reads[v(3)]) > 0.0, "without it: the wear stands")
