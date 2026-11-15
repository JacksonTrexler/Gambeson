extends Test

# Shove, fear and entrance (docs/plans/fear.md): forced moves an Effect stat carries (Battle.drive(), _frighten()),
# one primitive under them and Displace (Battle.displace()): a grapple either side of a forced move ends, a push
# stopped short hurts, and the tags (shove, fear, entrance) ride on the move and its damage.

var hitch: Skill = load("res://Skills/hitch.tres")
var moves := []  # b.driven: [unit, by, tags, went, hit]


# Hex with no roll, putting e on whoever it lands on (Behaviour.Cast.put() is the same path for a behaviour).
func carrying(e: Effect, turns := 1) -> Skill:
	var s: Skill = hex.duplicate()
	s.rolls = false
	e.turns = turns
	s.effects = [e] as Array[Effect]
	s.behaviours = [] as Array[Behaviour]
	v(1).learned.append(slot(s))
	v(1).refresh()
	return s


func watch() -> void:
	moves.clear()
	b.driven.connect(func(u: Unit, by: Unit, tags: Array[StringName], went: int, hit: bool): moves.append([u, by, tags, went, hit]))


func test_the_three_effects() -> void:
	watch()
	stage(lancin, {v(1): Vector2i(2, 3), v(3): Vector2i(4, 3)})
	soak(v(3))
	var s := carrying(effect("shove", 2.0))
	ok(b.cast(v(1), s, v(3)) and v(3).cell == Vector2i(6, 3), "shove drives it 2 tiles straight away (%s)" % v(3).cell)
	ok(v(3).timed.is_empty() or not v(3).timed.keys().any(func(e: Effect): return e.stat == "shove"), "and is instant: nothing stays on")
	ok(moves.size() == 1 and moves[0][1] == v(1) and moves[0][2] == [&"shove"] and moves[0][3] == 2 and not moves[0][4], "told, with its tag and its driver: %s" % [moves])
	stage(lancin, {v(1): Vector2i(2, 3), v(3): Vector2i(7, 3)})
	moves.clear()
	var e := effect("entrance", 3.0)
	s = carrying(e, 2)
	v(1).refresh()
	ok(b.cast(v(1), s, v(3)) and v(3).cell == Vector2i(4, 3) and moves[0][2] == [&"entrance"], "entrance draws it 3 tiles toward (%s)" % v(3).cell)
	ok(e in v(3).timed, "and stays on, a status")
	b.end_turn()
	ok(v(3).cell == Vector2i(3, 3) and moves.size() == 2, "its turn starting, it's drawn again, stopping beside its source (%s)" % v(3).cell)
	stage(lancin, {v(1): Vector2i(2, 3), v(3): Vector2i(5, 3)})
	moves.clear()
	var f := effect("fear", 2.0)
	f.per_rank = true
	s = carrying(f, 2)
	ok(b.cast(v(1), s, v(3)) and v(3).cell == Vector2i(7, 3) and moves[0][2] == [&"fear"], "fear drives it away, x rank (%s)" % v(3).cell)
	b.move(v(1), Vector2i(7, 4))
	b.end_turn()
	ok(v(3).cell == Vector2i(7, 2) or v(3).cell.y < 3, "and again as its turn starts, from where its source stands then (%s)" % v(3).cell)
	ok(Effect.HARMFUL.has("fear") and f.helps() < 0 and "away" in f.describe(), f.describe())


func holds(by: Unit, t: Unit) -> void:
	by.learned.append(slot(hitch, 2))
	by.strength = 60
	stage(lancin, {by: Vector2i(4, 3), t: Vector2i(5, 3)})
	by.refresh()
	soak(t, 300)
	t.strength = 1
	t.dexterity = 1
	b.cast(by, hitch, t)


