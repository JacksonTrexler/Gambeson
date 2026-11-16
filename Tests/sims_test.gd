extends Test

# The big sims' scene (Tests/sims/field.gd, used by hunt_10v10.gd and busy_fight.gd, outside the suite) still builds and plays:
# a few class units a side on an open field with sight on, a round of AI turns, one a hider the Rangers' side was told of.


func test_field_round() -> void:
	var f: Variant = load("res://Tests/sims/field.gd").new()
	await f.open(tree, 1, 24, 12)
	var roles: Array[String] = ["fighter", "ranger", "mage"]
	for i in 3:
		f.add(f.lancin, load("res://Roles/%s.tres" % roles[i]), Vector2i(2, 2 + i * 3), "L%d" % i, 3)
		f.add(f.nemes, load("res://Roles/%s.tres" % roles[i]), Vector2i(10, 2 + i * 3), "N%d" % i, 3)
	ok(f.b.units.size() == 6 and f.b.on_map(Vector2i(23, 11)) and not f.b.on_map(Vector2i(24, 12)), "6 units on a 24 x 12 field")
	for u: Unit in f.b.units.values():
		for t: Unit in f.b.units.values():
			if u.faction != t.faction:
				f.b.sighted(u.faction, t, t.cell)
	var start: Array = f.b.members(f.lancin).map(func(u: Unit): return u.cell)
	var timing: Dictionary = f.play(f.lancin)
	ok(timing.acts.size() == 3 and f.b.turn == f.nemes, "a round of AI turns: each of the side acted, the turn passed")
	ok(f.b.members(f.lancin).any(func(u: Unit): return u.cell not in start), "and they went for the foes they were told of")
	f.close()
