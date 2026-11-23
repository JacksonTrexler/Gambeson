extends SceneTree

# Runs the test_* methods in Tests/*_test.gd, each on a fresh museum with rng seed 1. Exit code 1 on
# any failure. What it runs, by the arguments after `--`:
#   (none) or all   every test (about a minute: the museum is held for the whole run, see below)
#   quick           the 20/80 tier: everything but the slow tests listed in Tests/slow.txt (about 40 s), except the risk
#                   tests (Tests/risk.txt), which it keeps even when slow
#   risk            only the risk tests: the few whose failure means the game itself is broken (a whole AI fight that
#                   stalls or idles, saving, the core rules and the wiring of every skill). Seconds; run after any AI,
#                   Battle or Unit change before the longer runs. Mark a test: add its "file.method" (or any word, as
#                   below) to Tests/risk.txt with a reason. Mark what a bug would hurt most and a loosened pin cannot see
#   <segment>       one system's tests, by the files listed under it in Tests/segments.txt: ai (what units read and
#                   decide, sight, suspicion), ui (HUD, slots, keys, glossary), rules (the core: checks, movement,
#                   effects, saving, turns), content (a skill, class, item or place's own rules: the default for a file
#                   no line lists), sims (whole fights), tools (the authoring tools and the runner). A segment name
#                   is not a substring word: segments combine with each other and with words (`ai ui`, `ai quick`)
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
const RISK_LIST := "res://Tests/risk.txt"  # one word a line (matched as a targeted word is): what the quick tier keeps and `risk` runs alone
const SEGMENT_LIST := "res://Tests/segments.txt"  # "name: file file ..." (file without _test.gd), lines of one name join


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var quick := "quick" in args
	var times := "times" in args
	var reverse := "reverse" in args
	var segments := _segments()
	var picked: Array = Array(args).filter(func(a: String): return a in segments)
	var words: Array = Array(args).filter(func(a: String): return a not in ["quick", "all", "times", "reverse", "soak", "risk"] and a not in segments)
	var risk := _list(RISK_LIST)
	var only_risk := "risk" in args
	var slow := _list(SLOW_LIST).filter(func(id: String): return not _hit(id, risk)) if quick else []
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
	var leaked := 0
	var leaks := []  # "test<TAB>Class<TAB>path" per leaked node, merged into Tests/leaks.txt
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
			if only_risk and not _hit(id, risk):
				continue
			if not picked.is_empty() and not picked.any(func(s: String): return file.trim_suffix("_test.gd") in segments[s] or (s == "content" and not segments.values().any(func(l: Array): return file.trim_suffix("_test.gd") in l))):
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
			Game.roster = []
			Game.party = []
			Game.fielded = {}
			var before := root.get_children()  # what a test adds to the root itself (a HUD, a scene) goes with it, below
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
			for n in root.get_children():  # a test's leftovers (Test.hud puts a HUD on the root) must not reach the next: a leaked HUD in the "hud" group gave the battle camera a stale selection
				if n not in before:
					leaked += 1
					leaks.append("%s\t%s\t%s" % [id, n.get_class() if not n.get_script() else n.get_script().get_global_name(), String(n.get_path()).replace("@", "")])
					n.free()
			spent[id] = Time.get_ticks_msec() - start
	if times:
		var ids := spent.keys()
		ids.sort_custom(func(a: String, b: String): return spent[a] > spent[b])
		for id in ids:
			print("TIME %6d ms  %s" % [spent[id], id])
	_wipe()
	if leaked:
		print("freed %d nodes tests left on the root" % leaked)
		_record_leaks(leaks)
	print("%d checks, %d failed (%d tests%s%s%s)" % [checks, failed, ran, ", quick" if quick else "", ", reverse" if reverse else "", ", soak" if "soak" in args else ""])
	quit(1 if failed else 0)


# The running list of leaks (Tests/leaks.txt, committed, for batch fixing): `test<TAB>Class<TAB>path` lines, deduped across runs,
# kept sorted so reverse/forward order doesn't matter. Never fails the run. Written to a per-process temp then renamed (atomic), so a
# parallel run can at worst lose a line, which its next run re-adds; a missing file is just an empty list.
func _record_leaks(leaks: Array) -> void:
	var path := "res://Tests/leaks.txt"
	var lines := _list_raw(path)
	var added := false
	for l in leaks:
		if l not in lines:
			lines.append(l)
			added = true
	if not added:
		return
	lines.sort()
	var tmp := "%s.%d.tmp" % [path, OS.get_process_id()]
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		print("leaks.txt: cannot write (%d)" % FileAccess.get_open_error())
		return
	f.store_string("\n".join(lines) + "\n")
	f.close()
	DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), ProjectSettings.globalize_path(path))


func _list_raw(path: String) -> Array:
	var out := []
	var f := FileAccess.open(path, FileAccess.READ)
	if f:
		for line in f.get_as_text().split("\n"):
			if line.strip_edges():
				out.append(line)
	return out


# The per-process files a test may have written: settings, key binds, the save (and a bad one set aside).
func _wipe() -> void:
	var path: String = _save.get("PATH")
	for p in [Prefs.SAVE, _keys.get("SAVE"), path, path + ".bad", path + ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	_save.set("loaded", false)


# A list file: a word a line (# comments): Tests/slow.txt, Tests/risk.txt.
func _list(path: String) -> Array:
	var out := []
	var f := FileAccess.open(path, FileAccess.READ)
	if f:
		for line in f.get_as_text().split("\n"):
			line = line.split("#")[0].strip_edges()
			if line:
				out.append(line)
	return out


func _hit(id: String, words: Array) -> bool:
	return words.any(func(w: String): return w in id)


# Tests/segments.txt as {name: [files]}; `content` is listed by what it isn't (see the header), so it is always a key.
func _segments() -> Dictionary:
	var out := {"content": []}
	for line: String in _list(SEGMENT_LIST):
		var at := line.find(":")
		var name := line.substr(0, at).strip_edges()
		out[name] = out.get(name, []) + Array(line.substr(at + 1).split(" ", false))
	return out
