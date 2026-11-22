extends Test

# Levels (Unit.gain_xp()): each costs XP growing n log n - level n to the next takes 20 x n log2 n, at
# least 20 x n - up to level 20. A unit is worth the mean of its six core stats (no effects) and its
# level, rounded (Unit.xp_worth()). As it falls, its foes within 3 tiles share that, a share each and
# two for whoever struck it last (Battle._award()); brought back, its own side near it share it the
# same way, two shares to the one who saved it (Battle.rescued()). Each pays out once for falling and
# once for being brought back. A level brings a skill point and its max HP at once. The player's
# starter keeps its level and XP from battle to battle (Game.level, Game.xp).


func test_curve() -> void:
	ok([1, 2, 3, 4, 5, 10].map(func(n: int): return Unit.xp_to_next(n)) == [20, 40, 100, 160, 240, 680], "20 x n log2 n, at least 20 x n: %s" % [[1, 2, 3, 4, 5, 10].map(func(n: int): return Unit.xp_to_next(n))])
	ok(Unit.worth(5, 1) == Unit.nlogn(5) and Unit.nlogn(5) == 12, "the same curve as +1 Affinity")


func test_worth() -> void:
	ok(v(1).bst() == 64 and v(1).xp_worth() == 9, "a villager: BST 64 (12, 12, 12, 8, 12, 8), level 1: (64 + 1) / 7, 9")
	v(1).level = 3
	ok(v(1).xp_worth() == 10, "at level 3: 67 / 7, 10 - level is one more stat")
	var siren: Unit = load("res://Scenes/siren.tscn").instantiate()
	siren.level = 4
	ok(siren.bst() == 78 and siren.xp_worth() == 12, "a level 4 Siren: 82 / 7, 12")
	siren.free()


func test_gain() -> void:
	var u := b.starter({faction = lancin, role = load("res://Roles/fighter.tres"), name = "Brick"})
	b.get_node("Units").add_child(u)
	var hp := u.max_hp
	ok(u.gain_xp(19) == 0 and u.level == 1 and u.xp == 19, "short of 20: still level 1")
	u.hp -= 3
	ok(u.gain_xp(46) == 2 and u.level == 3 and u.xp == 5 and u.skill_points == 2, "65 in all: level 3 (20, then 40), 5 toward the next, a point a level")
	ok(u.max_hp > hp and u.hp == u.max_hp - 3, "its levels' max HP, at once: %d -> %d" % [hp, u.max_hp])


func test_cap() -> void:
	v(1).level = 19
	ok(v(1).gain_xp(99999) == 1 and v(1).level == Unit.MAX_LEVEL and v(1).xp == 0, "level 20 is the cap: what's over is lost")
	ok(v(1).gain_xp(50) == 0 and v(1).xp == 0, "and nothing more is taken")
	Game.level = 25
	var u := b.starter({faction = lancin, role = load("res://Roles/fighter.tres"), name = "Brick"})
	ok(u.level == 20, "a starter never past it")
	u.free()
	Game.level = 1


func earned() -> Array:
	var got := []
	b.gained_xp.connect(func(u: Unit, n: int, levels: int, from: Unit, saved: bool): got.append([u, n, levels, from, saved]))
	return got


func test_kill() -> void:
	stage(lancin, {v(1): Vector2i(1, 2), v(2): Vector2i(1, 3), v(3): Vector2i(2, 2), v(4): Vector2i(2, 3)})
	var got := earned()
	v(3).hit(999.0, [], v(1))
	ok(not v(3).is_alive() and got == [[v(1), 6, 0, v(3), false], [v(2), 3, 0, v(3), false]],
			"its 9 in three shares: two to its killer, one to its foe beside it (not its ally): %s" % [got])
	got.clear()
	v(2).hit(5.0, [], v(4))
	v(2).hit(999.0, [], v(1))
	ok(got == [[v(4), 9, 0, v(2), false]], "felled by an ally: its killer earns nothing; the foe beside it takes the only share")
	got.clear()
	b.move(v(4), Vector2i(8, 8))
	v(4).last_hit_by = null
	v(4).damage(999)
	ok(got.is_empty(), "nobody's blow (poison, a fall) and nobody near: nobody's XP")


func test_near() -> void:
	stage(lancin, {v(1): Vector2i(0, 0), v(2): Vector2i(3, 4), v(3): Vector2i(3, 0), v(4): Vector2i(6, 0)})
	var got := earned()
	v(3).hit(999.0, [], v(1))
	ok(got == [[v(1), 9, 0, v(3), false]], "its other foe 4 tiles off (its ally 3 off takes none): the killer's two shares are all of it: %s" % [got])
	got.clear()
	stage(lancin, {v(1): Vector2i(0, 0), v(2): Vector2i(5, 1), v(4): Vector2i(5, 0)})
	v(4).hit(999.0, [], v(1))
	ok(got == [[v(1), 6, 0, v(4), false], [v(2), 3, 0, v(4), false]], "a killer far off still takes its two shares: %s" % [got])


func test_once() -> void:
	stage(lancin, {v(1): Vector2i(1, 2), v(3): Vector2i(2, 2)})
	var got := earned()
	v(3).hit(999.0, [], v(1))
	v(3).hp = 5  # back somehow
	v(3).hit(999.0, [], v(1))
	ok(got.size() == 1 and v(1).xp == 9, "a unit pays out for falling once")


func test_rescue() -> void:
	stage(lancin, {v(1): Vector2i(1, 2), v(2): Vector2i(1, 3), v(3): Vector2i(2, 2), v(4): Vector2i(5, 5)})
	var got := earned()
	v(2).hit(999.0, [], v(3))
	got.clear()
	v(2).hp = v(2).max_hp
	b.rescued(v(2), v(1))
	ok(got == [[v(1), 9, 0, v(2), true]], "brought back: its saviour takes two shares; its foe beside it none: %s" % [got])
	got.clear()
	b.rescued(v(2), v(1))
	ok(got.is_empty(), "and only once")
	v(4).hit(999.0, [], v(1))
	got.clear()
	b.move(v(3), Vector2i(4, 5))
	v(4).hp = v(4).max_hp
	b.rescued(v(4), null)
	ok(got == [[v(3), 9, 0, v(4), true]], "its saviour gone: its side near it share it all: %s" % [got])
	ok(v(4).paid_fall and v(4).paid_rise, "falling and coming back each pay out, once each")


func test_starter_keeps() -> void:
	Game.level = 3
	Game.xp = 12
	var u := b.starter({faction = lancin, role = load("res://Roles/fighter.tres"), name = "Brick"})
	b.get_node("Units").add_child(u)
	ok(u.level == 3 and u.xp == 12 and u.skill_points == 2 and u.hp == u.max_hp, "the next battle: level 3, its XP, a point a level gained to learn its skills again")
	b.player = u
	b.move(u, Vector2i(5, 5))
	stage(lancin, {u: Vector2i(5, 5), v(3): Vector2i(6, 5)})
	v(3).strength = 647  # BST 699: (699 + 1) / 7, a worth of 100
	v(3).hit(999.0, [], u)
	ok(u.level == 4 and u.xp == 12 and Game.level == 4 and Game.xp == 12, "100 XP on its 12: level 4 (100), 12 over - kept for the next battle: level %d, %d XP" % [u.level, u.xp])
	Game.level = 1
	Game.xp = 0
