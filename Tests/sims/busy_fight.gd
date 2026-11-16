extends SceneTree

# Busy AI-vs-AI fights, timed (docs/plans/r-sims.md). Not in the suite. Run:
#   godot --headless --path . -s Tests/sims/busy_fight.gd -- [15|20 ...] [n=2] [rounds=10] [skills=4] [debug]
# Each side fields N class units (a mix of the 12 classes, `skills` open skills each on their bar, level 1) on a 32 x 26 field,
# 12 tiles apart with sight on; both sides see the others drawn up in the open, as a battle's start does. The sides play by the
# AI (AI.act per unit, then end_turn) until one falls or `rounds`. Per fight size it prints the time of every unit's AI turn
# (ms: mean / p95 / max, all turns and the turns in which a skill was used), of each side's end_turn, and a round, then judges
# them against the budget at TARGET speed, which is this machine's time x SLOWDOWN (the user's call: tests may assume a device
# 4x stronger than a consumer target, so the target takes 4x as long as the M3 does here).
# Frames: headless has none. Run it in a window (drop --headless; a display is needed) and it also awaits a frame after each
# unit and prints the frame times (ms) between them: an AI turn is one frame's work, so its hitch is that frame's length.

const SLOWDOWN := 4.0  # target device = this machine's time x 4
const TURN_BUDGET_MS := 100.0  # a unit's AI turn on the target before it reads as a hitch (the HUD paces units 450 ms apart)
const SIDE_BUDGET_MS := 1000.0  # a side's end_turn, or a whole round of AI turns on the target, before it reads as a freeze
const FIELD := Vector2i(32, 26)
const GAP := 12
const FIELD_SCRIPT := "res://Tests/sims/field.gd"  # loaded at run time: naming it (or Role) as a type here makes the scripts load in a cycle
const ROLES := ["fighter", "ranger", "mage", "cleric", "rogue", "bard", "berserker", "paladin", "druid", "warlock", "wizard", "sorcerer"]

var _first: Test = null  # named first: scripts load in the order ai_sim's `extends Test` gives them (any other type first loads them in a cycle)
var _debug := false
var _windowed := DisplayServer.get_name() != "headless"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_debug = "debug" in args
	var n := 2
	var rounds := 10
	var skills := 4
	var sizes: Array[int] = []
	for a in args:
		if a.begins_with("n="):
			n = int(a.substr(2))
		elif a.begins_with("rounds="):
			rounds = int(a.substr(7))
		elif a.begins_with("skills="):
			skills = int(a.substr(7))
		elif a.is_valid_int():
			sizes.append(int(a))
	if sizes.is_empty():
		sizes = [15, 20]
	var probe: Variant = load(FIELD_SCRIPT).new()
	probe.isolate()
	print("SIM busy target = this machine x %.0f; budgets on the target: unit turn %.0f ms (%.1f ms here), side end_turn or round %.0f ms (%.0f ms here)%s" % [SLOWDOWN, TURN_BUDGET_MS, TURN_BUDGET_MS / SLOWDOWN, SIDE_BUDGET_MS, SIDE_BUDGET_MS / SLOWDOWN, "; windowed: frames timed" if _windowed else "; headless: no frames"])
	for size in sizes:
		await _fight(size, n, rounds, skills)
	var perf: Dictionary = Engine.get_meta(&"perf", {})  # filled by temporary #PERF wrappers (the profiling-godot note), empty otherwise
	var keys := perf.keys().filter(func(k: String): return not k.ends_with("#"))
	keys.sort_custom(func(a: String, b: String): return perf[a] > perf[b])
	for k in keys:
		print("PERF %-24s %9.1f ms %7d calls %8.3f ms each" % [k, perf[k] / 1000.0, perf[k + "#"], perf[k] / 1000.0 / perf[k + "#"]])
	probe.clean_up()
	quit()


