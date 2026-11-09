extends Test

# Levels (Unit.gain_xp()): each costs XP growing n log n - level n to the next takes 20 x n log2 n, at
# least 20 x n. A fallen unit is worth its base stat total (its six core stats, no effects) x its level
# / 10, paid to whoever struck it last (Battle._award()), if that one is still standing and not on its
# side. A level brings a skill point and its max HP at once. The player's starter keeps its level and
# XP from battle to battle (Game.level, Game.xp).


func test_curve() -> void:
	ok([1, 2, 3, 4, 5, 10].map(func(n: int): return Unit.xp_to_next(n)) == [20, 40, 100, 160, 240, 680], "20 x n log2 n, at least 20 x n: %s" % [[1, 2, 3, 4, 5, 10].map(func(n: int): return Unit.xp_to_next(n))])
	ok(Unit.worth(5, 1) == Unit.nlogn(5) and Unit.nlogn(5) == 12, "the same curve as +1 Affinity")


func test_worth() -> void:
	ok(v(1).bst() == 64 and v(1).xp_worth() == 6, "a villager: BST 64 (12, 12, 12, 8, 12, 8), level 1: worth 6")
	v(1).level = 3
	ok(v(1).xp_worth() == 19, "at level 3: 64 x 3 / 10, 19")
	var siren: Unit = load("res://Scenes/siren.tscn").instantiate()
	siren.level = 4
	ok(siren.bst() == 78 and siren.xp_worth() == 31, "a level 4 Siren: 78 x 4 / 10, 31")
	siren.free()


func test_gain() -> void:
	var u := b.starter({faction = lancin, role = load("res://Roles/fighter.tres"), name = "Brick"})
	b.get_node("Units").add_child(u)
	var hp := u.max_hp
	ok(u.gain_xp(19) == 0 and u.level == 1 and u.xp == 19, "short of 20: still level 1")
	u.hp -= 3
	ok(u.gain_xp(46) == 2 and u.level == 3 and u.xp == 5 and u.skill_points == 2, "65 in all: level 3 (20, then 40), 5 toward the next, a point a level")
	ok(u.max_hp > hp and u.hp == u.max_hp - 3, "its levels' max HP, at once: %d -> %d" % [hp, u.max_hp])


func test_kill() -> void:
	stage(lancin, {v(1): Vector2i(1, 2), v(2): Vector2i(1, 3), v(3): Vector2i(2, 2), v(4): Vector2i(2, 3)})
	var got := []
	b.gained_xp.connect(func(u: Unit, n: int, levels: int, from: Unit): got.append([u, n, levels, from]))
	v(3).hit(999.0, [], v(1))
	ok(not v(3).is_alive() and v(1).xp == 6 and got == [[v(1), 6, 0, v(3)]], "its killer earns its worth")
	v(2).hit(5.0, [], v(4))
	v(2).hit(999.0, [], v(1))
	ok(v(1).xp == 6 and got.size() == 1, "felling an ally earns nothing")
	v(4).last_hit_by = null
	v(4).damage(999)
	ok(got.size() == 1, "nobody's blow (poison, a fall): nobody's XP")


func test_starter_keeps() -> void:
	Game.level = 3
	Game.xp = 12
	var u := b.starter({faction = lancin, role = load("res://Roles/fighter.tres"), name = "Brick"})
	b.get_node("Units").add_child(u)
	ok(u.level == 3 and u.xp == 12 and u.skill_points == 2 and u.hp == u.max_hp, "the next battle: level 3, its XP, a point a level gained to learn its skills again")
	b.player = u
	b.move(u, Vector2i(5, 5))
	stage(lancin, {u: Vector2i(5, 5), v(3): Vector2i(6, 5)})
	v(3).level = 15
	v(3).hit(999.0, [], u)
	ok(u.level == 4 and u.xp == 8 and Game.level == 4 and Game.xp == 8, "a level 15 villager's 96 XP on its 12: level 4 (100), 8 over - kept for the next battle")
	Game.level = 1
	Game.xp = 0
