extends Test

# Routes steer round what the walker knows is harmful (Battle.route()), by the one cost stride() that the
# walk, the HUD's preview and the AI all pay; and the hazard estimate (Battle.hazard(), HUD.hazard())
# counts a wound's every tick and the afflicts of ordinary known ground.

const TRAP := Vector2i(5, 4)


func walker(int_score := 10) -> void:
	stage(lancin, {v(1): Vector2i(4, 4), v(3): Vector2i(1, 1)})
	v(1).intelligence = int_score
	v(1).movement = 9
	v(1).refresh()


func test_steers_round_a_known_trap() -> void:
	walker()
	var plain: Array = b.walk(v(1), Vector2i(7, 4), true).path
	ok(plain.back() == Vector2i(7, 4) and TRAP in plain, "a trap it hasn't found: the plan goes through (%s)" % [plain])
	b.revealed[TRAP] = true
	var w := b.walk(v(1), Vector2i(7, 4), true)
	ok(w.path.back() == Vector2i(7, 4) and TRAP not in w.path and w.path.size() == 3, "a known one: round it, for the same movement (%s)" % [w.path])
	ok(w.line == w.path, "the preview's line is the route")
	var state := b.rng.state
	b.walk(v(1), Vector2i(7, 4), true)
	ok(b.rng.state == state, "planning leaves the rng alone")
	var hp := v(1).hp
	var walked := b.travel(v(1), Vector2i(7, 4))
	ok(walked == w.path and v(1).cell == Vector2i(7, 4) and v(1).hp == hp, "the walk takes the planned route and springs nothing (%s)" % [walked])


func test_the_ai_walks_round_it_too() -> void:
	walker()
	stage(nemes, {v(3): Vector2i(4, 4), v(1): Vector2i(1, 1)})
	v(3).intelligence = 10
	v(3).movement = 9
	v(3).refresh()
	b.revealed[TRAP] = true
	var hp := v(3).hp
	b.travel(v(3), Vector2i(7, 4))
	ok(v(3).cell == Vector2i(7, 4) and v(3).hp == hp, "an AI unit's travel() steers by the same route")


func test_only_what_it_knows() -> void:
	walker()
	b.snares[TRAP] = Battle.Snare.new(b.terrain(TRAP), v(3))  # laid by someone else, unseen by v(1)
	var hidden: Array = b.walk(v(1), Vector2i(7, 4), true).path
	ok(TRAP in hidden, "it can't steer by a trap it has no read on, though the map has it (%s)" % [hidden])
	b.snares[TRAP].known[v(1)] = true  # it has been told
	b._views.clear()
	ok(TRAP not in b.walk(v(1), Vector2i(7, 4), true).path, "told of it, it goes round")


func test_negative_int_plans_regardless() -> void:
	walker(8)  # -1
	b.revealed[TRAP] = true
	ok(b.foresight_allowance(v(1)) == -1 and b.walk(v(1), Vector2i(7, 4), true).path.back() == TRAP, "a negative int mod plans optimistically: through the trap, and it stops there")
	v(1).afflict(effect("foresight", 1.0), 5)
	ok(b.foresight_allowance(v(1)) == 0 and TRAP not in b.walk(v(1), Vector2i(7, 4), true).path, "a foresight bonus that lifts it to 0 steers again")


func test_fire_is_steered_round() -> void:
	walker()
	b.flames[TRAP] = Battle.Flame.new(v(3), 1)
	var w := b.walk(v(1), Vector2i(7, 4), true)
	ok(TRAP not in w.path and w.path.back() == Vector2i(7, 4), "known fire: round it (%s)" % [w.path])


func test_no_way_round_keeps_the_line() -> void:
	walker()
	b.revealed[TRAP] = true
	for y in range(2, 7):  # fire across the whole width it may wander, the trap the cheapest crossing
		if y != 4:
			b.flames[Vector2i(5, y)] = Battle.Flame.new(v(3), 1)
	var path: Array = b.walk(v(1), Vector2i(7, 4), true).path
	ok(path.back() == TRAP, "when every way costs more than the straight one, it stays on the line (%s)" % [path])


func test_a_long_way_round_isnt_worth_it() -> void:
	walker()
	b.revealed[TRAP] = true
	# known ground that drags it, either side of the trap: the way round costs more than the trap weighs
	var mud := Terrain.new()
	mud.name = "Mud ??"
	mud.drag = 4.0
	for c in [Vector2i(4, 3), Vector2i(5, 3), Vector2i(6, 3), Vector2i(4, 5), Vector2i(5, 5), Vector2i(6, 5)]:
		b.lay_layer(c, mud, false)
	var path: Array = b.walk(v(1), Vector2i(7, 4), true).path
	ok(path.back() == TRAP, "a detour dearer than the hazard's weight isn't taken (%s)" % [path])


func test_bleed_counts_every_tick() -> void:
	walker()
	b.revealed[TRAP] = true
	var wound := effect("bleed", 1.0)
	wound.dice = Vector2i(1, 4)
	var spike: Terrain = b.terrain(TRAP).duplicate()
	spike.wounds = [wound] as Array[Effect]
	spike.wound_turns = 3
	b.snares[TRAP] = Battle.Snare.new(spike, v(3))
	b._views.clear()
	var dice := spike.times * spike.dice.x * (spike.dice.y + 1) / 2.0 + spike.bonus
	var owed := b.hazard(v(1), TRAP, b.read(v(1), TRAP))
	ok(is_equal_approx(owed.get(&"hp", 0.0), dice + 3 * 2.5), "its dice and three ticks of 1d4 (%s)" % [owed])
	var poison := effect("poison", 0.1)
	spike.wounds = [poison] as Array[Effect]
	owed = b.hazard(v(1), TRAP, b.read(v(1), TRAP))
	ok(is_equal_approx(owed.get(&"hp", 0.0), dice + 3 * 0.1 * v(1).max_hp), "poison each turn of its length (%s)" % [owed])


func test_afflicts_of_known_ground() -> void:
	walker()
	var brier := Terrain.new()
	brier.name = "Briers ??"
	brier.turns = 2
	var sting := effect("bleed", 3.0)
	var winded := effect("winded", 1.0)
	brier.afflicts = [sting, winded] as Array[Effect]
	var c := Vector2i(5, 4)
	b.lay_layer(c, brier, false)
	var owed := b.hazard(v(1), c, b.read(v(1), c))
	ok(is_equal_approx(owed.get(&"hp", 0.0), 6.0) and owed.get(&"ap") == 1.0, "ordinary ground's afflicts: 3 a turn for 2 turns, and winded once (%s)" % [owed])
	ok(b.hazard(v(1), c, Read.new()).is_empty(), "ground it can't read owes nothing")
	var w := b.walk(v(1), Vector2i(7, 4), true)
	ok(c not in w.path and w.path.back() == Vector2i(7, 4), "and it steers round it (%s)" % [w.path])
	sting.turns = 0
	brier.turns = 3
	ok(is_equal_approx(b.hazard(v(1), c, b.read(v(1), c)).get(&"hp", 0.0), 9.0), "an effect without turns of its own takes the ground's")
