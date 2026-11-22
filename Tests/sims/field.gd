extends Test

# Shared by the big sims (hunt_10v10.gd, busy_fight.gd; docs/plans/r-sims.md): an open grass field of any size cut into the
# museum's battle (its tile set and rules), emptied of its units, sight limits ON, for the sims to fill with class units.
# Not a test (the suite reads only Tests/*_test.gd).

const MUSEUM := "res://Scenes/museum.tscn"

var rng := RandomNumberGenerator.new()
var scene: Node
var _pid := OS.get_process_id()


# Saves and settings go to per-process files, as run.gd and ai_sim.gd (a sim must never touch the player's own).
func isolate() -> void:
	Prefs.SAVE = "user://settings_sim_%d.cfg" % _pid
	var save: GDScript = load("res://Scripts/Save.gd")
	save.set("PATH", "user://save_sim_%d.json" % _pid)
	var keys: GDScript = load("res://Scripts/KeyBinds.gd")
	keys.set("SAVE", "user://keybinds_sim_%d.cfg" % _pid)


func clean_up() -> void:
	var save: GDScript = load("res://Scripts/Save.gd")
	var keys: GDScript = load("res://Scripts/KeyBinds.gd")
	for p in [Prefs.SAVE, keys.get("SAVE"), save.get("PATH"), save.get("PATH") + ".bad", save.get("PATH") + ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(p))


# A fresh battle on a w x h field of grass, seeded, with nobody on it and sight on. Game's statics as run.gd leaves them.
func open(t: SceneTree, seed: int, w: int, h: int) -> void:
	tree = t
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
	scene = (load(MUSEUM) as PackedScene).instantiate()
	scene.get_node("Battle").rng.seed = seed
	t.root.add_child(scene)
	await t.process_frame
	b = scene.get_node("Battle")
	rng.seed = seed * 7919 + 13
	for u: Unit in b.get_node("Units").get_children():
		b.units.erase(u.cell)
		b.get_node("Units").remove_child(u)
		u.free()
	b.sightings.clear()  # the museum's start put its units down (now freed)
	b.sighted_when.clear()
	b.swept.clear()
	b.attacks.clear()
	b.map.clear()
	for x in w:
		for y in h:
			b.map.set_cell(Vector2i(x, y), 0, Vector2i(0, 0), 0)
	b.order.assign([lancin, nemes])
	b.turn = lancin
	Exhaustion.on = false
	b.sight = true


func close() -> void:
	scene.free()


# A level 1 unit of `role` on side f at c, with up to `skills` of its tree's open skills learned and room on the bar for them.
func add(f: Faction, role: Resource, c: Vector2i, nick: String, skills := 0) -> Unit:
	var u := b.from_role(f, role, nick)
	var outfit: Dictionary = role.outfit()
	for s in outfit:
		u.set(s, outfit[s])
	u.cell = c
	b.get_node("Units").add_child(u, true)
	b.move(u, c)
	b._listen(u)
	var have: Array = []
	for r in role.roots:
		for br in r.branches:
			if have.size() < skills and br.after.is_empty() and br.needs == 0 and br.skill not in have and (br.skill.ap > 0.0 or br.skill.hostile):
				have.append(br.skill)
	for s in have:
		u.learned.append(slot(s))
	if not have.is_empty():
		roomy(u, have.size())
	u.refresh()
	return u


# One side's turn: each living unit acts by the AI, the turn passes. Returns microseconds each unit's act took, then the end_turn's.
func play(f: Faction) -> Dictionary:
	var acts: Array[int] = []
	for u: Unit in b.members(f):
		var t0 := Time.get_ticks_usec()
		AI.act(b, u)
		acts.append(Time.get_ticks_usec() - t0)
	var t1 := Time.get_ticks_usec()
	b.end_turn()
	return {acts = acts, end = Time.get_ticks_usec() - t1}
