extends SceneTree
# Times a fresh museum's pieces (instantiate, add_child, a frame, free), N times. Not a test: run by hand.
#   godot --headless --path . -s Tests/museum_prof.gd
func _initialize() -> void:
	var museum: PackedScene = load("res://Scenes/museum.tscn")
	var n := 60
	var t := {"inst": 0, "add": 0, "frame": 0, "free": 0}
	for i in n:
		var a := Time.get_ticks_usec()
		var scene: Node = museum.instantiate()
		var b := Time.get_ticks_usec()
		scene.get_node("Battle").rng.seed = 1
		root.add_child(scene)
		var c := Time.get_ticks_usec()
		await process_frame
		var d := Time.get_ticks_usec()
		scene.free()
		var e := Time.get_ticks_usec()
		if i >= 5:
			t.inst += b - a; t.add += c - b; t.frame += d - c; t.free += e - d
	var d: Dictionary = Engine.get_meta(&"perf", {})
	var ks := d.keys()
	ks.sort_custom(func(a, b): return d[a] > d[b])
	for k in ks:
		print("  %s %.2f ms" % [k, d[k] / 1000.0 / n])
	d = Engine.get_meta(&"cnt", {})
	ks = d.keys()
	ks.sort_custom(func(a, b): return d[a] > d[b])
	for k in ks.slice(0, 40):
		print("  # %s %d" % [k, d[k] / n])
	for k in t:
		print("%s %.2f ms" % [k, t[k] / 1000.0 / (n - 5)])
	quit()
