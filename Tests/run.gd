extends SceneTree

# Runs every test_* method in Tests/*_test.gd, each on a fresh museum with rng seed 1.
# `god test` runs this; exit code 1 on any failure.

const MUSEUM := "res://Scenes/museum.tscn"


func _initialize() -> void:
	var checks := 0
	var failed := 0
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
			await t.call(m.name)
			checks += t.checks
			for f in t.failures:
				failed += 1
				print("FAIL %s.%s: %s" % [file.get_basename(), m.name, f])
			scene.free()
	print("%d checks, %d failed" % [checks, failed])
	quit(1 if failed else 0)
