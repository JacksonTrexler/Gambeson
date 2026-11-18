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
	v(3).refresh()
	var ap := v(3).ap_for(&"move")
	v(3).facing = Vector2(-1, 0)
	ok(b.cast(v(1), s, v(3)) and v(3).cell == Vector2i(7, 3) and moves[0][2] == [&"fear"], "fear drives it away, x rank (%s)" % v(3).cell)
	ok(v(3).facing == Vector2(1, 0) and is_equal_approx(v(3).ap_for(&"move"), ap - 2.0) and is_equal_approx(v(3).moved, 2.0), "it fled by itself: it faces the way it went and paid 2 tiles of movement AP (%s, %s of %s)" % [v(3).facing, v(3).ap_for(&"move"), ap])
	b.move(v(1), Vector2i(7, 4))
	b.end_turn()
	ok(v(3).cell == Vector2i(7, 2) or v(3).cell.y < 3, "and again as its turn starts, from where its source stands then (%s)" % v(3).cell)
	ok(v(3).moved > 0.0 and v(3).facing.y < 0.0, "that one a fresh turn's movement, spent and faced (%s)" % v(3).facing)
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


func test_whatever_puts_it_on_drives() -> void:
	stage(lancin, {v(1): Vector2i(2, 3), v(3): Vector2i(4, 3)})
	soak(v(3))
	var c := b.cast_of(v(1), hex, v(3), 1, true)
	c.put(effect("shove", 1.0), 1)
	ok(v(3).cell == Vector2i(5, 3), "a behaviour's put() drives it (%s)" % v(3).cell)
	var m := Battle.Mark.new(&"scare", v(1), lancin)
	m.effects = [effect("fear", 2.0)] as Array[Effect]
	b.lay_mark(Vector2i(5, 3), m)
	b._trigger(v(3), Vector2i(5, 3), &"enter")
	ok(v(3).cell == Vector2i(7, 3), "and a mark's effects do, from the one who laid it (%s)" % v(3).cell)


# The forecast (docs/plans/forced-forecast.md): foresee() reads a forced move to where it would end, through
# the one course() that displace() mirrors, so the foreseen tile is the tile it really ends on - for an
# effect's shove, fear and entrance, and Displace's push, draw and teleport - and a stop short is its slam.
func test_the_forecast_reads_where_it_ends() -> void:
	var edge := Vector2i(7, 3)
	while b.on_map(edge + Vector2i.RIGHT):
		edge += Vector2i.RIGHT
	for k in [["shove", 2.0, Vector2i(4, 3)], ["fear", 3.0, Vector2i(4, 3)], ["entrance", 3.0, Vector2i(7, 3)]]:
		stage(lancin, {v(1): Vector2i(2, 3), v(3): k[2]})
		soak(v(3))
		var s := carrying(effect(k[0], k[1]))
		v(1).refresh()
		var f := b.foresee(v(1), s, v(3))
		var end := Vector2i(f.notes[0].split("(")[1].split(",")[0].to_int(), 3)
		ok(f.notes.size() == 1 and Battle.VERBS[StringName(k[0])] in f.notes[0], "%s is said: %s" % [k[0], f.notes])
		b.cast(v(1), s, v(3))
		ok(v(3).cell == end and end != k[2], "%s: foreseen end %s is where it went (%s)" % [k[0], end, v(3).cell])


func test_a_stop_short_is_foreseen() -> void:
	var edge := Vector2i(7, 3)
	while b.on_map(edge + Vector2i.RIGHT):
		edge += Vector2i.RIGHT
	var room := edge.x - 7  # tiles from (7, 3) to the edge
	stage(lancin, {v(1): Vector2i(2, 3), v(3): Vector2i(7, 3)})
	soak(v(3), 300)
	var s := carrying(effect("shove", room + 2.0))
	v(1).refresh()
	var f := b.foresee(v(1), s, v(3))
	ok(f.lo == Battle.SLAM * 2 and f.hi == f.lo and f.riders == Battle.PUSH * room and "slams the edge" in f.notes[0], "driven into the edge: the tiles it has, then the slam (%s)" % [f])
	var blow: int = Battle.damage_range(v(1), s, v(3), b).get("lo", 0)  # (the carrier's own hit)
	ok(b.cast(v(1), s, v(3)) and v(3).hp == 300 - blow - f.lo, "and the slam is what it took, on top of the blow (%d: %d + %d)" % [300 - v(3).hp, blow, f.lo])
	stage(lancin, {v(1): Vector2i(2, 3), v(3): Vector2i(4, 3), v(2): Vector2i(5, 3)})
	soak(v(3), 300)
	s = carrying(effect("shove", 3.0))
	f = b.foresee(v(1), s, v(3))
	ok(f.spill == -float(Battle.SLAM * 3) and f.riders == 0.0, "into its own ally: the ally's slam is against it (%s)" % [f])
	v(2).faction = nemes
	ok(b.foresee(v(1), s, v(3)).spill == float(Battle.SLAM * 3), "into a foe: for it")
	s.dual = true
	ok(b.foresee(v(1), s, v(3)).is_empty(), "a dual skill's effects skip a foe: nothing foreseen")