func test_a_forced_move_lets_go() -> void:
	holds(v(1), v(3))
	ok(b.held_by(v(3)) != null, "held (setup)")
	ok(b.displace(v(3), v(1).cell, 1, 2) == 2 and b.held_by(v(3)) == null, "the one held, driven off, is let go")
	holds(v(1), v(3))
	ok(b.displace(v(1), v(3).cell, 1, 1) == 1 and b.held_by(v(3)) == null, "the one holding, driven off, lets go")
	holds(v(1), v(3))
	b.move(v(4), Vector2i(6, 3))
	ok(b.displace(v(3), v(1).cell, 1, 2) == 0 and b.held_by(v(3)) != null, "one that goes nowhere keeps its grip")
	holds(v(1), v(3))
	soak(v(3), 300)
	var g := effect("fear", 1.0)
	var a := v(1).afflict(g, 2)
	a.by = v(3)
	b.drive(v(1), g, a)
	ok(b.held_by(v(3)) == null and v(1).cell == Vector2i(3, 3), "a grappler it frightens lets go and flees (%s)" % v(1).cell)


func test_a_stopped_push_hurts() -> void:
	watch()
	var blows := []
	stage(lancin, {v(1): Vector2i(2, 3), v(3): Vector2i(4, 3), v(4): Vector2i(5, 3)})
	soak(v(3), 300)
	soak(v(4), 300)
	for u in [v(3), v(4)]:
		u.taking_hit.connect(func(w: Unit, blow: Dictionary): blows.append([w, blow.tags.duplicate()]))
	ok(b.displace(v(3), v(1).cell, 1, 3, false, [&"shove"] as Array[StringName], v(1)) == 0, "blocked at once")
	ok(v(3).hp == 300 - Battle.SLAM * 3 and v(4).hp == 300 - Battle.SLAM * 3, "both take SLAM for each tile unspent (%d, %d)" % [300 - v(3).hp, 300 - v(4).hp])
	ok(blows.size() == 2 and blows.all(func(x): return &"blunt" in x[1] and &"shove" in x[1]), "as blunt blows carrying the push's tag: %s" % [blows])
	ok(moves.size() == 1 and moves[0][4], "told as a hit")
	v(3).hp = 300
	v(3).afflict(effect("mitigate", 0.5, [&"shove"]), 3)
	b.displace(v(3), v(1).cell, 1, 1, false, [&"shove"] as Array[StringName], v(1))
	ok(v(3).hp == 300 - Battle.SLAM / 2, "an effect tagged shove halves it (%d): the tag reaches effects" % (300 - v(3).hp))
	var edge := Vector2i(7, 3)
	while b.on_map(edge + Vector2i.RIGHT):
		edge += Vector2i.RIGHT
	v(3).timed.clear()
	stage(lancin, {v(1): edge - Vector2i(3, 0), v(3): edge - Vector2i(1, 0)})
	soak(v(3), 300)
	ok(b.displace(v(3), v(1).cell, 1, 4, false, [&"shove"] as Array[StringName], v(1)) == 1 and v(3).hp == 300 - Battle.SLAM * 3, "driven into the map's edge: the tiles it didn't get, SLAM each (%d)" % (300 - v(3).hp))
	stage(lancin, {v(1): Vector2i(2, 3), v(3): Vector2i(4, 3)})
	soak(v(3), 300)
	ok(b.displace(v(3), v(1).cell, 1, 2) == 2 and v(3).hp == 300, "a clear push does no damage")
	stage(lancin, {v(1): Vector2i(2, 3), v(3): Vector2i(7, 3), v(4): Vector2i(3, 3)})
	soak(v(3), 300)
	ok(b.displace(v(3), v(1).cell, -1, 5) == 3 and v(3).hp == 300, "and a draw stopped beside its source isn't a collision")


func test_displace_carries_its_tags() -> void:
	watch()
	var d := Displace.new()
	var s: Skill = hex.duplicate()
	s.rolls = false
	s.behaviours = [d] as Array[Behaviour]
	v(1).learned.append(slot(s))
	stage(lancin, {v(1): Vector2i(2, 3), v(3): Vector2i(4, 3)})
	soak(v(3))
	b.cast(v(1), s, v(3))
	d.toward = true
	v(1).refresh()
	b.cast(v(1), s, v(3))
	ok(moves.size() == 2 and moves[0][2] == [&"shove"] and moves[1][2] == [&"entrance"], "a Displace tells shove away and entrance toward: %s" % [moves.map(func(m): return m[2])])