func _fight(size: int, n: int, rounds: int, skills: int) -> void:
	var acts: Array[float] = []
	var busy: Array[float] = []  # the turns in which a skill was used
	var ends: Array[float] = []
	var turns: Array[float] = []  # a side's whole turn: its units' acts and the end_turn
	var frames: Array[float] = []
	var played := 0
	var left_l := 0
	var left_n := 0
	for seed in n:
		var f: Variant = load(FIELD_SCRIPT).new()
		await f.open(self, seed, FIELD.x, FIELD.y)
		var cols := ceili(size / 5.0)
		var sides := [[f.lancin, 3], [f.nemes, 3 + GAP + cols]]
		for s in sides:
			for i in size:
				var role: Resource = load("res://Roles/%s.tres" % ROLES[(i + (3 if s[0] == f.nemes else 0)) % ROLES.size()])
				var c := Vector2i(s[1] + i / 5, 2 + (i % 5) * 4)
				f.add(s[0], role, c, "%s%d" % [s[0].name.left(1), i], skills)
		for u: Unit in f.b.units.values():
			u.suspicion.clear()
			for t: Unit in f.b.units.values():
				if u.faction != t.faction and Perception.cover(f.b, t) == 0:
					f.b.sighted(u.faction, t, t.cell)  # each side knows where the other drew up in the open
		var last := Time.get_ticks_usec()
		for r in rounds:
			var round_us := 0
			for side: Faction in [f.lancin, f.nemes]:
				f.b.turn = side
				var side_us := 0
				for u: Unit in f.b.members(side):
					var t0 := Time.get_ticks_usec()
					var log: Array[String] = AI.act(f.b, u)
					var us := Time.get_ticks_usec() - t0
					side_us += us
					acts.append(us / 1000.0)
					if log.any(func(l: String): return " uses " in l):
						busy.append(us / 1000.0)
					if _windowed:
						await process_frame
						var now := Time.get_ticks_usec()
						frames.append((now - last) / 1000.0)
						last = now
				var t1 := Time.get_ticks_usec()
				f.b.end_turn()
				var eus := Time.get_ticks_usec() - t1
				ends.append(eus / 1000.0)
				turns.append((side_us + eus) / 1000.0)
				round_us += side_us + eus
				if f.b.phase != Battle.Phase.TURNS:
					break
			played += 1
			if _debug:
				print("  size %d seed %d round %d: %d v %d alive, %.0f ms" % [size, seed, r + 1, f.b.members(f.lancin).size(), f.b.members(f.nemes).size(), round_us / 1000.0])
			if f.b.phase != Battle.Phase.TURNS:
				break
		left_l += f.b.members(f.lancin).filter(func(u: Unit): return u.is_alive()).size()
		left_n += f.b.members(f.nemes).filter(func(u: Unit): return u.is_alive()).size()
		f.close()
		await process_frame
	print("SIM busy-%dv%d fights=%d rounds_played=%.1f alive_at_end=%.1f v %.1f (of %d a side)" % [size, size, n, float(played) / n, float(left_l) / n, float(left_n) / n, size])
	_report("busy-%dv%d unit turn" % [size, size], acts, TURN_BUDGET_MS)
	_report("busy-%dv%d unit turn using a skill" % [size, size], busy, TURN_BUDGET_MS)
	_report("busy-%dv%d side end_turn" % [size, size], ends, SIDE_BUDGET_MS)
	_report("busy-%dv%d side turn (acts + end_turn)" % [size, size], turns, SIDE_BUDGET_MS)
	if not frames.is_empty():
		_report("busy-%dv%d frame (one unit's turn, rendered)" % [size, size], frames, TURN_BUDGET_MS)


# mean / p95 / max in ms here and on the target (x SLOWDOWN), against the budget there.
func _report(name: String, ms: Array[float], budget: float) -> void:
	if ms.is_empty():
		print("SIM %s: none" % name)
		return
	var s := ms.duplicate()
	s.sort()
	var sum := 0.0
	for x in s:
		sum += x
	var mean := sum / s.size()
	var p95: float = s[mini(int(s.size() * 0.95), s.size() - 1)]
	var worst: float = s[-1]
	var verdict := "within" if p95 * SLOWDOWN <= budget and worst * SLOWDOWN <= budget else ("p95 within, max over" if p95 * SLOWDOWN <= budget else "OVER")
	print("SIM %s (n=%d): here mean %.1f p95 %.1f max %.1f ms | target mean %.0f p95 %.0f max %.0f ms | budget %.0f ms: %s" % [name, s.size(), mean, p95, worst, mean * SLOWDOWN, p95 * SLOWDOWN, worst * SLOWDOWN, budget, verdict])
