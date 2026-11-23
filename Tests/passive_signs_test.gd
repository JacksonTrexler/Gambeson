extends Test

# Passive signs (docs/plans/w7-passives.md): one signal, Battle.passive_fired, from the moments a passive (or what a skill
# put on, or luck itself) really acts on a unit - never a plan - and the HUD's answer to it: the viewed unit's slot lights,
# anyone else gets "Name amount" floated over it; rounded amounts are slanted (down) or heavy (up); always-on passives muted.

var fired: Array = []


func _listen() -> void:
	fired.clear()
	if not b.passive_fired.is_connected(_on_fired):
		b.passive_fired.connect(_on_fired)


func _on_fired(u: Unit, s: Skill, amount: int, stat: StringName, rounded: int) -> void:
	fired.append([u, s, amount, stat, rounded])


# The Battle side: regen, luck (a squeezed step, a reach only luck made, never a planned walk), a hurt hook (Molothrus).
func test_battle_signs() -> void:
	stage(lancin, {v(1): Vector2i(5, 1), v(2): Vector2i(1, 5), v(3): Vector2i(8, 5)})
	_listen()
	v(2).max_hp = 10
	v(2).hp = 1
	var a := v(2).afflict(effect("regen", 0.15), 5)
	b._mend(v(2))
	ok(v(2).luck > 0 and fired == [[v(2), null, 2, &"regen", 1]], "regen 1.5, lucky: +2, rounded up, signed as Regen itself: %s" % [fired])
	fired.clear()
	a.skill = sk("rejuvinate")
	b._mend(v(2))
	ok(fired.size() == 1 and fired[0][1] == a.skill and fired[0][3] == &"hp", "put on by Rejuvinate: signed by it, in hp")
	fired.clear()
	v(2).hp = 10
	b._mend(v(2))
	ok(fired.is_empty(), "nothing healed: no sign")

	v(1).moved = 4.0
	b.walk(v(1), Vector2i(6, 1), true)
	ok(fired.is_empty(), "a planned walk (expected) signs nothing, though luck would squeeze the step in")
	ok(b.travel(v(1), Vector2i(6, 1)).size() == 1 and fired == [[v(1), null, v(1).luck, &"luck", 0]], "the real walk: luck squeezed it in, Luck +%d: %s" % [v(1).luck, fired])

	fired.clear()
	stage(lancin, {v(1): Vector2i(4, 4), v(3): Vector2i(5, 5)})
	ok(b.cast(v(1), strike, v(3)) and fired.size() == 1 and fired[0][3] == &"luck" and fired[0][2] == v(1).luck - v(3).luck,
			"a diagonal Strike only luck's rounding reaches: Luck +net, once paid: %s" % [fired])
	fired.clear()
	stage(lancin, {v(1): Vector2i(4, 4), v(3): Vector2i(5, 4)})
	b.cast(v(1), strike, v(3))
	ok(fired.is_empty(), "in reach anyway: luck did nothing, no sign")

	var bl: Unit = b.summon(load("res://Scenes/blinthe.tscn"), load("res://Factions/unaligned.tres"), Vector2i(5, 3))
	stage(lancin, {v(1): Vector2i(4, 3)})
	b.move(bl, Vector2i(5, 3))
	soak(bl, 200)
	fired.clear()
	var took := bl.hit(10, [&"physical"] as Array[StringName])
	ok(fired.size() == 1 and fired[0][0] == bl and fired[0][1].name == "Molothrus" and fired[0][2] == 10 - took and fired[0][3] == &"hp",
			"Molothrus passing part of a hit on: it signs on its holder, the hp it was spared: %s" % [fired])


# The HUD side: the viewed unit's slot lights instead of a floater; anyone else gets its sign; luck glints; rounding's faces.
func test_hud_signs() -> void:
	var favour_ := favour
	roomy(v(1))
	roomy(v(2))
	for u in [v(1), v(2)]:
		u.learned.append(slot(favour_, 1)); u.sync_bar()
		u.refresh()
	stage(lancin, {v(1): Vector2i(1, 2), v(2): Vector2i(1, 5)})
	var h := await hud(v(1))
	h.select(v(1))
	h._refresh_bar()
	var lit := func() -> SkillSlot:
		for x: SkillSlot in h.bar.get_children():
			if x.skill == favour_:
				return x
		return null
	var floats := func() -> Array:
		return h.overlay.top.get_children().filter(func(n: Node): return n is Label and not n.is_queued_for_deletion())
	var before: int = floats.call().size()
	ok(lit.call() != null and SkillSlot.muted(favour_) and not SkillSlot.muted(strike), "an always-on passive's slot is muted; an active's isn't")
	b.passive(v(1), favour_, 0, &"")
	ok(lit.call()._glow() > 0.0 and lit.call()._rim and floats.call().size() == before, "on the viewed unit: its slot lights (with a rim, first time), no floater")
	b.passive(v(1), favour_, 0, &"")
	ok(not lit.call()._rim, "again at once: it only unmutes")
	b.passive(v(2), favour_, 3, &"hp")
	var signs: Array = floats.call()
	ok(signs.size() == before + 1 and signs[-1].text == "Favour +3 hp", "another unit: its sign floats over it (%s)" % [signs.map(func(l): return l.text)])
	b.passive(v(2), null, 1, &"luck")
	signs = floats.call()
	ok(signs[-1].text == "Luck +1" and signs[-1].get_children().any(func(n: Node): return n is Polygon2D), "luck itself: \"Luck +1\" with a glint")
	h.overlay.float_text(v(2), "-3", Color.RED, -1)
	var down: Label = floats.call()[-1]
	h.overlay.float_text(v(2), "-4", Color.RED, 1)
	var up: Label = floats.call()[-1]
	var face := func(l: Label) -> FontVariation:
		return l.get_theme_font(&"font") as FontVariation if l.has_theme_font_override(&"font") else null
	ok(face.call(down) and face.call(down).variation_transform.y.x != 0.0 and face.call(up) and face.call(up).variation_embolden > 0.0,
			"rounded down: slanted; rounded up: heavy")
	var e := SkillEntry.new(favour_, 1, true, true, true, v(1))
	ok(e.find_children("*", "Label", true, false).any(func(l: Label): return l.text == favour_.name and l.get_theme_color(&"font_color") == SkillSlot.MUTED_TEXT),
			"the spellbook mutes it too")
	e.free()
	h.free()


