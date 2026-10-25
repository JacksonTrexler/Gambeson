extends Test

# Straight-line movement over terrain costs, AP, luck squeezing in, traps, holes and units.
# Map: rough (6,1) (7,1) (6,2) (2,5) (3,5); shrine (5,2) (3,6); bramble (2,2); hidden trap (5,4).

func cells(a: Array) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	out.assign(a)
	return out


func test_line_shape() -> void:
	var good := true
	for a in [Vector2i(0, 0), Vector2i(4, 3), Vector2i(9, 7)]:
		for x in 10:
			for y in 8:
				var bb := Vector2i(x, y)
				if bb == a:
					continue
				var path := b.line(a, bb, 0)
				var at: Vector2i = a
				var distinct := {}
				for c in path:
					good = good and absi(c.x - at.x) <= 1 and absi(c.y - at.y) <= 1 and c != a
					distinct[c] = true
					at = c
				good = good and path.size() == ceili(Vector2(a).distance_to(Vector2(bb)) - 0.0001)
				good = good and distinct.size() == path.size() and path[-1] == bb
	ok(good, "every line: ceil(distance) distinct, adjacent tiles, ending at the target")


func test_terrain_costs() -> void:
	stage(lancin, {v(1): Vector2i(1, 2)})
	var p := b.travel(v(1), Vector2i(6, 2))
	ok(p == cells([Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2), Vector2i(5, 2)]), "bramble 1, leaving it 1 + 1, grass 1, shrine 1 = 5: stops before the rough")
	ok(v(1).cell == Vector2i(5, 2) and v(1).moved == 5.0, "5 movement spent")
	ok(v(1).ap[1].amount == 0 and v(1).ap[0].amount == 6, "5 AP: the dex (move-only) pool first, then 4 general")
	ok(b.travel(v(1), Vector2i(5, 3)).is_empty(), "no movement left this turn")
	stage(nemes, {v(3): Vector2i(5, 1)})
	ok(b.travel(v(3), Vector2i(8, 1)) == cells([Vector2i(6, 1), Vector2i(7, 1), Vector2i(8, 1)]), "rough 2 + rough 2 + grass 1")


func test_squeeze() -> void:
	stage(lancin, {v(1): Vector2i(5, 1)})
	v(1).moved = 4.0
	ok(b.travel(v(1), Vector2i(6, 1)) == cells([Vector2i(6, 1)]) and v(1).moved == 5.0, "1 left for rough (2): lucky rounds 0.5 up and squeezes in")
	stage(nemes, {v(3): Vector2i(5, 1)})
	v(3).moved = 4.0
	ok(b.travel(v(3), Vector2i(6, 1)).is_empty(), "luck 0: standard, stops short")
	v(3).afflict(hex.effects[0], 3)
	ok(b.travel(v(3), Vector2i(6, 1)).is_empty(), "unlucky: stops short too")


func test_trap() -> void:
	stage(lancin, {v(1): Vector2i(4, 4)})
	v(1).moved = 4.5
	ok(b.travel(v(1), Vector2i(5, 4)).is_empty(), "lucky won't squeeze onto a hidden trap")
	stage(lancin, {v(1): Vector2i(4, 3)})
	v(1).moved = 4.5
	ok(b.travel(v(1), Vector2i(5, 3)) == cells([Vector2i(5, 3)]), "...but squeezes onto plain grass")
	stage(nemes, {v(3): Vector2i(4, 4)})
	v(3).moved = 4.5
	ok(b.travel(v(3), Vector2i(5, 4)).is_empty(), "luck 0 stops short")
	v(3).afflict(hex.effects[0], 3)
	ok(b.travel(v(3), Vector2i(5, 4)) == cells([Vector2i(5, 4)]), "unlucky stumbles onto it")
	stage(lancin, {v(1): Vector2i(4, 4)})
	ok(b.travel(v(1), Vector2i(5, 4)) == cells([Vector2i(5, 4)]), "with movement to spare anyone walks onto an unknown trap")


func test_tie_luck() -> void:
	# (5,1) -> (6,2) crosses (5.5, 1.5): shrine (5,2) or rough (6,1) are equally near.
	ok(b.line(Vector2i(5, 1), Vector2i(6, 2), 1)[0] == Vector2i(5, 2), "lucky takes the shrine")
	ok(b.line(Vector2i(5, 1), Vector2i(6, 2), -1)[0] == Vector2i(6, 1), "unlucky takes the rough")
	var seen := {}
	for seed in 40:
		b.rng.seed = seed
		seen[b.line(Vector2i(5, 1), Vector2i(6, 2), 0)[0]] = true
	ok(seen.size() == 2, "luck 0: coin")
	ok(b.line(Vector2i(4, 3), Vector2i(4, 6), -5) == b.line(Vector2i(4, 3), Vector2i(4, 6), 5), "no ties, no luck")
	# (1,2) -> (2,3) crosses (1.5, 2.5): grass (1,3) or bramble (2,2), which costs 1 more to leave.
	ok(b.line(Vector2i(1, 2), Vector2i(2, 3), 1)[0] == Vector2i(1, 3), "lucky avoids the sticky bramble")
	ok(b.line(Vector2i(1, 2), Vector2i(2, 3), -1)[0] == Vector2i(2, 2), "unlucky gets stuck in it")


