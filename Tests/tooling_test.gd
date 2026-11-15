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
	for tool in ["tile", "role", "unit", "mechanic", "item"]:
		tool_check(tool)


# item.py new writes an Item Godot loads as asked: ?? on a made-up name, the quality and scope tags, a lent
# skill, a loot table entry; it refuses enchanted with honed. A dry run, saved under user:// and loaded.
func test_item_tool() -> void:
	var py := ProjectSettings.globalize_path("res://Util/item.py")
	var out := []
	var code := OS.execute("python3", [py, "new", "zz_probe", "--slot", "trinket", "--rarity", "rare", "--enchanted", "--skill", "kick",
			"--emblem", "rho_up", "--scope", "sigil", "--loot", "alabaster:2", "--dry-run"], out, true)
	if code == -1 or code == 127:
		print("tooling_test: no python3, skipped")
		return
	var text := "".join(out)
	ok(code == 0, "item.py new runs: %s" % text)
	var body := text.get_slice("--- would write Items/zz_probe.tres ---\n", 1).get_slice("\n--- would write", 0)
	var f := FileAccess.open("user://zz_probe.tres", FileAccess.WRITE)
	f.store_string(body)
	f.close()
	var it := ResourceLoader.load("user://zz_probe.tres", "", ResourceLoader.CACHE_MODE_IGNORE) as Item
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://zz_probe.tres"))
	ok(it != null and it.name == "Zz Probe ??" and it.slot == "trinket" and it.rarity == "rare", "an Item, its made-up name marked ??")
	ok(it != null and it.enchanted() and &"sigil" in it.tags and it.emblem == &"rho_up" and it.ranked() == 2, "enchanted (rank +1), an emblem with its scope as a tag")
	ok(it != null and it.skills.size() == 1 and it.skills[0].resource_path == "res://Skills/kick.tres", "it lends the skill")
	ok('res://Items/zz_probe.tres' in text and "1.0, 2.0])" in text, "the loot table gains it at its weight")
	out.clear()
	code = OS.execute("python3", [py, "new", "zz_probe", "--slot", "trinket", "--tags", "enchanted,honed", "--dry-run"], out, true)
	ok(code != 0 and "exclude" in "".join(out), "enchanted and honed together are refused")
