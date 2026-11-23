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


# The busy_fight sim's OUTCOME checks, in the suite (docs/plans/w16-testaudit.md): two parties of 5 a side (a skilled leader, the
# rest following) of the 12 classes fight on an open field, 12 tiles apart, each side told of the other, by the AI alone. A
# regression that makes units idle, stall or never close fails here; there is no digest (decisions may change): blood is shed, no
# unit sits the fight out with a foe standing, someone is left, and it is decided, not stalled. Marked risk (Tests/risk.txt).
func test_fight_outcome() -> void:
	var f: Variant = load("res://Tests/sims/field.gd").new()
	await f.open(tree, 3, 32, 26)
	var size := 10
	var roles := ["fighter", "ranger", "mage", "cleric", "rogue", "bard", "berserker", "paladin", "druid", "warlock", "wizard", "sorcerer"]
	var head: Unit = null
	for side: Array in [[f.lancin, 3, 0], [f.nemes, 15, 3]]:
		for i in size:
			var c := Vector2i(side[1] + i % 5 % 3, 2 + i / 5 * 4 + i % 5 / 3)
			var u: Unit = f.add(side[0], load("res://Roles/%s.tres" % roles[(i + side[2]) % roles.size()]), c, "%s%d" % [side[0].name.left(1), i], 4)
			if i % 5 == 0:
				u.charisma = 14
				head = u
			else:
				u.follows = head
	for u: Unit in f.b.units.values():
		u.suspicion.clear()
		for t: Unit in f.b.units.values():
			if u.faction != t.faction and Perception.cover(f.b, t) == 0:
				f.b.sighted(u.faction, t, t.cell)
	var acted := {}
	f.b.traveled.connect(func(u: Unit, _from: Vector2i, _path: Array[Vector2i]): acted[u] = true)
	f.b.used.connect(func(u: Unit, _s: Skill, _at: Variant, _d: int): acted[u] = true)
	var all: Array = f.b.units.values()
	var rounds := 0
	while f.b.phase == Battle.Phase.TURNS and rounds < 12:
		f.play(f.lancin)
		if f.b.phase == Battle.Phase.TURNS:
			f.play(f.nemes)
		rounds += 1
	var alive := all.filter(func(u: Unit): return u.is_alive())
	ok(alive.size() > 0 and 2 * size - alive.size() >= size / 3, "blood is shed and someone is left (%d of %d standing after %d rounds)" % [alive.size(), 2 * size, rounds])
	var idle := all.filter(func(u: Unit): return u not in acted and u.is_alive())
	ok(idle.is_empty() and [f.lancin, f.nemes].all(func(s: Faction): return all.filter(func(u: Unit): return u.faction == s and u in acted).size() >= size / 2), "no unit sits the fight out, and each side moved or struck (%s)" % [idle.map(func(u: Unit): return u.name)])
	print("  outcome: %d standing, %d rounds, %d acted" % [alive.size(), rounds, acted.size()])
	ok(f.b.phase == Battle.Phase.OVER or rounds < 12, "it is decided, not stalled (%d rounds)" % rounds)
	f.close()
