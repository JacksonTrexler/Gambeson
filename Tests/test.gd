class_name Test
extends RefCounted

# Base for test suites. Tests/run.gd builds a fresh, seeded museum battle for every test_* method.
# Villagers 1-2 are Lancin (Favour), 3-4 Nemes (Wary, Hex); all have Strike. Champions:
# Alabaster (Lancin) and Icor (Nemes).

var b: Battle
var tree: SceneTree  # for tests that build their own battles
var lancin: Faction = load("res://Factions/lancin.tres")
var nemes: Faction = load("res://Factions/nemes.tres")
var favour: Skill = load("res://Skills/favour.tres")
var wary: Skill = load("res://Skills/wary.tres")
var hex: Skill = load("res://Skills/hex.tres")
var strike: Skill = load("res://Skills/strike.tres")
var manifest: Skill = load("res://Skills/manifest.tres")
var checks := 0
var failures: Array[String] = []


func ok(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures.append(what)


func v(i: int) -> Unit:
	return b.get_node("Units/Villager%d" % i)


func effect(stat: String, amount: float, tags: Array[StringName] = []) -> Effect:
	var e := Effect.new()
	e.stat = stat
	e.amount = amount
	e.tags = tags
	return e


# Lets u read everything about others (recon 3): their level, class, skills - what an AI weighs
# targets by (AI._best_target(), want()). Without it, two villagers look alike.
func sharp(u: Unit) -> Unit:
	u.afflict(effect("recon", 3), 9)
	return u


# Leaves u at `left` HP (a heal's target for a helpful healer).
func hurt_to(u: Unit, left := 2) -> Unit:
	u.hp = left
	return u


# Gives u n more sure slots, so skills a test hands it go on the bar (only equipped skills work: Unit.equipped()).
func roomy(u: Unit, n := 4) -> Unit:
	u.extra_slots += n
	u._arrange()
	return u


func slot(s: Skill, r := 1) -> Slot:
	var x := Slot.new()
	x.skill = s
	x.rank = r
	return x


# Just the four villagers, on their usual cells (the museum's champions step out).
func villagers_only() -> void:
	stage(lancin, {v(1): Vector2i(1, 2), v(2): Vector2i(1, 5), v(3): Vector2i(8, 2), v(4): Vector2i(8, 5)})


# Clears the board except the given units, placed at the given cells, and starts f's turn - calm:
# nobody suspicious of anything from the looks it took as it started (calm()); nobody facing any way.
func stage(f: Faction, placed: Dictionary) -> void:
	for u: Unit in b.units.values():
		b.units.erase(u.cell)
		u.cell = Vector2i(-99, -99)
	for u: Unit in placed:
		b.move(u, placed[u])
		u.facing = Vector2.ZERO  # facing no way: front from every side, till a test turns it (facing_test)
	b.order.assign([lancin, nemes])
	b.turn = null
	b.turn = f
	calm()


# Nobody suspicious of anything (each unit's first looks are still taken), for tests of plain reads.
func calm() -> void:
	for u: Unit in b.get_node("Units").get_children():
		u.suspicion.clear()
	b.sight = false  # the museum's tests read across the map: sight limits only where a test turns them on (sight_test)
	Exhaustion.on = false  # staged tests use a skill over and over at its plain cost: it wears units out only where a test turns it on (exhaustion_test, combat_test)


# Armor of no weight with a flat Defense of 20 (its floor, with nothing to scale): a target only 19
# and 20 hit with +1.
func bulwark() -> Item:
	var it := Item.new()
	it.name = "Bulwark"
	it.defense = 20
	it.skills = [load("res://Skills/armor.tres")] as Array[Skill]  # armor sets Defense through the equipment skill it lends
	return it


# A skill by id: load("res://Skills/<id>.tres").
func sk(id: String) -> Skill:
	return load("res://Skills/%s.tres" % id)


# v(1) learns s at rank r and stands at (4, 3) beside its target, at (5, 3): a foe, v(3), or with foe
# false an ally, v(2). Returns the target. The line most skill tests start with.
func duel(s: Skill, r := 1, foe := true) -> Unit:
	var t := v(3) if foe else v(2)
	v(1).learned.append(slot(s, r))
	stage(lancin, {v(1): Vector2i(4, 3), t: Vector2i(5, 3)})
	return t


# Rigs skill s's declared check (Skill.check; a save, a contest) for caster to win outright: its stat
# at 60 and t's at 1, through the stats alone. Returns t.
func sure_save_fail(caster: Unit, s: Skill, t: Unit) -> Unit:
	caster.set(s.check.mine(s) if s.check else s.stat(), 60)
	t.set(s.check.theirs(s) if s.check else s.stat(), 1)
	return t


# Gives u a deep pool of HP, so a skill's damage never ends the test early. Returns u.
func soak(u: Unit, hp := 999) -> Unit:
	u.max_hp = hp
	u.hp = hp
	return u


# A HUD on the test battle (auto off, at `pace`, 0: no waits), led by `leader` if given - others'
# sides are left alone - ready once a frame passes: `var h := await hud(v(1))`.
func hud(leader: Unit = null, pace := 0.0) -> HUD:
	if leader:
		b.player = leader
	var h: HUD = load("res://Scenes/UI/hud.tscn").instantiate()
	h.battle = b
	h.auto = false
	h.pace = pace
	tree.root.add_child(h)
	await tree.process_frame
	return h


# Runs `python3 Util/<tool>.py check` (python3 on the PATH, else where a Mac or Linux puts it) and checks
# it passed. A failed check, never a skip, if there's no python3 at all: the wiring checks guard the data.
func tool_check(tool: String) -> void:
	var out := []
	var code := -1
	for py in ["python3", "python", "/usr/bin/python3", "/opt/homebrew/bin/python3", "/usr/local/bin/python3"]:
		out.clear()
		code = OS.execute(py, [ProjectSettings.globalize_path("res://Util/%s.py" % tool), "check"], out, true)
		if code != -1 and code != 127:
			break
	if code == -1 or code == 127:
		ok(false, "Util/%s.py check couldn't run: no python3 found (PATH, /usr/bin, /opt/homebrew/bin, /usr/local/bin): install it - this check guards the data" % tool)
		return
	ok(code == 0, "Util/%s.py check: %s" % [tool, "".join(out).strip_edges()])
