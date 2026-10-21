extends Test

# Full battles on the museum map played by the game AI (Scripts/AI.gd), checking invariants after
# every unit's turn.

const MAX_TURNS := 100


func test_battles() -> void:
	var wins := {}
	var turns_taken: Array[int] = []
	for seed in 30:
		var result := fight(seed)
		ok(result.over, "seed %d: battle ends within %d turns" % [seed, MAX_TURNS])
		wins[result.winner] = wins.get(result.winner, 0) + 1
		turns_taken.append(result.turns)
	print("  30 battles: ", ", ".join(wins.keys().map(func(k): return "%s %d" % [k, wins[k]])),
			" | turns %d-%d" % [turns_taken.min(), turns_taken.max()])


func test_replay() -> void:
	ok(fight(7).log == fight(7).log, "same seed, same battle")
	ok(fight(7).log != fight(8).log, "different seed, different battle")


func fight(seed: int) -> Dictionary:
	var scene: Node = load("res://Scenes/museum.tscn").instantiate()
	scene.get_node("Battle").rng.seed = seed
	tree.root.add_child(scene)
	b = scene.get_node("Battle")
	var log: Array[String] = []
	var turns := 0
	while b.phase == Battle.Phase.TURNS and turns < MAX_TURNS:
		for other in b.units.values():
			if other.faction != b.turn:
				ok(b.travel(other, other.cell + Vector2i.RIGHT).is_empty(), "seed %d: only the turn's faction moves" % seed)
				break
		for u in b.members(b.turn):
			log.append_array(AI.act(b, u))
			check(seed)
			if b.phase != Battle.Phase.TURNS:
				break
		b.end_turn()
		turns += 1
	var alive := b.units.values().map(func(u): return u.faction.name)
	var result := {over = b.phase == Battle.Phase.OVER, turns = turns, log = log,
			winner = alive[0] if alive else "nobody"}
	scene.free()
	return result


func check(seed: int) -> void:
	for u: Unit in b.get_node("Units").get_children():
		ok(u.hp >= 0 and u.hp <= u.max_hp and u.energy >= 0 and u.energy <= u.max_energy, "seed %d: %s hp/energy in range" % [seed, u.name])
		ok(u.moved <= u.stat(&"movement") + 0.0001, "seed %d: %s moved within its movement" % [seed, u.name])
		ok(u.ap.all(func(p: AP): return p.amount >= -0.0001), "seed %d: %s AP never negative" % [seed, u.name])
		ok(u.is_alive() == (b.unit_at(u.cell) == u), "seed %d: %s on the board iff alive" % [seed, u.name])
	for c in b.units:
		ok(b.units[c].cell == c and b.units[c].position == b.map.map_to_local(c), "seed %d: board and positions agree" % seed)
	var sides := {}
	for u in b.units.values():
		sides[u.faction] = true
	ok((sides.size() < 2) == (b.phase == Battle.Phase.OVER), "seed %d: over exactly when one faction is left" % seed)
