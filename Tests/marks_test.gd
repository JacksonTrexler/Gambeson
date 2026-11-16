extends Test

# Tile marks (Battle.Mark, lay_mark(), _trigger()): effects, a trigger and a lifetime on a tile, one
# generic thing for later skills to lay. Who knows of one is Mark.told() and the tile's read
# (Perception.tile()); the hazard estimate and routes count the harmful ones they know (docs/plans/tile-marks.md).

const AT := Vector2i(5, 4)


# A mark by v(1)'s side on AT, for foes, putting `e` on whoever enters; `concealment` hides it.
func lay(e: Effect, concealment := 0, who := &"foes") -> Battle.Mark:
	var m := Battle.Mark.new(&"test", v(1))
	m.who = who
	m.effects.assign([e] if e else [])
	m.concealment = concealment
	return b.lay_mark(AT, m)


# u on its side's turn at (8, 4), moving 9; with int 8 (mod -1) it plans optimistically, so it walks straight over marks.
func walker(f: Faction, u: Unit, int_score := 8) -> void:
	stage(f, {u: Vector2i(8, 4), (v(1) if u != v(1) else v(3)): Vector2i(1, 1)})
	u.movement = 9
	u.intelligence = int_score
	u.refresh()


func test_a_mark_triggers_once() -> void:
	var poor := effect("luck", -1)
	lay(poor)
	walker(nemes, v(3))
	var seen := []
	b.marked.connect(func(c: Vector2i, u: Unit, m: Battle.Mark): seen.append([c, u]))
	b.travel(v(3), Vector2i(3, 4))
	ok(poor in v(3).timed and seen.size() == 1 and seen[0][0] == AT, "a foe walking over it: its effect goes on, once")
	ok(not b.marks.has(AT), "used up: gone")
	var ta := v(3).timed[poor]
	ok(ta.by == v(1) and ta.turns == 1, "marked as laid by its setter, until its own turn ends")
	b.move(v(4), Vector2i(8, 4))
	stage(nemes, {v(4): Vector2i(8, 4), v(1): Vector2i(1, 1)})
	v(4).movement = 9
	v(4).refresh()
	b.travel(v(4), Vector2i(3, 4))
	ok(poor not in v(4).timed and seen.size() == 1, "the next one walks over bare ground")


func test_only_those_it_is_for() -> void:
	var poor := effect("luck", -1)
	lay(poor)  # for foes
	walker(lancin, v(2))
	b.travel(v(2), Vector2i(3, 4))
	ok(poor not in v(2).timed and b.has_mark(AT, &"test"), "its own side walks through it: nothing, and it stays")
	b.marks.clear()
	lay(poor, 0, &"allies")
	walker(nemes, v(3))
	b.travel(v(3), Vector2i(3, 4))
	ok(poor not in v(3).timed and b.has_mark(AT, &"test"), "an `allies` mark leaves a foe be")
	stage(lancin, {v(2): Vector2i(8, 4), v(3): Vector2i(1, 1)})
	v(2).movement = 9
	v(2).refresh()
	b.travel(v(2), Vector2i(3, 4))
	ok(poor in v(2).timed and not b.marks.has(AT), "...and goes off for an ally")


func test_it_lasts_so_many_of_its_sides_turns() -> void:
	var m := lay(null)
	m.turns = 2
	m.uses = 0
	stage(nemes, {v(3): Vector2i(8, 4), v(1): Vector2i(1, 1)})
	b.end_turn()
	ok(b.has_mark(AT, &"test") and m.turns == 2, "another side's turns don't count")
	stage(lancin, {v(1): Vector2i(1, 1), v(3): Vector2i(8, 4)})
	b.end_turn()
	ok(m.turns == 1 and b.has_mark(AT, &"test"), "its side's turn: one fewer")
	stage(lancin, {v(1): Vector2i(1, 1), v(3): Vector2i(8, 4)})
	b.end_turn()
	ok(not b.marks.has(AT), "and gone when they run out")


func test_a_mark_that_stays_until_its_turns_run_out() -> void:
	var m := lay(effect("luck", -1))
	m.uses = 0
	walker(nemes, v(3))
	b.travel(v(3), Vector2i(3, 4))
	ok(b.has_mark(AT, &"test") and v(3).timed.size() >= 1, "uses 0: it goes off for each that enters, and stays")


func test_turn_end_trigger() -> void:
	var poor := effect("luck", -1)
	var m := lay(poor)
	m.on = &"end"
	stage(nemes, {v(3): AT, v(1): Vector2i(1, 1)})
	b.end_turn()
	ok(poor in v(3).timed and not b.marks.has(AT), "ending its turn on an `end` mark: it goes off")
	m = lay(poor)
	m.on = &"end"
	stage(nemes, {v(3): Vector2i(8, 4), v(1): Vector2i(1, 1)})
	v(3).timed.clear()
	b.place(v(3), AT)
	ok(poor not in v(3).timed, "an `end` mark isn't an entry")
	b.marks.clear()
	m = lay(poor)
	b.place(v(3), Vector2i(6, 4))
	b.place(v(3), AT)
	ok(poor in v(3).timed, "an `enter` mark goes off when it's placed there too (a teleport)")


