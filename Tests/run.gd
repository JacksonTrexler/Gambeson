extends SceneTree

# Runs the test_* methods in Tests/*_test.gd, each on a fresh museum with rng seed 1. Exit code 1 on
# any failure. What it runs, by the arguments after `--`:
#   (none) or all   every test (about a minute: the museum is held for the whole run, see below)
#   quick           the 20/80 tier: everything but the slow tests listed in Tests/slow.txt (about 30 s)
#   reverse         files and tests in reverse order: a test that leaks into a later one (resources are
#                   cached across tests) fails here when it doesn't forward. Run both before merging
#   soak            the long form of the seeded tests: combat_test fights all 30 seeds, not 8 (about 20 s more)
#   <words>         targeted: only tests whose "file.method" contains one of the words
#                   (hud_test, warlock_test.test_toggle, smite)
#   times           also print each test's time, slowest first (with any of the above)
# e.g. godot --headless --path . -s Tests/run.gd -- quick

# The run holds museum.tscn (and so Roles/, Trees/, Skills/ it pulls in) for its whole length. Without a
# reference they leave the ResourceCache when a test frees its scene and every test reloads them (150 ms).
const MUSEUM := "res://Scenes/museum.tscn"
var _save: GDScript  # Save and KeyBinds, as scripts (_initialize)
var _keys: GDScript
const SLOW_LIST := "res://Tests/slow.txt"  # one "file.method" a line: what the quick tier leaves out


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var quick := "quick" in args
	var times := "times" in args
	var reverse := "reverse" in args
	var words: Array = Array(args).filter(func(a: String): return a not in ["quick", "all", "times", "reverse", "soak"])
	var slow := _slow() if quick else []
	# A test's toggles never reach (or come from) the player's own settings, nor another run's: a file per process.
	Prefs.SAVE = "user://settings_test_%d.cfg" % OS.get_process_id()
	var museum: PackedScene = load(MUSEUM)
	# The same for the save file and the key binds: never the player's own, never another run's. By load(), after
	# the museum: naming Save or KeyBinds here would compile them (and Role, Item...) before Skill and trip a script cycle.
	var pid := OS.get_process_id()
	_save = load("res://Scripts/Save.gd")
	_save.set("PATH", "user://save_test_%d.json" % pid)
	_keys = load("res://Scripts/KeyBinds.gd")
	_keys.set("SAVE", "user://keybinds_test_%d.cfg" % pid)
	OS.add_logger(ScriptErrors.new())  # a test that crashes mid-way is a failed test
	ScriptErrors.take()
	var checks := 0
	var failed := 0
	var ran := 0
	var spent := {}
	var files := Array(DirAccess.get_files_at("res://Tests")).filter(func(f: String): return f.ends_with("_test.gd"))
	files.sort()
	if reverse:
		files.reverse()
	for file in files:
		var suite: GDScript = load("res://Tests/" + file)
		var methods := suite.get_script_method_list()
		if reverse:
			methods.reverse()
		for m in methods:
			var id := "%s.%s" % [file.get_basename(), m.name]
			if not m.name.begins_with("test_") or id in slow:
				continue
			if not words.is_empty() and not words.any(func(w: String): return w in id):
				continue
			var start := Time.get_ticks_msec()
			_wipe()
			var t: Test = suite.new()
			# What one test leaves in Game's statics (a starter, its level, outfit, hearts, the stash) doesn't carry over.
			Game.starter = {}
			Game.difficulty = 0.0
			Game.dungeon = null
			Game.hero = {}
			Game.outfit = {}
			Game.level = 1
			Unit.auto_equip = true  # a test that switches it off doesn't leave it off
			Game.xp = 0
			Game.hearts = 0
			Game.stash = []
			Game.equipped = []
			Game.lapses = {}
			var scene: Node = museum.instantiate()
			scene.get_node("Battle").rng.seed = 1
			root.add_child(scene)
			await process_frame
			t.b = scene.get_node("Battle")
			t.tree = self
			t.calm()
			await t.call(m.name)
			checks += t.checks
			ran += 1
			for f in t.failures:
				failed += 1
				print("FAIL %s: %s" % [id, f])
			for e in ScriptErrors.take():
				failed += 1
				print("FAIL %s: crashed, its remaining checks did not run: %s" % [id, e])
			scene.free()
			spent[id] = Time.get_ticks_msec() - start
	if times:
		var ids := spent.keys()
		ids.sort_custom(func(a: String, b: String): return spent[a] > spent[b])
		for id in ids:
			print("TIME %6d ms  %s" % [spent[id], id])
	_wipe()
	print("%d checks, %d failed (%d tests%s%s%s)" % [checks, failed, ran, ", quick" if quick else "", ", reverse" if reverse else "", ", soak" if "soak" in args else ""])
	quit(1 if failed else 0)


# The per-process files a test may have written: settings, key binds, the save (and a bad one set aside).
func _wipe() -> void:
	var path: String = _save.get("PATH")
	for p in [Prefs.SAVE, _keys.get("SAVE"), path, path + ".bad", path + ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	_save.set("loaded", false)


# The tests the quick tier skips: Tests/slow.txt, a "file.method" a line (# comments).
func _slow() -> Array:
	var out := []
	var f := FileAccess.open(SLOW_LIST, FileAccess.READ)
	if f:
		for line in f.get_as_text().split("\n"):
			line = line.split("#")[0].strip_edges()
			if line:
				out.append(line)
	return out
