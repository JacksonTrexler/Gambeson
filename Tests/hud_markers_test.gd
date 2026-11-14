extends Test

# What the map, card and hotbar say of the unit (HUD.gd, Unit.gd, SkillSlot.gd): the target choice asks every
# behaviour's fits() as Battle.cast() does (Resuscitate: only the Downed), a Borrowed Time chip, a mark on the
# slot of a Mana / Stamina switch in progress, a Downed unit lying on its side, a bar for every reserve held.

var resuscitate: Skill = load("res://Skills/resuscitate.tres")
var tenacity: Skill = load("res://Skills/tenacity.tres")
var borrowed: Skill = load("res://Skills/borrowed_time.tres")
var stamina: Skill = load("res://Skills/stamina.tres")
var focus: Skill = load("res://Skills/focus.tres")
var stamina_pool: Reserve = load("res://Reserves/stamina.tres")
var focus_pool: Reserve = load("res://Reserves/focus.tres")
var sweet: Reserve = load("res://Reserves/sweet_nothings.tres")
var mana_skill: Skill = load("res://Skills/mana.tres")


func unit(n: String) -> Unit:
	return b.get_node("Units/" + n)


func start(leader: Unit) -> HUD:
	b.player = leader
	var h: HUD = load("res://Scenes/UI/hud.tscn").instantiate()
	h.battle = b
	h.auto = false
	h.pace = 0.0
	tree.root.add_child(h)
	await tree.process_frame
	return h


func test_target_gating() -> void:
	v(1).learned.append(slot(resuscitate, 2))
	v(2).learned.append(slot(tenacity, 3))
	stage(lancin, {v(1): Vector2i(4, 3), v(2): Vector2i(5, 3), v(3): Vector2i(8, 6)})
	v(1).refresh()
	var h := await start(v(1))
	ok(h.why_not(v(1), resuscitate, v(2)) == "Only the Downed", "a standing ally isn't a target: %s" % h.why_not(v(1), resuscitate, v(2)))
	ok(h.skill_glow(v(1), resuscitate, v(2)) == -1, "and doesn't glow for it")
	h.free()
	v(2).damage(999)
	ok(v(2).dbno != null, "Downed")
	h = await start(v(1))
	ok(h.why_not(v(1), resuscitate, v(2)) == "" and h.skill_glow(v(1), resuscitate, v(2)) == Unit.Intensity.FULLY, "a Downed one beside it is: it glows fully")
	h.free()


func test_borrowed_chip() -> void:
	v(3).learned.append(slot(borrowed, 2))
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3), v(4): Vector2i(8, 6)})
	v(3).refresh()
	v(3).max_hp = 100
	v(3).hp = 100
	var h := await start(v(3))
	ok(not h._info(v(3)).chips.any(func(c): return c[0].begins_with("Borrowed")), "no chip before it's borrowing")
	v(3).damage(20)
	v(3).damage(999)
	ok(v(3).deferred == 2, "on borrowed time")
	var chips: Array = h._info(v(3)).chips.map(func(c): return c[0])
	ok("Borrowed time: 2 rounds left" in chips and "2 harms to replay" in chips, "its card says how long, and the harms waiting (%s)" % [chips])
	h.free()


func test_switch_marked() -> void:
	var icor := unit("Icor")
	stage(nemes, {icor: Vector2i(7, 3), v(1): Vector2i(1, 2)})
	var h := await start(icor)
	var marked := func() -> Array:
		return h.bar.get_children().filter(func(s: SkillSlot): return s.switching).map(func(s: SkillSlot): return s.skill)
	ok(marked.call() == [], "no slot marked at first")
	h.use_slot(2)
	await tree.process_frame
	ok(icor.switching() == &"energy" and marked.call() == [mana_skill], "switching off Mana: its slot is marked")
	ok((h.bar.get_child(2) as SkillSlot).tooltip_text.contains("Switching to Energy"), "and says to what")
	h.use_slot(2)
	await tree.process_frame
	ok(icor.switching() == null and marked.call() == [], "done: the mark goes")
	h.free()


func test_downed_lies() -> void:
	v(2).learned.append(slot(tenacity, 3))
	stage(lancin, {v(1): Vector2i(4, 3), v(2): Vector2i(5, 3), v(3): Vector2i(8, 6)})
	var sat := func(u: Unit) -> float: return u.sprite.material.get_shader_parameter(&"saturation")
	ok(v(2).sprite.rotation == 0.0 and sat.call(v(2)) == 1.0, "upright, full colour")
	v(2).damage(999)
	ok(v(2).dbno != null and absf(v(2).sprite.rotation) > 1.0 and v(2).sprite.position.y > 0.0, "Downed: lying on its side, lowered")
	ok(is_equal_approx(sat.call(v(2)), Unit.DOWN_SAT), "and drained of some colour")
	v(2).set_saturation(0.5)
	ok(is_equal_approx(sat.call(v(2)), 0.5 * Unit.DOWN_SAT), "whatever the HUD asks of it scales")
	v(2).heal(30)
	ok(v(2).dbno == null and v(2).sprite.rotation == 0.0 and v(2).sprite.position.y == 0.0 and is_equal_approx(sat.call(v(2)), 0.5), "healed, it stands again")


func test_every_reserve() -> void:
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	var u := v(1)
	u.learned.append(slot(stamina))
	u.learned.append(slot(focus))
	u.reserves[sweet] = 4
	u.energy = 0
	u.set_store(stamina_pool, 3)
	u.set_store(focus_pool, 2)
	u.set_store(sweet, 4)
	u.appear(null)
	var held := u.held_reserves()
	ok(held.size() == 3 and held[0] == stamina_pool, "holds three: %s" % [held.map(func(r): return r.name)])
	ok(u.reserve_bar.visible and u.second_bar.visible and u.more_bars.size() == 1 and u.more_bars[0].visible, "a bar each: the third a sliver")
	ok(u.more_bars[0].size.y == 1.0 and u.more_bars[0].value == u.store(sweet) and u.store(sweet) > 0, "1px, with its store")
	ok((u.more_bars[0].get_theme_stylebox("fill") as StyleBoxFlat).bg_color == held[2].color, "in its colour")
	var bottom := u.more_bars[0].position.y + 1.0
	ok(u.second_bar.position.y + 2.0 == u.more_bars[0].position.y or u.more_bars[0].position.y + 1.0 == u.second_bar.position.y, "stacked with the rest")
	ok(u.trim.position.y + u.trim.size.y - 1.0 >= bottom, "inside the trim")
	u.learned.clear()
	u.reserves.erase(sweet)
	u.appear(null)
	ok(not u.more_bars[0].visible, "gone with the reserve")