func test_displace_foresees() -> void:
	var d := Displace.new()
	d.tiles = 3
	var s: Skill = hex.duplicate()
	s.behaviours = [d] as Array[Behaviour]
	v(1).learned.append(slot(s))
	for mode in [[false, false, Vector2i(5, 3)], [true, false, Vector2i(6, 3)], [false, true, Vector2i(7, 3)]]:
		stage(lancin, {v(1): Vector2i(2, 3), v(3): mode[2]})
		v(1).refresh()
		soak(v(3))
		d.toward = mode[0]
		d.teleport = mode[1]
		var f := b.foresee(v(1), s, v(3))
		var end := Vector2i(f.notes[0].split("(")[1].split(",")[0].to_int(), 3)
		b.displace(v(3), v(1).cell, -1 if d.toward else 1, d.reach(b.cast_of(v(1), s, v(3), 1, true)), d.teleport)
		ok(v(3).cell == end and end != mode[2] and f.notes.size() == 1, "toward %s, teleport %s: foreseen %s, went %s" % [d.toward, d.teleport, end, v(3).cell])


# Aura and Coordinate put their skill's effects on others as a cast does, so a forced move on them drives.
func test_aura_and_coordinate_drive() -> void:
	var s: Skill = load("res://Skills/flamecharm.tres").duplicate()
	s.effects = [effect("shove", 2.0)] as Array[Effect]
	v(1).learned.append(slot(s))
	stage(lancin, {v(1): Vector2i(3, 3), v(2): Vector2i(4, 3)})
	v(1).refresh()
	ok(b.cast(v(1), s, v(1)) and v(2).cell == Vector2i(6, 3) and v(1).cell == Vector2i(3, 3), "an aura's shove drives its allies from the caster (%s)" % v(2).cell)
	var c: Skill = load("res://Skills/coordinate.tres").duplicate()
	c.effects = [effect("fear", 2.0)] as Array[Effect]
	v(1).learned.append(slot(c))
	stage(lancin, {v(1): Vector2i(3, 3), v(2): Vector2i(4, 3)})
	v(1).refresh()
	ok(b.cast(v(1), c, v(1)) and v(2).cell == Vector2i(6, 3), "and so does a link's fear (%s)" % v(2).cell)


# The audit of what impairs a unit's ability to act (cc) and what forces a unit itself (shove): Skills/*.tres and the
# statuses they put on, by what they do - a new one that stuns, sleeps, grapples or drives a unit joins the table.
func test_cc_and_shove_are_tagged() -> void:
	var cc_stats := ["sleep", "helpless", "grappled", "jammed", "no_traits", "winded", "mindless", "fear", "entrance"]
	var cc_skills := [&"stun", &"jam", &"slam_jam", &"hitch", &"drown", &"coalescing", &"brainfog", &"interdict", &"bludgeon", &"sing", &"mindless_fury"]
	var seen := 0
	for f in DirAccess.get_files_at("res://Skills"):
		if not f.ends_with(".tres"):
			continue
		var s: Skill = load("res://Skills/" + f)
		var id := StringName(f.get_basename())
		var forces := s.behaviours.any(func(h: Behaviour): return (h is Displace and not h.toward) or h.get_script().resource_path.ends_with("/kick.gd"))
		ok((&"shove" in s.tags) == forces, "%s: shove only where its own force moves a unit (%s)" % [id, forces])
		var impairs := s.effects.any(func(e: Effect): return &"cc" in e.bears) or s.disables or Displace.draws(s) != null or id in cc_skills
		ok((&"cc" in s.tags) == impairs, "%s: cc where it impairs a unit's ability to act (%s)" % [id, impairs])
		for e in s.effects:
			ok(&"cc" in e.bears or e.stat not in cc_stats, "%s's %s status: cc where it impairs (%s)" % [id, e.stat, e.bears])
			ok(&"cc" not in e.tags, "%s's %s: cc is borne, never a filter" % [id, e.stat])
		seen += 1
	for f in DirAccess.get_files_at("res://Effects"):
		if f.ends_with(".tres"):
			var e: Effect = load("res://Effects/" + f)
			ok((&"cc" in e.bears) == (e.stat in cc_stats or e.stat == "tow"), "%s: cc where it impairs a unit's ability to act (%s)" % [f, e.stat])
	ok(seen > 200, "every skill audited (%d)" % seen)
	var stunned: Effect = load("res://Effects/stunned.tres")
	v(1).afflict(stunned, 2)
	v(1).afflict(effect("mitigate", 0.5), 2)
	ok(v(1).afflicted(&"cc").size() == 1 and v(1).afflicted(&"cc")[0] == stunned and &"cc" in Glossary.TERMS and Tags.coloured(&"cc"), "Unit.afflicted() finds the statuses that bear it; cc has its term and colour")
