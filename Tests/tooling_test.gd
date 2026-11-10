extends Test

# What the authoring tools (Util/*.py, .claude/skills/) promise: every skill has an icon, a tile with
# its own art paints anywhere, and each tool's check passes.

func test_icons() -> void:
	var missing: Array[String] = []
	for f in DirAccess.get_files_at("res://Skills"):
		if f.ends_with(".tres") and (load("res://Skills/" + f) as Skill).icon() == null:
			missing.append(f)
	ok(missing.is_empty(), "every skill has an icon (python3 Util/icon.py skills): %s" % ", ".join(missing))
	ok(Skill.new().icon() == null, "a skill with no file has none: its mark is drawn instead")


func test_paint_look() -> void:
	var t := Terrain.new()
	t.name = "Probe"
	t.look = load("res://Icons/Skills/kick.png")
	var before := b.map.tile_set.get_source_count()
	b.paint(Vector2i(2, 2), t)
	ok(b.terrain(Vector2i(2, 2)) == t and b.map.tile_set.get_source_count() == before + 1, "a terrain with its own art paints as a source of its own")
	b.paint(Vector2i(3, 2), t)
	ok(b.map.tile_set.get_source_count() == before + 1 and b.terrain(Vector2i(3, 2)) == t, "and again from that source")


func test_checks() -> void:
	for tool in ["tile", "role", "unit", "mechanic"]:
		var out := []
		var code := OS.execute("python3", [ProjectSettings.globalize_path("res://Util/%s.py" % tool), "check"], out, true)
		if code == -1 or code == 127:
			print("tooling_test: no python3, checks skipped")
			return
		ok(code == 0, "Util/%s.py check: %s" % [tool, "".join(out).strip_edges()])
