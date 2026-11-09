extends SceneTree

# Runs the test_* methods in Tests/*_test.gd, each on a fresh museum with rng seed 1. Exit code 1 on
# any failure. What it runs, by the arguments after `--`:
#   (none) or all   every test (about 10 minutes)
#   quick           the 20/80 tier: everything but the slow tests listed in Tests/slow.txt (about a minute)
#   <words>         targeted: only tests whose "file.method" contains one of the words
#                   (hud_test, warlock_test.test_toggle, smite)
#   times           also print each test's time, slowest first (with any of the above)
# e.g. godot --headless --path . -s Tests/run.gd -- quick

const MUSEUM := "res://Scenes/museum.tscn"
const SLOW_LIST := "res://Tests/slow.txt"  # one "file.method" a line: what the quick tier leaves out


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var quick := "quick" in args
	var times := "times" in args
	var words: Array = Array(args).filter(func(a: String): return a not in ["quick", "all", "times"])
	var slow := _slow() if quick else []
	var checks := 0
	var failed := 0
	var ran := 0
	var spent := {}
	for file in DirAccess.get_files_at("res://Tests"):
		if not file.ends_with("_test.gd"):
			continue
		var suite: GDScript = load("res://Tests/" + file)
		for m in suite.get_script_method_list():
			var id := "%s.%s" % [file.get_basename(), m.name]
			if not m.name.begins_with("test_") or id in slow:
				continue
			if not words.is_empty() and not words.any(func(w: String): return w in id):
				continue
			var start := Time.get_ticks_msec()
			var t: Test = suite.new()
			Game.level = 1  # a player's starter levelled by an earlier test's battle doesn't carry over
			Game.xp = 0
			var scene: Node = load(MUSEUM).instantiate()
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
			scene.free()
			spent[id] = Time.get_ticks_msec() - start
	if times:
		var ids := spent.keys()
		ids.sort_custom(func(a: String, b: String): return spent[a] > spent[b])
		for id in ids:
			print("TIME %6d ms  %s" % [spent[id], id])
	print("%d checks, %d failed (%d tests%s)" % [checks, failed, ran, ", quick" if quick else ""])
	quit(1 if failed else 0)


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
