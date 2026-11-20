extends Test

# Preparation (Battle.Phase.PREP, a battle from the entry screen: Battle.prep): before the initiative
# roll the player looks the field over and studies up to its cha mod of allies and its wis mod of foes
# and tiles (Battle.prepare()), its side reading each a recon level better for the battle - a foe that
# fools it looked at harder (doubt()), a tile inspected - then Begins.


func test_studies() -> void:
	stage(lancin, {v(1): Vector2i(1, 2), v(2): Vector2i(2, 2), v(3): Vector2i(5, 2), v(4): Vector2i(6, 2)})
	b.phase = Battle.Phase.PREP
	v(1).charisma = 12  # cha mod 1
	v(1).wisdom = 14  # wis mod 2
	ok(b.studies_left(v(1), true) == 1 and b.studies_left(v(1), false) == 2, "an ally by cha mod, two foes or tiles by wis mod")
	var net := b.read(v(1), v(2)).net
	ok(b.prepare(v(1), v(2)) == &"study_ally", "studies an ally")
	ok(b.read(v(1), v(2)).net == net + 1, "read a recon level better (%d -> %d)" % [net, b.read(v(1), v(2)).net])
	ok(b.studies_left(v(1), true) == 0, "no ally studies left")
	ok(b.prepare(v(1), v(2)) == &"", "nor the same one twice")
	net = b.read(v(1), v(3)).net
	ok(b.prepare(v(1), v(3)) == &"study" and b.read(v(1), v(3)).net == net + 1, "a foe")
	ok(b.prepare(v(1), Vector2i(4, 4)) == &"study" and b.studies_left(v(1), false) == 0, "a tile")
	ok(b.prepare(v(1), v(4)) == &"", "none left")
	ok(b.read(v(2), v(3)).net == net + 1, "shared across its side")
	b.begin()
	ok(b.phase == Battle.Phase.TURNS and b.turn != null, "Begin: the roll, then the first turn")
	ok(b.prepare(v(1), v(4)) == &"", "no studying once it's begun")


func test_none_below_zero() -> void:
	stage(lancin, {v(1): Vector2i(1, 2), v(2): Vector2i(2, 2)})
	b.phase = Battle.Phase.PREP
	v(1).charisma = 6
	ok(b.studies_left(v(1), true) == 0 and b.prepare(v(1), v(2)) == &"", "cha mod -2: no ally studies")


func test_hud() -> void:
	stage(lancin, {v(1): Vector2i(1, 2), v(2): Vector2i(2, 2), v(3): Vector2i(5, 2)})
	b.player = v(1)
	v(1).charisma = 12
	b.phase = Battle.Phase.PREP
	var h := await hud()
	h._mark()
	h._refresh()
	ok(h.end_button.text.begins_with("Begin") and not h.end_button.disabled, "the end turn button begins")
	ok(not h.my_turn(), "no orders in preparation")
	v(1).wisdom = 12  # wis mod 1
	h._mark()
	h._refresh()
	ok(h.phase_box.said() == ["Preparing", ["Study: 1 ally, 1 foe or tile"]], "the top box: the phase, and a study line (%s)" % [h.phase_box.said()])
	ok(h.study_state(v(2).cell) == &"open" and h.study_state(v(3).cell) == &"open" and h.study_state(Vector2i(4, 4)) == &"open", "the cursor's open over an ally, a foe, a tile")
	ok(h.study_state(v(1).cell) == &"" and h.study_state(HUD.NOWHERE) == &"", "none over the leader or nothing")
	h.prep_uses[&"survey"] = func() -> String: return "Survey: 2"
	h._refresh()
	ok(h.phase_box.said()[1] == ["Study: 1 ally, 1 foe or tile", "Survey: 2"], "a later use adds a line through prep_uses")
	h.prep_uses.erase(&"survey")
	h.hover_cell(v(2).cell)
	h._process(0.0)
	ok(h.study_cursor.visible and h.study_cursor.modulate.a == 1.0, "a magnifier by the pointer over a studyable unit")
	h.click(v(2).cell)
	ok(b.studied[lancin].has(v(2)) and "studies" in h.log_box.get_parsed_text(), "a click studies")
	h._refresh()
	ok(h.phase_box.said()[1] == ["Study: 1 foe or tile"], "the line follows what's left")
	h.click(v(2).cell)
	ok(h._note == "Already studied", "the same twice")
	h.click(v(3).cell)
	h.click(Vector2i(4, 4))
	h._refresh()
	ok(h._note == "No studies left" and h.phase_box.said()[1] == ["Study: none left"], "click with none left: a short note, only on a click (%s)" % h._note)
	h._note = ""
	h.hover_cell(Vector2i(4, 4))
	h._process(0.0)
	ok(h._note == "" and h.study_state(Vector2i(4, 4)) == &"spent" and h.study_cursor.visible and h.study_cursor.modulate.a < 1.0, "hovering says nothing; the magnifier greys")
	h.hover_cell(v(1).cell)
	h._process(0.0)
	ok(not h.study_cursor.visible, "no magnifier over the leader")
	h._end_pressed()
	for i in 4:
		await tree.process_frame
	ok(b.phase == Battle.Phase.TURNS and not h._opening, "begun")
	ok(h.phase_box.said().is_empty() and h.study_state(v(3).cell) == &"", "the box and the cursor are gone once it's begun")
	h.free()


func test_entry_prepares() -> void:
	ok(load("res://Scripts/Entry.gd").source_code.contains("prep = true"), "a battle from the entry screen opens in preparation")