func test_who_knows() -> void:
	var m := lay(effect("luck", -1), 2)
	stage(lancin, {v(1): Vector2i(1, 1), v(2): Vector2i(1, 5), v(3): Vector2i(8, 2), v(4): Vector2i(8, 5)})
	ok(b.read(v(1), AT).marks == [m] and b.read(v(2), AT).marks == [m], "its side knows it's there")
	ok(b.read(v(3), AT).marks.is_empty() and b.known_marks(v(3), AT).is_empty(), "a foe with no read on the tile doesn't")
	sharp(v(3))
	ok(b.read(v(3), AT).marks == [m], "...until its recon gets through the concealment")
	var plain := Battle.Mark.new(&"plain", v(1))
	b.lay_mark(Vector2i(6, 6), plain)
	ok(b.read(v(4), Vector2i(6, 6)).marks == [plain], "nothing hiding it: everyone knows (like fire)")
	b.marks[AT][0].known[v(4)] = true
	ok(b.read(v(4), AT).marks == [m], "told: known")
	v(3).afflict(effect("recon", -3), 9)
	b.marks[AT][0].known.erase(v(4))
	ok(b.known_marks(v(4), AT).is_empty() or v(4).stat(&"recon") > 0, "(unknown to the unread again)")


func test_hazard_counts_known_marks() -> void:
	var bleed := effect("bleed", 3.0)
	var m := lay(bleed, 2)
	stage(nemes, {v(3): Vector2i(8, 4), v(1): Vector2i(1, 1)})
	var r := b.read(v(3), AT)
	ok(b.hazard(v(3), AT, r).is_empty(), "unknown to the walker: nothing foreseen")
	m.known[v(3)] = true
	r = b.read(v(3), AT)
	ok(is_equal_approx(b.hazard(v(3), AT, r).get(&"hp", 0.0), 3.0), "known: its bleed's HP foreseen (%s)" % [b.hazard(v(3), AT, r)])
	ok(b.hazard(v(1), AT, b.read(v(1), AT)).is_empty(), "not for those it doesn't go off on")


func test_routes_round_a_known_harmful_mark() -> void:
	var m := lay(null, 2)
	m.cost = 3.0
	walker(nemes, v(3), 10)
	var via: Array = b.walk(v(3), Vector2i(2, 4), true).path
	ok(AT in via, "a mark it can't see: the plan goes through it (%s)" % [via])
	m.known[v(3)] = true
	var w := b.walk(v(3), Vector2i(2, 4), true)
	ok(AT not in w.path and w.path.back() == Vector2i(2, 4), "known: round it (%s)" % [w.path])
	var hp := v(3).hp
	var walked := b.travel(v(3), Vector2i(2, 4))
	ok(walked == w.path and b.has_mark(AT, &"test"), "the real walk takes it, and the mark is untouched")
	m.cost = 0.0
	m.effects.assign([effect("luck", -1)])
	ok(m.harms(v(3)) and not m.harms(v(1)), "harmful to the foes it's for, not to its own side")
	ok(AT not in b.walk(v(3), Vector2i(2, 4), true).path, "a harmful effect alone steers it round too")


func test_cost_is_paid_on_entering() -> void:
	var m := lay(null)
	m.cost = 2.0
	walker(nemes, v(3))
	var w := b.walk(v(3), Vector2i(3, 4))
	var at: int = w.path.find(AT)
	ok(at >= 1 and is_equal_approx(w.costs[at], w.costs[at - 1] + 2.0), "entering it costs 2 more movement than the tile before (%s)" % [w.costs])
	b.travel(v(3), Vector2i(3, 4))
	ok(not b.marks.has(AT), "paid, and used up")
	stage(nemes, {v(4): Vector2i(8, 4), v(1): Vector2i(1, 1)})
	var again := b.walk(v(4), Vector2i(3, 4))
	ok(again.costs.size() == 0 or is_equal_approx(again.costs.reduce(func(s, x): return s + x, 0.0), float(again.path.size())), "gone: plain ground again")


