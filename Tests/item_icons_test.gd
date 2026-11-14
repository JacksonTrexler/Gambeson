extends Test

# Item icons (Icons/Items/<item file>.png, Item.icon()): every item has one, drawn by Util/icon.py; the card and the
# character sheet show them beside the trim banner.


func test_every_item_has_an_icon() -> void:
	var missing: Array[String] = []
	for f in DirAccess.get_files_at("res://Items"):
		if f.ends_with(".tres") and not ResourceLoader.exists("res://Icons/Items/%s.png" % f.get_basename()):
			missing.append(f)
	ok(missing.is_empty(), "every item has Icons/Items/<id>.png (python3 Util/icon.py items): %s" % ", ".join(missing))
	var it: Item = load("res://Items/dagger.tres")
	ok(it.icon() != null and it.icon().get_width() == 32, "an item reads its icon from the fixed path")
	var copy: Item = it.duplicate()
	ok(copy.icon() == it.icon(), "a copy made at run time (no file) finds it by name")
	var tp: Item = load("res://Items/tacticians_playbook.tres")
	ok(tp.icon() != null, "an apostrophe in a name doesn't lose it")


func test_icon_tool_check() -> void:
	var out := []
	var code := OS.execute("python3", [ProjectSettings.globalize_path("res://Util/icon.py"), "check"], out, true)
	ok(code == 0, "icon.py check passes: %s" % "".join(out))


func test_sheet_and_card_show_icons() -> void:
	var m := UnitCard.trim_mark(Color(1, 0, 0), "Dagger", (load("res://Items/dagger.tres") as Item).icon())
	ok(m is HBoxContainer and m.get_child(0) is TextureRect and m.get_child(1).custom_minimum_size == Vector2(7, 10), "an icon with the banner beside it")
	m.free()
	var u := v(1)
	u.weapon = load("res://Items/dagger.tres")
	ok(HUD.trims(u).any(func(t: Array) -> bool: return t[1] == "Dagger" and t[2] != null), "the card lists a worn weapon with its icon")
