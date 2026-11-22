extends Test

# Evidence (Battle._scatter()): hiding leaves debris on tiles around the hider, by their tags (or the
# area's): a good job (CLEAN_HIDE+) 1-2, 2-4 tiles off; a middling one (FAIR_HIDE+) 2-3, 1-3 off; a
# poor one 3-4, within 2. Moving while hidden leaves one fewer, around the path. Stepping on debris
# destroys it; it's gone once its hider is revealed, or too far off (Battle._tidy_debris()). Enemies
# who can make out the ground see it (Battle.evidence()), and the AI searches by it, with the other clues
# it has (AI.clues()): where its side last saw a foe and how far it could have got since, where a blow it
# couldn't place came from, marks, all from what the searcher knows and never the true map.

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
		if s.behaviour(&"observe"):
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


const TRAP := Vector2i(5, 4)  # the museum's spike trap: a hint, so a clue of its own, unless revealed


# v(1), Observe and wisdom 16 (a look of 4 tiles), at `at`; v(3) hidden at (9, 7), far from every clue; the
# trap's hint put out so it is no clue.
func watcher(at := Vector2i(3, 3)) -> void:
	stage(lancin, {v(1): at, v(3): Vector2i(9, 7)})
	v(3).afflict(effect("concealment", 4), 9)
	v(1).wisdom = 16
	v(1).learned.append(slot(sk("observe"), 1))
	v(1).refresh()
	b.revealed[TRAP] = true
	forget()


# Neither side remembers seeing anyone, nor searching anywhere or being struck (the battle's start put every unit down).
func forget() -> void:
	b.sightings.clear()
	b.sighted_when.clear()
	b.swept.clear()
	b.attacks.clear()


# Where v(1) cast Observe on its turn, or null.
func searched() -> Variant:
	var at := []
	var f := func(_u: Unit, s: Skill, where: Variant, _d: int):
		if s.behaviour(&"observe"):
			at.append(where)
	b.used.connect(f)
	AI.act(b, v(1))
	b.used.disconnect(f)
	return at[0] if at.size() == 1 else null


func test_clues_weigh() -> void:
	watcher()
	ok(AI.clues(b, v(1)).is_empty() and searched() == null, "nothing to go on: it doesn't search")
	var far := Vector2i(8, 1)
	b.sighted(lancin, v(3), far, 2.0)
	var now := AI.clues(b, v(1))
	ok(now.size() == 1 and is_equal_approx(now[far], 1.0), "a foe seen this turn: one foe's worth, there %s" % [now])
	b.turns_begun += 2  # a round on
	var then := AI.clues(b, v(1))
	var sum := 0.0
	for c in then:
		sum += then[c]
	ok(is_equal_approx(sum, 1.0) and then[far] > 0.5 and then.size() > 5 and then.keys().all(func(c: Vector2i): return Command.tiles(c, far) <= 2),
			"a round on: still one foe's worth, most where it was, the rest over the tiles within its 2 movement (%d)" % then.size())
	b.turns_begun += 10
	var late := AI.clues(b, v(1))
	var spot: Variant = late.keys().filter(func(c: Vector2i): return Command.tiles(c, far) >= 3).front()
	ok(late.size() > then.size() and spot != null and late.keys().all(func(c: Vector2i): return Command.tiles(c, far) <= 6),
			"long gone: further, but no further than 3 turns of walking, 6 tiles (%d tiles)" % late.size())
	b.swept[lancin] = {spot: b.turns_begun}
	ok(spot not in AI.clues(b, v(1)) and far in AI.clues(b, v(1)), "a tile its side just searched is no longer a guess")
	b.turns_begun += Battle.SWEEP_TURNS + 1
	ok(spot in AI.clues(b, v(1)), "but it's worth another look in time")


func test_clues_lost_foe() -> void:
	watcher()
	b.sighted(lancin, v(3), Vector2i(4, 3), 2.0)
	b.last_seen(lancin).erase(v(3))  # its hunter reached the spot, found no one: the sighting forgotten
	var here := v(1).cell
	ok(AI.clues(b, v(1)) == {here: AI.LOST}, "a foe it made out once and has lost: a look where it stands, nothing else %s" % [AI.clues(b, v(1))])
	b.swept[lancin] = {here: b.turns_begun}
	ok(AI.clues(b, v(1)).is_empty(), "looked over: nothing to go on")
	b.turns_begun += Battle.SWEEP_TURNS + 1
	ok(here in AI.clues(b, v(1)), "but it looks again in time, not standing by a hider for good")
	b.sighted_when[lancin].clear()
	ok(AI.clues(b, v(1)).is_empty(), "a foe it never made out is no clue")