# A mark hidden from the player's side shows the HUD's "?" as a hidden trap does (item 5 of
# docs/plans/gaps-react-marks.md): from the hint its concealment gives, and from suspicion that hasn't got through it.
func test_hud_suspects_a_hidden_mark() -> void:
	var spot := Vector2i(3, 5)  # plain ground (AT is a trap)
	stage(lancin, {v(1): Vector2i(2, 4), v(3): Vector2i(8, 1)})
	var m := Battle.Mark.new(&"test", v(3))
	m.concealment = 3
	m.effects.assign([effect("luck", -1)])
	b.lay_mark(spot, m)
	var h := await hud(v(1))
	ok(spot in h.suspect and spot in b.maybe_suspicious(v(1)), "hidden from it, its tile is marked with a ? (%s)" % [h.suspect.get(spot)])
	h.hover_cell(spot)
	ok(h.get_node("%TileLines").get_children().map(func(l): return l.get_parsed_text()) == ["?"], "and the tile card says something's there, nothing more")
	m.concealment = 2
	v(1).suspicion[spot] = 1  # not enough to see through it: recon 0 - (2 - 1) = -1, no hint to give
	b._views.clear()
	h._refresh()
	ok(b.read(v(1), spot).net == -1 and b.read(v(1), spot).hint == "" and spot in h.suspect, "suspected, still hidden, no hint: still a ? (net -1)")
	h.hover_cell(spot)
	ok(h.get_node("%TileNotes").get_children().any(func(l): return l.get_parsed_text() == "Suspicious of it: 1"), "the tile card counts its suspicion")
	m.concealment = 1
	b._views.clear()
	h._refresh()
	ok(spot not in h.suspect and not b.read(v(1), spot).marks.is_empty(), "seen through: the mark is known, no longer a ? (%s, %s)" % [h.suspect.get(spot), b.read(v(1), spot).net])
	h.free()


# A known helpful mark (Charge!) pulls a route a little (item 6 of docs/plans/gaps-react-marks.md): of two ways
# as long as each other it takes the one through it, never a longer way, and not one it can't see, nor a foe's.
func test_helpful_marks_pull() -> void:
	var edge := Vector2i(7, 3)  # a tile beside the straight run (8,4) -> (6,4), as far as it
	var good := effect("damage", 0.1)
	var dest := Vector2i(6, 4)
	stage(lancin, {v(2): Vector2i(8, 4), v(3): Vector2i(1, 1)})
	v(2).movement = 9
	v(2).intelligence = 12  # it plans (a negative foresight allowance walks the line)
	v(2).refresh()
	var plain := b.travel(v(2), dest)
	ok(plain == ([Vector2i(7, 4), dest] as Array[Vector2i]), "no mark: the straight run (%s)" % [b.line(Vector2i(8, 4), dest, v(2).luck, v(2))])
	b.move(v(2), Vector2i(8, 4))
	var m := Battle.Mark.new(&"test", v(1))
	m.who = &"allies"
	m.effects.assign([good])
	b.lay_mark(edge, m)
	ok(m.helps(v(2)) and b.lure(v(2), edge) == Battle.HELP_PULL and b.lure(v(3), edge) == 0.0, "a mark for its side helps it, not a foe")
	var way := b.route(v(2), dest, b.line(Vector2i(8, 4), dest, v(2).luck, v(2)))
	ok(edge in way and way.size() == 2, "a way as short through it: it bends to it (%s)" % [way])
	b.move(v(2), Vector2i(8, 4))
	var far := Battle.Mark.new(&"far", v(1))
	far.who = &"allies"
	far.effects.assign([good])
	b.marks.clear()
	b.lay_mark(Vector2i(7, 1), far)  # two tiles out: a longer way to it
	ok(not (Vector2i(7, 1) in b.route(v(2), dest, b.line(Vector2i(8, 4), dest, v(2).luck, v(2)))), "never a longer way")
	b.marks.clear()
	var hid := Battle.Mark.new(&"hid", v(3))  # a foe's (it's for its foes: v(2) is one), hidden
	hid.who = &"foes"
	hid.concealment = 3
	hid.effects.assign([good])
	b.lay_mark(edge, hid)
	ok(not hid.told(v(2)) and b.lure(v(2), edge) == 0.0, "one it can't make out is no lure")


func test_helpful_marks_draw_the_approach() -> void:
	stage(lancin, {v(2): Vector2i(5, 3), v(3): Vector2i(1, 3), v(1): Vector2i(2, 3)})  # the straight way in is taken; the two diagonal tiles cost the same
	var reads := {v(3): b.read(v(2), v(3))}
	var first := AI._approach(b, v(2), v(3), reads)
	var m := Battle.Mark.new(&"test", v(1))
	m.who = &"allies"
	m.effects.assign([effect("damage", 0.1)])
	b.lay_mark(Vector2i(2, 2), m)
	var drawn := AI._approach(b, v(2), v(3), reads)
	ok(first == Vector2i(2, 4) and drawn == Vector2i(2, 2), "it closes by the tile with a mark that helps it, over one as near (%s, %s)" % [first, drawn])