func test_ap_limits() -> void:
	stage(lancin, {v(1): Vector2i(0, 7)})
	v(1).pay(9, &"skill")  # wis 1 + general 8
	ok(is_equal_approx(v(1).ap_for(&"move"), 3.0), "3 AP left that can move (dex 1 + general 2)")
	ok(b.travel(v(1), Vector2i(9, 7)).size() == 3 and v(1).cell == Vector2i(3, 7), "AP caps the move at 3 tiles")
	ok(v(1).ap_for(&"move") == 0.0, "spent")


func test_blockers() -> void:
	stage(lancin, {v(1): Vector2i(1, 2), v(2): Vector2i(3, 2), v(3): Vector2i(9, 0)})
	ok(b.travel(v(1), Vector2i(3, 2)) == cells([Vector2i(2, 2)]) and v(1).moved == 1.0, "stops short of a unit, paying only for tiles kept")
	stage(lancin, {v(1): Vector2i(0, 4), v(2): Vector2i(1, 4)})
	ok(b.travel(v(1), Vector2i(3, 4)).back() == Vector2i(3, 4), "can pass through a unit")
	stage(lancin, {v(1): Vector2i(1, 7)})
	b.map.erase_cell(Vector2i(3, 7))
	ok(b.travel(v(1), Vector2i(5, 7)) == cells([Vector2i(2, 7)]), "a hole stops the line before it")
	stage(nemes, {v(1): Vector2i(1, 1), v(3): Vector2i(8, 7)})
	ok(b.travel(v(1), Vector2i(2, 1)).is_empty(), "not on the other faction's turn")
	stage(lancin, {v(1): Vector2i(1, 1), v(2): Vector2i(9, 7), v(3): Vector2i(9, 0)})
	v(1).damage(99)
	ok(b.phase == Battle.Phase.TURNS and b.travel(v(1), Vector2i(2, 1)).is_empty(), "not when dead (battle still on)")


func test_move_cost_effects() -> void:
	stage(nemes, {v(3): Vector2i(5, 1)})
	v(3).afflict(effect("move_cost", -1, [&"rough"]), 99)  # a Pathfinder-style passive, as data
	ok(b.travel(v(3), Vector2i(8, 1)).size() == 3 and v(3).moved == 3.0, "rough costs 1 with the effect")


func test_moving_through() -> void:
	var al: Unit = b.get_node("Units/Alabaster")
	stage(lancin, {v(1): Vector2i(0, 3), v(2): Vector2i(1, 3), v(3): Vector2i(8, 2), al: Vector2i(5, 6)})
	ok(is_equal_approx(b.pass_cost(v(1), v(2)), 2.4), "through an ally: size 3, 10% off per dex mod, the mover's (+1) and the ally's (+1)")
	ok(is_equal_approx(b.pass_cost(v(1), v(3)), 2.7), "an enemy doesn't step aside: only the mover's dex helps")
	ok(is_equal_approx(b.pass_cost(v(1), al), 3.2), "Alabaster: size 4, clumsy (dex -3 under Stoneskin) but Relay's shove (str +4) helps: 4 x 0.8")
	ok(b.travel(v(1), Vector2i(2, 3)).back() == Vector2i(2, 3) and is_equal_approx(v(1).moved, 4.4), "walking through the ally costs 1 + 2.4, then 1")
	v(1).dexterity = 40
	ok(b.pass_cost(v(1), v(2)) == 0.0, "however nimble, never a boost without Relay")
	v(1).learned.append(slot(load("res://Skills/relay.tres")))
	ok(is_equal_approx(b.pass_cost(v(1), v(2)), 3 * (1 - 1.5 - 0.1 - 0.1)), "with Relay it can go below 0")
	stage(lancin, {v(1): Vector2i(0, 3), v(2): Vector2i(1, 3), v(3): Vector2i(8, 2)})
	ok(b.travel(v(1), Vector2i(2, 3)).size() == 2 and v(1).moved < 0.0 and v(1).move_left() > v(1).stat(&"movement"),
			"a boost: it's further to go than it started with")
