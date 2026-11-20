extends SceneTree

# 10 Rangers seek 10 hiders on a large open field (docs/plans/r-sims.md). Not in the suite. Run:
#   godot --headless --path . -s Tests/sims/hunt_10v10.gd -- [still|moving] [near] [n=8] [rounds=20] [wis=16] [debug]
# `near`: the hiders start within the Rangers' reach (x 6 to 15, not 12 to 56), to measure the search apart from the walk across the field.
# Per seed and as a mean: hiders found, the round of the first find and the last, mean round found. Both modes unless one is named.
# Each hider was seen once where it stood (the Rangers' side knows that spot), cast Hide (debris), then stepped up to 2 tiles and hides
# under one shared concealment 7; `moving` hiders step 2 tiles again every round. Rangers act by the AI (Observe where clues point,
# hunting the last sightings); the hiders only hide. Hider found: some Ranger's read of it is located (Read.located()), checked after
# the Rangers' turn each round. Constants below are the scene: edit and rerun.

const FIELD := Vector2i(60, 40)
const FIELD_SCRIPT := "res://Tests/sims/field.gd"  # loaded at run time: naming it (or Role) as a type here makes the scripts load in a cycle
const RANGERS := 10
const HIDERS := 10
const COVER := 7
const NEAR_X := 6  # `near`: hiders start at x NEAR_X to NEAR_X + NEAR_SPAN - 1
const NEAR_SPAN := 10

var _first: Test = null  # named first: scripts load in the order ai_sim's `extends Test` gives them (any other type first loads them in a cycle)
var _debug := false
var _near := false


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_debug = "debug" in args
	_near = "near" in args
	var n := 8
	var rounds := 20
	var wis := 16
	var modes: Array[bool] = []
	for a in args:
		if a.begins_with("n="):
			n = int(a.substr(2))
		elif a.begins_with("rounds="):
			rounds = int(a.substr(7))
		elif a.begins_with("wis="):
			wis = int(a.substr(4))
		elif a == "still":
			modes.append(false)
		elif a == "moving":
			modes.append(true)
	if modes.is_empty():
		modes = [false, true]
	var probe: Variant = load(FIELD_SCRIPT).new()
	probe.isolate()
	for moving in modes:
		await _mode(moving, n, rounds, wis)
	probe.clean_up()
	quit()


func _mode(moving: bool, n: int, rounds: int, wis: int) -> void:
	var name := ("moving" if moving else "still") + ("-near" if _near else "")
	var rate := 0.0
	var firsts := 0.0
	var lasts := 0.0
	var means := 0.0
	var with_find := 0
	var ms := 0.0
	for seed in n:
		var f: Variant = load(FIELD_SCRIPT).new()
		await f.open(self, seed, FIELD.x, FIELD.y)
		var ranger: Resource = load("res://Roles/ranger.tres")
		var observe: Skill = load("res://Skills/observe.tres")
		var hide: Skill = load("res://Skills/hide.tres")
		var cover: Effect = f.effect("concealment", COVER)  # one Effect: a fresh one a round stacks (ai_sim's lesson)
		var seekers: Array[Unit] = []
		for i in RANGERS:
			var u: Unit = f.add(f.lancin, ranger, Vector2i(2 + i % 3, 3 + i * (FIELD.y - 6) / (RANGERS - 1) if RANGERS > 1 else 3), "Ranger%d" % i)
			u.wisdom = wis
			u.learned.append(f.slot(observe, 1))
			u.refresh()
			seekers.append(u)
		var hiders: Array[Unit] = []
		var taken := {}
		for i in HIDERS:
			var c := _hider_cell(f)
			while c in taken:
				c = _hider_cell(f)
			taken[c] = true
			var h: Unit = f.add(f.nemes, load("res://Roles/rogue.tres"), c, "Hider%d" % i)
			h.learned.append(f.slot(hide, 1))
			h.refresh()
			hiders.append(h)
		for u: Unit in f.b.units.values():
			u.suspicion.clear()
		f.b.sightings.clear()
		f.b.sighted_when.clear()
		f.b.swept.clear()
		f.b.attacks.clear()
		for h in hiders:
			f.b.sighted(f.lancin, h, h.cell, 2.0)  # seen there a moment ago
			f.b.cast(h, hide, h)  # the debris it leaves
			h.afflict(cover, COVER + 2)
			_step(f, h)
		var found := {}  # hider -> round found
		var t0 := Time.get_ticks_usec()
		for r in rounds:
			var played: Dictionary = f.play(f.lancin)
			if _debug:
				print("  %s r%d rangers at %s, acts %.0f ms, end_turn %.0f ms" % [name, r + 1, seekers.map(func(s: Unit): return s.cell.x), played.acts.reduce(func(a: int, x: int): return a + x, 0) / 1000.0, played.end / 1000.0])
			for h in hiders:
				if not found.has(h) and seekers.any(func(s: Unit): return f.b.read(s, h).located()):
					found[h] = r + 1
			if _debug:
				print("  %s seed %d r%d found %d/%d" % [name, seed, r + 1, found.size(), HIDERS])
			if found.size() == HIDERS:
				break
			for h in hiders:
				if moving and not found.has(h):
					_step(f, h)
				h.afflict(cover, COVER + 2)
			f.b.end_turn()
		ms += (Time.get_ticks_usec() - t0) / 1000.0
		var rs: Array = found.values()
		rs.sort()
		var first: Variant = rs[0] if not rs.is_empty() else "-"
		var last: Variant = rs[-1] if not rs.is_empty() else "-"
		var mean := 0.0
		for x in rs:
			mean += x
		mean = mean / rs.size() if not rs.is_empty() else 0.0
		print("SIM hunt10-%s seed=%d found=%d/%d first=%s last=%s mean_round=%.2f" % [name, seed, found.size(), HIDERS, first, last, mean])
		rate += float(found.size()) / HIDERS
		if not rs.is_empty():
			firsts += rs[0]
			lasts += rs[-1]
			means += mean
			with_find += 1
		f.close()
		await process_frame
	print("SIM hunt10-%s MEAN seeds=%d find_rate=%.2f first=%.2f last=%.2f mean_round=%.2f (rounds cap %d, wis %d, %.0f ms a seed)" % [name, n, rate / n, firsts / maxi(with_find, 1), lasts / maxi(with_find, 1), means / maxi(with_find, 1), rounds, wis, ms / n])


# A hider steps to a free cell within 2 tiles (or stays).
func _step(f: Variant, h: Unit) -> void:
	var near: Array = f.b.cells_near(h.cell, 2).filter(func(c: Vector2i): return f.b.unit_at(c) == null and f.b.map.get_cell_source_id(c) != -1)
	if not near.is_empty():
		f.b.move(h, near[f.rng.randi() % near.size()])


# Where a hider starts: across the field, or within the Rangers' reach (`near`).
func _hider_cell(f: Variant) -> Vector2i:
	var x: int = NEAR_X + f.rng.randi() % NEAR_SPAN if _near else 12 + f.rng.randi() % (FIELD.x - 15)
	return Vector2i(x, 3 + f.rng.randi() % (FIELD.y - 6))
