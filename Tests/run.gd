extends SceneTree

# Runs every test_* method in Tests/*_test.gd, each on a fresh museum with rng seed 1.
# `god test` runs this; exit code 1 on any failure. A script error inside a test (which would
# otherwise just cut the test short) counts as a failure too.

const MUSEUM := "res://Scenes/museum.tscn"


# Collects script errors raised while a test runs.
class Errors extends Logger:
	var seen: Array[String] = []
	var _lock := Mutex.new()

	func _log_error(function: String, file: String, line: int, code: String, rationale: String,
			_editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type != ERROR_TYPE_SCRIPT:
			return
		_lock.lock()
		seen.append("%s (%s:%d %s)" % [rationale if rationale else code, file.get_file(), line, function])
		_lock.unlock()


func _initialize() -> void:
	var checks := 0
	var failed := 0
	var errors := Errors.new()
	OS.add_logger(errors)
	for file in DirAccess.get_files_at("res://Tests"):
		if not file.ends_with("_test.gd"):
			continue
		var suite: GDScript = load("res://Tests/" + file)
		for m in suite.get_script_method_list():
			if not m.name.begins_with("test_"):
				continue
			var t: Test = suite.new()
			var scene: Node = load(MUSEUM).instantiate()
			scene.get_node("Battle").rng.seed = 1
			root.add_child(scene)
			await process_frame
			t.b = scene.get_node("Battle")
			t.tree = self
			errors.seen.clear()
			await t.call(m.name)
			checks += t.checks
			for f in t.failures + errors.seen.map(func(e): return "script error: " + e):
				failed += 1
				print("FAIL %s.%s: %s" % [file.get_basename(), m.name, f])
			scene.free()
	OS.remove_logger(errors)
	print("%d checks, %d failed" % [checks, failed])
	quit(1 if failed else 0)
