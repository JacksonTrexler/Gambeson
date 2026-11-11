extends Test

# Preparation (Battle.Phase.PREP, a battle from the entry screen: Battle.prep): before the initiative
# roll the player looks the field over and studies up to its cha mod of allies and its wis mod of foes
# and tiles (Battle.study()), its side reading each a recon level better for the battle - a foe that
# fools it looked at harder (doubt()), a tile inspected - then Begins.


func test_studies() -> void:
	stage(lancin, {v(1): Vector2i(1, 2), v(2): Vector2i(2, 2), v(3): Vector2i(5, 2), v(4): Vector2i(6, 2)})
	b.phase = Battle.Phase.PREP
	v(1).charisma = 12  # cha mod 1
	v(1).wisdom = 14  # wis mod 2
	ok(b.studies_left(v(1), true) == 1 and b.studies_left(v(1), false) == 2, "an ally by cha mod, two foes or tiles by wis mod")
	var net := b.read(v(1), v(2)).net
	ok(b.study(v(1), v(2)), "studies an ally")
	ok(b.read(v(1), v(2)).net == net + 1, "read a recon level better (%d -> %d)" % [net, b.read(v(1), v(2)).net])
	ok(b.studies_left(v(1), true) == 0, "no ally studies left")
	ok(not b.study(v(1), v(2)), "nor the same one twice")
	net = b.read(v(1), v(3)).net
	ok(b.study(v(1), v(3)) and b.read(v(1), v(3)).net == net + 1, "a foe")
	ok(b.study(v(1), Vector2i(4, 4)) and b.studies_left(v(1), false) == 0, "a tile")
	ok(not b.study(v(1), v(4)), "none left")
	ok(b.read(v(2), v(3)).net == net + 1, "shared across its side")
	b.begin()
	ok(b.phase == Battle.Phase.TURNS and b.turn != null, "Begin: the roll, then the first turn")
	ok(not b.study(v(1), v(4)), "no studying once it's begun")


func test_none_below_zero() -> void:
	stage(lancin, {v(1): Vector2i(1, 2), v(2): Vector2i(2, 2)})
	b.phase = Battle.Phase.PREP
	v(1).charisma = 6
	ok(b.studies_left(v(1), true) == 0 and not b.study(v(1), v(2)), "cha mod -2: no ally studies")


func test_hud() -> void:
	stage(lancin, {v(1): Vector2i(1, 2), v(2): Vector2i(2, 2), v(3): Vector2i(5, 2)})
	b.player = v(1)
	v(1).charisma = 12
	b.phase = Battle.Phase.PREP
	var h: HUD = load("res://Scenes/UI/hud.tscn").instantiate()
	h.battle = b
	h.auto = false
	h.pace = 0.0
	tree.root.add_child(h)
	await tree.process_frame
	h._mark()
	h._refresh()
	ok(h.end_button.text.begins_with("Begin") and not h.end_button.disabled, "the end turn button begins")
	ok(not h.my_turn(), "no orders in preparation")
	h.click(v(2).cell)
	ok(b.studied[lancin].has(v(2)) and "studies" in h.log_box.get_parsed_text(), "a click studies")
	h._end_pressed()
	for i in 4:
		await tree.process_frame
	ok(b.phase == Battle.Phase.TURNS and not h._opening, "begun")
	h.free()


func test_entry_prepares() -> void:
	ok(load("res://Scripts/Entry.gd").source_code.contains("prep = true"), "a battle from the entry screen opens in preparation")
