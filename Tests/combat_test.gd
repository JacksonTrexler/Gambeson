extends Test

# Full battles on the museum map played by the game AI (Scripts/AI.gd), checking invariants after
# every unit's turn. Each invariant is one ok() per battle: it fails with the first seed, turn and unit
# that broke it. 8 seeds by default; `soak` on the runner's command line fights all 30. (The check count
# is far lower than when every evaluation was an ok(); the invariants and the battles are the same.)

const MAX_TURNS := 100
const SEEDS := 8
const SOAK_SEEDS := 30
const REPLAY_TURNS := 5
const INVARIANTS: Array[String] = ["hp/energy in range", "moved within its movement", "AP never negative",
		"on the board iff alive", "board and positions agree", "over exactly when one faction is left",
		"only the turn's faction moves"]


func test_battles() -> void:
	var wins := {}
	var turns_taken: Array[int] = []
	var seeds := SOAK_SEEDS if "soak" in OS.get_cmdline_user_args() else SEEDS
	for seed in seeds:
		var result := fight(seed)
		ok(result.over, "seed %d: battle ends within %d turns" % [seed, MAX_TURNS])
		for what in INVARIANTS:
			ok(not result.broke.has(what), "seed %d: %s (first broken: %s)" % [seed, what, result.broke.get(what, "")])
		wins[result.winner] = wins.get(result.winner, 0) + 1
		turns_taken.append(result.turns)
	print("  %d battles: " % seeds, ", ".join(wins.keys().map(func(k): return "%s %d" % [k, wins[k]])),
			" | turns %d-%d" % [turns_taken.min(), turns_taken.max()])


func test_replay() -> void:
	var seven: Array = fight(7, REPLAY_TURNS).log
	ok(seven == fight(7, REPLAY_TURNS).log, "same seed, same battle")
	ok(seven != fight(8, REPLAY_TURNS).log, "different seed, different battle")


# Plays a battle (up to `max_turns`); result.broke maps each INVARIANTS entry that failed to the
# "turn N, unit" where it first did.
func fight(seed: int, max_turns := MAX_TURNS) -> Dictionary:
	var scene: Node = load("res://Scenes/museum.tscn").instantiate()
	scene.get_node("Battle").rng.seed = seed
	tree.root.add_child(scene)
	b = scene.get_node("Battle")
	Exhaustion.on = true  # a whole battle, as it's played (Test.calm() turns it off for staged tests)
	var log: Array[String] = []
	var broke := {}
	var turns := 0
	peak = {}
	while b.phase == Battle.Phase.TURNS and turns < max_turns:
		for other in b.units.values():
			if other.faction != b.turn:
				if not b.travel(other, other.cell + Vector2i.RIGHT).is_empty():
					broke[INVARIANTS[6]] = broke.get(INVARIANTS[6], "turn %d, %s" % [turns + 1, other.name])
				break
		for u in b.members(b.turn):
			log.append_array(AI.act(b, u))
			check(broke, turns + 1)
			if b.phase != Battle.Phase.TURNS:
				break
		b.end_turn()
		turns += 1
	var alive := b.units.values().map(func(u): return u.faction.name)
	var result := {over = b.phase == Battle.Phase.OVER, turns = turns, log = log, broke = broke,
			winner = alive[0] if alive else "nobody"}
	scene.free()
	return result


var peak := {}  # unit -> the most movement it has had since its moved count last reset (check())


# Notes into `broke` the first time each invariant fails ("turn N, who").
func check(broke: Dictionary, turn: int) -> void:
	for u: Unit in b.get_node("Units").get_children():
		# Movement is live (a tile's bonus left behind, a slow, a fall), so what it spent is held to the
		# most it had since its count last reset, not to what it has now.
		var mv := u.stat(&"movement")
		peak[u] = mv if u.moved == 0.0 else maxf(peak.get(u, mv), mv)
		_note(broke, 0, turn, u.name, u.hp >= 0 and u.hp <= u.max_hp and u.energy >= 0 and u.energy <= u.max_energy)
		_note(broke, 1, turn, u.name, u.moved <= peak[u] + 0.0001)
		_note(broke, 2, turn, u.name, u.ap.all(func(p: AP): return p.amount >= -0.0001))
		_note(broke, 3, turn, u.name, u.is_alive() == (b.unit_at(u.cell) == u))
	for c in b.units:
		_note(broke, 4, turn, b.units[c].name, b.units[c].cell == c and b.units[c].position == b.map.map_to_local(c))
	var sides := {}
	for u in b.units.values():
		sides[u.faction] = true
	_note(broke, 5, turn, "the board", (sides.size() < 2) == (b.phase == Battle.Phase.OVER))


func _note(broke: Dictionary, which: int, turn: int, who: String, good: bool) -> void:
	if not good and not broke.has(INVARIANTS[which]):
		broke[INVARIANTS[which]] = "turn %d, %s" % [turn, who]
