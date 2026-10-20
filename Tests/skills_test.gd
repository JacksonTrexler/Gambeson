extends Test

# Strike and Hex: reach, size, net luck, AP and energy, turn rules, timed effects.


func test_strike_damage() -> void:
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	ok(v(1).actives.has(strike) and v(3).actives == [strike, hex], "every villager has Strike")
	ok(b.cast(v(1), strike, v(3)) and v(3).hp == 8, "Lancin Strike: 1 + str mod 1 = 2")
	b.end_turn()
	ok(b.cast(v(3), strike, v(1)) and v(1).hp == 9, "Nemes Strike vs Favour: 1.98, net luck +1 for Lancin -> 1")
	v(1).afflict(hex.effects[0])
	ok(b.cast(v(3), strike, v(1)) and v(1).hp == 7, "hexed (net 0): standard rounds up -> 2")


func test_strike_strength() -> void:
	stage(nemes, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	v(3).strength = 15
	ok(b.cast(v(3), strike, v(1)) and v(1).hp == 8, "str 15 (+2): 3 x 0.99 = 2.97, Lancin luckier -> 2")
	v(3).strength = 3
	b.cast(v(3), strike, v(1))
	ok(v(1).hp == 8, "str 3 (-4): power clamps at 0")


func test_strike_reach() -> void:
	ok(is_equal_approx(b.skill_range(v(1), strike, v(3)), 1.21), "range 1 + size 3 x 0.05 + target size 3 x 0.02")
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 4)})
	ok(b.in_reach(v(1), strike, v(3)), "diagonal (1.41, 0.2 over): luckier Lancin rounds it in")
	b.end_turn()
	ok(not b.in_reach(v(3), strike, v(1)) and not b.cast(v(3), strike, v(1)), "Nemes (net -1) misses the same diagonal")
	v(1).afflict(hex.effects[0])
	ok(not b.in_reach(v(3), strike, v(1)), "equal luck: standard rule, a miss")
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(6, 3)})
	ok(not b.in_reach(v(1), strike, v(3)), "2 tiles (0.79 over) is out for anyone")
	v(1).afflict(effect("reach", 1))
	ok(b.in_reach(v(1), strike, v(3)), "+1 reach (a spear) makes it")


func test_size() -> void:
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(6, 3)})
	v(1).afflict(hex.effects[0])  # equal luck: only size decides
	ok(not b.in_reach(v(1), strike, v(3)), "2 tiles: out at medium size")
	v(3).size = 50
	ok(b.in_reach(v(1), strike, v(3)), "a size-50 target (+1.0) is in reach")
	v(3).size = 3
	v(1).size = 20
	ok(b.in_reach(v(1), strike, v(3)), "a size-20 attacker (+1.0) reaches it too")


func test_hex() -> void:
	stage(nemes, {v(3): Vector2i(8, 2), v(4): Vector2i(8, 5), v(1): Vector2i(1, 2), v(2): Vector2i(3, 5)})
	ok(not b.cast(v(3), hex, v(1)), "out of range at 7")
	ok(not b.cast(v(3), hex, v(4)), "allies can't be hexed")
	ok(not b.cast(v(3), favour, v(1)), "passives can't be cast")
	ok(b.cast(v(4), hex, v(2)), "range 5 + 0.21: (8,5) -> (3,5) at exactly 5")
	ok(v(4).energy == 8 and v(2).hp == 9 and v(2).luck == 0 and v(2).timed[hex.effects[0]] == 3, "2 energy, 1 direct damage, luck -1 for 3 turns")
	ok(is_equal_approx(v(4).ap_for(&"skill"), 7.0) and v(4).ap[2].amount == 0, "4 AP of 11 for skills, wis pool first")
	b.cast(v(4), hex, v(2))
	ok(v(2).luck == 0 and v(2).timed.size() == 1, "re-Hex refreshes, doesn't stack")
	ok(v(2).hit(10, [&"slash"]) == 10, "hexed Favour: mitigation trivial again")


func test_hex_margin() -> void:
	stage(nemes, {v(3): Vector2i(0, 0), v(1): Vector2i(4, 4), v(2): Vector2i(5, 1)})
	ok(b.in_reach(v(3), hex, v(2)), "(5,1) at 5.10 is inside 5.21")
	ok(not b.in_reach(v(3), hex, v(1)), "(4,4) at 5.66 is a near miss Nemes (net -1) loses")
	v(3).afflict(effect("luck", 2))
	ok(b.in_reach(v(3), hex, v(1)), "with net luck +1 it rounds in")


func test_hex_ticks() -> void:
	stage(nemes, {v(3): Vector2i(5, 2), v(1): Vector2i(3, 2)})
	b.cast(v(3), hex, v(1))
	b.end_turn()
	ok(v(1).timed[hex.effects[0]] == 3, "the caster's turn ending doesn't tick it")
	b.end_turn()
	ok(v(1).timed[hex.effects[0]] == 2, "the target faction's turn ending does")
	for i in 3:
		b.end_turn()
	ok(v(1).timed[hex.effects[0]] == 1 and v(1).luck == 0, "still on after 2 Lancin turns")
	b.end_turn()
	ok(v(1).timed.is_empty() and v(1).luck == 1, "gone after 3")


func test_costs_and_turns() -> void:
	stage(nemes, {v(3): Vector2i(4, 3), v(1): Vector2i(5, 3)})
	ok(not b.cast(v(1), strike, v(3)), "not your turn")
	for i in 3:
		ok(b.cast(v(3), strike, v(1)), "Strike %d (3 AP)" % (i + 1))
	ok(not b.cast(v(3), strike, v(1)) and is_equal_approx(v(3).ap_for(&"skill"), 2.0), "11 skill AP (10 + wis 1; dex AP only moves): 3 Strikes")
	ok(is_equal_approx(v(3).ap_for(&"move"), 3.0), "what's left (2 general + 1 dex) can still move")
	b.end_turn()
	b.end_turn()
	ok(b.cast(v(3), strike, v(1)), "AP refills on the next Nemes turn")
	v(3).energy = 1
	stage(nemes, {v(3): Vector2i(4, 3), v(1): Vector2i(6, 3)})
	ok(not b.cast(v(3), hex, v(1)), "Hex needs 2 energy")
	stage(nemes, {v(3): Vector2i(4, 3), v(1): Vector2i(5, 3), v(2): Vector2i(0, 7)})
	v(1).damage(99)
	ok(b.phase == Battle.Phase.TURNS and not b.cast(v(3), strike, v(1)), "no casting at the dead (battle still on)")
