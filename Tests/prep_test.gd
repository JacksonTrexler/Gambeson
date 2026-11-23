extends Test

# Preparation (Battle.Phase.PREP, a battle from the entry screen: Battle.prep): before the initiative
# roll the player looks the field over and studies up to its cha mod of allies and its wis mod of foes
# and tiles (Battle.prepare()), its side reading each a recon level better for the battle - a foe that
# fools it looked at harder (doubt()), a tile inspected - then Begins. Study is two rows of Prep.USES; the
# Surveyor, Evaluator and Inquisitor add the rest (a rank each), and the same tags, in battle, add their rank
# to the checks of their kind (survey: inspecting a tile; evaluate: sizing a unit up, recon; inquire: doubting).

var surveyor: Skill = load("res://Skills/surveyor.tres")
var evaluator: Skill = load("res://Skills/evaluator.tres")
var inquisitor: Skill = load("res://Skills/inquisitor.tres")


func siren() -> Unit:
	return b.get_node("Units/Siren")


func give(u: Unit, s: Skill, r := 1) -> void:
	u.learned.append(slot(s, r))


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


# Surveys: a tile's intel alone (no inspection of it); Inquisitions: suspicion alone, of a unit that fools it,
# and for units only; each by its rank, a target once.
func test_uses() -> void:
	var trap := Vector2i(5, 4)  # the museum's spike trap: inspecting it would roll
	stage(nemes, {siren(): Vector2i(8, 6), v(1): Vector2i(5, 6), v(2): Vector2i(8, 5), v(3): Vector2i(2, 6)})
	b.phase = Battle.Phase.PREP
	var leader := v(1)
	leader.wisdom = 6  # no studies
	leader.charisma = 6
	give(leader, surveyor, 2)
	give(leader, inquisitor, 2)
	ok(Prep.total(leader, &"survey") == 2 and Prep.total(leader, &"inquire") == 2 and Prep.total(leader, &"evaluate") == 0, "a use for each rank of its skill")
	var looks := []
	b.inspected.connect(func(_by, at, _a, _b): looks.append(at))
	b.doubted.connect(func(by: Unit, of: Unit, _a, _b): looks.append(of))
	ok(b.read(leader, siren()).deceived, "it takes the siren for what she's not")
	var net := b.read(leader, trap).net
	ok(b.prepare(leader, trap) == &"survey" and b.read(leader, trap).net == net + 1, "a tile: its Survey reads it a level better")
	ok(looks.is_empty() and leader.suspects(trap) == 0, "and inspects nothing: intel alone")
	ok(b.prepare(leader, trap) == &"", "once")
	ok(b.prepare(leader, siren()) == &"inquire" and looks == [siren()], "a unit that fools it: an Inquisition doubts it")
	ok(not siren() in b.studied.get(leader.faction, {}) and b.prepare(leader, siren()) == &"", "with no intel from it, and once")
	ok(b.prepare(leader, v(3)) == &"inquire" and looks == [siren()] and b.uses_left(leader, &"inquire") == 0, "one that fools it by nothing: spent, no doubt to make")
	ok(b.prepare(leader, v(2)) == &"" and b.uses_left(leader, &"survey") == 1, "none left of a kind: the others stay")
	ok(b.prepare(leader, Vector2i(4, 5)) == &"survey" and b.prepare(leader, Vector2i(3, 5)) == &"", "a Survey for each rank")


# What a click spends, in order: Study first (intel and a look), then the skills' uses; intel a target already
# has is no reason to spend one that gives only intel, a use that gives only suspicion still fits.
func test_use_order() -> void:
	stage(lancin, {v(1): Vector2i(1, 2), v(3): Vector2i(5, 2), v(4): Vector2i(6, 2)})
	b.phase = Battle.Phase.PREP
	var leader := v(1)
	leader.wisdom = 12  # one study
	leader.charisma = 6
	give(leader, evaluator, 2)
	give(leader, inquisitor, 1)
	var doubts := []
	b.doubted.connect(func(_by, of: Unit, _a, _b): doubts.append(of))
	var net := b.read(leader, v(4)).net
	ok(b.prepare(leader, v(3)) == &"study" and b.prepare(leader, v(4)) == &"evaluate", "Study, then an Evaluate")
	ok(b.read(leader, v(4)).net == net + 1 and doubts.is_empty(), "an Evaluate reads a unit better and doubts nothing")
	ok(b.prepare(leader, v(3)) == &"inquire" and b.prepare(leader, v(4)) == &"" and b.uses_left(leader, &"evaluate") == 1, "a studied unit takes the Inquisition, not an Evaluate it has no use for")
	ok(b.prepare(leader, v(1)) == &"" and b.prepare(leader, Vector2i(-1, 0)) == &"", "never itself, never off the map")


func test_none_below_zero() -> void:
	stage(lancin, {v(1): Vector2i(1, 2), v(2): Vector2i(2, 2)})
	b.phase = Battle.Phase.PREP
	v(1).charisma = 6
	ok(b.studies_left(v(1), true) == 0 and b.prepare(v(1), v(2)) == &"", "cha mod -2: no ally studies")


