extends Test

# The HUD driving a battle: selecting, hover planning and moving, number keys arming skills and
# clicks landing them, toggles, orders to allies in range, the party, the spellbook and hotbar
# drops, allies acting on their own as the turn ends, and a whole battle played through the HUD.

var arcanist: Skill = load("res://Skills/arcanist.tres")


func unit(n: String) -> Unit:
	return b.get_node("Units/" + n)


# A HUD on the test battle, led by `leader`, that leaves other sides alone; ready once a frame passes.
func start(leader: Unit) -> HUD:
	b.player = leader
	var h: HUD = load("res://Scenes/UI/hud.tscn").instantiate()
	h.battle = b
	h.auto = false
	h.pace = 0.0
	tree.root.add_child(h)
	await tree.process_frame
	return h


func key(k: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = k
	e.pressed = true
	return e


func test_select_and_move() -> void:
	stage(lancin, {v(1): Vector2i(1, 2), v(3): Vector2i(8, 2)})
	var h := await start(v(1))
	ok(h.selected == v(1) and h.my_turn(), "the leader is selected as its turn starts")
	h.hover_cell(Vector2i(3, 2))
	ok(h.plan.path.back() == Vector2i(3, 2), "hovering a tile plans the walk there")
	ok("Walk here: 3 of 5" in h.tip_label.text and h.tip.visible, "the tip gives its cost (bramble 1, leaving it 1 + 1)")
	h._refresh()
	ok(Vector2i(3, 2) in h.reach and Vector2i(8, 7) not in h.reach, "reachable tiles are known")
	h.click(Vector2i(3, 2))
	ok(v(1).cell == Vector2i(3, 2) and v(1) in h.command.ordered, "clicking walks there")
	h.click(Vector2i(8, 2))
	ok(h.selected == v(3), "clicking a unit selects it")
	h.click(Vector2i(8, 3))
	ok(v(3).cell == Vector2i(8, 2) and h.selected == null, "an enemy takes no orders; clicking away lets go")
	h.free()


func test_keys_and_targets() -> void:
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	var h := await start(v(1))
	h._unhandled_input(key(KEY_1))
	ok(h.armed == strike, "1 arms Strike")
	ok(h.targets().size() == 1 and h.targets()[0] == v(3), "the enemy in reach is its one target")
	h.hover_cell(Vector2i(5, 3))
	ok("Click to use: 3 AP · 2 damage" in h.tip_label.text, "hovering it forecasts the cost and damage")
	h.click(Vector2i(5, 3))
	ok(v(3).hp == 8 and h.armed == null and v(1) in h.command.ordered, "clicking it strikes (1 + str mod 1)")
	h._unhandled_input(key(KEY_1))
	h.click(Vector2i(6, 6))
	ok(h.armed == strike and h._note == "Pick a unit", "an empty tile isn't a target")
	h._unhandled_input(key(KEY_1))
	ok(h.armed == null, "the same key again disarms")
	h._unhandled_input(key(KEY_1))
	h._unhandled_input(key(KEY_ESCAPE))
	ok(h.armed == null and h.selected == v(1), "Esc disarms first")
	h._unhandled_input(key(KEY_ESCAPE))
	ok(h.selected == null, "then lets go")
	h.free()


func test_toggle_from_bar() -> void:
	var icor := unit("Icor")
	stage(nemes, {icor: Vector2i(7, 3), v(1): Vector2i(1, 2)})
	var h := await start(icor)
	h._unhandled_input(key(KEY_2))
	ok(not icor.is_on(arcanist) and h.armed == null, "2 switches Arcanist Perspective off")
	h.use_slot(1)
	ok(icor.is_on(arcanist), "and on again")
	h.free()


func test_orders_in_range() -> void:
	var al := unit("Alabaster")
	stage(lancin, {v(1): Vector2i(1, 2), v(2): Vector2i(2, 3), al: Vector2i(5, 5), v(3): Vector2i(8, 2)})
	var h := await start(v(1))
	h.click(Vector2i(2, 3))
	h.click(Vector2i(3, 3))
	ok(v(2).cell == Vector2i(3, 3), "an ally a step from the leader takes orders")
	h.click(Vector2i(5, 5))
	h.click(Vector2i(5, 4))
	ok(al.cell == Vector2i(5, 5) and h._note.begins_with("Too far"), "one further off doesn't, and the hint says why")
	h.free()


func test_party() -> void:
	stage(lancin, {v(1): Vector2i(1, 2), v(2): Vector2i(2, 2), v(3): Vector2i(8, 2)})
	var h := await start(v(1))
	h.select(v(2))
	h._unhandled_input(key(KEY_P))
	ok(v(2) in h.command.party, "P invites the selected ally")
	h.select(v(1))
	h.click(Vector2i(1, 0))
	h.select(v(2))
	ok(h._orders(v(2)), "2 tiles from the leader, a party member still takes orders")
	h._unhandled_input(key(KEY_P))
	ok(v(2) not in h.command.party and not h._orders(v(2)), "P again lets it go; now it's too far")
	h.free()


func test_spellbook_and_bar() -> void:
	var icor := unit("Icor")
	stage(nemes, {icor: Vector2i(7, 3), v(1): Vector2i(1, 2)})
	var h := await start(icor)
	h._unhandled_input(key(KEY_B))
	ok(h.spellbook.visible and h.spellbook.unit == icor, "B opens the selected unit's spellbook")
	var actives := h.spellbook.actives.get_children()
	var passives := h.spellbook.passives.get_children()
	ok(actives.size() == 1 and actives[0].skill == hex and passives.size() == 1 and passives[0].skill == arcanist, "Hex under Active, Arcanist Perspective under Passive")
	ok(actives[0].get_child(0).get_child(0).text == "III", "ranks in numerals")
	ok(passives[0].draggable, "a toggled passive can go on the bar")
	var slot: SkillSlot = h.bar.get_child(3)
	var data := {skill = arcanist, from = -1}
	ok(slot._can_drop_data(Vector2.ZERO, data), "a hotbar slot takes it")
	slot._drop_data(Vector2.ZERO, data)
	ok(icor.hotbar[3] == arcanist and icor.hotbar[1] == null, "dropped in slot 4, it leaves slot 2")
	var right := InputEventMouseButton.new()
	right.button_index = MOUSE_BUTTON_RIGHT
	right.pressed = true
	(h.bar.get_child(0) as SkillSlot)._on_gui_input(right)
	ok(icor.hotbar[0] == null, "right-clicking a slot empties it")
	h._unhandled_input(key(KEY_B))
	ok(not h.spellbook.visible, "B closes it")
	h.select(v(1))
	h._unhandled_input(key(KEY_B))
	ok(h.spellbook.unit == icor, "with an enemy selected, B opens your own unit's")
	h.free()
	var h2: HUD = await start(v(1))
	h2._unhandled_input(key(KEY_B))
	ok(not (h2.spellbook.passives.get_child(0) as SkillEntry).draggable, "a passive without a toggle can't go on the bar")
	ok(not (h2.bar.get_child(0) as SkillSlot)._can_drop_data(Vector2.ZERO, {skill = favour, from = -1}), "nor be dropped there")
	h2.free()


func test_end_turn() -> void:
	var al := unit("Alabaster")
	stage(lancin, {v(1): Vector2i(1, 2), v(2): Vector2i(1, 3), al: Vector2i(2, 6), v(3): Vector2i(5, 6), v(4): Vector2i(9, 0)})
	var h := await start(v(1))
	h.select(v(2))
	h._unhandled_input(key(KEY_H))
	ok(v(2) in h.command.ordered, "H holds an ally")
	h._unhandled_input(key(KEY_SPACE))
	ok(al.cell != Vector2i(2, 6) and v(2).cell == Vector2i(1, 3) and v(1).cell == Vector2i(1, 2), "on ending the turn the ally without orders acts; the held one and the leader don't")
	await tree.process_frame
	ok(b.turn == nemes and not h.my_turn(), "then the turn passes")
	h.free()


func test_what_shows() -> void:
	var siren := unit("Siren")
	stage(lancin, {v(1): Vector2i(5, 6), siren: Vector2i(6, 6), v(3): Vector2i(4, 6)})
	v(3).afflict(effect("concealment", 4), 9)
	var h := await start(v(1))
	var info := h._info(siren)
	ok(info.chips[0][0] == "Friendly" and info.name != "Siren", "the Siren's persona: it shows as a friend, not by name")
	ok(not ("Siren" in h._tag(siren)), "nor does the log give it away")
	h.use_slot(0)
	ok(h.targets().is_empty(), "Strike offers neither the 'friend' nor a unit it can't make out")
	h.click(Vector2i(4, 6))
	ok(v(3).hp == 10 and h._note == "Pick a unit", "clicking where the hidden one stands finds nothing")
	h.disarm()
	h.click(Vector2i(4, 6))
	ok(h.selected == v(1) and v(1).cell == Vector2i(5, 6), "nor selected: the click is a move, and bumps into it")
	h.free()


func test_play_scene() -> void:
	Game.starter = {faction = lancin, role = load("res://Roles/fighter.tres"), name = "Tess"}
	var scene: Node = load("res://Scenes/play.tscn").instantiate()
	var pb: Battle = scene.get_node("Museum/Battle")
	pb.rng.seed = 3
	var h: HUD = scene.get_node("HUD")
	h.pace = 0.0
	tree.root.add_child(scene)
	ok(h.command.leader == pb.player and pb.player.nick == "Tess", "the starter leads")
	var frames := 0
	while pb.phase == Battle.Phase.TURNS and frames < 500:
		await tree.process_frame
		frames += 1
		if h.my_turn():
			h.end_turn()
	await tree.process_frame
	ok(pb.phase == Battle.Phase.OVER and h.over.visible, "ending every turn, the battle plays out and says who won (%d frames)" % frames)
	scene.free()
