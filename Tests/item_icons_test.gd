extends Test

# Item icons (Icons/Items/<item file>.png, Item.icon()): every item has one, drawn by Util/icon.py; the card and the
# character sheet show them beside the trim banner.


# Every item having one is item.py check's (tooling_test.test_checks).
func test_item_reads_its_icon() -> void:
	var it: Item = load("res://Items/dagger.tres")
	ok(it.icon() != null and it.icon().get_width() == 32, "an item reads its icon from the fixed path")
	var copy: Item = it.duplicate()
	ok(copy.icon() == it.icon(), "a copy made at run time (no file) finds it by name")
	var tp: Item = load("res://Items/tacticians_playbook.tres")
	ok(tp.icon() != null, "an apostrophe in a name doesn't lose it")


func test_sheet_and_card_show_icons() -> void:
	var m := UnitCard.trim_mark(Color(1, 0, 0), "Dagger", (load("res://Items/dagger.tres") as Item).icon())
	ok(m is HBoxContainer and m.get_child(0) is TextureRect and m.get_child(1).custom_minimum_size == Vector2(7, 10), "an icon with the banner beside it")
	m.free()
	var u := v(1)
	u.weapon = load("res://Items/dagger.tres")
	ok(HUD.trims(u).any(func(t: Array) -> bool: return t[1] == "Dagger" and t[2] != null), "the card lists a worn weapon with its icon")


# However many items a card lists, no icon overlaps another or the name block above; the spoils are icons too.
func test_card_icons_never_overlap_and_spoils_show_them() -> void:
	var h := await hud(v(1))
	var it: Item = load("res://Items/dagger.tres")
	var trims := []
	for i in 9:
		trims.append([Color(1, 0, 0) if i % 2 else Color(0, 0, 0, 0), "Dagger", it.icon()])
	var info: Dictionary = h._info(v(1))
	info["trims"] = trims
	h.card.set_info(info)
	await tree.process_frame
	await tree.process_frame
	var rects: Array[Rect2] = [h.card.get_node("Head").get_global_rect()]
	for c: Control in h.card.trims.get_children():
		rects.append(c.get_global_rect())
	ok(rects.size() == 10, "an icon each (%d rects)" % rects.size())
	var hit := false
	for i in rects.size():
		for j in range(i + 1, rects.size()):
			hit = hit or rects[i].intersects(rects[j])
	ok(not hit, "no icon touches another or the head (%s)" % [rects])
	h._show_spoils([it, it] as Array[Item])
	var row: Node = h.get_node("%OverText").get_parent().get_node_or_null("Spoils")
	ok(row != null and row.get_child_count() == 2 and row.get_child(0).get_child(0) is TextureRect, "the spoils draw an icon each")
	h._show_spoils([] as Array[Item])
	ok(h.get_node("%OverText").get_parent().get_node_or_null("Spoils") == null, "and no row without any")
	h.free()