# What a skill adds in battle, on the check channels its tag names: a check of the kind gets its rank, others don't.
func test_check_channels() -> void:
	stage(nemes, {siren(): Vector2i(8, 6), v(1): Vector2i(5, 6), v(2): Vector2i(8, 5), v(3): Vector2i(2, 6)})
	var u := v(1)
	var seen := b.read(v(2), v(3)).net
	give(u, surveyor, 2)
	give(v(2), evaluator, 3)
	give(v(3), inquisitor, 4)
	ok(u.check_bonus(&"wisdom", &"offensive", [&"survey"]) == 2 and u.check_bonus(&"wisdom", &"offensive", [&"inquire"]) == 0 and u.check_bonus(&"wisdom", &"offensive") == 0,
			"+rank to a check carrying its tag, none to the rest")
	ok(v(3).check_bonus(&"wisdom", &"offensive", [&"inquire"]) == 4, "an Inquisitor's, to overcoming trickery")
	ok(v(2).stat(&"recon", Perception.sizing(v(3))) == 3 and v(2).stat(&"recon", v(3).tags) == 0 and v(2).stat(&"recon", [&"trap"]) == 0, "an Evaluator's: +rank to sizing up a unit, not to reading ground")
	v(2).refresh()
	ok(b.read(v(2), v(3)).net == seen + 3, "and a read of it makes out that much more (%d -> %d)" % [seen, b.read(v(2), v(3)).net])
	# the checks themselves carry the tags: a bonus of 30 beats any d20 (wis mod 0, a tile or two off)
	u.wisdom = 10
	u.timed.clear()
	u.learned.clear()
	u.afflict(effect("check", 30, [&"survey"]), 9)
	var totals := []
	b.inspected.connect(func(_by, _at, total: int, _against): totals.append(total))
	ok(b.inspect(u, Vector2i(5, 4)) and totals.size() == 1 and totals[0] > 20, "inspecting a tile counts a Survey bonus (%s)" % [totals])
	u.timed.clear()
	u.afflict(effect("check", 30, [&"inquire"]), 9)
	b.doubted.connect(func(_by, _of, total: int, _against): totals.append(total))
	b.doubt(u, siren())
	ok(totals.size() == 2 and totals[1] > 20, "doubting counts an Inquisition bonus (%s)" % [totals])
	b.investigated.connect(func(_o, _u, _s, total: int, _against, _close): totals.append(total))
	b.investigate(v(2), load("res://Skills/hide.tres"), [u] as Array[Unit], 0)
	ok(totals.size() == 3 and totals[2] > 20, "so does looking into what a skill hid (%s)" % [totals])


# The two sides of doubt(): a trickster's own Inquisition doesn't help it lie (their_tags = []), and an
# Inquisition's use looks at advantage (Prep.USES.inquire.edge), through prepare().
func test_doubt_sides() -> void:
	stage(nemes, {siren(): Vector2i(8, 6), v(1): Vector2i(0, 6), v(2): Vector2i(8, 5), v(3): Vector2i(2, 6)})
	var leader := v(1)
	leader.wisdom = 10
	give(leader, inquisitor, 1)
	var against := []
	b.doubted.connect(func(_by, _of, _a, vs: int): against.append(vs))
	for i in 60:
		b.doubt(leader, siren())
	var base: int = against.max()
	against.clear()
	siren().afflict(effect("check", 30, [&"inquire"]), 99)
	for i in 20:
		b.doubt(leader, siren())
	ok(against.max() <= base + 10, "a trickster's own inquire bonus adds nothing to its side (%d vs %d)" % [against.max(), base])
	siren().timed.clear()
	var tally := func(use: bool) -> int:
		var n := 0
		for i in 250:
			leader.suspicion.clear()
			if use:
				b.prepped.clear()
				b.studied.clear()
				n += int(b.prepare(leader, siren()) == &"inquire" and leader.suspects(siren()) > 0)
			else:
				n += int(b.doubt(leader, siren()))
		return n
	b.phase = Battle.Phase.PREP
	leader.wisdom = 10
	var plain: int = tally.call(false)
	var edged: int = tally.call(true)
	ok(edged > plain + 20, "an Inquisition's doubt is at advantage: %d well over %d (of 250)" % [edged, plain])


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


# The top box carries a line for each use a skill grants, once its holder has one, counted down as they're spent.
func test_hud_uses() -> void:
	stage(lancin, {v(1): Vector2i(1, 2), v(2): Vector2i(2, 2), v(3): Vector2i(5, 2)})
	b.player = v(1)
	b.phase = Battle.Phase.PREP
	v(1).wisdom = 6
	v(1).charisma = 6
	give(v(1), surveyor, 2)
	give(v(1), inquisitor, 1)
	var h := await hud()
	h._mark()
	h._refresh()
	ok(h.phase_box.said()[1] == ["Study: none left", "Surveys: 2 tiles", "Inquisitions: 1 unit"], "a line per use it has, none for Evaluates (%s)" % [h.phase_box.said()])
	ok(h.study_state(Vector2i(4, 4)) == &"open" and h.study_state(v(3).cell) == &"open", "the magnifier's open over what a use fits")
	h.click(Vector2i(4, 4))
	h.click(v(3).cell)
	h._refresh()
	ok(h.phase_box.said()[1] == ["Study: none left", "Surveys: 1 tile", "Inquisitions: none left"] and "surveys" in h.log_box.get_parsed_text() and "inquires about" in h.log_box.get_parsed_text(),
			"counted down, and the log says which (%s)" % [h.phase_box.said()])
	ok(h.study_state(v(3).cell) == &"spent" and h.study_state(Vector2i(3, 3)) == &"open", "spent over a unit it can't use more on, open over another tile")
	h._end_pressed()
	for i in 4:
		await tree.process_frame
