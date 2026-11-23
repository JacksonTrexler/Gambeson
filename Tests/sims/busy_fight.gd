extends SceneTree

# Busy AI-vs-AI fights, timed (docs/plans/r-sims.md). Not in the suite. Run:
#   godot --headless --path . -s Tests/sims/busy_fight.gd -- [15|20 ...] [n=2] [rounds=10] [skills=4] [lead] [swarm=60] [debug]
# Each side fields N class units (a mix of the 12 classes, `skills` open skills each on their bar, level 1) on a 32 x 26 field,
# 12 tiles apart with sight on; both sides see the others drawn up in the open, as a battle's start does. The sides play by the
# AI (AI.act per unit, then end_turn) until one falls or `rounds`. Per fight size it prints the time of every unit's AI turn
# (ms: mean / p95 / max, all turns and the turns in which a skill was used), of each side's end_turn, and a round, then judges
# them against the budget at TARGET speed, which is this machine's time x SLOWDOWN (the user's call: tests may assume a device
# 4x stronger than a consumer target, so the target takes 4x as long as the M3 does here).
# swarm=M: Lancin fields M rats (one class, RAT_HP, Strike only) in a dense block against N mixed Nemes (docs/plans/w16-swarm.md).
# lead: each side in parties of PARTY, the first a skilled leader (charisma LEADER_CHA) the rest follow (Unit.follows).
# Wait: what the player stares at with nothing moving, per side turn on the target (compute only, not the HUD's pacing):
# one frame (all of a side's acts in one frame, then the walks: the old HUD) vs a frame per unit (HUD._act_alone now: each
# unit's walk or blow shows while the next plans; an act inside a walk or a number still showing counts as shown, a stutter
# not a stare). A walk shows tiles x Overlay.STEP_TIME, a used skill its number SHOWN s; the end_turn is a stare in both.
# A side's opening looks (Battle.lazy_looks) go one a frame over the TRANSITION, the rest as each acts; the end_turn runs under
# the side's last walks and blows (HUD._act_alone): stare only past them. One frame: all of it in the frame (the old HUD).
# Outcome: no digest (decisions may change); it checks every fight sheds blood, no unit sits out a whole fight with a foe
# standing, and a side is left standing. "OUTCOME ok" or "OUTCOME FAIL: ...".
# Frames: headless has none. Run it in a window (drop --headless; a display is needed) and it also awaits a frame after each
# unit and prints the frame times (ms) between them: an AI turn is one frame's work, so its hitch is that frame's length.

const SLOWDOWN := 4.0  # target device = this machine's time x 4
const TURN_BUDGET_MS := 200.0  # a unit's AI turn on the target before it shows: it plans in its own frame while the units before it walk and their numbers show (HUD._act_alone), and a 3-tile walk is 0.21 s (was 100 before a frame per unit; docs/plans/w13-aifast.md)
const SIDE_BUDGET_MS := 1000.0  # a side's end_turn, a whole round of AI turns, or a side's stare (nothing showing) on the target, before it reads as a freeze
const PARTY := 5
const LEADER_CHA := 14  # mod +2: high (Command.skilled()), a skilled leader (AI._calm())
const SHOWN := 0.9  # s a used skill's number shows (Overlay.float_text)
const STEP := 0.07  # s a tile of walking shows (Overlay.STEP_TIME)
const TRANSITION := 1.0  # s a turn change shows (HUD.TRANSITION)
const FRAME := 1.0 / 60.0  # s a frame takes besides the work in it
const FIELD := Vector2i(32, 26)
const RAT_HP := 4  # a swarm unit's HP (swarm=M)
const RAT_ROLE := "fighter"
const GAP := 12
const FIELD_SCRIPT := "res://Tests/sims/field.gd"  # loaded at run time: naming it (or Role) as a type here makes the scripts load in a cycle
const ROLES := ["fighter", "ranger", "mage", "cleric", "rogue", "bard", "berserker", "paladin", "druid", "warlock", "wizard", "sorcerer"]

