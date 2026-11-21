extends SceneTree

# The AI sim set: scratch battles for what the museum fight can't exercise (docs/plans/ai-sim.md). Not in the suite
# (Tests/run.gd only reads Tests/*_test.gd). Run:
#   godot --headless --path . -s Tests/sims/ai_sim.gd -- [scenario words] [n=8]
# Prints one `SIM <scenario> key=value ...` line per scenario. Constants are `const`, so a sweep edits the source and
# reruns: Tests/sims/sweep.sh CONSTANT low high [scenario words].
#   hunt     an Observe user after a hider that was seen once (Hide's debris, last seen, reach), still and moving
#   clash    two clues pull apart (debris at one end, a sighting at the other): rounds to find it when each is the true one
#   ambush   an Observe user struck by a hider it can't place (the blows)
#   kick     Kick against a wall behind the foe, 0..3 tiles off, and in the open: Kick or Strike
#   grudge   a Grudge unit in a corner, two foes near it and one more to fight: who starves, who is hit
#   rider    Poach and Slam Jam among Strike and Hex, foes near falling: the choices, the rounds to win
#   cc       Stun among Strike against a hard hitter and a weak foe (what a cc is worth, AI._afflicting()): who is stunned, idle turns
#   armor    a foe in plate or in rags, its Defense not read: Strike or Hex (GUESS_DEFENSE)
#   plate    plated foes (Power Armor, Scrap Plating): v(1) carrying spare armor dresses (rounds, Defense) with a foe near and far; Strike at two foes of one Defense, only one's blocks costing it Power
#   dread    v(1), foes' skills read, against a Stunner v(3) starting `gap` tiles off (AI._shy(), DREAD): stuns it takes, turns it holds or backs off, who strikes first, the winner
#   worn     Strike and Hex worn by exhaustion, 10 rounds on a soaker (WORN)
#   host     a Skeleton caster 10 tiles from a soaker, 8 rounds: bodies raised, damage dealt (AI._summon(), BODY)
#   hostnear the same with the soaker 5 tiles off, in the skeletons' walk: damage with and without them (sweep BODY "0 5")
#   hide     Invisibility offered to an ally with a watcher of rising wisdom (SEEN)
# Saves and settings go to per-process files, as run.gd (a sim must never touch the player's own).

const MUSEUM := "res://Scenes/museum.tscn"
const ROUNDS := 10

var _museum: PackedScene
var _debug := false  # `debug` among the arguments: a line a round for hunt and ambush


