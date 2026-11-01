extends Test

# Hearts: a unit taking mortal damage with a heart left goes down instead of falling - holding its
# tile, beyond harm - and gets up at full HP as the turn ends, bringing what it summons (a
# Regeneration Probe). A probe's Regeneration Pulse heals its allies once every (its side's lives
# left) turns (Battle._pulse()). Units the player doesn't command act on their own (shades).

var probe: PackedScene = load("res://Scenes/probe.tscn")


func test_down_and_up() -> void:
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3), v(4): Vector2i(8, 6)})
	v(3).hearts = 1
	v(3).summons = probe
	v(3).afflict(effect("luck", 1), 9)
	var downs := []
	b.downed.connect(func(u: Unit): downs.append(u))
	v(3).hp = 0
	ok(downs == [v(3)] and not v(3).is_alive() and v(3).reviving and v(3).hearts_used == 1 and v(3).lives_left() == 0, "down, a heart spent")
	ok(b.unit_at(Vector2i(5, 3)) == v(3) and v(3).timed.is_empty(), "it holds its tile; nothing stays on it")
	ok(b.phase == Battle.Phase.TURNS and not b.cast(v(1), strike, v(3)), "the battle goes on; it can't be hit")
	ok(b.lives(nemes) == 1 and b.lives_left(nemes) == 0, "its side: 1 life, none left")
	var ups := []
	b.revived.connect(func(u: Unit, came: Unit): ups.append([u, came]))
	b.end_turn()
	ok(ups.size() == 1 and ups[0][0] == v(3) and v(3).is_alive() and v(3).hp == v(3).max_hp and not v(3).reviving, "as the turn ends, it gets up at full HP")
	var came: Unit = ups[0][1]
	ok(came != null and came.faction == nemes and b.unit_at(came.cell) == came and Command.tiles(came.cell, v(3).cell) <= 1, "a probe beside it, on its side")
	v(3).hp = 0
	ok(not v(3).is_alive() and not v(3).reviving and b.unit_at(Vector2i(5, 3)) == null, "no hearts left: it falls")


func test_pulse() -> void:
	stage(nemes, {v(3): Vector2i(5, 3), v(4): Vector2i(6, 3), v(1): Vector2i(1, 1)})
	var p := b.summon(probe, nemes, Vector2i(5, 4))
	ok(p and p.stat(&"pulse") == 1.0 and p.behaviour == &"skittish", "a Regeneration Probe")
	v(3).hearts = 2
	v(4).hp = 3
	var pulses := []
	b.pulsed.connect(func(u: Unit, healed: Dictionary): pulses.append(healed))
	b.end_turn()
	b.end_turn()
	ok(pulses.is_empty(), "2 lives left: not on the first of its turns")
	b.end_turn()
	b.end_turn()
	ok(pulses.size() == 1 and v(4) in pulses[0] and pulses[0][v(4)] >= 1 and v(1) not in pulses[0], "on the second: its allies near it, not its foes %s" % [pulses])
	v(3).hearts_used = 2
	b.end_turn()
	b.end_turn()
	ok(pulses.size() == 2, "none left: every turn")
	ok("Regeneration Pulse: every (its side's lives left) turns, heals allies within 3 tiles" in (load("res://Skills/regeneration_pulse.tres") as Skill).describe(1), "described")


func test_skittish() -> void:
	stage(nemes, {v(1): Vector2i(2, 3)})
	var p := b.summon(probe, nemes, Vector2i(4, 3))
	p.refresh()
	var before := Command.tiles(p.cell, v(1).cell)
	AI.act(b, p)
	ok(Command.tiles(p.cell, v(1).cell) > before, "it keeps away from its foes")


func test_uncontrolled() -> void:
	var shade: Unit = load("res://Scenes/shade.tscn").instantiate()
	shade.faction = lancin
	shade.cell = Vector2i(2, 3)
	b.get_node("Units").add_child(shade)
	b.move(shade, shade.cell)
	stage(lancin, {v(1): Vector2i(1, 3), shade: Vector2i(2, 3), v(3): Vector2i(8, 3)})
	var c := Command.new(b, v(1))
	ok(not c.can_order(shade) and not c.can_join(shade) and shade in c.idle(), "a shade takes no orders and joins no party: it acts on its own")
