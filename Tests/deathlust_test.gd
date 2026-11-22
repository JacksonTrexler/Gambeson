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
	var signed := []
	b.passive_fired.connect(func(u: Unit, s: Skill, _a: int, _st: StringName, _r: int): signed.append([u, s]))
	b.neutralize(v(4), &"killed")
	ok(is_equal_approx(uses(v(1)), 2.0) and signed.is_empty(), "a death 4 tiles off, past rank 1's 1: nothing, and no sign")
	b.neutralize(v(3), &"killed")
	ok(is_equal_approx(uses(v(1)), 1.5), "a foe killed beside it: 25%% off (%s)" % uses(v(1)))
	ok(signed == [[v(1), deathlust]], "easing a count signs the passive (Battle.passive_fired), by no name but its hook's effect (%s)" % [signed])
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
	var signed := []
	b.passive_fired.connect(func(u: Unit, _s: Skill, _a: int, _st: StringName, _r: int): signed.append(u))
	lusty(1, {v(4): Vector2i(4, 4)})
	v(1).exhaustion.uses.clear()
	v(4).hp = 1
	v(1).refresh()
	ok(b.cast(v(1), strike, v(4)) and not v(4).is_alive(), "a Strike that kills")
	ok(is_equal_approx(uses(v(1)), 0.0), "adds no use of Strike (%s)" % uses(v(1)))
	ok(signed == [v(1), v(1)], "and signs it twice: the death eases its count as it falls, the cancelled use at the cast's end (%s)" % [signed])


# The HUD logs the relief (Battle.passive's &"exhaustion" stat), once per easing, in the holder's tag.
func test_log_line() -> void:
	lusty(1)
	var h := await hud(v(1))
	var text := func() -> String: return h.log_box.get_parsed_text()
	b.neutralize(v(3), &"killed")
	await tree.process_frame
	ok(text.call().count("Villager1's Deathlust eases its exhaustion") == 1, "a kill beside it: one log line (%s)" % text.call())
	b.neutralize(v(3), &"downed")
	b.neutralize(v(3), &"down")
	await tree.process_frame
	ok(text.call().count("eases its exhaustion") == 1, "an unrelieved moment: none (%s)" % text.call())
	h.free()


# The AI prices a worn skill by the wearing() hooks: a blow that would kill costs no wear with Deathlust.
func test_ai_weighs_kill_discount() -> void:
	lusty(1)
	v(1).exhaustion.uses[strike] = 3.0
	var dmg := int(Battle.damage_range(v(1), strike, v(3), b).avg)
	var reads := AI.reads_from({v(3): b.read(v(1), v(3))})
	var worn := AI._wear(v(1), strike, b, v(3), reads[v(3)])
	ok(worn > 0.0, "a blow that doesn't kill: its wear counts (%.2f)" % worn)
	soak(v(3), maxi(dmg, 1))
	reads = {v(3): b.read(v(1), v(3))}
	ok(AI._wear(v(1), strike, b, v(3), reads[v(3)]) == 0.0, "one that kills: no wear with Deathlust")
	v(1).learned.clear()
	v(1).refresh()
	ok(AI._wear(v(1), strike, b, v(3), reads[v(3)]) > 0.0, "without it: the wear stands")


# What a death in reach gives its other counts back is priced through the neutralized() hooks (AI._relief()), not by name:
# a blow that would kill a unit beside it is worth the most any other skill's extra cost falls by; one that wouldn't, or a
# death out of its reach, nothing; its counts are as they were after. Without the passive: nothing.
func test_ai_prices_relief() -> void:
	lusty(1, {v(4): Vector2i(8, 3)})
	var hex := sk("hex")
	v(1).learned.append(slot(hex))
	v(1).refresh()
	v(1).exhaustion.uses[strike] = 3.0
	v(1).exhaustion.uses[hex] = 3.0
	var dmg := int(Battle.damage_range(v(1), strike, v(3), b).avg)
	var read := b.read(v(1), v(3))
	ok(AI._relief(b, v(1), strike, v(3), read) == 0.0, "a blow that wouldn't kill: none")
	soak(v(3), maxi(dmg, 1))
	read = b.read(v(1), v(3))
	var before := v(1).exhaustion.uses.duplicate()
	var worth := AI._relief(b, v(1), strike, v(3), read)
	ok(worth > 0.0 and v(1).exhaustion.uses == before, "one that kills a unit beside it: its other counts' relief (%.2f), and the counts left as they were" % worth)
	v(1).exhaustion.uses.erase(hex)
	ok(AI._relief(b, v(1), strike, v(3), read) == 0.0, "no other skill worn: nothing to ease (Strike's own is _wear()'s)")
	v(1).exhaustion.uses[hex] = 3.0
	v(3).cell = Vector2i(8, 3)
	v(4).cell = Vector2i(5, 3)
	soak(v(4), maxi(dmg, 1))
	v(1).learned.clear()
	v(1).refresh()
	ok(AI._relief(b, v(1), strike, v(4), b.read(v(1), v(4))) == 0.0, "without the passive: nothing")