func test_clues_reach_by_known_ground() -> void:
	watcher()
	var from := Vector2i(8, 3)
	b.sighted(lancin, v(3), from, 3.0)
	b.turns_begun += 2
	var plain := b.reckon_reach(v(1), v(3), from, 3.0)
	ok(Vector2i(5, 3) in plain and Vector2i(4, 3) not in plain, "3 movement over plain ground: 3 tiles")
	var mud := load("res://Terrain/stew.tres").duplicate()  # enter 4
	b.paint(Vector2i(7, 3), mud)
	b.paint(Vector2i(7, 2), mud)
	b.paint(Vector2i(7, 4), mud)
	ok(Vector2i(5, 3) not in b.reckon_reach(v(1), v(3), from, 3.0), "ground it can see is dear, and the way round costs more: it can't have got as far")
	var hid := load("res://Terrain/trap.tres").duplicate()  # concealed: v(1) can't make it out
	hid.enter = 4
	for c in [Vector2i(7, 3), Vector2i(7, 2), Vector2i(7, 4)]:
		b.paint(c, hid)
	ok(b.read(v(1), Vector2i(7, 3)).net < 0 and b.reckon_reach(v(1), v(3), from, 3.0) == plain,
			"what it can't make out counts as plain: the true map doesn't change its guess")


func test_clues_attack() -> void:
	stage(nemes, {v(1): Vector2i(3, 3), v(3): Vector2i(2, 3)})  # v(3) behind it, hidden
	b.revealed[TRAP] = true
	forget()
	v(3).afflict(effect("concealment", 4), 9)
	v(1).facing = Vector2.RIGHT
	for i in 20:
		v(3).refresh()
		if v(1).hp < v(1).max_hp:
			break
		b.cast(v(3), strike, v(1))
		v(3).afflict(effect("concealment", 4), 9)
	b.turn = null
	b.turn = lancin
	ok(not b.attacks_on(lancin).is_empty() and not b.read(v(1), v(3)).located(), "struck from the rear by one it couldn't place")
	var seen: Array = b.attacks_on(lancin)[0].tiles
	ok(seen.size() > 0 and seen.all(func(c: Vector2i): return v(1).side_of(c) == &"rear" and Command.tiles(c, v(1).cell) <= 2),
			"the clue is every tile behind it within the blow's reach, not the tile it was struck from %s" % [seen])
	var clues := AI.clues(b, v(1))
	ok(Vector2i(2, 3) in clues and clues[Vector2i(2, 3)] == clues[seen[0]], "the hider's own tile is no likelier than the others")
	v(3).cell = Vector2i(9, 7)
	b.units.erase(Vector2i(2, 3))
	b.units[Vector2i(9, 7)] = v(3)
	ok(AI.clues(b, v(1)) == clues, "and where it really is changes nothing")


# Each clue sends the search its way where there was none, and what it does is from what its side
# knows: the foe's true whereabouts change nothing.
func test_ai_searches_by_clues() -> void:
	var far := Vector2i(8, 1)
	var seen := []
	for where in [Vector2i(9, 7), Vector2i(0, 7)]:  # the foe is really elsewhere: no matter
		watcher()
		v(3).cell = where
		b.units.erase(Vector2i(9, 7))
		b.units[where] = v(3)
		b.sighted(lancin, v(3), far, 2.0)
		seen.append(searched())
	ok(seen[0] != null and Command.tiles(seen[0], far) <= 4 and seen[0] == seen[1], "last seen there: it looks there, wherever the foe really is %s" % [seen])
	b.turns_begun += 2
	v(1).refresh()
	ok(searched() == null, "it has looked there: no looking again")
	watcher()
	var m := Battle.Mark.new(&"charge", v(3))
	b.lay_mark(Vector2i(8, 6), m)
	var at: Variant = searched()
	ok(at != null and Command.tiles(at, Vector2i(8, 6)) <= 4, "a mark a foe laid: it looks there %s" % [at])
	watcher()
	b.debris[Vector2i(8, 6)] = Battle.Debris.new("Rubble", v(3), b.turns_begun)
	at = searched()
	ok(at != null and Command.tiles(at, Vector2i(8, 6)) <= 4, "debris: it looks there %s" % [at])
	stage(nemes, {v(1): Vector2i(5, 5), v(3): Vector2i(4, 5)})
	b.revealed[TRAP] = true
	forget()
	v(3).afflict(effect("concealment", 4), 9)
	v(1).facing = Vector2.RIGHT
	v(1).wisdom = 16
	v(1).learned.append(slot(sk("observe"), 1))
	for i in 20:
		if v(1).hp < v(1).max_hp:
			break
		v(3).refresh()
		b.cast(v(3), strike, v(1))
		v(3).afflict(effect("concealment", 4), 9)
	b.turn = null
	b.turn = lancin
	v(1).refresh()
	var rear: Array = b.attacks_on(lancin)[0].tiles
	at = searched()
	ok(at != null and rear.all(func(c: Vector2i): return Command.tiles(at, c) <= 4), "struck from behind: it looks behind it %s" % [at])
