extends Test

# Disabled skills, by Brainfog (a Warlock's curse): the foe saves (d20 + wis mod + the ranks of the
# skills it would lose) against d20 + the caster's cha mod + rank, or loses the caster's luck-rounded
# sqrt(rank) of its skill slots, right to left (Unit.disable_order()), for rank + 1 turns. Pillar skills
# sit in the last sure slots and go as one, at their median rank (Unit.disable(), Unit.slot_weight()).

var brainfog: Skill = load("res://Skills/brainfog.tres")


func caster(r := 1) -> void:
	v(3).charisma = 20  # mod 5: range 5 + rank
	v(3).learned.append(slot(brainfog, r))
	v(3).refresh()


func pillar(n: String, amount: float) -> Skill:
	var s := Skill.new()
	s.name = n
	s.passive = true
	s.tags = [&"pillar"]
	s.effects = [effect("initiative", amount)]
	return s


# Casts until the foe fails its save (it has wis 1), or gives up.
func fog(t: Unit) -> bool:
	for i in 30:
		v(3).refresh()
		b.cast(v(3), brainfog, t)
		if not t.disabled.is_empty():
			return true
	return false


func test_order() -> void:
	ok(v(1).disable_order() == [[favour], [strike]], "the always-on passive (Favour), then the hotbar from the right (Strike)")
	var p1 := pillar("P1", 1)
	var p2 := pillar("P2", 2)
	var p3 := pillar("P3", 4)
	v(1).learned.append_array([slot(p1, 1), slot(p2, 3), slot(p3, 5)])
	var order := v(1).disable_order()
	ok(order.size() == 3 and order[0] == [p1, p2, p3], "pillar skills first, as one slot")
	ok(v(1).slot_weight(order[0]) == 3 and v(1).slot_weight([strike]) == 1, "they weigh their median rank (1, 3, 5: 3)")
	v(1).disable(p2, 2)
	ok(v(1).disabled.keys() == [p1, p2, p3] and v(1).stat(&"initiative") == 0, "one pillar disabled: all of them, and their effects stop")
	ok(v(1).disable_order() == [[favour], [strike]], "skills already disabled aren't reached again")


func test_disables() -> void:
	stage(nemes, {v(3): Vector2i(5, 1), v(1): Vector2i(1, 1)})
	caster()
	ok(b.skill_range(v(3), brainfog) >= 6.0 and not brainfog.attacks(), "range cha mod + rank; no attack roll")
	v(1).wisdom = 1
	ok(fog(v(1)) and v(1).disabled.keys() == [favour] and v(1).disabled[favour] == 2, "rank I: one slot, the rightmost (Favour), for 2 turns")
	ok(v(1).luck == 0 and strike in v(1).actives, "its luck is gone; Strike still works")
	ok(favour in b.read(v(2), v(1)).kit, "allies still know it has it")
	v(1).tick()
	ok(v(1).disabled[favour] == 1, "a turn down")
	v(1).tick()
	ok(v(1).disabled.is_empty() and v(1).luck == 1, "and back")
	v(1).disable(strike, 1)
	b.end_turn()
	ok(not b.cast(v(1), strike, v(3)), "a disabled active can't be used")


func test_pillars() -> void:
	stage(nemes, {v(3): Vector2i(5, 1), v(1): Vector2i(1, 1)})
	caster(4)  # sqrt 4: 2 slots
	v(1).wisdom = 1
	var p := [pillar("P1", 1), pillar("P2", 1), pillar("P3", 1)]
	for s: Skill in p:
		v(1).learned.append(slot(s))
	var said := []
	b.contested.connect(func(_c: Unit, _t: Unit, total: int, against: int): said.append([total, against]))
	ok(fog(v(1)) and v(1).disabled.size() == 4 and favour in v(1).disabled and strike not in v(1).disabled,
			"two slots: the three pillars as one, and the passive left of them - four skills %s" % [v(1).disabled.keys()])
	ok(said.all(func(x: Array): return x[1] - 2 <= 20 - 5 and x[1] - 2 >= 1 - 5), "its save adds their ranks: the pillars' median (1) and Favour's (1)")


func test_saved() -> void:
	stage(nemes, {v(3): Vector2i(5, 1), v(1): Vector2i(4, 1)})
	caster()
	v(1).wisdom = 42  # mod 16
	ok(b.cast(v(3), brainfog, v(1)) and v(1).disabled.is_empty(), "a passed save: nothing")
	ok(v(1).suspects(v(3)) == 1, "but it felt something try: suspicious of the caster")
	ok("Failing, 1 of its skill slots are disabled" in brainfog.describe(1) and "2 (3 while lucky)" in brainfog.describe(5), brainfog.describe(5))


func test_hotbar() -> void:
	stage(lancin, {v(1): Vector2i(1, 2), v(3): Vector2i(8, 2)})
	b.player = v(1)
	var h: HUD = load("res://Scenes/UI/hud.tscn").instantiate()
	h.battle = b
	h.auto = false
	h.pace = 0.0
	tree.root.add_child(h)
	await tree.process_frame
	v(1).disable(strike, 2)
	h.select(v(1))
	h._refresh()
	var c := h.bar.get_child(0) as SkillSlot
	ok(c.skill == strike and c.off == 2 and not c.usable and "Disabled for 2" in c.tooltip_text, "greyed out, struck through, saying for how long")
	h.use_slot(0)
	ok(h.armed == null and "disabled for 2" in h._note, h._note)
	h.free()