# The rest of the rounding styles (docs/plans/w8-fc.md): a heal carries how luck rounded it (Unit.being_healed's dict) from
# each path that rounds one - a potion, a skill's stat mods, regen - and the HUD slants or emboldens its number; the log's
# amounts take the same faces (italic down, bold up) when what they say all came of one way of rounding.
func test_rounded_heals_and_log() -> void:
	stage(lancin, {v(1): Vector2i(5, 1), v(2): Vector2i(5, 2), v(3): Vector2i(8, 5)})
	var heard: Array = []
	for u in [v(1), v(2)]:
		u.being_healed.connect(func(_u: Unit, got: Dictionary): heard.append(got.duplicate()))
	var potion: Item = load("res://Items/health_potion.tres").duplicate()
	potion.restore_mod = &""  # (whole: only the 15% of max HP is fractional)
	v(1).max_hp = 33  # 4.95 of it
	v(1).hp = 1
	var lucky := effect("luck", 5.0)
	var unlucky := effect("luck", -10.0)
	v(1).afflict(lucky, 9)
	v(1).equip(potion)
	b.restore(v(1), potion)
	v(1).hp = 1
	v(1).timed.erase(lucky)
	v(1).afflict(unlucky, 9)
	b.restore(v(1), potion)
	v(1).timed.erase(unlucky)
	ok(heard.map(func(g): return [g.hp, g.rounded]) == [[5, 1], [4, -1]], "a potion's 15%% of 33 (4.95): lucky 5 (up), unlucky 4 (down): %s" % [heard])
	heard.clear()
	var aid := sk("first_aid")
	v(2).learned.append(slot(aid, 1)); v(2).sync_bar()
	v(1).hp = 1
	v(2).wisdom = 16  # +3, dexterity's mod odd or even: nudge to an odd sum so the split leaves a half
	while int(aid.heal_raw(v(2)) * 2.0) % 2 == 0 and v(2).wisdom < 30:
		v(2).wisdom += 2
	var raw := aid.heal_raw(v(2))
	ok(raw != floorf(raw), "(a fractional heal: %s)" % raw)
	var settled := v(2).rounded(raw)
	b.cast(v(2), aid, v(1))
	ok(heard.size() == 1 and heard[0].rounded == Luck.rounded(raw, settled), "a skill's stat mods: signed as luck rounded them (%s of %s)" % [heard, raw])
	heard.clear()
	v(2).max_hp = 10
	v(2).hp = 1
	v(2).luck = 2
	v(2).afflict(effect("regen", 0.15), 5)
	b._mend(v(2))
	ok(heard.size() == 1 and heard[0].rounded == 1, "regen 1.5, lucky: up (%s)" % [heard])

	var h := await hud(v(1))
	var floats := func() -> Array:
		return h.overlay.top.get_children().filter(func(n: Node): return n is Label and not n.is_queued_for_deletion())
	v(2).hp = 1
	v(2).heal(4, true, -1)
	var l: Label = floats.call()[-1]
	ok(l.text == "+4" and l.get_theme_font(&"font") is FontVariation and l.get_theme_font(&"font").variation_transform.y.x != 0.0, "a heal rounded down: its number is slanted (%s)" % l.text)
	v(2).heal(3, true, 1)
	l = floats.call()[-1]
	ok(l.text == "+3" and l.get_theme_font(&"font").variation_embolden > 0.0, "up: heavy")
	v(2).heal(2)
	l = floats.call()[-1]
	ok(l.text == "+2" and not l.has_theme_font_override(&"font"), "unrounded: plain")
	# the log: blows a unit took this frame, summed; one way of rounding styles the amount, two ways or a cut doesn't
	var blow := func(n: int, r: int) -> Dictionary: return {damage = n, rounded = r, tags = [] as Array[StringName], by = null}
	h._on_taking_hit(v(3), blow.call(3, -1))
	h._on_taking_hit(v(3), blow.call(2, 0))
	ok(h._taken_rounded(v(3), 5) == -1 and HUD.amount_text("-", 5, "#f00", -1) == "[i][color=#f00]-5[/color][/i]" and HUD.amount_text("-", 5, "#f00", 1).begins_with("[b]"), "a use's blows, one way rounded: its log amount is italic (down) or bold (up)")
	ok(h._taken_rounded(v(3), 4) == 0, "an amount that is not all of those blows: plain")
	h._on_taking_hit(v(3), blow.call(1, 1))
	ok(h._taken_rounded(v(3), 6) == 0 and HUD.amount_text("-", 6, "#f00", 0) == "[color=#f00]-6[/color]", "rounded both ways: plain")
	for box: RichTextLabel in [h.log_box, h.get_node("%LogLine")]:
		ok(box.get_theme_font(&"italics_font").variation_transform.y.x != 0.0 and box.get_theme_font(&"bold_font").variation_embolden > 0.0, "the log's italics and bold faces are the slanted and heavy ones")
	h.free()
