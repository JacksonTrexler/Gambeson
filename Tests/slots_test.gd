extends Test

# Hotbar slots under buffs and curses: a level effect moves a unit's level (Unit.lv()), slots following
# - a curse's lost slots stay, sealed (Unit.sealed()); pillar skills keep the last sure slots; and on
# the bar, disabled skills dim while a curse's also quiver (SkillSlot.cursed).

var brainfog: Skill = load("res://Skills/brainfog.tres")


func test_level_curse() -> void:
	v(1).level = 4
	v(1)._arrange()
	ok(v(1).slot_count() == 5 and v(1).clover() == -1, "level 4: five sure slots, no clover")
	v(1).afflict(effect("level", -1), 1)
	ok(v(1).lv() == 3 and v(1).slot_count() == 5 and v(1).sealed(4) and not v(1).slot_works(4), "cursed to 3: the fifth slot stays, sealed")
	ok(v(1).clover() == 5 and v(1).bar_size() == 6, "and level 3 rounds: a clover slot")
	ok(not v(1).bar_place(strike, 4), "nothing goes in a sealed slot")
	v(1).tick()
	ok(v(1).lv() == 4 and not v(1).sealed(4) and v(1).bar_size() == 5, "the curse ends: back")


func test_level_buff() -> void:
	v(1).level = 3
	v(1)._arrange()
	ok(v(1).slot_count() == 4 and v(1).clover() == 4, "level 3: four sure slots and a clover")
	v(1).afflict(effect("level", 1), 1)
	ok(v(1).lv() == 4 and v(1).slot_count() == 5 and v(1).clover() == -1 and not v(1).sealed(4), "buffed to 4: a fifth sure slot")
	v(1).hotbar[4] = favour
	v(1).tick()
	ok(v(1).bar_size() == 5 and v(1).clover() == 4, "it ends: the slot goes, the clover comes back")
	v(1).level = 1


func test_curse_on_defense() -> void:
	v(1).level = 20
	v(1).armor = load("res://Items/plate.tres")
	var d := v(1).defense()
	v(1).afflict(effect("level", 5), 1)
	ok(v(1).defense() == d + 5, "plate goes by its level now: +5")
	v(1).tick()
	v(1).armor = null
	v(1).level = 1


func test_pillar_pinned() -> void:
	var p := Skill.new()
	p.name = "Bedrock"
	p.tags = [&"pillar"]
	p.ap = 1.0
	v(1).learned.append(slot(p))
	v(1).hotbar.clear()
	v(1)._fill_bar()
	var last := v(1).slot_count() - 1
	ok(v(1).hotbar[last] == p, "a pillar active takes the last sure slot")
	ok(not v(1).bar_place(p, 0) and not v(1).bar_place(strike, last), "it can't be moved, nor anything put over it")
	v(1).bar_clear(last)
	ok(v(1).hotbar[last] == p, "nor taken off")
	var free := v(1).hotbar.find(null)
	var at := v(1).hotbar.find(strike)
	ok(v(1).bar_place(strike, free) and v(1).hotbar[free] == strike and at != free, "anything else moves freely")


func test_brainfog_curses() -> void:
	stage(nemes, {v(3): Vector2i(5, 1), v(1): Vector2i(4, 1)})
	v(3).charisma = 20
	v(3).learned.append(slot(brainfog))
	v(1).wisdom = 1
	for i in 30:
		v(3).refresh()
		b.cast(v(3), brainfog, v(1))
		if not v(1).disabled.is_empty():
			break
	ok(not v(1).cursed.is_empty() and v(1).cursed.keys() == v(1).disabled.keys(), "Brainfog's are a curse's")
	for i in 5:
		v(1).tick()
	ok(v(1).disabled.is_empty() and v(1).cursed.is_empty(), "both wear off")


func test_slot_looks() -> void:
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
	ok(c.off == 2 and not c.cursed and not c.is_processing() and "Disabled for 2" in c.tooltip_text, "disabled: dimmed, still")
	v(1).disabled.clear()
	v(1).disable(strike, 2, true)
	h._refresh()
	c = h.bar.get_child(0) as SkillSlot
	ok(c.off == 2 and c.cursed and c.is_processing() and "Cursed for 2" in c.tooltip_text, "cursed: it quivers")
	v(1).disabled.clear()
	v(1).cursed.clear()
	v(1).level = 4
	v(1)._arrange()
	v(1).afflict(effect("level", -1), 1)
	h._refresh()
	c = h.bar.get_child(4) as SkillSlot
	ok(c.sealed and c.cursed and not c.works, "a slot a level curse took: sealed, quivering")
	v(1).timed.clear()
	v(1).level = 1
	h.free()