var _first: Test = null  # named first: scripts load in the order ai_sim's `extends Test` gives them (any other type first loads them in a cycle)
var _debug := false
var _lead := false
var _swarm := 0  # swarm=M: Lancin's rats
var _fails: Array[String] = []
var _windowed := DisplayServer.get_name() != "headless"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_debug = "debug" in args
	_lead = "lead" in args
	var n := 2
	var rounds := 10
	var skills := 4
	var sizes: Array[int] = []
	for a in args:
		if a.begins_with("n="):
			n = int(a.substr(2))
		elif a.begins_with("rounds="):
			rounds = int(a.substr(7))
		elif a.begins_with("swarm="):
			_swarm = int(a.substr(6))
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
	print("OUTCOME ok" if _fails.is_empty() else "OUTCOME FAIL: " + "; ".join(_fails))
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
	var waits: Array = []  # per side turn: [one frame, frame per unit], ms here
	var parts := [0.0, 0.0, 0.0]  # of the frame-per-unit stares, s on the target: -, acts (an opening look past the turn change among them), end_turns
	var fallen := 0
	for seed in n:
		var f: Variant = load(FIELD_SCRIPT).new()
		await f.open(self, seed, FIELD.x, FIELD.y)
		var cols := ceili(size / 5.0) if _swarm == 0 else 6
		var sides := [[f.lancin, 3], [f.nemes, 3 + GAP + cols]]
		var head: Unit = null
		for s in sides:
			if _swarm > 0 and s[0] == f.lancin:
				for i in _swarm:  # a dense block, 6 wide
					var rat: Unit = f.add(s[0], load("res://Roles/%s.tres" % RAT_ROLE), Vector2i(3 + i % 6, 1 + i / 6 * 24 / maxi(1, ceili(_swarm / 6.0)) % 24), "rat%d" % i, 0)  # Strike only
					rat.max_hp = RAT_HP
					rat.hp = RAT_HP
				continue
			for i in size:
				var role: Resource = load("res://Roles/%s.tres" % ROLES[(i + (3 if s[0] == f.nemes else 0)) % ROLES.size()])
				var c := Vector2i(s[1] + i / 5, 2 + (i % 5) * 4) if not _lead else Vector2i(s[1] + i % PARTY % 3, 2 + i / PARTY * 4 + i % PARTY / 3)  # lead: each party in a 3 x 2 block
				var u: Unit = f.add(s[0], role, c, "%s%d" % [s[0].name.left(1), i], skills)
				if _lead and i % PARTY == 0:
					u.charisma = LEADER_CHA
					head = u
				elif _lead:
					u.follows = head
		for u: Unit in f.b.units.values():
			u.suspicion.clear()
			for t: Unit in f.b.units.values():
				if u.faction != t.faction and Perception.cover(f.b, t) == 0:
					f.b.sighted(u.faction, t, t.cell)  # each side knows where the other drew up in the open
		var last := Time.get_ticks_usec()
		var shows := {at = 0.0}  # what the current act puts on screen: s of feedback
		var on_walk := func(_u: Unit, _from: Vector2i, path: Array[Vector2i]): shows.at = maxf(shows.at, path.size() * STEP)
		var on_use := func(_c: Unit, _s: Skill, _at: Variant, _d: int): shows.at = maxf(shows.at, SHOWN)
		if &"lazy_looks" in f.b:
			f.b.lazy_looks = true  # as the HUD has it when watched
		f.b.traveled.connect(on_walk)
		f.b.used.connect(on_use)
		var did: Dictionary[Unit, bool] = {}
		var all: Array = f.b.units.values()
		for r in rounds:
			var round_us := 0
			for side: Faction in [f.lancin, f.nemes]:
				f.b.turn = side
				var side_us := 0
				var clock := 0.0  # s on the target since the side's turn began, a frame per unit
				var shown_to := 0.0  # till when something is on screen
				var stare := 0.0
				if f.b.has_method(&"look_ahead"):  # its opening looks, a frame each while the turn change shows (HUD._act_alone); the rest as each acts
					var shown := 0.0
					var more := true
					while more and shown < TRANSITION:
						var t2 := Time.get_ticks_usec()
						more = f.b.look_ahead()
						var lus := Time.get_ticks_usec() - t2
						side_us += lus
						shown += lus / 1e6 * SLOWDOWN + FRAME
				for u: Unit in f.b.members(side):
					shows.at = 0.0
					var t0 := Time.get_ticks_usec()
					var log: Array[String] = AI.act(f.b, u)
					var us := Time.get_ticks_usec() - t0
					if shows.at > 0.0 or log.size() > 0:
						did[u] = true
					var a := us / 1e6 * SLOWDOWN
					stare += a - clampf(shown_to - clock, 0.0, a)
					parts[1] += a - clampf(shown_to - clock, 0.0, a)
					clock += a
					shown_to = maxf(shown_to, clock + shows.at)
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
				var e := eus / 1e6 * SLOWDOWN  # it runs under the last walks and blows (HUD._act_alone)
				var e_stare := e - clampf(shown_to - clock, 0.0, e)
				ends.append(eus / 1000.0)
				parts[2] += e_stare
				turns.append((side_us + eus) / 1000.0)
				waits.append([(side_us + eus) / 1000.0, (stare + e_stare) * 1000.0 / SLOWDOWN])  # ms here (x SLOWDOWN on the target)
				if _debug:
					print("  size %d seed %d round %d %s: %d acted, stare on the target %.0f ms (end_turn %.0f), one frame %.0f" % [size, seed, r + 1, side.name, f.b.members(side).size(), (stare + e_stare) * 1000.0, e_stare * 1000.0, (side_us + eus) / 1000.0 * SLOWDOWN])
				round_us += side_us + eus
				if f.b.phase != Battle.Phase.TURNS:
					break
			played += 1
			if _debug:
				print("  size %d seed %d round %d: %d v %d alive, %.0f ms" % [size, seed, r + 1, f.b.members(f.lancin).size(), f.b.members(f.nemes).size(), round_us / 1000.0])
			if f.b.phase != Battle.Phase.TURNS:
				break
		var al: int = f.b.members(f.lancin).filter(func(u: Unit): return u.is_alive()).size()
		var an: int = f.b.members(f.nemes).filter(func(u: Unit): return u.is_alive()).size()
		left_l += al
		left_n += an
		var total := size + (_swarm if _swarm > 0 else size)
		fallen += total - al - an
		var idle := all.filter(func(u: Unit): return u not in did and u.is_alive())
		if total - al - an < size / 3:
			_fails.append("size %d seed %d: only %d fell" % [size, seed, total - al - an])
		if al + an == 0:
			_fails.append("size %d seed %d: no one left standing" % [size, seed])
		if not idle.is_empty():
			_fails.append("size %d seed %d: %d sat it out (%s)" % [size, seed, idle.size(), idle[0].name])
		f.close()
		await process_frame
	print("SIM busy-%dv%d%s fights=%d rounds_played=%.1f alive_at_end=%.1f v %.1f (of %d v %d) fallen %.1f a fight" % [_swarm if _swarm else size, size, (" swarm %d" % _swarm) if _swarm else (" lead" if _lead else ""), n, float(played) / n, float(left_l) / n, float(left_n) / n, _swarm if _swarm else size, size, float(fallen) / n])
	var one: Array[float] = []
	var per: Array[float] = []
	for w in waits:
		one.append(w[0])
		per.append(w[1])
	_report("busy-%dv%d side wait, one frame" % [_swarm if _swarm else size, size], one, -1.0)
	_report("busy-%dv%d side wait, frame per unit" % [_swarm if _swarm else size, size], per, SIDE_BUDGET_MS)
	print("SIM busy-%dv%d frame-per-unit wait on the target, mean a side turn: acts %.0f, end_turn %.0f ms" % [size, size, parts[1] * 1000.0 / waits.size(), parts[2] * 1000.0 / waits.size()])
	_report("busy-%dv%d unit turn" % [_swarm if _swarm else size, size], acts, TURN_BUDGET_MS)
	_report("busy-%dv%d unit turn using a skill" % [_swarm if _swarm else size, size], busy, TURN_BUDGET_MS)
	_report("busy-%dv%d side end_turn" % [_swarm if _swarm else size, size], ends, SIDE_BUDGET_MS)
	_report("busy-%dv%d side turn (acts + end_turn)" % [_swarm if _swarm else size, size], turns, -1.0)  # no budget: its units are paced 450 ms apart anyway
	if not frames.is_empty():
		_report("busy-%dv%d frame (one unit's turn, rendered)" % [_swarm if _swarm else size, size], frames, TURN_BUDGET_MS)


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
	print("SIM %s (n=%d): here mean %.1f p95 %.1f max %.1f ms | target mean %.0f p95 %.0f max %.0f ms | %s" % [name, s.size(), mean, p95, worst, mean * SLOWDOWN, p95 * SLOWDOWN, worst * SLOWDOWN, ("budget %.0f ms: %s" % [budget, verdict]) if budget > 0.0 else "no budget"])