class Sim extends Test:
	var rng := RandomNumberGenerator.new()
	var logs: Array[String] = []

	# Cells around c within r tiles that a unit can stand on, empty and not a trap.
	func spots(c: Vector2i, r: int) -> Array[Vector2i]:
		var out: Array[Vector2i] = []
		for x in b.cells_near(c, r):
			if b.map.get_cell_source_id(x) != -1 and b.unit_at(x) == null and not b.terrain(x).is_trap():
				out.append(x)
		return out

	func pick(from: Array[Vector2i]) -> Vector2i:
		return from[rng.randi() % from.size()]

	func near_or_here(u: Unit, r: int) -> Array[Vector2i]:
		var out := spots(u.cell, r)
		out.append(u.cell)
		return out

	# One side's turn: each unit acts by the AI (its log kept), then the turn passes.
	func turn(units: Array) -> void:
		for u: Unit in units:
			if u.is_alive():
				logs.append_array(AI.act(b, u))
		b.end_turn()

	func uses(who: String, skill: String) -> int:
		return logs.filter(func(l: String): return l.begins_with(who + " uses " + skill)).size()

	func count(word: String) -> int:
		return logs.filter(func(l: String): return word in l).size()

	# Neither side remembers seeing anyone, searching anywhere or being struck (the battle's start put every unit down).
	func forget_all() -> void:
		b.sightings.clear()
		b.sighted_when.clear()
		b.swept.clear()
		b.attacks.clear()

	var cover: Effect = effect("concealment", 7)  # one Effect, so a refresh doesn't stack a second

	func hiding(u: Unit) -> void:
		u.afflict(cover, 9)

	func observer(u: Unit) -> void:
		u.wisdom = 16
		u.learned.append(slot(sk("observe"), 1))
		u.refresh()

	# The first skill an act used (the name between "uses " and " on "), or "" for none.
	func first_use(u: Unit) -> String:
		for l in AI.act(b, u):
			if " uses " in l:
				return l.split(" uses ")[1].split(" on ")[0]
		return ""


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_debug = "debug" in args
	var words := Array(args).filter(func(a: String): return not a.begins_with("n=") and a != "debug")
	var n := 8
	for a in args:
		if a.begins_with("n="):
			n = int(a.substr(2))
	Prefs.SAVE = "user://settings_sim_%d.cfg" % OS.get_process_id()
	var pid := OS.get_process_id()
	var save: GDScript = load("res://Scripts/Save.gd")
	save.set("PATH", "user://save_sim_%d.json" % pid)
	var keys: GDScript = load("res://Scripts/KeyBinds.gd")
	keys.set("SAVE", "user://keybinds_sim_%d.cfg" % pid)
	_museum = load(MUSEUM)
	for sc in ["hunt", "clash", "ambush", "kick", "grudge", "rider", "cc", "armor", "plate", "worn", "hide", "host", "hostnear", "dread"]:
		if words.is_empty() or words.any(func(w: String): return w in sc):
			await call("_" + sc, n)
	for p in [Prefs.SAVE, keys.get("SAVE"), save.get("PATH"), save.get("PATH") + ".bad", save.get("PATH") + ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	quit()


# A fresh museum, seeded, wrapped for the scenario: Game's statics as run.gd leaves them.
func _fresh(seed: int) -> Sim:
	Game.starter = {}
	Game.difficulty = 0.0
	Game.dungeon = null
	Game.hero = {}
	Game.outfit = {}
	Game.level = 1
	Unit.auto_equip = true
	Game.xp = 0
	Game.hearts = 0
	Game.stash = []
	Game.equipped = []
	var scene: Node = _museum.instantiate()
	scene.get_node("Battle").rng.seed = seed
	root.add_child(scene)
	await process_frame
	var t := Sim.new()
	t.b = scene.get_node("Battle")
	t.tree = self
	t.rng.seed = seed * 7919 + 13
	t.calm()
	return t


func _drop(t: Sim) -> void:
	t.b.get_parent().free()


func _say(name: String, stats: Dictionary) -> void:
	var parts: Array[String] = []
	for k in stats:
		var x: Variant = stats[k]
		parts.append("%s=%s" % [k, ("%.2f" % x) if x is float else str(x)])
	print("SIM %s %s" % [name, " ".join(parts)])


# Rounds until v(1) makes v(3) out (Read.located()), a hider seen once, `moving` or not; ROUNDS if it never does.
func _hunt(n: int) -> void:
	for moving in [false, true]:
		var found := 0
		var lost := 0
		var looks := 0
		for seed in n:
			var t := await _fresh(seed)
			var far := t.pick(t.spots(Vector2i(8, 2), 2))
			var at := t.pick(t.spots(Vector2i(1, 6), 2))
			t.stage(t.lancin, {t.v(1): at, t.v(3): far})
			t.observer(t.v(1))
			t.b.revealed[Vector2i(4, 4)] = true
			t.forget_all()
			var hide: Skill = load("res://Skills/hide.tres")
			t.v(3).learned.append(t.slot(hide, 1))
			t.v(3).refresh()
			t.b.cast(t.v(3), hide, t.v(3))  # the debris it leaves
			t.hiding(t.v(3))
			t.b.sighted(t.lancin, t.v(3), far, 2.0)  # seen there a moment ago, then it hid
			var step := t.pick(t.spots(far, 2))
			t.b.move(t.v(3), step)
			var rounds := ROUNDS
			for r in ROUNDS:
				var before := t.logs.size()
				if _debug:
					var cl := AI.clues(t.b, t.v(1))
					var tot := 0.0
					for k in cl:
						tot += cl[k]
					print("  clues r%d n=%d total=%.2f max=%.2f swept=%s turns=%d" % [r, cl.size(), tot, cl.values().max() if not cl.is_empty() else 0.0, t.b.swept.get(t.lancin, {}).size(), t.b.turns_begun])
				t.turn([t.v(1)])
				if _debug:
					print("  hunt r%d v1 %s hider %s located %s | %s" % [r, t.v(1).cell, t.v(3).cell, t.b.read(t.v(1), t.v(3)).located(), t.logs.slice(before)])
				if t.b.read(t.v(1), t.v(3)).located():
					rounds = r + 1
					break
				if moving:
					t.b.move(t.v(3), t.pick(t.near_or_here(t.v(3), 2)))
				t.hiding(t.v(3))
				t.turn([])
			if rounds < ROUNDS:
				found += rounds
			else:
				lost += 1
			looks += t.uses("Villager1", "Observe")
			_drop(t)
		_say("hunt-" + ("moving" if moving else "still"), {found_rounds = float(found) / maxi(n - lost, 1), lost = lost, looks = float(looks) / n})
	await process_frame


# Debris at (8, 6) and a sighting at (8, 1), two rounds old, equally far from v1 at (1, 6); the hider is really where the
# debris is ("debris"), or near the sighting while the debris is a stranger's, a second hider's ("seen"). Rounds to find it.
func _clash(n: int) -> void:
	for truth in ["debris", "seen"]:
		var found := 0
		var lost := 0
		var looks := 0
		for seed in n:
			var t := await _fresh(seed)
			var y := Vector2i(8, 6)
			var x := Vector2i(8, 1)
			var real := y if truth == "debris" else x + Vector2i(0, 1 + t.rng.randi() % 2)
			t.stage(t.lancin, {t.v(1): Vector2i(1, 6), t.v(3): real, t.v(4): Vector2i(9, 9)})
			t.v(4).faction = t.nemes
			t.observer(t.v(1))
			t.v(1).wisdom = 12  # a look of 2 tiles: it can't take in both ends
			t.cover = t.effect("concealment", 6)
			t.b.revealed[Vector2i(4, 4)] = true
			t.forget_all()
			t.b.sighted(t.lancin, t.v(3), x, 2.0)
			t.b.debris[y] = Battle.Debris.new("Disturbed foliage, twigs", t.v(3) if truth == "debris" else t.v(4), t.b.turns_begun)
			t.b.turns_begun += 2
			t.hiding(t.v(3))
			t.hiding(t.v(4))
			var rounds := ROUNDS
			for r in ROUNDS:
				t.turn([t.v(1)])
				if _debug:
					print("  clash %s r%d v1 %s located %s | %s" % [truth, r, t.v(1).cell, t.b.read(t.v(1), t.v(3)).located(), t.logs.slice(-2)])
				if t.b.read(t.v(1), t.v(3)).located():
					rounds = r + 1
					break
				t.hiding(t.v(3))
				t.turn([])
			if rounds < ROUNDS:
				found += rounds
			else:
				lost += 1
			looks += t.uses("Villager1", "Observe")
			_drop(t)
		_say("clash-" + truth, {found_rounds = float(found) / maxi(n - lost, 1), lost = lost, looks = float(looks) / n})
	await process_frame


# A hider strikes v(1) from behind each round; rounds until v(1) makes it out, hp it loses.
func _ambush(n: int) -> void:
	var found := 0
	var lost := 0
	var hp := 0.0
	var looks := 0
	for seed in n:
		var t := await _fresh(seed)
		t.stage(t.nemes, {t.v(1): Vector2i(5, 5), t.v(3): Vector2i(4, 5)})
		t.b.revealed[Vector2i(4, 4)] = true
		t.forget_all()
		t.hiding(t.v(3))
		t.v(1).facing = Vector2.RIGHT
		t.observer(t.v(1))
		t.soak(t.v(1), 400)
		var rounds := ROUNDS
		for r in ROUNDS:
			t.v(3).refresh()
			t.hiding(t.v(3))
			var hit := t.b.cast(t.v(3), t.strike, t.v(1))
			if _debug:
				print("  ambush r%d hider cast %s turn %s" % [r, hit, t.b.turn.name])
			t.b.end_turn()
			t.turn([t.v(1)])
			if _debug:
				print("  ambush r%d hp %d located %s | %s" % [r, t.v(1).hp, t.b.read(t.v(1), t.v(3)).located(), t.logs.slice(-2)])
			if t.b.read(t.v(1), t.v(3)).located():
				rounds = r + 1
				break
		if rounds < ROUNDS:
			found += rounds
		else:
			lost += 1
		hp += t.v(1).max_hp - t.v(1).hp
		looks += t.uses("Villager1", "Observe")
		_drop(t)
	_say("ambush", {found_rounds = float(found) / maxi(n - lost, 1), lost = lost, hp_lost = hp / n, looks = float(looks) / n})
	await process_frame


# v(1) (Kick, strength 10 or 40, Strike) against a foe d tiles from the map's edge with its back to it (d = 9: open
# ground): Kick's score less Strike's, an AI choice read straight off its prices (positive: it kicks), by Kick's rank.
# Then a seeded fight on the edge and in the open: Kicks used in 6 rounds.
func _kick(n: int) -> void:
	for rank in [1, 3]:
		for str in [10, 40]:
			var margins := {}
			for d in [0, 1, 2, 3, 9]:
				var t := await _fresh(1)
				t.v(1).learned.append(t.slot(t.sk("kick"), rank))
				t.v(1).strength = str
				t.stage(t.lancin, {t.v(1): Vector2i(d + 1, 3), t.v(3): Vector2i(d, 3)} if d < 9 else {t.v(1): Vector2i(4, 3), t.v(3): Vector2i(5, 3)})
				t.v(1).refresh()
				t.soak(t.v(3), 300)
				var r := t.b.read(t.v(1), t.v(3))
				margins["edge%d" % d] = AI.score(t.v(1), t.sk("kick"), r, t.b, t.v(3)) - AI.score(t.v(1), t.strike, r, t.b, t.v(3))
				_drop(t)
			var t := await _fresh(1)  # and a friend of the kicker's behind the foe: the drive stops short, the slam hurts both
			t.v(1).learned.append(t.slot(t.sk("kick"), rank))
			t.v(1).strength = str
			t.stage(t.lancin, {t.v(1): Vector2i(4, 3), t.v(3): Vector2i(5, 3), t.v(2): Vector2i(6, 3)})
			t.v(1).refresh()
			t.soak(t.v(3), 300)
			var r := t.b.read(t.v(1), t.v(3))
			margins["ally"] = AI.score(t.v(1), t.sk("kick"), r, t.b, t.v(3)) - AI.score(t.v(1), t.strike, r, t.b, t.v(3))
			_drop(t)
			_say("kick-margin-rank%d-str%d" % [rank, str], margins)
	var wall := 0
	var open := 0
	for seed in n:
		for edge in [true, false]:
			var t := await _fresh(seed)
			t.v(1).learned.append(t.slot(t.sk("kick"), 2))
			t.v(1).strength = 10
			t.stage(t.lancin, {t.v(1): Vector2i(1, 3), t.v(3): Vector2i(0, 3)} if edge else {t.v(1): Vector2i(4, 3), t.v(3): Vector2i(5, 3)})
			t.v(1).refresh()
			t.soak(t.v(3), 300)
			for r in 6:
				t.turn([t.v(1)])
				t.b.end_turn()
			if edge:
				wall += t.uses("Villager1", "Kick")
			else:
				open += t.uses("Villager1", "Kick")
			_drop(t)
	_say("kick-fight", {kicks_at_wall = float(wall) / n, kicks_in_open = float(open) / n})
	await process_frame


# v(3) (Grudge II) goes down in the corner at (0, 0); v(1) and v(2) stand 3-6 tiles off, v(4) a standing foe between.
# Each round Lancin acts, then Nemes (v(3), v(4)). Their HP lost, the starving turns, Grudge's blows, rounds to end.
func _grudge(n: int) -> void:
	var lost := 0.0
	var starved := 0
	var blows := 0
	var dead := 0
	var kills := 0
	for seed in n:
		var t := await _fresh(seed)
		t.v(3).learned.append(t.slot(load("res://Skills/grudge.tres"), 2))
		var a := Vector2i(1 + t.rng.randi() % 3, 3 + t.rng.randi() % 3)
		var c := Vector2i(4 + t.rng.randi() % 3, 1 + t.rng.randi() % 3)
		t.v(1).strength = 20  # a blow worth giving up
		t.v(2).strength = 20
		t.stage(t.lancin, {t.v(1): a, t.v(2): c, t.v(3): Vector2i(0, 0), t.v(4): a + Vector2i(1, -1)})  # a foe at the first Lancin's shoulder: a blow to take or a Grudge to starve
		t.v(4).faction = t.nemes
		t.v(4).hp = maxi(t.v(4).max_hp / 2, 1)
		t.v(1).refresh()
		t.v(2).refresh()
		t.v(3).refresh()
		t.v(3).damage(999)
		t.v(3).dbno.fresh = false
		var before := t.v(1).hp + t.v(2).hp
		for r in 6:
			t.turn([t.v(1), t.v(2)])
			if t.b.phase != Battle.Phase.TURNS:
				break
			t.turn([t.v(3), t.v(4)])
			if t.b.phase != Battle.Phase.TURNS:
				break
		lost += before - t.v(1).hp - t.v(2).hp
		starved += t.count("starving")
		blows += t.uses("Villager3", "")
		dead += 1 if not t.v(1).is_alive() or not t.v(2).is_alive() else 0
		kills += 1 if not t.v(4).is_alive() else 0
		_drop(t)
	_say("grudge", {lancin_hp_lost = lost / n, starving_turns = float(starved) / n, grudge_blows = float(blows) / n, lancin_downed = dead, foe_killed = kills})
	await process_frame


# v(1): Strike, Poach, Slam Jam (II), against v(3) (twice the HP) and v(4) (half) of Nemes, v(2) beside it. Who is used, rounds to win.
func _rider(n: int) -> void:
	var tally := {}
	var rounds := 0.0
	var wins := 0
	var hp := 0.0
	for seed in n:
		var t := await _fresh(seed)
		t.v(1).strength = 12
		t.v(1).learned.append(t.slot(t.sk("poach")))
		t.v(1).learned.append(t.slot(t.sk("slam_jam"), 2))
		t.roomy(t.v(1))
		t.v(1).refresh()
		t.stage(t.lancin, {t.v(1): Vector2i(4, 3), t.v(2): Vector2i(3, 4), t.v(3): Vector2i(5, 3), t.v(4): Vector2i(5, 4)})
		t.v(3).max_hp *= 4  # sturdy: a fight of several rounds, the cheap kill and the slam each in turn
		t.v(3).hp = t.v(3).max_hp
		t.v(4).max_hp *= 2
		t.v(4).hp = t.v(4).max_hp / 2
		var done := ROUNDS
		for r in ROUNDS:
			t.turn([t.v(1), t.v(2)])
			if t.b.phase != Battle.Phase.TURNS:
				done = r + 1
				break
			t.turn([t.v(3), t.v(4)])
			if t.b.phase != Battle.Phase.TURNS:
				done = r + 1
				break
		rounds += done
		wins += 1 if not t.v(3).is_alive() and not t.v(4).is_alive() else 0
		hp += t.v(1).hp + t.v(2).hp
		for s in ["Strike", "Poach", "Slam Jam", "Hex"]:
			tally[s] = tally.get(s, 0) + t.uses("Villager1", s) + t.uses("Villager2", s)
		_drop(t)
	_say("rider", {strike = float(tally.Strike) / n, poach = float(tally.Poach) / n, slam_jam = float(tally["Slam Jam"]) / n, hex = float(tally.Hex) / n,
			rounds = rounds / n, won = wins, lancin_hp = hp / n})
	await process_frame


# v(1) with Strike and Stun (II) beside v(2) against v(4), a hard hitter (strength 40, four times the HP), and v(3), a weak foe
# (strength 1, half the HP), v(1) reading them at recon 0 (nothing), 1 (stats) and 3 (skills). Stuns and Strikes used, v(1)'s turns with no skill used (a price must not turn a unit
# passive), Lancin's HP left, rounds to win.
func _cc(n: int) -> void:
	for recon in [0, 1, 3]:  # nothing read of the foes, their stats, their skills
		await _cc_at(n, recon)


func _cc_at(n: int, recon: int) -> void:
	var tally := {}
	var idle := 0
	var hard := 0
	var weak := 0
	var first := 0
	var turns := 0
	var rounds := 0.0
	var wins := 0
	var hp := 0.0
	for seed in n:
		var t := await _fresh(seed)
		t.v(1).strength = 12
		t.v(1).afflict(t.effect("recon", recon), 99)
		t.v(1).learned.append(t.slot(t.sk("stun"), 2))
		t.roomy(t.v(1))
		t.v(1).refresh()
		t.stage(t.lancin, {t.v(1): Vector2i(4, 3), t.v(2): Vector2i(3, 4), t.v(3): Vector2i(5, 3), t.v(4): Vector2i(5, 4)})
		t.v(4).strength = 40  # the hard hitter comes second in the list: a tie goes to the weak foe
		t.v(4).max_hp *= 4
		t.v(4).hp = t.v(4).max_hp
		t.v(3).strength = 1
		t.v(3).max_hp *= 2
		t.v(3).hp = t.v(3).max_hp / 2
		var done := ROUNDS
		for r in ROUNDS:
			if t.v(1).is_alive():
				var log := AI.act(t.b, t.v(1))
				t.logs.append_array(log)
				turns += 1
				idle += 0 if log.any(func(l: String): return " uses " in l) else 1
			t.turn([t.v(2)])
			if t.b.phase != Battle.Phase.TURNS:
				done = r + 1
				break
			t.turn([t.v(3), t.v(4)])
			if t.b.phase != Battle.Phase.TURNS:
				done = r + 1
				break
		rounds += done
		wins += 1 if not t.v(3).is_alive() and not t.v(4).is_alive() else 0
		hp += t.v(1).hp + t.v(2).hp
		for s in ["Strike", "Stun"]:
			tally[s] = tally.get(s, 0) + t.uses("Villager1", s)
		hard += t.count("uses Stun on Villager4")
		weak += t.count("uses Stun on Villager3")
		var opening := t.logs.filter(func(l: String): return "uses Stun on" in l)
		first += 1 if not opening.is_empty() and "on Villager4" in opening[0] else 0
		_drop(t)
	_say("cc-recon%d" % recon, {strike = float(tally.Strike) / n, stun = float(tally.Stun) / n, stun_hard_hitter = float(hard) / n, stun_weak_foe = float(weak) / n, first_stun_on_hard_hitter = float(first) / n, idle_turns = float(idle) / n, of_turns = float(turns) / n, rounds = rounds / n, won = wins, lancin_hp = hp / n})
	await process_frame


# v(1) (the foes' skills read) closes on a plain foe v(3), 3 tiles east and 3 north; v(4) with Stun stands to the west, its reach
# covering the side of v(3) nearest v(1) and not the far one (AI._stunners(), DREAD): 4 rounds, the foes acting after it. Stuns v(1)
# took, the share of its blows (Strike) that were at v(3), its HP left, who is left of the foes.
func _dread(n: int) -> void:
	var stuns := 0
	var blows := 0
	var at_plain := 0
	var hp := 0.0
	var left := 0
	for seed in n:
		var t := await _fresh(seed)
		t.v(1).afflict(t.effect("recon", 3), 99)
		t.v(4).learned.append(t.slot(t.sk("stun"), 2))
		t.roomy(t.v(1))
		t.v(4).refresh()
		t.stage(t.lancin, {t.v(1): Vector2i(4, 6), t.v(3): Vector2i(7, 3), t.v(4): Vector2i(0, 3)})
		t.v(3).strength = 1
		for r in 4:
			if t.v(1).is_alive():
				t.logs.append_array(AI.act(t.b, t.v(1)))
			t.b.end_turn()
			t.turn([t.v(3), t.v(4)])
			if t.b.phase != Battle.Phase.TURNS:
				break
		stuns += t.count("uses Stun on Villager1")
		blows += t.count("Villager1 uses Strike")
		at_plain += t.count("Villager1 uses Strike on Villager3")
		hp += t.v(1).hp
		left += int(t.v(3).is_alive()) + int(t.v(4).is_alive())
		_drop(t)
	_say("dread", {stuns = float(stuns) / n, blows = float(blows) / n, blows_at_plain_foe = float(at_plain) / n, v1_hp = hp / n, foes_left = float(left) / n})
	await process_frame


# v(1) with Strike and Hex against v(3): bare (Defense 0) or plated (20), its armor not read; uses of each over 6 rounds.
func _armor(n: int) -> void:
	for plated in [false, true]:
		var strikes := 0
		var hexes := 0
		var dmg := 0.0
		var unread := 0
		for seed in n:
			var t := await _fresh(seed)
			t.v(1).learned.append(t.slot(t.hex))
			t.roomy(t.v(1))
			t.stage(t.lancin, {t.v(1): Vector2i(4, 3), t.v(3): Vector2i(5, 3)})
			if plated:
				t.v(3).armor = t.bulwark()
			t.v(3).afflict(t.effect("concealment", 1), 99)  # dimly made out: placed, its armor not read
			t.v(1).refresh()
			t.soak(t.v(3), 300)
			unread += 1 if t.b.read(t.v(1), t.v(3)).located() and t.b.read(t.v(1), t.v(3)).defense == null else 0
			for r in 6:
				t.turn([t.v(1)])
				t.b.end_turn()
			strikes += t.uses("Villager1", "Strike")
			hexes += t.uses("Villager1", "Hex")
			dmg += 300 - t.v(3).hp
			_drop(t)
		var t := await _fresh(1)
		t.v(1).learned.append(t.slot(t.hex))
		t.stage(t.lancin, {t.v(1): Vector2i(4, 3), t.v(3): Vector2i(5, 3)})
		if plated:
			t.v(3).armor = t.bulwark()
		t.v(3).afflict(t.effect("concealment", 1), 99)
		t.v(1).refresh()
		t.soak(t.v(3), 300)
		var read := t.b.read(t.v(1), t.v(3))
		var worth := {}
		for s: Skill in [t.strike, t.hex]:  # what each is truly worth against it (its real Defense), and as the AI prices it unread
			var d := Battle.damage_range(t.v(1), s, t.v(3), t.b)
			worth[s.name + "_true"] = Battle.hit_chance(t.v(1), s, t.v(3), t.b) * d.avg
			worth[s.name + "_ai"] = AI.score(t.v(1), s, read, t.b, t.v(3))
			worth[s.name + "_p"] = AI._chance(t.v(1), s, read, t.b, t.v(3))
		worth["hp_read"] = read.hp
		_drop(t)
		_say("armor-" + ("plated" if plated else "bare"), worth.merged({strike = float(strikes) / n, hex = float(hexes) / n, damage = dmg / n, unread = unread}))
	await process_frame


# v(1) carries a Bulwark and has Scrap Plating: a foe v(3) far off or in reach (it dresses in the first round it has AP over:
# Defense after 3 rounds, strikes); then v(1) at two foes of Defense 20 - v(4) in the slot of Power Armor, v(3) wearing it proper (listed first: a tie goes to it)
# - its first blow's target and the Power it drains.
func _plate(n: int) -> void:
	for near in [false, true]:
		var defense := 0.0
		var dressed := 0
		var strikes := 0
		for seed in n:
			var t := await _fresh(seed)
			t.stage(t.lancin, {t.v(1): Vector2i(4, 3), t.v(3): Vector2i(5, 3) if near else Vector2i(8, 6)})
			t.v(1).learned.append(t.slot(t.sk("scrap_plating"), 3))
			t.v(1).pack.append(t.bulwark())
			t.roomy(t.v(1))
			t.v(1).refresh()
			t.soak(t.v(3), 300)
			for r in 3:
				t.turn([t.v(1)])
				t.b.end_turn()
			if _debug:
				print("  ", t.logs.slice(-4), t.v(1).ap_for(&"equip"), t.v(1).plate_slots(), t.v(1).pack.size())
			defense += t.v(1).defense()
			dressed += 1 if t.v(1).get(&"plate_scrap_plating") != null else 0
			strikes += t.uses("Villager1", "Strike")
			_drop(t)
		_say("plate-dress-" + ("near" if near else "far"), {defense = defense / n, dressed = dressed, strikes = float(strikes) / n})
	var first := 0
	var power := 0.0
	var power_hits := 0
	for seed in n:
		var t := await _fresh(seed)
		t.stage(t.lancin, {t.v(1): Vector2i(4, 3), t.v(3): Vector2i(5, 3), t.v(4): Vector2i(3, 3)})
		for foe: Unit in [t.v(3), t.v(4)]:
			foe.learned.clear()
			foe.armor = null
			foe.plating.clear()
			t.soak(foe, 300)
		t.v(4).learned.append(t.slot(t.sk("power_armor"), 3))
		t.v(3).learned.append(t.slot(t.sk("scrap_plating"), 5))
		t.v(4).equip(t.bulwark(), Unit.plate_slot(t.sk("power_armor")))
		t.v(3).armor = t.bulwark()
		t.v(3).refresh()
		t.v(4).refresh()
		var scrap := AI.score(t.v(1), t.strike, t.b.read(t.v(1), t.v(3)), t.b, t.v(3))
		var power_armor := AI.score(t.v(1), t.strike, t.b.read(t.v(1), t.v(4)), t.b, t.v(4))
		var pre := t.v(4).energy
		if _debug:
			print("  def3=%s def4=%s read4=%s plates4=%s scores %s %s blocks %s" % [t.v(3).defense(), t.v(4).defense(), t.b.read(t.v(1), t.v(4)).defense, t.v(4).plates().size(), scrap, power_armor, AI._blocks(t.b, t.v(1), t.strike, t.b.read(t.v(1), t.v(4)), t.v(4), 5.0)])
		t.turn([t.v(1)])
		first += 1 if t.uses("Villager1", "Strike") > 0 and t.logs.any(func(l: String): return l.begins_with("Villager1 uses Strike on") and t.v(4).name in l) else 0
		power += pre - t.v(4).energy
		power_hits += 1 if power_armor > scrap else 0
		_drop(t)
	_say("plate-blocks", {struck_power_armor_first = first, of = n, power_drained = power / n, scored_higher = power_hits})
	await process_frame


# Exhaustion on: Strike and Hex used on a soaker for 10 rounds; uses of each, damage done.
func _worn(n: int) -> void:
	var strikes := 0
	var hexes := 0
	var dmg := 0.0
	for seed in n:
		var t := await _fresh(seed)
		t.v(1).learned.append(t.slot(t.hex))
		t.roomy(t.v(1))
		t.stage(t.lancin, {t.v(1): Vector2i(4, 3), t.v(3): Vector2i(5, 3)})
		Exhaustion.on = true
		t.v(1).refresh()
		t.soak(t.v(3), 900)
		for r in ROUNDS:
			t.turn([t.v(1)])
			t.b.end_turn()
		strikes += t.uses("Villager1", "Strike")
		hexes += t.uses("Villager1", "Hex")
		dmg += 900 - t.v(3).hp
		Exhaustion.on = false
		_drop(t)
	_say("worn", {strike = float(strikes) / n, hex = float(hexes) / n, damage = dmg / n})
	await process_frame


# v(1) with Skeleton against a soaker v(3) 9 tiles off, ROUNDS rounds: the bodies it raises and the damage to the foe.
func _host(n: int) -> void:
	await _hosts(n, 13, "host")


# The same with the soaker 5 tiles off: within the skeletons' walk, so what they raise strikes it (BODY 0 is the AI that never raised them).
func _hostnear(n: int) -> void:
	await _hosts(n, 8, "hostnear")


func _hosts(n: int, foe_x: int, name: String) -> void:
	var bodies := 0
	var dmg := 0.0
	for seed in n:
		var t := await _fresh(seed)
		t.v(1).learned.append(t.slot(load("res://Skills/skeleton.tres")))
		t.roomy(t.v(1))
		t.stage(t.lancin, {t.v(1): Vector2i(4, 3), t.v(3): Vector2i(foe_x, 3)})
		t.soak(t.v(3), 900)
		var before: int = t.b.members(t.lancin).size()
		for r in ROUNDS:
			t.turn(t.b.members(t.lancin))
		bodies += t.b.members(t.lancin).size() - before
		dmg += 900 - t.v(3).hp
		_drop(t)
	_say(name, {bodies = float(bodies) / n, damage = dmg / n})
	await process_frame


# v(1) (Invisibility, can hide v(2)) with a watcher v(3) of wisdom w beside: does it hide, for w in a ladder.
func _hide(_n: int) -> void:
	var out := {}
	for w in [1, 20, 30, 33, 36, 40, 60]:
		var t := await _fresh(1)
		var inv: Skill = load("res://Skills/invisibility.tres")
		t.v(1).learned.append(t.slot(inv, 1))
		t.v(1).intelligence = 20
		t.v(1).refresh()
		t.stage(t.lancin, {t.v(1): Vector2i(4, 3), t.v(2): Vector2i(5, 3), t.v(3): Vector2i(6, 3)})
		t.v(2).intelligence = 1
		t.v(3).wisdom = w
		var log: Array[String] = []
		AI._support(t.b, t.v(1), {t.v(2): t.b.read(t.v(1), t.v(2)), t.v(3): t.b.read(t.v(1), t.v(3))}, log)
		out["wis%d" % w] = "hides" if not log.is_empty() else "holds"
		_drop(t)
	_say("hide", out)
	await process_frame
