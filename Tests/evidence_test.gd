extends Test

# Evidence (Battle._scatter()): hiding leaves debris on tiles around the hider, by their tags (or the
# area's): a good job (CLEAN_HIDE+) 1-2, 2-4 tiles off; a middling one (FAIR_HIDE+) 2-3, 1-3 off; a
# poor one 3-4, within 2. Moving while hidden leaves one fewer, around the path. Stepping on debris
# destroys it; it's gone once its hider is revealed, or too far off (Battle._tidy_debris()). Enemies
# who can make out the ground see it (Battle.evidence()), and the AI searches by it.

var hide: Skill = load("res://Skills/hide.tres")


func test_kinds() -> void:
	ok(b.debris_kind(Vector2i(1, 4)) == "Disturbed foliage, twigs", "grass: foliage")
	ok(b.debris_kind(Vector2i(2, 2)) == "Disturbed foliage, twigs", "bramble (shrubbery): foliage")
	ok(b.debris_kind(Vector2i(5, 2)) == "Rubble", "the shrine (stone): rubble")
	ok(b.debris_kind(Vector2i(7, 6)) == "", "water: none")
	b.area_tags = [&"desert"]
	ok(b.debris_kind(Vector2i(7, 6)) == "Depressions", "where the tile says nothing, the area: a desert")
	ok(b.debris_kind(Vector2i(1, 4)) == "Disturbed foliage, twigs", "the tile comes first")
	ok(Battle.material(&"stone") and not Battle.material(&"sticky"), "material tags")


func test_scatter() -> void:
	stage(nemes, {v(3): Vector2i(4, 3), v(1): Vector2i(9, 1)})
	for i in 10:
		b.debris.clear()
		b._scatter(v(3), Battle.CLEAN_HIDE)
		ok(b.debris.size() in [1, 2] and b.debris.keys().all(func(c: Vector2i): return Command.tiles(c, v(3).cell) in [2, 3, 4]),
				"a good job: 1-2, 2-4 tiles off %s" % [b.debris.keys()])
	for i in 10:
		b.debris.clear()
		b._scatter(v(3), Battle.CLEAN_HIDE - 1)
		ok(b.debris.size() in [2, 3] and b.debris.keys().all(func(c: Vector2i): return Command.tiles(c, v(3).cell) in [1, 2, 3]),
				"a middling one (14): 2-3, 1-3 tiles off %s" % [b.debris.keys()])
	for i in 10:
		b.debris.clear()
		b._scatter(v(3), Battle.FAIR_HIDE - 1)
		ok(b.debris.size() in [3, 4] and b.debris.keys().all(func(c: Vector2i): return Command.tiles(c, v(3).cell) in [1, 2]),
				"a poor one: 3-4, within 2 %s" % [b.debris.keys()])
	ok(b.debris.values().all(func(d: Battle.Debris): return d.by == v(3) and d.kind != ""), "its own, of the ground's kind")


func test_hide_leaves_it() -> void:
	stage(nemes, {v(3): Vector2i(4, 3), v(4): Vector2i(5, 3), v(1): Vector2i(9, 1)})
	v(3).learned.append(slot(hide, 1))
	v(3).refresh()
	ok(b.cast(v(3), hide, v(3)) and not b.debris.is_empty(), "hiding leaves debris (%d)" % b.debris.size())
	var c: Vector2i = b.debris.keys()[0]
	ok(c in b.evidence(v(1)), "an enemy that can make out the ground sees it")
	ok(c not in b.evidence(v(4)), "its own side doesn't count it: they know")


func test_ai_follows_it() -> void:
	stage(lancin, {v(1): Vector2i(1, 4), v(3): Vector2i(8, 1)})
	v(3).afflict(effect("concealment", 4), 9)
	v(1).wisdom = 16  # look: 3 + rank 1
	v(1).learned.append(slot(load("res://Skills/observe.tres"), 1))
	v(1).refresh()
	for c in [Vector2i(5, 0), Vector2i(6, 0), Vector2i(5, 1)]:
		b.debris[c] = Battle.Debris.new("Disturbed foliage, twigs", v(3), 0)
	var at := []
	b.used.connect(func(_u: Unit, s: Skill, where: Variant, _d: int):
		if s.observes:
			at.append(where))
	AI.act(b, v(1))
	ok(at.size() == 1 and [Vector2i(5, 0), Vector2i(6, 0), Vector2i(5, 1)].all(func(c: Vector2i): return Command.tiles(at[0], c) <= 4)
			and Command.tiles(at[0], Vector2i(5, 4)) <= 4, "it searches where the debris and the trap's hint both are: %s" % [at])


func test_trail() -> void:
	stage(nemes, {v(3): Vector2i(1, 1), v(1): Vector2i(9, 1)})
	v(3).afflict(effect("concealment", 3), 9)  # not Hide: it stays hidden moving
	v(3).dexterity = 10
	var path := b.travel(v(3), Vector2i(4, 1))
	ok(not path.is_empty() and Perception.cover(b, v(3)) > 0, "it moved, still hidden")
	ok(b.debris.size() in [0, 1, 2, 3] and b.debris.keys().all(func(c: Vector2i): return c not in path and c != Vector2i(1, 1)),
			"one fewer than hiding would leave, near the path, not on it %s %s" % [b.debris.keys(), path])
	b.debris.clear()
	for i in 5:
		b._scatter(v(3), 1, path)
	ok(not b.debris.is_empty() and b.debris.keys().all(func(c: Vector2i): return path.any(func(p: Vector2i): return Command.tiles(p, c) <= 2)),
			"a poor job: within 2 of the path")


func test_cleared() -> void:
	stage(nemes, {v(3): Vector2i(4, 3), v(1): Vector2i(9, 1)})
	v(3).afflict(effect("concealment", 2), 9)
	v(3).dexterity = 10
	b._scatter(v(3), 1)
	var c: Vector2i = b.debris.keys()[0]
	b.end_turn()
	v(1).refresh()
	b.move(v(1), c + Vector2i(1, 0) if b.on_map(c + Vector2i(1, 0)) and not b.unit_at(c + Vector2i(1, 0)) else c + Vector2i(-1, 0))
	b.travel(v(1), c)
	ok(c not in b.debris, "stepped on: destroyed")
	ok(not b.debris.is_empty(), "the rest stays while it hides nearby")
	v(3).exposed = 2
	b._tidy_debris()
	ok(b.debris.is_empty(), "its hider revealed: all gone")
	v(3).exposed = 0
	b._scatter(v(3), 1)
	b.move(v(3), Vector2i(9, 7))
	b._tidy_debris()
	ok(b.debris.is_empty(), "its hider gone further than it could have been left (2) + dex mod (0): cold")
